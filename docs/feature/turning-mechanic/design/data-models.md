# Data Models: Turning Mechanic

**Feature**: turning-mechanic
**Date**: 2026-04-02
**Author**: Morgan (Solution Architect — DESIGN wave)

This document specifies the data model contracts for all new and modified domain types. Software-crafter owns internal implementation. These specifications describe structure and invariants only — no method signatures, no algorithm implementations.

---

## New Types

### `CardinalDirection`

Module: `GameDomain`
Kind: `enum`
Conformances: `Sendable`, `CaseIterable` (optional convenience), `Equatable`, `Hashable`

Four cases exactly: `.north`, `.east`, `.south`, `.west`. No associated values. No stored properties.

Invariant: There are exactly four valid facing states. Any switch over `CardinalDirection` must be exhaustive.

### `TurnDirection`

Module: `GameDomain`
Kind: `enum`
Conformances: `Sendable`, `Equatable`

Two cases exactly: `.left`, `.right`.

### `Position`

Module: `GameDomain`
Kind: `struct`
Conformances: `Sendable`, `Equatable`, `Hashable`

Fields:
- `x: Int` — column index, 0-based, increases eastward
- `y: Int` — row index, 0-based, increases northward

No computed geometry methods. No initialiser beyond memberwise. Arithmetic on Position values (addition of deltas) belongs in RulesEngine and Renderer, not in Position itself.

### `Cell`

Module: `GameDomain`
Kind: `enum`
Conformances: `Sendable`, `Equatable`

Two cases: `.wall`, `.corridor`.

A corridor cell is passable. A wall cell is not. This is the complete semantic — passability is a property of `Cell`, not of `Position` or `FloorMap`.

---

## Modified Types

### `GameCommand` (modified)

Added case: `case turn(TurnDirection)`

The full enum after modification:

```
case move(MoveDirection)
case turn(TurnDirection)      ← NEW
case dash
case brace
case special
case confirmOverlay
case selectUpgrade(Upgrade)
case restart
case none
```

No other changes.

### `GameState` (modified)

Added field: `facingDirection: CardinalDirection`

Changed field: `playerPosition` changes type from `Int` to `Position`

New functional updater: `withFacingDirection(_: CardinalDirection) -> GameState`

Existing `withPlayerPosition` updater must accept `Position` instead of `Int`. The updater name may stay the same if the crafter prefers, or be named `withPlayerPosition2D` to signal the type change during migration — crafter's choice.

`GameState.initial(config:)` must initialise:
- `facingDirection: .north`
- `playerPosition: Position(x: 4, y: 0)` — entry cell of the standard floor grid

`withCurrentFloor(_:)` must NOT reset `facingDirection`. It changes `currentFloor` only.

Invariant: `facingDirection` is the single source of truth for all facing-dependent logic. No other component caches or derives a secondary facing value.

### `FloorMap` (redesigned)

Existing 1D position fields are replaced by 2D grid and `Position` landmarks.

New fields:
- `cells: [[Cell]]` — row-major storage: `cells[y][x]`. Index y from 0 (south) to `height-1` (north). Index x from 0 (west) to `width-1` (east).
- `width: Int` — number of columns
- `height: Int` — number of rows

Changed fields (type `Int` → `Position`):
- `entryPosition: Position`
- `staircasePosition: Position`
- `exitPosition: Position`
- `eggRoomPosition: Position?`
- `encounterPosition: Position?`

Removed fields:
- `isNavigable: Bool` — redundant; a floor is always navigable if generated
- `hasExitSquare: Bool` — retained (boolean flag, not a position)
- `hasBossEncounter: Bool` — retained
- `hasEggRoom: Bool` — retained

The `entryPosition` is always `Position(x: 4, y: 0)` for the standard topology. `staircasePosition` is `Position(x: 4, y: 6)`. These may vary in post-jam scope.

Invariant: `cells[y][x]` is accessible for all `0 <= x < width` and `0 <= y < height`. A `Position` stored in any landmark field is always a valid cell index within the grid bounds.

Invariant: `entryPosition` is always a `.corridor` cell.

### `FloorGenerator` (updated)

`generate(floorNumber:config:)` returns a `FloorMap` with the 2D grid populated according to the L-shaped corridor topology:

Main corridor: cells at `x = 4`, `y = 0...6` are `.corridor`. All other cells are `.wall` unless part of the branch.

Branch corridor: cells at `y = 3`, `x = 2...6` are `.corridor`.

All other cells: `.wall`.

This produces a 11×7 grid (indices 0...10 for x, 0...6 for y). Standard positions:

| Landmark | Position |
|----------|----------|
| Entry | (4, 0) |
| Staircase (non-final floors) | (4, 6) |
| Exit (final floor) | (4, 6) |
| Egg room (when present) | (2, 3) |
| Encounter (standard floor) | (4, 3) |
| Boss encounter (final floor) | (4, 3) |

The egg room is at the west end of the branch. Reaching it requires the player to be at the junction (4, 3) and move west (facing west, then forward) or move along the branch.

`generateRun(config:seed:)` is unchanged in its interface. It calls `generate` per floor.

---

## Rotation Table (canonical — lives in RulesEngine)

This table is the single authoritative definition. It is reproduced here for traceability; the implementation lives in `RulesEngine` only.

| Current facing | Turn left | Turn right |
|----------------|-----------|------------|
| `.north` | `.west` | `.east` |
| `.east` | `.north` | `.south` |
| `.south` | `.east` | `.west` |
| `.west` | `.south` | `.north` |

---

## Movement Delta Table (canonical — lives in RulesEngine)

| Facing | Forward (dx, dy) | Backward (dx, dy) |
|--------|-----------------|-------------------|
| `.north` | (0, +1) | (0, -1) |
| `.east` | (+1, 0) | (-1, 0) |
| `.south` | (0, -1) | (0, +1) |
| `.west` | (-1, 0) | (+1, 0) |

`playerPosition` after move = `Position(x: playerPosition.x + dx, y: playerPosition.y + dy)`.

Movement resolution order (for crafter):
1. Compute target `Position` by applying `(dx, dy)` to current `playerPosition`.
2. Bounds check: if target is outside `[0..<width, 0..<height]`, clamp to the nearest valid position and return — do not proceed to cell check.
3. Cell check: if `cells[target.y][target.x] == .wall`, return current position unchanged — the player cannot step into a wall.
4. If target is in bounds and is `.corridor`, apply all subsequent game logic (encounter check, staircase transition, win condition) and return the updated position.

This order ensures that wall collisions are silent (no effect) and that all existing rules (DISC-03, win condition) are evaluated only on valid moves.

---

## Minimap Symbol Table (Renderer — not a domain type)

| State | Character |
|-------|-----------|
| Player facing `.north` | `^` |
| Player facing `.east` | `>` |
| Player facing `.south` | `v` |
| Player facing `.west` | `<` |
| Wall cell | `#` |
| Corridor cell (unvisited/generic) | `.` |
| Entry landmark | `E` |
| Staircase landmark | `S` |
| Exit landmark | `X` |
| Egg room (egg not collected) | `*` |
| Egg room (egg collected) | `e` |
| Encounter / guard | `G` |
| Boss encounter | `B` |
| Player position (overrides any landmark) | `^` / `>` / `v` / `<` |

Player marker overrides all landmarks. When the player is standing on the entry, the cell shows `^` (or appropriate caret), not `E`.

---

## Invariants Summary

| Invariant | Source |
|-----------|--------|
| `facingDirection` initialises to `.north` on `GameState.initial` | BR-07 |
| `facingDirection` is unchanged by `withCurrentFloor` | AC-06-1 |
| `facingDirection` is unchanged by `.turn` during `.combat` screen mode | BR-05 |
| `playerPosition` is clamped to valid grid bounds after every move | AC-03-7 |
| Player marker overrides landmarks at the same cell in the minimap | AC-04-7 |
| Turn command has zero side effects on HP, dash, special, position | AC-02-4 |
| Four consecutive turns in the same direction return to original facing | AC-02-5 |
