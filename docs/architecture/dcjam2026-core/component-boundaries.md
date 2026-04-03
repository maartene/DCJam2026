# Component Boundaries — Ember's Escape (dcjam2026-core)
**Feature**: dcjam2026-core
**Date**: 2026-04-02
**Author**: Morgan (Solution Architect — DESIGN wave)

---

## Module Map

Six modules (SwiftPM targets). Each module is a distinct directory under `Sources/`.

```
Sources/
  DCJam2026/           ← EntryPoint (executable target, wires all modules)
  GameDomain/          ← Pure game logic, zero I/O
  TUILayer/            ← ANSI adapter, raw terminal I/O
  InputHandler/        ← Non-blocking keyboard input → GameCommand
  Renderer/            ← GameState → draw calls via TUIOutputPort
  GameLoop/            ← Real-time tick driver, owns the run loop
```

---

## Dependency Graph

```
EntryPoint
  └─ GameLoop
       ├─ GameDomain  (no outgoing deps)
       ├─ Renderer
       │    ├─ GameDomain (read-only)
       │    └─ TUILayer (via TUIOutputPort protocol)
       ├─ InputHandler
       │    └─ TUILayer (for raw mode setup)
       └─ TUILayer
```

**Rule**: `GameDomain` has zero imports. It is the dependency sink. All arrows point toward it, none away.

---

## Module Specifications

### GameDomain

**Responsibility**: Everything the game "knows." Pure logic. No `print`, no `Foundation.Date`, no file I/O.

**Public surface** (what other modules may use):
- `GameState` — immutable value snapshot of all game variables
- `GameCommand` — enum of player actions: `.dash`, `.brace`, `.special`, `.confirmOverlay`, `.restart`, `.move(Direction)`, `.none`
- `RulesEngine` — pure functions: `apply(command:to:deltaTime:) -> GameState`
- `FloorGenerator` — pure functions: `generate(floorNumber:seed:) -> FloorMap`
- `FloorMap` — value type: grid, enemy positions, egg room, staircase, exit square
- `EncounterModel` — value type: enemy stats, boss flag (`isBossEncounter: Bool`)
- `UpgradePool` — value type + functions: upgrade definitions, draw logic, applied-upgrades tracking
- `ThoughtsLog` — value type: ordered array of `(timestamp, String)` entries
- `TimerModel` — value type: cooldown state for dash charges, special charge accumulator
- `GameConfig` — value type: all tunable constants (`dashCooldownSeconds`, `specialChargeRatePerSecond`, `dashStartingCharges`, `maxFloors`, etc.)
- `ScreenMode` — enum: `.dungeon`, `.combat(EncounterModel)`, `.narrativeOverlay(NarrativeEvent)`, `.upgradePrompt([Upgrade])`, `.deathState`, `.winState`
- `NarrativeEvent` — enum: `.eggDiscovery`, `.specialAttack`, `.exitPatio`

**What GameDomain must NOT contain**:
- Any `import TUILayer`, `import Renderer`, `import InputHandler`
- Any ANSI strings
- Any `print` or `write` calls
- Any wall-clock access (time is injected as `deltaTime: Double`)

**Boundary enforcement**: `GameDomain` is a separate SwiftPM `Target` with no declared dependencies. A forbidden import is a build error.

---

### TUILayer

**Responsibility**: All terminal I/O primitives. Single file of responsibility: "talk to the terminal."

**Public surface**:
- `TUIOutputPort` — protocol defining all drawing capabilities (the port; `Renderer` depends on this abstraction)
- `ANSITerminal` — concrete implementation of `TUIOutputPort` using ANSI escape codes
- `TerminalRawMode` — manages `tcsetattr` lifecycle (enter/exit raw mode, restore on exit)
- `TerminalSize` — queries terminal dimensions (`TIOCGWINSZ`), enforces 80×24 minimum

**Platform isolation**: `#if os(macOS)` / `#if os(Linux)` guards for `Darwin.POSIX` vs `Glibc` differences contained entirely here.

---

### InputHandler

**Responsibility**: Convert raw keyboard bytes into `GameCommand` values.

**Public surface**:
- `InputPort` — protocol: `poll() -> GameCommand?` (non-blocking)
- `KeyboardInputHandler` — concrete implementation: sets `O_NONBLOCK` on stdin, reads bytes, maps to `GameCommand`

**Key mapping** (configurable in `InputConfig` within this module):
- `1` → `.dash`
- `2` → `.brace`
- `3` → `.special`
- Arrow keys / `wasd` → `.move(Direction)`
- `Enter` / `Space` → `.confirmOverlay`
- `r` → `.restart`
- No key → `.none`

**Depends on**: `TUILayer` (for `TerminalRawMode` — raw mode must be enabled before input polling works)

---

### Renderer

**Responsibility**: Translate a `GameState` snapshot into a sequence of draw calls on `TUIOutputPort`.

**Public surface**:
- `GameRenderer` — `render(state: GameState)` — the single entry point

**Internal strategies** (not public, crafter decides decomposition):
- Three-region dungeon layout (first-person view + status line + Thoughts panel)
- Combat screen layout
- Narrative overlay screens (egg, special, exit patio)
- Upgrade prompt screen
- Death screen / win screen
- Status bar rendering (HP bar, Dash indicators, Special meter, EGG indicator)

**Depends on**:
- `GameDomain` (read-only, to interpret `GameState`)
- `TUILayer` via `TUIOutputPort` protocol (never direct ANSI strings)

**Testability**: Pass a mock `TUIOutputPort` that records draw calls as `[String]`. Assert snapshot output.

---

### GameLoop

**Responsibility**: Drive the real-time update cycle. Wire all modules. Own the single mutable game state.

**Public surface**:
- `GameLoop` — `run()` — blocking call that runs until win or quit

**Internal behavior**:
1. Initialize `GameState` from `FloorGenerator` and `GameConfig`
2. Enter terminal raw mode via `TerminalRawMode`
3. Loop at ~30 Hz:
   a. Measure `deltaTime`
   b. Poll `InputPort` → `GameCommand?`
   c. `RulesEngine.apply(command, to: currentState, deltaTime:)` → `newState`
   d. `Renderer.render(newState)`
   e. Update `currentState = newState`
4. Exit raw mode on loop termination

**Concurrency**: `@MainActor` isolation. The loop is synchronous. No `async`/`await` in the hot path.

**Depends on**: All other modules. This is the composition root — all dependencies are injected here.

---

### EntryPoint (DCJam2026 executable)

**Responsibility**: Bootstrap and run.

**Behavior**:
1. Check terminal size (warn if below 80×24)
2. Construct concrete implementations: `ANSITerminal`, `KeyboardInputHandler`, `GameLoop`
3. Call `GameLoop.run()`

**Depends on**: `GameLoop`, `TUILayer`

---

## Shared Artifact Traceability

The DISCUSS wave defined Shared Artifacts (SA-01 through SA-13). This table maps them to the component that owns each artifact.

| SA | Name | Owning Component |
|----|------|-----------------|
| SA-01 | DashChargeState | `GameDomain.GameState.dashCharges` + `TimerModel` |
| SA-02 | DashCooldownTimer | `GameDomain.TimerModel.dashCooldowns` |
| SA-03 | SpecialChargeState | `GameDomain.GameState.specialCharge` |
| SA-04 | EggCarryState | `GameDomain.GameState.hasEgg` |
| SA-05 | FloorProgressionState | `GameDomain.GameState.currentFloor` + `FloorGenerator` |
| SA-06 | PlayerHP | `GameDomain.GameState.hp` |
| SA-07 | ActiveUpgrades | `GameDomain.GameState.activeUpgrades` + `UpgradePool` |
| SA-08 | EggRoomPlacement | `GameDomain.FloorGenerator` (placement constraint) |
| SA-09 | ExitSquareState | `GameDomain.FloorMap.exitPosition` |
| SA-10 | UpgradePool | `GameDomain.UpgradePool` |
| SA-11 | BossEncounterFlag | `GameDomain.EncounterModel.isBossEncounter` |
| SA-12 | ThoughtsLog | `GameDomain.ThoughtsLog` |
| SA-13 | ScreenLayout | `Renderer` (layout strategy) + `GameDomain.ScreenMode` |

---

## Integration Points and Critical Boundaries

### INT-01: Win Condition (hasEgg + exitPosition)
`RulesEngine` checks `gameState.hasEgg == true && playerPosition == floorMap.exitPosition`. Both conditions required. Tested as a pure domain rule.

### INT-02: Special Charge Rate Calibration
`GameConfig.specialChargeRatePerSecond` must be set so that `specialCharge` cannot reach `1.0` (full) in the time between game start and first encounter. Typical Floor 1 walk time: 10-20 seconds. A rate of `0.008/s` yields 8% charge in 10 seconds — safe. This is a configuration value, testable: inject `deltaTime = 20.0`, assert `specialCharge < 1.0`.

### INT-03: Dash Charge Display Consistency (no stale reads)
`Renderer` reads `GameState` (immutable snapshot). Since `GameState` is a value type passed as a single snapshot per tick, there is no possibility of a stale read — the renderer always sees the state that was computed in the same tick.

### INT-04: Full State Reset on Restart
`RulesEngine.apply(.restart, ...)` produces a new `GameState` from `FloorGenerator.generate(floorNumber: 1, seed: newSeed)` and `GameConfig.initialState`. The `GameLoop` replaces its `currentState`. No carry-over possible.
