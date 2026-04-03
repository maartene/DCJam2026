# Component Boundaries — game-polish-v1
**Feature**: game-polish-v1
**Date**: 2026-04-03
**Author**: Morgan (Solution Architect — DESIGN wave)

---

## Boundary Invariants (Must Not Be Violated)

1. **GameDomain has zero imports.** Any ANSI escape string, terminal concern, or I/O call
   in GameDomain is a boundary violation.
2. **App depends on GameDomain, never the reverse.** SwiftPM enforces this at build time.
3. **RulesEngine is a stateless pure function.** It takes `(GameState, GameCommand, deltaTime)`
   and returns `GameState`. No side effects, no stored properties.
4. **Renderer reads GameState; it never mutates it.** Renderer is a pure consumer.

---

## Component Responsibility Table

### GameDomain module

| Component | File | Responsibility | game-polish-v1 changes |
|-----------|------|---------------|------------------------|
| `ScreenMode` | `ScreenMode.swift` | Enum driving Renderer strategy selection | Add `.startScreen` case |
| `GameState` | `GameState.swift` | Complete run snapshot as value type | Add `transientOverlay: TransientOverlay?` field + `withTransientOverlay()` helper |
| `RulesEngine` | `RulesEngine.swift` | Pure state transformer | `applyEnemyAttackTick()` sets brace overlays; `applyDash()` sets dash overlay; `advanceTimers()` decrements overlay countdown; `applyConfirmOverlay()` handles `.startScreen` |
| `NarrativeEvent` | `NarrativeEvent.swift` | Full-screen keypress-dismissed overlay identifiers | **Unchanged** |
| `TimerModel` | `TimerModel.swift` | Dash cooldown slot tracking | **Unchanged** |
| `TransientOverlay` | `TransientOverlay.swift` (new file) | Value type for auto-clearing in-game feedback overlays | New type |

### App module (DCJam2026)

| Component | File | Responsibility | game-polish-v1 changes |
|-----------|------|---------------|------------------------|
| `Renderer` | `Renderer.swift` | GameState → ANSI draw calls via TUIOutputPort | Multiple changes — see below |
| `InputHandler` | `InputHandler.swift` | Raw bytes → GameCommand; owns `shouldQuit` flag | Remove Q/Shift-Q quit branch |
| `ANSITerminal` | `ANSITerminal.swift` | Concrete TUIOutputPort; buffered atomic writes | **Unchanged** |
| `TUIOutputPort` | `TUIOutputPort.swift` | Adapter boundary protocol | **Unchanged** |
| `GameLoop` | `GameLoop.swift` | 30Hz synchronous tick driver | **Unchanged** |
| `ANSIColors` | `ANSIColors.swift` (new file) | Module-private ANSI color constants and helper functions | New file |

---

## Renderer Change Detail

`Renderer.swift` receives changes in five distinct zones. Each zone is independently
modifiable:

| Zone | Method | Change |
|------|--------|--------|
| Strategy dispatch | `render(_ state:)` | Add `.startScreen` case; add transient overlay layer after `.dungeon`/`.combat` base render |
| Start screen | `renderStartScreen()` (new) | Full-screen start layout, no chrome |
| Narrative content | `narrativeContent(.eggDiscovery)` | Replace text + embed ANSI colors from spike2 |
| Win screen | `renderWinScreen()` | Replace content with spike2 narrative + stats |
| Status bar | `drawStatusBar()` | HP bar color by threshold; SPEC color by ready state; cooldown colors |
| Minimap | `renderMinimap()` | Refactor from row-string to per-cell moveCursor+write+reset |

---

## TransientOverlay New Type

Location: `Sources/GameDomain/TransientOverlay.swift`

This is a new file in GameDomain. It contains only the enum definition.
It has no imports. It is a pure value type.

**Cases**:
- `.braceSuccess(framesRemaining: Int)` — parry window was active when enemy attacked
- `.braceHit(framesRemaining: Int)` — no parry window; full damage taken (and player survived)
- `.dash(framesRemaining: Int)` — dash resolved successfully

**Frame countdown constant**: 23 frames (named constant, not magic number).
Location of constant: `TransientOverlay.swift` as a `public static let defaultDuration = 23`.

**Decrement rule**: Each case's `framesRemaining` is decremented by `RulesEngine.advanceTimers()`
on every tick. When the value reaches 0, `GameState.transientOverlay` is set to `nil`.

---

## RulesEngine Change Boundaries

Three private static methods in `RulesEngine.swift` gain changes. No public API changes.

### `advanceTimers(_:deltaTime:)`

After all existing timer decrements, add:

1. Decrement `transientOverlay` countdown if non-nil.
2. If countdown reaches 0, set `transientOverlay = nil`.

This is the sole location where overlay lifetime is managed. The Renderer never writes
to `transientOverlay`.

### `applyEnemyAttackTick(to:encounter:braceWasActive:)`

After the existing parry/hit branch:

- On parry success (`braceWasActive == true`): set `transientOverlay = .braceSuccess(framesRemaining: TransientOverlay.defaultDuration)`.
- On unbraced hit that does NOT kill (`newHP > 0`): set `transientOverlay = .braceHit(framesRemaining: TransientOverlay.defaultDuration)`.
- On fatal hit (`newHP == 0`): set `transientOverlay = nil` (death screen takes priority).

### `applyDash(to:)`

After the existing position/charge update, set:
`transientOverlay = .dash(framesRemaining: TransientOverlay.defaultDuration)`.

### `applyConfirmOverlay(to:)`

Add a guard/branch for `case .startScreen` in `screenMode`:

When `state.screenMode == .startScreen` and `confirmOverlay` is received:
transition to `.dungeon`. This handles the "any key to begin" UX.

Note: `confirmOverlay` is already the command produced by space/enter. Since the
start screen should respond to _any_ key, `GameLoop` may also trigger `confirmOverlay`
for any non-nil command received while in `.startScreen`. Design-time choice: the
simplest approach is to treat any GameCommand (including `.none` on the first non-empty
poll) as a dismiss trigger in the Renderer-dispatch level. See ADR-009 for the chosen
approach.

---

## InputHandler Change Boundary

**File**: `Sources/App/InputHandler.swift`
**Method**: `mapKey(_ buf: [UInt8], count: Int)` (private)
**Change**: Remove the `case UInt8(ascii: "q"), UInt8(ascii: "Q"):` branch that sets
`shouldQuit = true`. The `default: break` path already returns `.none`, which is the
desired behavior.
**ESC behavior**: Unchanged. ESC remains the sole quit trigger via `shouldQuit = true`.

This change has no domain impact — `GameCommand` has no `quit` case; `shouldQuit` is
the App-layer quit signal read by `GameLoop`. The domain is unaffected.

---

## ANSIColors New File

Location: `Sources/App/ANSIColors.swift`

Module-private (no `public` modifier) constants and a color-wrapping helper.

**Contents**:
- ANSI escape constants: reset, bold, dim, fg codes for green/yellow/red/cyan/white variants.
- `func colored(_ text: String, code: String) -> String` — wraps text with code + reset.

This is a companion to `Renderer.swift`. Centralizing colors here prevents duplication
across `drawStatusBar()`, `renderMinimap()`, `renderNarrativeOverlay()`, and the
transient overlay layer.

**Rule**: No raw `"\u{1B}["` literals appear in `Renderer.swift`. All color output
routes through `ANSIColors.swift` helpers.

---

## What Each Module Does NOT Own

| Concern | Does NOT belong in |
|---------|-------------------|
| ANSI escape strings | GameDomain (any file) |
| Frame countdown decrement | Renderer (owned by RulesEngine) |
| Rendering strategy dispatch | GameDomain |
| Q-key shouldQuit flag | GameDomain |
| TransientOverlay display word | GameDomain (display text is a rendering concern, not a domain concern) |
