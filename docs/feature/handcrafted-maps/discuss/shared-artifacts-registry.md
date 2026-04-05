# Shared Artifacts Registry — handcrafted-maps

**Feature**: handcrafted-maps
**Date**: 2026-04-04

This registry tracks every data artifact that crosses a boundary between stories or between the developer and player journey. Each entry documents its single authoritative source to prevent integration failures.

---

## SA-01: FloorDefinition

**Type**: Swift struct (GameDomain module)
**Owner**: GameDomain
**Consumers**: FloorRegistry, tests
**Description**: A value type holding all data needed to construct a `FloorMap` for one floor. Replaces the computed logic in `FloorGenerator.generate(floorNumber:config:)`.

**Fields**:
| Field | Type | Notes |
|-------|------|-------|
| `rows` | `[String]` | Array of strings, one per row. Each character is one cell. Row 0 = northernmost row. |

**Character vocabulary** (authoring format):
| Character | Meaning | Passable? |
|-----------|---------|-----------|
| `#` | Wall (impassable) | No |
| `.` | Floor (passable, empty) | Yes |
| `^` `>` `v` `<` | Player entry, facing N/E/S/W | Yes |
| `G` | Guard encounter | Yes |
| `B` | Boss encounter | Yes |
| `*` | Egg room | Yes |
| `S` | Stairs (between floors) | Yes |
| `X` | Exit (floor 5 only) | Yes |
| `E` | Entry point (alternative to directional marker) | Yes |

**Derived fields** (not stored; computed by `FloorRegistry` on parse):
- `width` = `rows[0].count`
- `height` = `rows.count`
- All `Position` landmarks (entry, staircase, encounter, boss, egg room, exit) — scanned from grid characters

**Constraint**: `FloorDefinition` is a pure data holder — a single `rows: [String]` field. All game rule derivations (`hasEggRoom`, `hasBossEncounter`, etc.) and all `Position` values are derived by `FloorRegistry` when constructing `FloorMap`. No separate `Position` fields on `FloorDefinition`.

---

## SA-02: FloorRegistry

**Type**: Swift enum (stateless namespace, GameDomain module)
**Owner**: GameDomain
**Consumers**: RulesEngine, Renderer
**Description**: The single authoritative source of floor maps during a run. Replaces `FloorGenerator` at all call sites.

**Interface** (solution-neutral description):
- Given a floor number (1-5) and a `GameConfig`, returns a `FloorMap`
- `FloorMap` interface is unchanged — callers need no changes beyond substituting the call
- The 5 handcrafted `FloorDefinition` instances are defined as private constants inside `FloorRegistry`

**Call sites to replace** (identified in codebase):
- `RulesEngine.applyMove` — line 173: `FloorGenerator.generate(floorNumber:config:)`
- `RulesEngine.applySpecial` — line 278: `FloorGenerator.generate(floorNumber:config:)`
- `Renderer.renderDungeon` — `FloorGenerator.generate(floorNumber:config:)`
- `Renderer.renderMinimap` — receives `floor: FloorMap` (already correct — no change needed here)

---

## SA-03: FloorMap (unchanged interface)

**Type**: Swift struct (GameDomain module, existing)
**Owner**: GameDomain
**Consumers**: RulesEngine, Renderer, all tests
**Description**: The existing `FloorMap` type. Its interface must not change — this is the stable contract between GameDomain and the renderer/rules engine.

**Key fields used by consumers**:
- `grid.width`, `grid.height` — minimap render loop must use these (not hardcoded 15/7)
- `entryPosition2D`, `staircasePosition2D`, `encounterPosition2D`, `eggRoomPosition2D`, `exitPosition2D`
- `hasEggRoom`, `hasBossEncounter`, `hasExitSquare`

---

## SA-04: Floor Label in Top Border

**Type**: String fragment embedded in Renderer.drawChrome()
**Owner**: Renderer
**Source data**: `GameState.currentFloor`, `GameState.config.maxFloors`
**Description**: "── Floor N/M ──" embedded in the right-panel segment of row 1 (the top border), replacing plain `─` characters. Frees row 2 from having a label and allows minimap to begin at row 2.

**Format**: The label occupies the rightmost available characters of the 19-char right-panel section of the top border (cols 61-79 minus the `┬` and `┐` corners). Maximum label text length: 15 chars ("── Floor 5/5 ──" = 15 chars exactly).

**Current state**: Label currently written at row 2, cols `(80 - label.count)` to 79, overwriting minimap row 2. This is the bug being fixed.

---

## SA-05: Minimap Render Dimensions

**Type**: Runtime values from FloorMap
**Owner**: Renderer.renderMinimap
**Source**: `floor.grid.width`, `floor.grid.height`
**Description**: The minimap loop must not use hardcoded constants. It must iterate `0..<floor.grid.width` and `0..<floor.grid.height`.

**Cell mapping formula**:
- `screenRow = 2 + (floor.grid.height - 1 - y)`  (y=0 is entry/south = bottom of minimap)
- `screenCol = 61 + x`
- Max screenRow = `2 + (15 - 1 - 0)` = 16 (row 16 is the last dungeon view row — acceptable)
- Max screenCol = `61 + 18` = 79 (last column of right panel — acceptable)

**Constraint**: Any floor taller than 15 rows would overflow into the status bar separator at row 17. Max height is therefore 15 (rows 2-16 = 15 rows).

---

## SA-06: GameRun (unchanged interface)

**Type**: Swift struct (GameDomain, existing)
**Owner**: GameDomain
**Consumers**: GameLoop, tests
**Description**: `GameRun` holds `[FloorMap]`. Currently produced by `FloorGenerator.generateRun`. With handcrafted maps, `FloorRegistry` produces each `FloorMap` individually (no run-level generation needed). `generateRun` can be removed or kept as a shim.

**Decision**: `FloorRegistry` does not need to produce a `GameRun`. RulesEngine calls `FloorRegistry.floor(N)` on demand. `GameRun` type can remain for future use but is not required by this feature.

---

## Integration Checkpoint Summary

| Checkpoint | Risk | Resolution |
|-----------|------|------------|
| RulesEngine still calls FloorGenerator | Player walks through walls | Replace all FloorGenerator calls with FloorRegistry |
| Minimap uses hardcoded width=15 height=7 | Map clipped or drawn at wrong rows | Use floor.grid.width and floor.grid.height |
| Floor label at row 2 conflicts with minimap | Row 2 of map invisible | Move label to row 1 top border |
| Existing tests hardcode Position(2,3) for egg | Egg room tests fail on new floors | Tests use floor.eggRoomPosition2D dynamically |
| Existing tests hardcode screenRow formula with height=7 | Wrong row assertions | Tests use floor.grid.height in screenRow formula |
