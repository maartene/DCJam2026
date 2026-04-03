# Evolution — game-polish-v1

**Date**: 2026-04-03
**Feature**: game-polish-v1
**Status**: DELIVERED

---

## Summary

Delivered a comprehensive visual and UX polish pass for Ember's Escape (DCJam 2026). The feature introduced a start screen, transient combat feedback overlays, HP bar color progression, status bar color semantics, a fully colored minimap, improved win screen, egg discovery narrative color, and centralized ANSI color constants. 206 tests pass; adversarial review approved with no defects.

---

## What Was Implemented

### New Types (GameDomain)

| Type | Description |
|------|-------------|
| `TransientOverlay` enum | Three cases: `braceSuccess` (SHIELDED!), `braceHit` (STRUCK!), `dash` (SWOOSH!) — each carrying a `framesRemaining: Int` countdown |
| `ScreenMode.startScreen` | New case added to the existing `ScreenMode` enum; drives start-screen rendering strategy |

### GameState Changes

- Added `transientOverlay: TransientOverlay?` field — nil when no overlay is active.
- Added `withTransientOverlay(_ overlay: TransientOverlay?) -> GameState` helper for pure-function state updates.
- `GameState.initial()` now returns `.startScreen` mode instead of `.dungeon`, ensuring the game does not immediately drop the player into gameplay.

### RulesEngine Changes

- Start screen transitions to `.dungeon` on any non-idle command. Timers are paused while on the start screen.
- Transient overlay lifecycle: set on brace parry (`braceSuccess`), unbraced hit (`braceHit`), and dash (`dash`). `advanceTimers` decrements `framesRemaining` each tick and clears the overlay when it reaches zero.

### InputHandler Changes

- Q / Shift-Q quit removed. ESC is now the sole quit key, eliminating accidental quit during gameplay.

### Renderer Changes

| Area | Change |
|------|--------|
| `renderStartScreen()` | Full-screen start screen with game title, controls list (no Q), and "Press any key to begin" prompt |
| `renderTransientOverlay()` | Centered at row 9: SHIELDED! (bright cyan) for `braceSuccess`, STRUCK! (bright red) for `braceHit`, SWOOSH! (bold white) for `dash` |
| HP bar color | Green (≥40% HP), yellow (≥20%), red (<20%) — communicates danger state visually |
| Special/cooldown status bar | Bold bright cyan when ready, dim cyan when charging, yellow on cooldown |
| Minimap per-cell colors | Player = bold white, G = red, B = bold red, * = bright yellow, e = yellow, S = cyan, X = bold cyan, E = dim cyan, # = gray |
| Win screen | Added stat block showing HP and floors cleared; "Press R to play again" instruction |
| Egg discovery narrative | ANSI color applied to egg discovery text |

### New Infrastructure

- `ANSIColors.swift` — centralized ANSI escape constant definitions and a `colored(_ text: String, _ code: String) -> String` helper. Eliminates raw escape strings scattered across the renderer.

---

## Architecture Decisions

### D1: `TransientOverlay` as a domain enum with `framesRemaining`

Overlay lifetime is tracked as a frame countdown in the domain rather than a wall-clock duration. This keeps the overlay lifecycle deterministic and fully testable without time injection. The renderer inspects the overlay case and renders the appropriate string; the rules engine decrements the counter on each `advanceTimers` call.

Alternatives considered:
- Wall-clock duration with `Date` — rejected because it introduces impure state into `GameState` and complicates testing.
- Renderer-side timer — rejected because overlay state belongs in the domain; the renderer is stateless.

### D2: `ScreenMode.startScreen` rather than a separate `isOnStartScreen: Bool` flag

Consistent with the existing `ScreenMode` pattern. The renderer already switches on `ScreenMode`; adding a case costs nothing and avoids a parallel Boolean that could desync.

### D3: Centralize ANSI constants in `ANSIColors.swift`

Raw ANSI strings embedded inline in `Renderer.swift` are fragile and hard to review. A single constants file with a `colored()` helper makes color usage greppable and auditable. This also aligns with the jam constraint of zero external TUI library dependencies.

### D4: ESC as sole quit key

Q was a collision risk during play (players press letter keys for navigation and ability use). ESC is unambiguous and conventional for "exit this program." The change was made in `InputHandler` only; no domain changes required.

---

## Test Coverage

| Metric | Value |
|--------|-------|
| Total tests passing | 206 |
| New test files/suites added | 27 |
| Adversarial review result | APPROVED — no defects found |

New test coverage spans: `TransientOverlay` lifecycle (set, decrement, clear), start screen transition logic, ESC-only quit, HP bar color thresholds, status bar color states, overlay render text and color codes, minimap cell color output, win screen stat block content, and `ANSIColors` helper correctness.

---

## Execution Steps

| Step | Description | Result |
|------|-------------|--------|
| 01 | `TransientOverlay` enum + `ScreenMode.startScreen` in GameDomain | COMMIT |
| 02 | `GameState` — `transientOverlay` field, `withTransientOverlay()`, `initial()` start screen | COMMIT |
| 03 | `RulesEngine` — start screen transition, overlay lifecycle, `advanceTimers` decrement | COMMIT |
| 04 | `InputHandler` — remove Q/Shift-Q quit | COMMIT |
| 05 | `Renderer` — `renderStartScreen()` implementation | COMMIT |
| 06 | `Renderer` — `renderTransientOverlay()` implementation | COMMIT |
| 07 | `Renderer` — HP bar color thresholds | COMMIT |
| 08 | `Renderer` — special/cooldown status bar colors | COMMIT |
| 09 | `Renderer` — minimap per-cell color writes | COMMIT |
| 10 | `Renderer` — win screen stat block | COMMIT |
| 11 | `Renderer` — egg discovery narrative color | COMMIT |
| 12 | `ANSIColors.swift` — centralized constants and `colored()` helper | COMMIT |
| 13 | Test suite — 27 new test files/suites, 206 total passing | PASS |
| 14 | Adversarial review | APPROVED |

---

## Lessons Learned

1. **Frame-count overlays are more testable than wall-clock overlays.** Representing `framesRemaining` as an integer in the domain means every test can drive the overlay to expiry by calling `advanceTimers` N times with a fixed delta — no `Date` mocking required.

2. **Centralizing ANSI constants pays off during review.** With raw escape strings inline, a reviewer cannot easily audit which colors are used where. `ANSIColors.swift` made the adversarial review faster and gave the reviewer a single grep target.

3. **Single quit key removes an entire class of playtest complaints.** The Q-key removal was low-effort but high-impact: accidental quit is one of the most disruptive moments in a jam playtest session.

4. **Color semantics need to be consistent with game feel.** HP bar green/yellow/red maps to the player's mental model of health in any game. Status bar cyan/dim-cyan/yellow communicates "ready / charging / cooling" in a way that matches the ability design. Picking colors that reinforce semantics — rather than purely aesthetic choices — reduces the cognitive load on the player.

5. **27 new test suites for a polish feature is not overkill.** Visual/color output is easy to regress silently. Snapshot-style tests on the rendered strings give the next contributor confidence that a refactor hasn't broken a color code or overlay message.

---

## Files Modified

| File | Change type |
|------|-------------|
| `Sources/GameDomain/TransientOverlay.swift` | New |
| `Sources/GameDomain/GameState.swift` | Modified — `transientOverlay` field, `withTransientOverlay()`, `initial()` |
| `Sources/GameDomain/ScreenMode.swift` | Modified — `startScreen` case |
| `Sources/GameDomain/RulesEngine.swift` | Modified — start screen transition, overlay lifecycle |
| `Sources/App/InputHandler.swift` | Modified — remove Q/Shift-Q |
| `Sources/App/Renderer.swift` | Modified — all rendering changes |
| `Sources/App/ANSIColors.swift` | New |
| `Tests/` (27 files) | New test suites |
