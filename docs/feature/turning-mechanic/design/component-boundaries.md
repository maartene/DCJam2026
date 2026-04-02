# Component Boundaries: Turning Mechanic

**Feature**: turning-mechanic
**Date**: 2026-04-02
**Author**: Morgan (Solution Architect — DESIGN wave)

---

## Module Boundary Map

Two modules are affected. No new modules are introduced. All changes are additive extensions or in-place modifications within existing boundaries.

```
GameDomain (pure domain — zero imports)
├── NEW:  CardinalDirection          enum
├── NEW:  TurnDirection              enum
├── NEW:  Position                   struct
├── MOD:  GameCommand                add case turn(TurnDirection)
├── MOD:  GameState                  add facingDirection; change playerPosition to Position
├── MOD:  FloorMap                   redesign to 2D grid (cells + Position landmarks)
├── MOD:  FloorGenerator             generate 2D FloorMap
└── MOD:  RulesEngine                handle .turn; update .move delta; guard turn in combat

DCJam2026 App (imports GameDomain + Darwin)
├── MOD:  InputHandler               add Arrow Left/Right and A/D turn bindings
└── MOD:  Renderer                   add 2D minimap region; update DungeonFrameKey derivation; update screen layout
```

---

## Component Responsibility Table

### GameDomain Components

| Component | Responsibility | Boundary Rule |
|-----------|---------------|---------------|
| `CardinalDirection` | Represent facing as a four-case value type | Read-only value. No mutable state. No methods beyond CaseIterable convenience if desired. |
| `TurnDirection` | Represent `.left` / `.right` turn input | Same as above. |
| `Position` | 2D coordinate `(x: Int, y: Int)` for all grid positions | Value type. No computed geometry (that belongs in RulesEngine or Renderer). |
| `GameCommand` | Enumerate all commands the RulesEngine can receive | Adding `case turn(TurnDirection)` is the only change. No logic here. |
| `GameState` | Complete snapshot of a run | `facingDirection` is the single source of truth for facing. `playerPosition` is the single source of truth for 2D grid position. Functional updaters `withFacingDirection(_:)` and `withPlayerPosition(_:)` follow the existing pattern. |
| `FloorMap` | Static description of a floor's 2D grid | Stores `cells: [[Cell]]`, `width`, `height`, all landmark positions as `Position`. Does not compute navigation; does not know about facing. |
| `Cell` | Wall or corridor classification for a grid cell | Simple enum `{ wall, corridor }`. Belongs in `GameDomain` alongside `FloorMap`. |
| `FloorGenerator` | Produce `FloorMap` values from config | Pure static function. No randomness beyond seed-derived egg floor selection (unchanged). Produces the L-shaped corridor topology. |
| `RulesEngine` | Apply commands to produce new `GameState` | Owns the rotation table (canonical). Owns the facing-relative delta table. Guards `.turn` in `.combat`. No output, no I/O. |

### App Components

| Component | Responsibility | Boundary Rule |
|-----------|---------------|---------------|
| `InputHandler` | Map raw bytes to `GameCommand` | Adds four new mappings. Does not contain rotation logic — it only produces `GameCommand.turn(.left/.right)`. |
| `Renderer` | Map `GameState` to ANSI terminal output | Owns screen layout. Owns 2D minimap rendering. Owns DungeonFrameKey derivation from 2D grid + facing. Reads `facingDirection` directly from `GameState` on every render — no caching. |

---

## What Each Component Does NOT Own

These are explicit exclusions to prevent boundary violations:

| Component | Does NOT own |
|-----------|-------------|
| `InputHandler` | The rotation table (RulesEngine owns it). InputHandler only maps keys to `.turn(.left/.right)`. |
| `Renderer` | Game rules for what is passable. Renderer reads `FloorMap.cells` to derive DungeonFrameKey, but passability semantics live in `FloorMap.Cell`. |
| `RulesEngine` | Screen layout decisions. It does not know about minimap rows or terminal columns. |
| `FloorMap` | Navigation logic. It stores the grid; RulesEngine applies movement deltas to positions. |
| `GameState` | Rendering decisions. It stores `facingDirection` as a domain fact; `Renderer` decides how to display it. |

---

## Dependency Direction (unchanged)

```
DCJam2026 App  ──imports──►  GameDomain
GameDomain     ──no imports──  (zero dependencies)
Tests          ──imports──►  GameDomain, DCJam2026
```

This is unchanged from the current architecture. The turning mechanic adds no new module dependencies.

---

## Change Impact by Component

| Component | Change Type | Impact Level |
|-----------|-------------|-------------|
| `CardinalDirection` | New type | None — additive |
| `TurnDirection` | New type | None — additive |
| `Position` | New type | None — additive |
| `GameCommand` | Add enum case | LOW — exhaustive switches in RulesEngine will require a new case; compiler will flag all missed cases |
| `GameState.facingDirection` | New stored property | LOW — additive; all functional updaters follow existing pattern |
| `GameState.playerPosition` | Type change `Int` → `Position` | HIGH — all call sites must be updated; compiler-driven migration |
| `FloorMap` | Full redesign | HIGH — all call sites (RulesEngine, Renderer, tests) must be updated |
| `FloorGenerator` | Updated to produce 2D FloorMap | HIGH — output type changes; tests must be updated |
| `RulesEngine.applyMove` | Logic change + new `applyTurn` | MEDIUM — logic rewrite; existing tests define expected behavior |
| `InputHandler.mapKey` | Additive: two new escape codes, two new ASCII codes | LOW — four new cases in existing switch |
| `Renderer.renderDungeon` | DungeonFrameKey derivation + minimap region | MEDIUM — screen layout change + new 2D lookahead logic |
