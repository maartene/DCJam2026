# Requirements — handcrafted-maps

**Feature**: handcrafted-maps
**Date**: 2026-04-04

---

## REQ-HM-01: FloorDefinition data type

**Problem**: There is no way to express a floor layout as static data. `FloorGenerator.generate()` mixes data and logic, making it impossible to author distinct layouts without changing the generation algorithm.

**Requirement**: A `FloorDefinition` value type (struct) exists in `GameDomain` that holds all data needed to construct a `FloorMap` for one floor number. It is a pure data container — no logic, no game rules.

**Migration constraint**: The first deliverable is a safe migration — the existing L-shaped corridor is expressed as a `FloorDefinition` character grid, producing an identical map to what exists today. No visible change to the player. All existing tests must still pass before any new floor topologies are authored.

**Constraints**:
- Grid stored as `[String]` — an array of strings, one string per row, where each character is a cell
- Character vocabulary: `#` = wall (impassable), `.` = floor (passable, empty), `^`/`>`/`v`/`<` = player entry (facing direction), `G` = guard encounter, `B` = boss encounter, `*` = egg room, `S` = stairs, `X` = exit (floor 5 only), `E` = entry point
- Width max 19, height max 15 (terminal constraint: cols 61-79 = 19, rows 2-16 = 15)
- Width and height are derived from the rows array (no separate `width`/`height` fields required — width = `rows[0].count`, height = `rows.count`)
- Landmark positions are parsed from the grid characters — no separate `Position` fields needed; `FloorRegistry` scans once to extract positions when building `FloorMap`
- Landmark fields on `FloorMap` are unchanged — only the authoring format changes

**Domain examples**:
1. Floor 1 (L-shape, 15×7): character grid where `^` marks the entry at column 7 row 0, `S` marks the staircase, `G` marks the guard. Matches current `FloorGenerator` output topology exactly — identical passable cells, identical landmark coordinates.
2. Floor 3 (T-junction, 19×10): 19-character-wide rows, 10 rows tall — `*` marks the egg room on the west branch, `S` at the north end. Demonstrably different shape.
3. Floor 5 (boss antechamber, 13×8): `B` at center (x=6, y=4), `X` at north (x=6, y=7), no `*` anywhere. Compact, symmetric.

---

## REQ-HM-02: FloorRegistry replaces FloorGenerator at all call sites

**Problem**: `FloorGenerator.generate(floorNumber:config:)` is called in `RulesEngine.applyMove`, `RulesEngine.applySpecial`, and `Renderer.renderDungeon`. Every call returns the same L-shaped layout. There is no mechanism to serve different floors by number.

**Requirement**: A `FloorRegistry` stateless namespace exists in `GameDomain`. Its primary interface is `FloorRegistry.floor(_ floorNumber: Int, config: GameConfig) -> FloorMap`. All existing `FloorGenerator` call sites are replaced with `FloorRegistry.floor(_:config:)`.

**Constraints**:
- `FloorMap` return type is unchanged — zero changes required in callers beyond the call substitution
- `FloorRegistry` uses the 5 `FloorDefinition` constants to construct `FloorMap` values
- `FloorGenerator` may be retained for test compatibility or removed — decision for DESIGN wave
- `FloorRegistry` derives `hasEggRoom`, `hasBossEncounter`, `hasExitSquare` from `floorNumber` and `config.maxFloors` (same rules as `FloorGenerator`)
- `generateRun` is not required — `FloorRegistry` serves floors on demand

**Domain examples**:
1. `FloorRegistry.floor(1, config: .default)` returns `FloorMap` with `hasEggRoom == false`, `hasBossEncounter == false`, `hasExitSquare == false`.
2. `FloorRegistry.floor(2, config: .default)` returns `FloorMap` with `hasEggRoom == true`, egg at floor 2's defined position.
3. `FloorRegistry.floor(5, config: .default)` returns `FloorMap` with `hasBossEncounter == true`, `hasExitSquare == true`, `hasEggRoom == false`.

---

## REQ-HM-03: Floor label moved to top border (row 1)

**Problem**: The floor label "Floor N/M" is currently written at row 2, cols `(80 - label.count)` to 79. This overwrites the topmost row of the minimap, making floor 1's top cell (entry row) invisible under the label.

**Requirement**: The floor label is embedded in the top border (row 1) inside the right-panel segment (cols 61-79). Row 2 of the right panel is free for minimap content on all floors.

**Constraints**:
- Label only appears in `.dungeon` screen mode (not combat, narrative, upgrade, death, win)
- Label format: `" Floor N/M "` (with spaces) fits within 19 chars for all valid values (max "Floor 5/5" = 11 chars including spaces)
- The top border string for `.dungeon` mode embeds the label; other modes use plain `─` characters
- Label is right-aligned within the 19-char right-panel segment, or centered — exact alignment is a DESIGN wave decision
- Minimap legend rows do not need adjustment (rows 9-15 unaffected by this change)

**Domain examples**:
1. Floor 1 of 5: label " Floor 1/5 " (11 chars). Remaining 8 chars of right panel segment are `─` borders.
2. Floor 5 of 5: label " Floor 5/5 " — same length, different number.
3. Combat screen: top border has no floor label — plain `─` fill in right-panel segment.

---

## REQ-HM-04: Minimap renders floors of any size up to 19×15

**Problem**: `Renderer.renderMinimap` uses `floor.grid.height` and `floor.grid.width` in its loop (correct), but the `screenRow` formula `2 + (floor.grid.height - 1 - y)` and `screenCol = 61 + x` already generalize correctly. However, existing tests hardcode the minimap position formula with the assumption of height=7 (`screenRow = 2 + (6 - y)`). Any floor with height ≠ 7 will have different screen positions and those tests will need updating.

**Requirement**: The minimap renders correctly for any floor grid with width 1-19 and height 1-15. The render loop uses `floor.grid.width` and `floor.grid.height` exclusively (no magic constants). Minimap cells always start at col 61 and row 2; the bottom of the map is row `2 + (height - 1)`.

**Constraints**:
- No cell is written outside cols 61-79 (width ≤ 19 guarantees this)
- No cell is written outside rows 2-16 (height ≤ 15 guarantees this)
- Legend (rows 9-15) must not conflict with taller maps. For floors with height > 7 (bottom minimap row > row 8), the legend shifts down or is omitted if it would overflow row 16. Decision: if `2 + (height - 1) >= 9`, the legend is omitted — floor shape takes precedence. This is a DESIGN wave decision; this requirement records the constraint.
- Existing minimap tests that use hardcoded `screenRow` formulas must be updated to use `floor.grid.height` in their assertions.

**Domain examples**:
1. Floor 1 (height=7): bottom minimap row = `2 + 6 = 8`. Legend at rows 9-15. No conflict.
2. Floor 3 (height=12): bottom minimap row = `2 + 11 = 13`. Legend would start at row 9 — rows 9-12 are map rows, rows 13-15 are legend rows. Legend is truncated or overlaps map. Design decision required.
3. Floor 5 (height=8): bottom minimap row = `2 + 7 = 9`. Legend starts at row 10. 6 of 7 legend entries fit (rows 10-15). "You" entry at row 9 is on map row 9.

---

## REQ-HM-05: Five distinct handcrafted floor layouts

**Problem**: The jam requires a 5-floor dungeon. With procedural generation returning the same L-shape every time, all 5 floors are visually and navigationally identical. This is a quality and engagement failure.

**Requirement**: Five `FloorDefinition` constants are authored, one per floor (1-5). Each floor has a distinct grid topology (different shape, different corridor arrangement). Game rules per floor are observed:
- Floor 1: no egg room, no boss, no exit. Entry at south, staircase at north.
- Floors 2-4: egg room present (exactly one per floor). Guard encounter. Staircase.
- Floor 5: boss encounter, exit square, no egg room, no staircase.

**Constraints**:
- All 5 floors compile as pure Swift literal `[String]` arrays — no file I/O, no JSON, no external data
- Each grid is within 19 characters wide × 15 rows tall
- All landmark characters lie on cells that the parser treats as passable (`.`, `^`, `>`, `v`, `<`, `G`, `B`, `*`, `S`, `X`, `E`)
- No two floors share the same grid topology (this is a design constraint, not a test assertion)
- Floor 5 topology is noticeably shorter/more compact than floors 2-4 (boss-room feel)

**Domain examples**:
1. Floor 1 — L-shape (15×7): current FloorGenerator topology, preserved exactly. Existing movement tests still pass.
2. Floor 3 — T-junction (19×10): full-width corridor with a T-arm. Distinct from L-shape in both width and shape.
3. Floor 5 — Boss antechamber (13×8): compact, symmetric, single path to boss at center.

---

## Non-Requirements (Out of Scope)

- Random/procedural floor generation is removed from the production path. `FloorGenerator.generateRun` is not called at runtime. It may remain in source for tests or be deleted.
- No serialization or deserialization of floor data beyond the in-source `[String]` literals.
- No runtime floor selection — floors are fixed by floor number.
- No dynamic legend repositioning for tall floors in this feature. If overlap occurs, legend is truncated. Full legend-repositioning is post-jam.
- No floor names/titles beyond the "Floor N/M" label.
