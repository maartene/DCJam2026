# Data Models — game-polish-v1
**Feature**: game-polish-v1
**Date**: 2026-04-03
**Author**: Morgan (Solution Architect — DESIGN wave)

---

## Summary of Data Model Changes

game-polish-v1 adds one new type (`TransientOverlay`) and one new field to `GameState`.
All other data types are unchanged.

---

## New Type: TransientOverlay

**File**: `Sources/GameDomain/TransientOverlay.swift` (new)
**Module**: GameDomain
**Type**: `public enum TransientOverlay: Equatable, Sendable`

### Cases

| Case | framesRemaining | Meaning |
|------|----------------|---------|
| `.braceSuccess(framesRemaining: Int)` | 23 at creation | Enemy attacked during active braceWindow — parry succeeded. 0 HP damage taken. |
| `.braceHit(framesRemaining: Int)` | 23 at creation | Enemy attacked with no active braceWindow — full damage taken, player survived. |
| `.dash(framesRemaining: Int)` | 23 at creation | Dash resolved successfully (dashCharges > 0, not a boss encounter). |

### Constants

| Constant | Value | Purpose |
|----------|-------|---------|
| `public static let defaultDuration: Int` | `23` | ~0.75 seconds at 30Hz (WAVE-DEC-02). Starting value for all new overlays. |

### Invariants

- `framesRemaining` is always >= 0 when the overlay exists in `GameState`.
- `framesRemaining == 0` is treated as "expired" by `RulesEngine.advanceTimers()`, which
  then sets `GameState.transientOverlay = nil`. The case is never held at 0 between ticks.
- `TransientOverlay` carries only the countdown, not display text. Display text (word + sub-line)
  is owned by `Renderer` — it belongs to the presentation layer, not the domain.

### Why `Equatable`

Tests need to assert `state.transientOverlay == .braceSuccess(framesRemaining: 23)` after a parry.
`Equatable` on the enum (with associated value) enables this without reflection.

---

## Modified Type: GameState

**File**: `Sources/GameDomain/GameState.swift`
**Change**: One new stored property + one new `with` helper.

### New field

```
public var transientOverlay: TransientOverlay?
```

Default value in `GameState.initial(config:)`: `nil`.

### New functional update helper

```
public func withTransientOverlay(_ overlay: TransientOverlay?) -> GameState
```

Follows the identical pattern of all existing `with` helpers (copy, assign, return).

### Updated initial() snapshot

`GameState.initial(config:)` gains two changes:
1. `screenMode: .startScreen` (was `.dungeon`) — player sees start screen on launch.
2. `transientOverlay: nil` — no overlay on fresh start.

---

## Modified Type: ScreenMode

**File**: `Sources/GameDomain/ScreenMode.swift`
**Change**: One new case.

```
case startScreen
```

No associated value. The start screen carries no domain state — it is a pure display mode.

### Full enum after change

```
public enum ScreenMode: Sendable {
    case startScreen
    case dungeon
    case combat(encounter: EncounterModel)
    case narrativeOverlay(event: NarrativeEvent)
    case upgradePrompt(choices: [Upgrade])
    case deathState
    case winState
}
```

---

## Unchanged Types

These types are confirmed unchanged by game-polish-v1:

| Type | File | Reason unchanged |
|------|------|-----------------|
| `NarrativeEvent` | `NarrativeEvent.swift` | Egg/exit/special overlays keep existing cases; transient overlays are a separate type |
| `TimerModel` | `TimerModel.swift` | Dash cooldown mechanism unchanged |
| `EncounterModel` | `EncounterModel.swift` | Combat rules unchanged |
| `FloorMap` | `FloorMap.swift` | Floor structure unchanged |
| `GameConfig` | `GameConfig.swift` | All tuning constants unchanged |
| `GameCommand` | `GameCommand.swift` | No new player commands introduced |

---

## Data Flow: Transient Overlay Lifecycle

```
RulesEngine.applyEnemyAttackTick()
  → sets GameState.transientOverlay = .braceSuccess(23) OR .braceHit(23) OR nil (fatal)

RulesEngine.applyDash()
  → sets GameState.transientOverlay = .dash(23)

RulesEngine.advanceTimers() [every tick]
  → if transientOverlay != nil: decrements framesRemaining
  → if framesRemaining reaches 0: sets transientOverlay = nil

Renderer.render(_:) [every frame]
  → reads state.transientOverlay
  → if non-nil AND screenMode is .dungeon or .combat: renders overlay word centered at row 9
  → after rendering, does NOT clear transientOverlay (RulesEngine owns the lifecycle)
```

---

## Data Flow: Start Screen Transition

```
GameState.initial()
  → screenMode = .startScreen
  → transientOverlay = nil

GameLoop tick: any keypress (non-ESC)
  → InputHandler.poll() returns GameCommand (any non-quit command)
  → RulesEngine.apply(command:, to: state, deltaTime:)
  → applyConfirmOverlay: state.screenMode == .startScreen → transition to .dungeon

Renderer.render(_:)
  → case .startScreen: renderStartScreen() [no chrome, no status bar]
  → case .dungeon: normal dungeon render with full chrome
```

---

## ANSI Color Mapping (Renderer-layer, not domain data)

This section documents the color semantics so the crafter can verify AC against implementation.
These values live in `ANSIColors.swift` in the App module — not in GameDomain.

### HP Bar (US-P05a)

| Condition | ANSI code | Color |
|-----------|-----------|-------|
| `hp >= 0.40 * maxHP` | `\u{1B}[32m` | Green |
| `hp >= 0.20 * maxHP` (and < 40%) | `\u{1B}[33m` | Yellow |
| `hp < 0.20 * maxHP` | `\u{1B}[31m` | Red |

Threshold arithmetic: `Double(state.hp) / Double(state.config.maxHP)`.
Boundary is inclusive at 40% (green) and 20% (yellow) — per WAVE-DEC-04.

### Special / Charge (US-P05b)

| Condition | ANSI code | Color |
|-----------|-----------|-------|
| `state.specialIsReady == true` | `\u{1B}[1m\u{1B}[96m` | Bold bright cyan |
| `!state.specialIsReady` | `\u{1B}[36m` | Dim cyan |
| Dash cooldown active | `\u{1B}[33m` | Yellow |
| `state.braceOnCooldown == true` | `\u{1B}[33m` | Yellow |

### Minimap Per-Cell (US-P05c)

| Character | ANSI code | Color |
|-----------|-----------|-------|
| `^` `>` `v` `<` (player) | `\u{1B}[1m\u{1B}[97m` | Bold bright white |
| `G` (guard) | `\u{1B}[91m` | Bright red |
| `B` (boss) | `\u{1B}[1m\u{1B}[91m` | Bold bright red |
| `*` (egg uncollected) | `\u{1B}[93m` | Bright yellow |
| `e` (egg collected) | `\u{1B}[33m` | Dim yellow |
| `S` (staircase) | `\u{1B}[96m` | Bright cyan |
| `X` (exit) | `\u{1B}[1m\u{1B}[96m` | Bold bright cyan |
| `E` (entry) | `\u{1B}[36m` | Dim cyan |
| `#` (wall) | `\u{1B}[90m` | Dark gray |
| `.` (passable) | (no code) | Default terminal color |

All colored writes are terminated with `\u{1B}[0m` (ANSI reset).

### Transient Overlay (US-P06, US-P07)

| Overlay | ANSI code | Color |
|---------|-----------|-------|
| `.braceSuccess` — "SHIELDED!" | `\u{1B}[96m` | Bright cyan |
| `.braceHit` — "STRUCK!" | `\u{1B}[91m` | Bright red |
| `.dash` — "SWOOSH!" | `\u{1B}[1m\u{1B}[97m` | Bold white |
