# CLAUDE.md — Ember's Escape (dcjam2026-core)
**Status**: FINAL — paradigm confirmed by developer 2026-04-02
**Date**: 2026-04-02

This file captures architectural constraints and decisions that all waves (crafter, tester, architect) must respect.

---

## Project Identity

- **Game**: Ember's Escape — you are Ember, a young dragon reclaiming your stolen egg from a dungeon.
- **Jam**: DCJam 2026
- **Scope**: Jam-only. Every feature must pass the question: "Is this necessary for a submittable entry?"
- **Language**: Swift 6.3 (developer preference; not a jam requirement)
- **Platform**: macOS/Linux terminal (ANSI-capable)

---

## Architecture: Confirmed Decisions

### Module Structure (Six SwiftPM Targets)

```
GameDomain      — Pure domain logic. Zero imports from other modules.
TUILayer        — ANSI adapter. Raw terminal I/O. Platform isolation here only.
InputHandler    — Non-blocking keyboard input → GameCommand.
Renderer        — GameState → draw calls via TUIOutputPort protocol.
GameLoop        — Real-time tick driver. Plain class. Owns mutable state. No @MainActor.
DCJam2026       — Entry point. Bootstrap only.
```

**Dependency rule (enforced by SwiftPM)**: `GameDomain` has NO dependencies. `GameLoop` is the only module that imports all others. Violations are build errors.

### TUI Layer: Raw ANSI, No External Library

No TUI library dependencies in `Package.swift`. The `TUILayer` module (~150-200 lines) implements:
- ANSI cursor positioning, color, clear screen
- Unicode box-drawing characters (U+2500 block)
- `tcsetattr` raw mode + `O_NONBLOCK` stdin for non-blocking input
- `TUIOutputPort` protocol as the adapter boundary

Do NOT add SwiftTerm, SwiftTUI, or ncurses bindings. See ADR-001.

**Terminal write rule (validated by spike + research)**: `write()` to a tty is NOT guaranteed to consume all bytes in one call. All terminal output MUST use a looping write pattern that handles both short writes and `EINTR`:
```
while offset < bytes.count {
    let n = write(STDOUT_FILENO, ptr + offset, bytes.count - offset)
    if n > 0        { offset += n }
    else if errno == EINTR { continue }   // signal interrupted — retry
    else            { break }             // real error
}
```

**Non-blocking input rule (critical)**: NEVER call `fcntl(STDIN_FILENO, F_SETFL, O_NONBLOCK)`. On macOS, stdin and stdout share the same underlying tty file description — making stdin non-blocking also makes stdout non-blocking. This causes `write()` to return `EAGAIN` mid-frame, splitting multi-byte UTF-8 sequences and producing U+FFFD corruption. Instead, open a **separate** fd for non-blocking input:
```swift
let inputFD = open("/dev/tty", O_RDONLY | O_NONBLOCK)
// Read from inputFD. STDOUT_FILENO stays blocking.
```

### First-Person Rendering: Lookup Table

First-person dungeon view uses pre-authored ASCII art frames. No ray-casting. No procedural line drawing. See ADR-003.

**Screen layout (fixed 80×25 terminal):**
```
┌──────────────────────────────────────────────────────────────────────────────┐ row 1
│                                                                              │
│                         dungeon view (78×15 interior)                        │
│                                                                              │ rows 2-16
├──────────────────────────────────────────────────────────────────────────────┤ row 17
│ HP [====] EGG [*]  (1)DASH[2](cd=12s)  (2)BRACE  (3)SPEC[====]             │ row 18
├─Thoughts─────────────────────────────────────────────────────────────────────┤ row 19
│ "..."                                                                        │ rows 20-22
│ "..."                                                                        │
│ "..."                                                                        │
│                                                                              │ rows 23-24
└──────────────────────────────────────────────────────────────────────────────┘ row 25
```

**Frame key — `DungeonFrameKey`:**
```swift
struct DungeonFrameKey: Hashable {
    let depth: Int       // 0=close wall  1=mid wall  2=far wall (brick)  3=fog
    let nearLeft: Bool   // opening at player's position going left
    let nearRight: Bool  // opening at player's position going right
    let farLeft: Bool    // opening one square ahead going left  (depth >= 1 only)
    let farRight: Bool   // opening one square ahead going right (depth >= 1 only)
}
```

**Depth values:**
| depth | meaning | far-wall rendering |
|-------|---------|-------------------|
| 0 | wall right in front | fills most of the view |
| 1 | wall one square ahead | solid wall face, no texture |
| 2 | wall two squares ahead | sparse `▓░` brick detail — a few chars only |
| 3 | corridor continues past draw distance | `·` fog dots, no wall face |

**Wireframe style:** `\` `/` `|` `_` for all perspective and corridor lines. No shading, no filled regions.

**Brick rule:** `▓░` used at depth=2 only, sparingly (a handful of chars on the wall face). Never repeated patterns that overwhelm the view.

**Frame inventory:** 52 total combinations (4 depths × 2⁴ near/far left/right). Author only frames the dungeon generator can actually produce; fall back gracefully to the closest match for any combination not explicitly authored. Left↔right mirror symmetry halves authoring effort (~30 unique frames at most, likely far fewer in practice).

### Game Loop: Synchronous, Delta-Time Driven

- 30 Hz synchronous blocking `while` loop — plain `class` (or `struct` with `mutating` run loop)
- No `@MainActor`, no `async/await`, no Swift concurrency primitives in the hot path. A synchronous loop does not require concurrency guards — there is no concurrent access to race on.
- Delta-time passed to `TimerModel.advance(delta:)` for Dash cooldowns and Special charge
- No `DispatchQueue.asyncAfter`, no `Timer`, no `Task.sleep` for game timers
- All timers are deterministic and testable via injected delta values

### Screen Modes (Renderer Strategy Selection)

The `ScreenMode` enum (in `GameDomain`) drives all rendering strategy selection:
```
.dungeon                          — three-region layout
.combat(encounter: EncounterModel) — combat screen
.narrativeOverlay(event: NarrativeEvent) — egg / special / exit overlays
.upgradePrompt(choices: [Upgrade]) — milestone upgrade choice
.deathState                       — death screen
.winState                         — win screen
```

---

## Architecture: Paradigm — CONFIRMED

**Value-Oriented OOP** — confirmed by developer 2026-04-02. See ADR-002.

- **Domain types**: `struct` (value types) — `GameState`, `FloorMap`, `EncounterModel`, `TimerModel`, `UpgradePool`, `ThoughtsLog`, `GameConfig`
- **Domain transformations**: pure functions — input state + command + deltaTime → output state. No side effects in the domain.
- **Port boundaries**: `protocol` — `TUIOutputPort`, `InputPort`
- **Game loop**: plain `class GameLoop` (no `@MainActor`). The loop is synchronous and blocking; no concurrent access exists to guard against. Do not add `@MainActor` without a concrete async concurrency need.
- **Stateless namespaces**: `RulesEngine` and `FloorGenerator` are enums with static methods or structs with no stored properties

---

## Key Game Rules (Invariants)

These are domain rules that must never be violated by any implementation:

| Rule | Source |
|------|--------|
| Dash charges cap starts at 2; each replenishes at ~45s (configurable) | DEC-08 |
| Special charge starts at 0; cannot be full on first encounter | DEC-10 |
| Win requires BOTH hasEgg=true AND position=exitSquare | INT-01 |
| Dash is blocked during boss encounter only (SA-11 flag, not floor number) | REQ-09 |
| Normal movement is locked when adjacent to enemy; only Dash exits | DISC-03 |
| All combat/movement text uses dragon vocabulary | DEC-04 |
| No timers as pressure mechanics; Dash cooldown is a readiness state | DEC-02 |
| Egg room: floors 2-4 only, exactly one per run | REQ-04 |
| Exit patio: floor 5 only | REQ-04 |
| On restart: ALL state resets (hp, dash, special, egg, floor, upgrades) | INT-04 |
| **Brace = timed invulnerability window, NOT damage reduction** | 2026-04-02 design session |
| Brace opens a 0.5 s parry window; enemy attacks on a 2.0 s fixed timer | 2026-04-02 design session |
| Successful parry (enemy attack lands during window): 0 damage + 15% Special bonus | 2026-04-02 design session |
| Unbraced hit (no active window): full encounter damage | 2026-04-02 design session |
| Brace has a 1.5 s cooldown — cannot be spammed | 2026-04-02 design session |
| Regular encounters must be dangerous enough to require Brace (teaches mechanic before boss) | 2026-04-02 design session |

---

## Tuning Constants (GameConfig defaults)

| Constant | Default | Notes |
|----------|---------|-------|
| `dashCooldownSeconds` | `45.0` | Per charge |
| `specialChargeRatePerSecond` | `0.008` | ~125s to full charge |
| `maxHP` | `100` | |
| `enemyAttackInterval` | `2.0` | Seconds between enemy attacks — sets combat rhythm |
| `braceWindowDuration` | `0.5` | Invulnerability window length after Brace input |
| `braceCooldownSeconds` | `1.5` | Cooldown before Brace can be used again |
| `braceSpecialBonus` | `0.15` | Special charge gained on a successful parry |
| `maxFloors` | `5` | 3 = minimum viable |
| `upgradeChoiceCount` | `3` | From pool of 8 |

---

## Out of Scope (Jam Entry)

Do not implement:
- Slash/melee attack (post-jam fallback only)
- Pomander-style floor bonuses
- Food as stat system
- Elemental RPS
- Free movement in combat (only Dash exits encounters)
- Tutorial text (mechanical state teaches organically)
- Post-jam expansion features

---

## Mutation Testing Strategy

Mutation testing is **disabled** for the `zero-download-deployment` infrastructure feature. The Node.js WebSocket bridge (`infrastructure/web/server.js`) is transparent byte-pipe infrastructure with no domain logic to mutate. Test quality is validated through port-to-port acceptance tests and manual smoke testing.

For `GameDomain` and `App` Swift targets: no mutation testing strategy is set — default to per-feature if configured in future.

---

## zero-download-deployment Bridge Notes

Terminal size protocol: **query parameters** (`ws://localhost:3000/game?cols=80&rows=25`). Confirmed 2026-04-04.

Bridge server location: `infrastructure/web/server.js`  
Acceptance tests: `infrastructure/tests/acceptance/steps/bridge.test.js`  
Deployment config: `infrastructure/deploy/`
