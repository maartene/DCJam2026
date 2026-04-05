# Walking Skeleton — handcrafted-maps

**Feature**: handcrafted-maps
**Wave**: DISTILL
**Date**: 2026-04-05

---

## The Skeleton

**`HandcraftedMapsWalkingSkeletonTests.swift`** — specifically test WS-06:

> Every cell on floor 1 has the same passability whether served by FloorRegistry or FloorGenerator.

Enabled alongside WS-01 through WS-07, this suite proves the safe migration in one step:
`FloorDefinition` character grid → `FloorDefinitionParser` → `FloorRegistry.floor(1, config:)` → `FloorMap` identical to `FloorGenerator.generate(floorNumber: 1, config:)`.

---

## Why This Is the Right First Step

### Observable user outcome

The player navigates the same L-shaped corridor as before. Nothing has changed from their perspective. The floor label is not yet relocated. The minimap rows are not yet shifted. The gameplay test suite is green. This is demonstrable to the developer in under one second: `swift test`.

### The litmus test: "Can Ember accomplish her goal?"

Yes. After WS-06 passes, Ember can:
- Spawn on floor 1 at (7, 0)
- Navigate north along the main corridor
- Turn west into the branch at y=4
- Reach the staircase at (7, 6)
- Descend to floor 2 (still served by `FloorGenerator` at that point, which is correct)

All of this is verified by the existing `WalkingSkeletonTests.swift` and `FloorNavigationTests.swift` which continue to pass because `FloorGenerator` is not deleted (DEC-DESIGN-02).

### Why not start with the floor label (US-HM-03)?

The floor label change (US-HM-03) is a pure rendering change — independent and lower risk. However, it requires the minimap row offset to shift, which affects existing `MinimapTests.swift`. That test file uses the old formula `screenRow = 2 + (6 - y)`. Changing the renderer before the migration is proven would conflate two changes. The migration gate (WS-06) must be green first so that any subsequent test failures are attributable to label/minimap row changes, not to character grid parsing errors.

### Why not start with floor 2-5 content (US-HM-05)?

Floor 2-5 content is developer-authored after the migration is proven (DEC-DESIGN-07, DEC-DESIGN-09). Authoring new floor topologies before the parsing pipeline is correct risks compounding transcription errors with pipeline errors. WS-06 eliminates the pipeline risk entirely before creative content is added.

---

## One-at-a-Time Enable Sequence

The crafter enables tests in this order during DELIVER:

1. **WS-01**: `Floor 1 served by FloorRegistry has 15 columns and 7 rows`
   — First test. Proves `FloorRegistry` compiles and returns a `FloorMap` at all.
   — Implement: `FloorDefinition`, `FloorDefinitionParser`, `FloorRegistry` with floor 1 grid.

2. **WS-02 through WS-05**: landmark positions and flag assertions.
   — Enable one per passing commit.

3. **WS-06**: `Every cell on floor 1 has the same passability whether served by FloorRegistry or FloorGenerator`
   — The migration gate. This is the commit that proves the data pipeline is correct.
   — After this passes: update `RulesEngine` and `Renderer` call sites (3 + 1 substitutions).

4. **WS-07, WS-08**: flags match + fallback resilience.

5. Move to `HandcraftedMapsFloorLabelTests.swift` (US-HM-03) and enable FL-01 first.

6. Move to `HandcraftedMapsMinimapTests.swift` (US-HM-04) and enable MM-01 first.

7. Move to `HandcraftedMapsFloorDefinitionTests.swift` suites as floor 2-5 content is authored.

---

## What "Done" Looks Like for the Walking Skeleton

- `swift test` is green after WS-06 passes
- The existing `WalkingSkeletonTests.swift`, `FloorNavigationTests.swift`, `MinimapTests.swift`, `TwoDFloorTests.swift` all still pass
- No modification to those existing test files was required
- The player's experience on floor 1 is visually identical to before
