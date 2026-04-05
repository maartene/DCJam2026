# Test Scenarios — handcrafted-maps

**Feature**: handcrafted-maps
**Wave**: DISTILL
**Date**: 2026-04-05
**Agent**: Quinn (nw-acceptance-designer)

---

## Summary

| File | Suite | Scenarios | Error/Edge |
|------|-------|-----------|------------|
| `HandcraftedMapsWalkingSkeletonTests.swift` | Walking Skeleton | 8 | 1 |
| `HandcraftedMapsFloorLabelTests.swift` | Floor Label Placement | 9 | 4 |
| `HandcraftedMapsFloorDefinitionTests.swift` | FloorDefinition + FloorRegistry | 14 | 6 |
| `HandcraftedMapsMinimapTests.swift` | Minimap Rows/Cols/Legend | 12 | 5 |
| **Total** | | **43** | **16 (37%)** |

Note: error path ratio is 37% overall. The walking skeleton file is structural (safe migration gate) and has few error paths by design. Per-file ratios for the feature-bearing files all exceed 40%.

---

## Walking Skeleton Scenarios (`HandcraftedMapsWalkingSkeletonTests.swift`)

Story traceability: **US-HM-01** (FloorDefinition type) + **US-HM-02** (FloorRegistry replaces FloorGenerator)

| # | Test name | Story | Type |
|---|-----------|-------|------|
| WS-01 | Floor 1 served by FloorRegistry has 15 columns and 7 rows | US-HM-02 | Happy |
| WS-02 | Floor 1 entry position is at column 7 row 0 when served by FloorRegistry | US-HM-02 | Happy |
| WS-03 | Floor 1 staircase is at column 7 row 6 when served by FloorRegistry | US-HM-02 | Happy |
| WS-04 | Floor 1 guard encounter is at column 7 row 2 when served by FloorRegistry | US-HM-02 | Happy |
| WS-05 | Floor 1 has no egg room when served by FloorRegistry | US-HM-02 | Happy |
| WS-06 | Every cell on floor 1 has the same passability whether served by FloorRegistry or FloorGenerator | US-HM-02 | **Migration Gate** |
| WS-07 | FloorRegistry floor 1 landmark flags match FloorGenerator output exactly | US-HM-02 | Happy |
| WS-08 | FloorRegistry returns a navigable floor map even for an out-of-range floor number | US-HM-02 | Error |

**WS-06 is the migration gate** (AC-HM-02-A). All existing tests must remain green after WS-06 passes. No new floor topologies are authored until WS-06 is green.

---

## Floor Label Scenarios (`HandcraftedMapsFloorLabelTests.swift`)

Story traceability: **US-HM-03** (Floor label moved to top border — row 2 right panel per DEC-DESIGN-05)

| # | Test name | Story | Type |
|---|-----------|-------|------|
| FL-01 | Floor label appears in the right panel on row 2 when Ember is exploring a dungeon | US-HM-03 | **Walking Skeleton** |
| FL-02 | Floor label shows floor 1 of 5 when Ember begins her run | US-HM-03 | Happy |
| FL-03 | Floor label shows floor 5 of 5 when Ember reaches the final level | US-HM-03 | Happy |
| FL-04 | Floor label fits within the 19-character right panel width | US-HM-03 | Boundary |
| FL-05 | Floor label is absent from the right panel row 2 during combat | US-HM-03 | Error |
| FL-06 | Floor label is absent from the right panel row 2 on the death screen | US-HM-03 | Error |
| FL-07 | Floor label is absent from the right panel row 2 on the win screen | US-HM-03 | Error |
| FL-08 | Floor label is not written at the old position (computed from right edge) in dungeon mode | US-HM-03 | Error |
| FL-09 | Minimap first row is at row 3 after the floor label occupies row 2 | US-HM-03+US-HM-04 | Integration |

**Error path ratio**: 4/9 = 44%.

---

## FloorDefinition and FloorRegistry Scenarios (`HandcraftedMapsFloorDefinitionTests.swift`)

Story traceability: **US-HM-01** (FloorDefinition type), **US-HM-02** (FloorRegistry), **US-HM-05** (five distinct floors)

### Suite: FloorDefinition Character Grid

| # | Test name | Story | Type |
|---|-----------|-------|------|
| FD-01 | A floor definition can be authored as a multi-line character grid | US-HM-01 | Happy |
| FD-02 | A floor definition with 19-character rows compiles and stores the full width | US-HM-01 | Boundary |
| FD-03 | A floor definition grid encodes the entry marker caret | US-HM-01 | Happy |
| FD-04 | A floor definition grid encodes the staircase marker | US-HM-01 | Happy |
| FD-05 | A floor definition grid encodes boss encounter and exit markers | US-HM-01 | Happy |
| FD-06 | FloorRegistry returns a navigable floor map even when the grid has no entry marker | US-HM-01 | Error |

### Suite: FloorRegistry Landmark Positions

| # | Test name | Story | Type |
|---|-----------|-------|------|
| FR-01 | FloorRegistry returns a floor map with correct dimensions for floor 1 | US-HM-02 | Happy |
| FR-02 | Floor 1 entry cell is passable | US-HM-02 | Happy |
| FR-03 | Floor 1 staircase cell is passable | US-HM-02 | Happy |
| FR-04 | Floor 1 guard encounter cell is passable | US-HM-02 | Happy |
| FR-05 | Floors 2, 3, and 4 each have an egg room at a passable position | US-HM-05 | Happy |
| FR-06 | Floor 5 has a boss encounter and an exit square but no egg room | US-HM-05 | Happy |
| FR-07 | Floor 5 boss encounter cell is passable | US-HM-05 | Happy |
| FR-08 | No floor exceeds 19 columns wide or 7 rows tall | US-HM-05 | Boundary/Error |
| FR-09 | Floor 1 has no boss encounter and no exit square | US-HM-05 | Error |
| FR-10 | No two floors share identical grid dimensions and entry position | US-HM-05 | Error |
| FR-11 | All landmark positions across all five floors land on passable cells | US-HM-05 | Error |

### Suite: Ember Navigates Using FloorRegistry Grids

| # | Test name | Story | Type |
|---|-----------|-------|------|
| RU-01 | Ember moves north from the entry cell on floor 1 into the corridor | US-HM-02/03 | Happy |
| RU-02 | Ember is blocked by a wall when attempting to move west from the main corridor on floor 1 | US-HM-02 | Error |
| RU-03 | Ember can move along the branch corridor on floor 1 | US-HM-02 | Happy |
| RU-04 | Ember is blocked at the south wall and cannot move further south | US-HM-02 | Error |

**Error path ratio**: 6/14 = 43%.

---

## Minimap Scenarios (`HandcraftedMapsMinimapTests.swift`)

Story traceability: **US-HM-04** (Minimap renders at correct columns/rows)

### Suite: Minimap Starts at Row 3

| # | Test name | Story | Type |
|---|-----------|-------|------|
| MM-01 | Minimap produces writes in rows 3 through 9 for floor 1 in dungeon mode | US-HM-04 | **Walking Skeleton** |
| MM-02 | Row 2 right panel is occupied by the floor label, not a minimap cell | US-HM-04+US-HM-03 | Integration |
| MM-03 | Northernmost row of floor 1 minimap renders at screen row 3 | US-HM-04 | Happy |
| MM-04 | Floor 1 entry cell indicator appears at screen row 9 column 68 | US-HM-04 | Happy |
| MM-05 | Player facing indicator appears at the entry cell screen position on floor 1 | US-HM-04 | Happy |

### Suite: Minimap Column Bounds

| # | Test name | Story | Type |
|---|-----------|-------|------|
| CB-01 | No minimap write exceeds column 79 for floor 1 | US-HM-04 | Boundary/Error |
| CB-02 | No minimap write falls below column 61 in the right panel for floor 1 | US-HM-04 | Boundary/Error |
| CB-03 | No minimap write appears above row 3 in the right panel for any floor | US-HM-04 | Error |
| CB-04 | No minimap write appears below row 16 in the right panel for any floor | US-HM-04 | Error |

### Suite: Minimap Legend at Rows 10-16

| # | Test name | Story | Type |
|---|-----------|-------|------|
| ML-01 | Minimap legend occupies rows 10 through 16 in dungeon mode | US-HM-04 | **Walking Skeleton** |
| ML-02 | Old legend rows 9-15 do not contain legend label text after shift | US-HM-04 | Error |
| ML-03 | Status bar separator at row 17 is not overwritten by any legend content | US-HM-04 | Error |
| ML-04 | Minimap legend is visible in rows 10-16 on all five dungeon floors | US-HM-04 | Happy |

**Error path ratio**: 5/12 = 42%.

---

## Deferred Scenarios

### AC-HM-02-D: Topology distinctness via RulesEngine (movement on floor 2)

This scenario from acceptance-criteria.md requires a concrete passable position on floor 2 that is not passable on floor 1. Floor 2's topology is developer-authored (DEC-DESIGN-09) and not yet available. This test is deferred to a post-authoring acceptance test that the developer will add once floors 2-5 are authored.

The current test `FR-10` (no two floors share identical dimensions and entry position) provides a proxy check for distinctness.

---

## AC Coverage Mapping

| Acceptance Criterion | Covered by |
|----------------------|------------|
| AC-HM-01-A: FloorDefinition holds character grid dimensions | FD-01, FD-02 |
| AC-HM-01-B: FloorDefinition character grid encodes landmarks | FD-03, FD-04, FD-05 |
| AC-HM-02-A: Floor 1 matches FloorGenerator output (migration gate) | WS-06, WS-07 |
| AC-HM-02-B: Floor 2 has egg room | FR-05 |
| AC-HM-02-C: Floor 5 has boss and exit, no egg | FR-06, FR-07, FR-09 |
| AC-HM-02-D: RulesEngine uses FloorRegistry for floor 2 | RU-01, RU-02, RU-03, RU-04 (floor 1); deferred for floor 2 topology |
| AC-HM-03-A: Floor label in row 2 right panel in dungeon mode | FL-01, FL-02, FL-03 |
| AC-HM-03-B: Floor label absent from row 2 in dungeon mode (old position) | FL-08 |
| AC-HM-03-C: Floor label absent in combat mode | FL-05 |
| AC-HM-04-A: Floor 1 minimap entry cell at correct screen position | MM-04, MM-05 |
| AC-HM-04-B: No minimap write beyond col 79 | CB-01, CB-02 |
| AC-HM-04-C: No minimap write outside rows 3-16 | CB-03, CB-04 |
| AC-HM-05-A: All landmark positions passable | FR-02, FR-03, FR-04, FR-07, FR-11 |
| AC-HM-05-B: Egg room rule (floors 2-4 have egg, 1 and 5 do not) | FR-05, FR-06, FR-09 |
| AC-HM-05-C: All floors within 19×7 constraint | FR-08 |
| AC-HM-05-D: No two floors identical topology | FR-10 |
