# Outcome KPIs — handcrafted-maps

**Feature**: handcrafted-maps
**Date**: 2026-04-04

---

## KPI-HM-01: Floor topology distinctness

**Story**: US-HM-05

**Who**: Player (Rowan, jam judge)
**Does what**: Perceives each floor as visually and navigationally distinct from the others
**By how much**: 5 of 5 floors have a different minimap shape (different grid dimensions or different passable cell arrangement)
**Measured by**: Automated test `AC-HM-05-D` (proxy) + developer visual inspection of minimap on each floor
**Baseline**: 0 of 5 floors are distinct today — all share the identical L-shape

**Target**: 5/5 floors pass the distinctness proxy test AND developer confirms visually distinct minimap shapes for each floor before submission.

---

## KPI-HM-02: Minimap row 2 availability

**Story**: US-HM-03

**Who**: Player (Rowan)
**Does what**: Sees an unobstructed minimap from row 2 on every floor in dungeon mode
**By how much**: 100% of dungeon-mode frames have zero floor-label text in row 2 right panel
**Measured by**: `AC-HM-03-B` — asserts row 2 cols 61-79 contain no "Floor" text
**Baseline**: Currently row 2 right panel is partially overwritten by the floor label on some floors

**Target**: Pass `AC-HM-03-B` on all 5 floors.

---

## KPI-HM-03: Regression-free replacement

**Story**: US-HM-02

**Who**: Developer (Maartene)
**Does what**: Replaces FloorGenerator with FloorRegistry without breaking any existing test
**By how much**: 100% of pre-existing tests pass after FloorRegistry substitution
**Measured by**: `swift test` exit code 0 after replacing FloorGenerator call sites
**Baseline**: Currently all tests pass with FloorGenerator; regression = any test newly failing after substitution

**Target**: `swift test` green on first run after substitution.

---

## KPI-HM-04: Landmark correctness across all floors

**Story**: US-HM-05 + US-HM-02

**Who**: Player (Rowan) + game engine (RulesEngine)
**Does what**: Every landmark (egg, guard, staircase, exit, boss) triggers at the correct position on every floor
**By how much**: 15 landmark positions across 5 floors are all on passable cells and trigger their respective game events correctly
**Measured by**: `AC-HM-05-A` (passability) + existing game-event trigger tests (FloorNavigationTests, WinLossConditionTests, ProgressionTests)
**Baseline**: Currently floor 1 is correct; floors 2-5 use floor 1's positions for all landmarks (wrong)

**Target**: All landmark position tests pass for all 5 floors.

---

## KPI-HM-05: Developer authoring effort

**Story**: US-HM-01 + US-HM-05

**Who**: Developer (Maartene)
**Does what**: Defines a new floor layout as a self-contained data change with no logic modifications
**By how much**: Adding a sixth floor (hypothetically) requires changes to exactly 1 file (the floor definition/registry file), 0 algorithm changes
**Measured by**: Code review confirmation that `FloorRegistry` contains only a lookup/switch and each floor's data is a self-contained `FloorDefinition` constant
**Baseline**: Currently adding a floor requires modifying `FloorGenerator.buildGrid` logic

**Target**: Floor data and floor lookup are cleanly separated; developer can add a floor by adding a `FloorDefinition` constant and a `case` in the registry switch.
