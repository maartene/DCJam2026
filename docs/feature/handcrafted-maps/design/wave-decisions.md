# Wave Decisions — handcrafted-maps

**Feature**: handcrafted-maps
**Wave**: DESIGN
**Date**: 2026-04-04
**Agent**: Morgan (nw-solution-architect)

This document summarises all DESIGN wave decisions for consumption by the DISTILL wave (acceptance-designer) and DELIVER wave (software-crafter).

---

## DEC-DESIGN-01: Character-grid format for floor data

**Decision**: Floor layouts are expressed as `[String]` — an array of Swift string literals, one string per row, each character representing one grid cell.

**Rationale**: Zero new dependencies; human-readable; diff-friendly; directly compilable as static data; satisfies GameDomain zero-I/O constraint. See ADR-HM-001.

**Impact on DISTILL**: Acceptance criteria referencing `FloorDefinition` should verify `rows` field contents and character-level assertions (e.g., `def.rows[1].contains("^")`).

**Impact on DELIVER**: Author five `FloorDefinition` constants in `Sources/GameDomain/HandcraftedFloors.swift` (or inline in `FloorRegistry`).

---

## DEC-DESIGN-02: FloorGenerator retained (not deleted)

**Decision**: `FloorGenerator` is not modified or deleted. All existing tests calling `FloorGenerator.generate` continue to compile and pass.

**Rationale**: Safe migration gate (AC-HM-02-A) requires `FloorGenerator` to exist as a comparison baseline. Deleting it would break existing tests and remove the regression baseline.

**Impact on DISTILL**: AC-HM-02-A directly calls both `FloorRegistry.floor(1, ...)` and `FloorGenerator.generate(floorNumber: 1, ...)` and asserts they are identical. This test is the gate for the walking skeleton.

**Impact on DELIVER**: Do not add `FloorGenerator` to the deletion scope. The crafter substitutes call sites in `RulesEngine` and `Renderer` but leaves `FloorGenerator` source intact.

---

## DEC-DESIGN-03: FloorDefinitionParser is internal to GameDomain

**Decision**: `FloorDefinitionParser` is an `internal` type within `GameDomain`. It is not part of the public API. Only `FloorRegistry` calls it.

**Rationale**: Parsing is an implementation detail of the registry. Exposing it publicly would create an unnecessary surface area for callers to bypass `FloorRegistry`'s game-rule logic.

**Impact on DISTILL**: No acceptance tests should directly test `FloorDefinitionParser`. Tests go through `FloorRegistry.floor(_:config:)` (the public interface).

**Impact on DELIVER**: `FloorDefinitionParser` may be `internal enum` or private to `FloorRegistry.swift`. Crafter decides the exact file placement.

---

## DEC-DESIGN-04: Game-rule flags derived from grid characters (grid is authoritative)

**Decision**: `hasEggRoom`, `hasBossEncounter`, and `hasExitSquare` in the constructed `FloorMap` are derived from whether the parsed grid contains `*`, `B`, or `X` respectively — not from floor-number conditionals.

**Rationale**: The grid is the single source of truth for floor content. Floor-number conditionals in `FloorRegistry` would re-introduce the coupling that `FloorDefinition` was designed to eliminate. If the developer authors a floor 3 grid without `*`, `hasEggRoom` is correctly false — no special-case code needed.

**Impact on DISTILL**: AC-HM-02-B and AC-HM-02-C test `hasEggRoom`, `hasBossEncounter`, `hasExitSquare` on specific floors. These pass because the floor definitions authored in DEC-DESIGN-01 contain the correct characters.

**Impact on DELIVER**: `FloorRegistry.floor` sets `hasEggRoom = parsed.eggPosition != nil`. No `switch floorNumber` for flag assignment.

---

## DEC-DESIGN-05: Floor label written at row 2, cols 61–79, directly in renderDungeon

**Decision**: The floor label is written at row 2, cols 61–79, by a direct `moveCursor` + `write` call inside `renderDungeon()`. `drawChrome()` signature is unchanged. The minimap starts at row 3. See ADR-018.

**Rationale**: Floor state is already available in `renderDungeon`. Extending `drawChrome` with a parameter would thread a feature-specific concern through a general-purpose chrome utility — unnecessary complexity for a jam-scope single-developer project. The row 2 placement is a two-line addition in one method with no impact on any other render path.

**Impact on DISTILL**: AC-HM-03-A should assert the label appears at row 2 cols 61–79 in dungeon mode (not row 1). AC-HM-03-C asserts it is absent in combat mode — this passes because only `renderDungeon` writes that location.

**Impact on DELIVER**: In `renderDungeon`, before the minimap draw: add `output.moveCursor(row: 2, col: 61); output.write(" Floor \(state.currentFloor)/\(state.config.maxFloors) ")`. Update minimap start row from 2 to 3. Do not change `drawChrome`.

---

## DEC-DESIGN-06: Minimap legend always visible — floor height capped at 7 rows

**Decision**: All handcrafted floors are authored at 7 rows maximum. `drawMinimapLegend()` is called unconditionally at rows 10–16. No conditional guard on floor height. See ADR-019.

**Rationale**: With the minimap starting at row 3, a floor of height H occupies rows 3 to `3 + H - 1`. The empty slack row 16 below the last legend entry is consumed when the floor label moves to row 2 and the legend shifts from rows 9–15 to rows 10–16. For the legend at rows 10–16 to never be obstructed, H must be ≤ 7. Capping floor height as an authoring constraint is simpler than a runtime conditional: no `if` guard, no acceptance test for the conditional, no risk of the off-by-one threshold being miscounted.

**Impact on DISTILL**: Acceptance tests for all floors 1–5 may assert legend rows 10–16 are present. No floor exceeds 7 rows.

**Impact on DELIVER**: Do not add any `if floor.grid.height <= N` guard. Call `drawMinimapLegend()` unconditionally at rows 10–16. All authored `FloorDefinition` grids must have at most 7 rows.

---

## DEC-DESIGN-07: Walking skeleton is the hard gate for floors 2-5

**Decision**: The safe migration (floor 1 via `FloorRegistry` producing identical output to `FloorGenerator`) must be complete and all tests green before any of floors 2-5 are authored.

**Rationale**: AC-HM-02-A is the regression gate. If parsing or FloorMap construction is wrong, it will surface on floor 1 before any new topology is introduced. This ordering prevents mixed-cause failures.

**Impact on DISTILL**: The acceptance test suite should be deliverable in two stages matching the story map's release slices: Release 1 (AC-HM-01, AC-HM-02-A) and Release 2+ (remaining ACs).

**Impact on DELIVER**: Commit order — floor 1 FloorDefinition + FloorRegistry wired first. Run `swift test`. Green = proceed to floors 2-5.

---

## DEC-DESIGN-08: Floor topology specifications — floor 1 only for crafter

**Decision**: The crafter authors the floor 1 character grid only. Floors 2–5 are developer-authored after crafter delivers the migration. All floors must be at most 7 rows tall (authoring constraint from ADR-019).

| Floor | Shape | W | H | Author |
|-------|-------|---|---|--------|
| 1 | L-shaped (existing topology) | 15 | 7 | Crafter |
| 2–5 | TBD by developer | ≤19 | ≤7 | Developer |

**Impact on DISTILL**: AC-HM-05-D (distinctness proxy) should be scoped to floors the developer has authored. AC-HM-04-A/B/C (minimap bounds) must verify height ≤ 7 for all floors.

**Impact on DELIVER**: Author only the floor 1 grid. Leave floors 2–5 as placeholder stubs (e.g., a minimal valid grid that compiles) or as empty `FloorDefinition` constants; the developer will replace them.

---

## DEC-DESIGN-09: Crafter scope is migration only — floor authoring by developer

**Decision**: The crafter's work is limited to:
1. Define `FloorDefinition`, `FloorDefinitionParser`, and `FloorRegistry` types in `GameDomain`
2. Populate `FloorRegistry` with the floor 1 L-shaped corridor expressed as a character grid (topology identical to `FloorGenerator` output today)
3. Update the 4 `FloorGenerator` call sites in `RulesEngine` and `Renderer` to use `FloorRegistry`
4. Move floor label to row 2, cols 61–79, in `renderDungeon`; update minimap start row to 3

Authoring floors 2–5 is explicitly out of scope for the crafter. The developer will author the 5 distinct floor layouts.

**Rationale**: The developer prefers to control the creative content (floor layout designs) directly. The crafter's value in this feature is establishing the type infrastructure and performing the mechanical migration — not designing or writing map content.

**Impact on DISTILL**: Acceptance criteria for floors 2–5 layout and topology (AC-HM-05-A through AC-HM-05-E) are conditioned on developer-authored content; they should be structured so the crafter's delivery is testable on floor 1 alone.

**Impact on DELIVER**: Deliver the migration (floor 1 + call sites + label relocation). Leave floors 2–5 as placeholder stubs with a minimal valid `FloorDefinition` that compiles. Do not design or author floor topologies for floors 2–5.

---

## Open Questions for DISTILL Wave

**AC-HM-02-D (topology distinctness test)**: This AC requires a concrete passable position on floor 2 that is not passable on floor 1. Floor 2's topology is not yet authored (developer-authored, out of crafter scope). The DISTILL wave should structure this AC so it can be validated after the developer authors floors 2–5, or scope it as a deferred acceptance test to be completed once floor 2's exact grid is known.

**AC-HM-02-A (migration gate)**: The floor 1 grid is 15×7, matching the `FloorGenerator` output of 15×7 exactly. AC-HM-02-A may compare `FloorRegistry` output to `FloorGenerator` output with an exact dimension match. The DISTILL wave should confirm whether the comparison is cell-for-cell exact or structural equivalence (topology + landmark positions); exact match is now feasible given equal dimensions.
