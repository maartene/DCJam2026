# Wave Decisions — handcrafted-maps

**Feature**: handcrafted-maps
**Wave**: DISTILL
**Date**: 2026-04-05
**Agent**: Quinn (nw-acceptance-designer)

---

## Key Decisions

### DEC-DISTILL-01: Floor label at row 2 (not row 1)

The DISCUSS acceptance-criteria.md (AC-HM-03-A) refers to "row 1 right panel". The DESIGN wave decision DEC-DESIGN-05 explicitly states "row 2, cols 61–79". The DESIGN wave is the authoritative source for implementation placement. All acceptance tests assert row 2.

The previous floor label was also at row 2 (written at `col = 80 - label.count`). The new placement is the same row, different column anchor. This is consistent with the DESIGN rationale: move from right-floated to left-anchored within the right panel, not from row 2 to row 1.

### DEC-DISTILL-02: Minimap row formula = `3 + (height - 1 - y)`, not `2 + (height - 1 - y)`

After the floor label occupies row 2, the minimap starts at row 3. The formula used in existing `MinimapTests.swift` (`2 + (6 - y)`) is now incorrect for the new layout. The new formula is `3 + (floor.grid.height - 1 - y)`.

For floor 1 (height = 7):
- Northernmost row (y = 6): screenRow = 3 + 0 = 3
- Entry cell (y = 0): screenRow = 3 + 6 = 9

The crafter must update the existing `minimapCharAt(x:y:spy:)` helper in `MinimapTests.swift` to use `3 + (6 - y)` once the Renderer change is implemented.

### DEC-DISTILL-03: Legend rows 10-16 (not 9-15)

With the minimap starting at row 3, a height-7 floor occupies rows 3-9. The legend follows immediately at rows 10-16. The existing `MinimapLegendTests.swift` asserts rows 9-15. Those tests will fail (correctly) once the Renderer is updated. The crafter must update those assertions to rows 10-16.

These existing test changes are required regression updates, not acceptance test changes.

### DEC-DISTILL-04: AC-HM-02-D deferred

The test for "Ember moves into a cell that is passable on floor 2 but not on floor 1" requires floor 2's exact topology. Floor 2 is developer-authored (DEC-DESIGN-09). This acceptance criterion is deferred until the developer authors floors 2-5. A proxy check (FR-10: no two floors share identical dimensions and entry position) covers the structural requirement.

### DEC-DISTILL-05: FloorDefinition uses `grid: String` (not `rows: [String]`)

The data-models.md (DESIGN wave) specifies `grid: String` (a multi-line `"""` block), not `rows: [String]` as the DISCUSS wave acceptance-criteria.md shows. The DESIGN data model is authoritative. Tests that verify grid content use `def.grid.contains(...)` or split on `"\n"`, not `def.rows[i]`.

### DEC-DISTILL-06: FloorDefinitionParser is not directly tested

Per DEC-DESIGN-03, `FloorDefinitionParser` is `internal` to `GameDomain`. No acceptance test imports or calls it directly. All assertions go through `FloorRegistry.floor(_:config:)`.

### DEC-DISTILL-07: Fast path not applicable (43 scenarios)

43 scenarios exceed the 3-scenario fast-path threshold. Standard review and DoD validation apply.

---

## Upstream Issues Noted

### Issue 1: DISCUSS vs DESIGN conflict on floor label row

- DISCUSS (AC-HM-03-A) says "row 1"
- DESIGN (DEC-DESIGN-05) says "row 2"
- Resolution: DESIGN is authoritative. All distill tests assert row 2.
- Recommendation: DISCUSS artifact should be updated for accuracy in a follow-up.

### Issue 2: DISCUSS uses `rows: [String]` but DESIGN uses `grid: String`

- DISCUSS user-stories.md and acceptance-criteria.md reference `rows: [String]`
- DESIGN data-models.md specifies `grid: String` (multi-line string)
- Resolution: DESIGN data model is authoritative. Tests use `grid: String`.
- Impact on crafter: use `FloorDefinition(grid:)` initializer, not `FloorDefinition(rows:)`.

### Issue 3: Branch corridor y-coordinate discrepancy

- data-models.md visual shows branch at y=4 with `G` at col 7, `*` at col 2
- FloorGenerator.swift source confirms: branch is at `y == 3` (not y=4), encounter at `y=2`
- The character grid in data-models.md uses y=4 for the branch (north-at-top visual counts from y=6 down)
- The character grid visual in data-models.md line 2 (index 2 from top = y=4) shows `##*....G.######`
- BUT FloorGenerator positions: encounter2D = Position(x: 7, y: 2), egg2D = Position(x: 2, y: 3)
- Resolution: The migration gate test WS-06 (cell-for-cell comparison) will catch any transcription error in the character grid. The crafter must verify the grid visually and with WS-06 passing.

---

## Total Scenario Count

- 43 acceptance test scenarios across 4 test files
- 16 error/edge scenarios (37% overall; individual feature files are 42-44%)
- 0 `@property`-tagged scenarios (no universal invariant criteria in this feature)
- 2 walking skeleton suites (WalkingSkeletonTests + HandcraftedMapsWalkingSkeletonTests)
- 1 deferred scenario (AC-HM-02-D)

---

## Mandate Compliance Evidence

**CM-A (Driving Port Usage)**: All 43 tests invoke either `FloorRegistry.floor(_:config:)` (GameDomain driving port) or `Renderer(output: TUIOutputSpy()).render(_:)` (Renderer driving port). `FloorDefinitionParser` is never called directly. `FloorGenerator` is only called in WS-06 and WS-07 as a comparison baseline, not as the system under test.

**CM-B (Business Language)**: Test names contain no technical terms (no `moveCursor`, `drawChrome`, `FloorDefinitionParser`, `buildGrid`, `splitRows`). Names use: floor, entry, staircase, boss, egg room, corridor, passable cell, dungeon mode, right panel, label, minimap, legend, Ember.

**CM-C (Walking Skeletons + Focused Scenarios)**: Two walking skeleton suites (`Handcrafted Maps — Walking Skeleton`, `Handcrafted Maps — Minimap Starts at Row 3`). Remaining scenarios are focused (one behavior per test).

**CM-D (Pure Function Inventory)**: `FloorRegistry.floor(_:config:)` and `FloorDefinitionParser.parse(_:)` are pure functions — no side effects, deterministic output. No extraction required; they are already pure by design (DESIGN wave, DEC-DESIGN-03).
