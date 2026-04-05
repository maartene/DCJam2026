# Evolution: gameplay-polish-fixes

**Date**: 2026-04-05
**Feature**: Three gameplay polish fixes — dash distance, egg minimap, patio night sky
**Status**: DELIVERED

---

## Summary

Three targeted gameplay polish fixes delivered in a single feature:

1. Dash advance distance reduced from 3 to 2 squares — improves combat feel and matches intended design.
2. Egg cell renders as `.` on the minimap after pickup (was incorrectly showing `e`) — minimap is now accurate post-collection.
3. Exit patio narrative overlay gains ASCII night sky art with star field and closing line "you are free" — narrative payoff improved.

## Steps Executed

| Step | Name | TDD Phases | Result |
|------|------|-----------|--------|
| 01-01 | Change dash advance distance from 3 to 2 squares | PREPARE → RED_ACCEPTANCE → RED_UNIT (skip: single constant) → GREEN → COMMIT | PASS |
| 02-01 | Egg cell shows '.' on minimap after pickup (hasEgg == true) | PREPARE → RED_ACCEPTANCE → RED_UNIT (skip: one-line renderer change) → GREEN → COMMIT | PASS |
| 03-01 | Add night sky ASCII art to exitPatio narrative overlay | PREPARE → RED_ACCEPTANCE → RED_UNIT (skip: renderer content change, no domain logic) → GREEN → COMMIT | PASS |

## Artifacts

### Production files modified

- `Sources/GameDomain/RulesEngine.swift` — `dashAdvanceSquares` constant changed from `3` to `2`
- `Sources/App/Renderer.swift` — egg minimap fix (`hasEgg == true` returns `.` not `e`) + exitPatio narrativeContent includes night sky art

### Test files added

- `Tests/DCJam2026Tests/DashDistanceTests.swift` — AC1/AC2/AC3 for dash distance
- `Tests/DCJam2026Tests/DashMechanicsTests.swift` — supporting dash mechanics coverage
- `Tests/DCJam2026Tests/EggMinimapTests.swift` — AC1/AC2/AC3 for egg minimap states
- `Tests/DCJam2026Tests/PatioNightSkyTests.swift` — AC1-AC4 for patio night sky render

### Test files updated

- `Tests/DCJam2026Tests/WalkingSkeletonTests.swift` — dash expectation updated 3 → 2
- `Tests/DCJam2026Tests/GuardClearedAfterDefeatTests.swift` — player position setup fix
- `Tests/DCJam2026Tests/MinimapColorTests.swift` — egg collected assertion updated (`"."` not `"e"`)

## Test Results

All 347 tests pass (includes all new and updated tests).

## DES Integrity

All 3 steps have complete traces in execution-log.json (PREPARE → RED_ACCEPTANCE → GREEN → COMMIT). RED_UNIT skipped on all three steps with documented rationale (single-constant change; one-line renderer change; renderer content change with no domain logic).
