# Test Scenarios: Turning Mechanic

**Feature**: turning-mechanic
**Date**: 2026-04-02
**Author**: Quinn (Acceptance Test Designer — DISTILL wave)
**Status**: Complete — ready for DELIVER wave

---

## Coverage Summary

| File | User Story | Scenarios | Error/Edge | Error % |
|------|------------|-----------|------------|---------|
| TurningMechanicTests.swift | US-TM-01 + US-TM-02 | 6 | 2 | 33% |
| TwoDFloorTests.swift | US-TM-03 | 13 | 5 | 38% |
| MinimapTests.swift | US-TM-04 | 8 | 2 | 25% |
| TurnKeyBindingTests.swift | US-TM-05 | 11 | 4 | 36% |
| TurningEdgeCaseTests.swift | US-TM-06 | 8 | 4 | 50% |
| **Total** | US-TM-01..06 | **46** | **17** | **37%** |

Target: 40% error/edge ratio. Overall at 37% — within acceptable range given the primarily-structural nature of US-TM-01 and US-TM-04. US-TM-06 at 50% compensates. Walking skeleton adds 1 enabled test.

---

## US-TM-01: CardinalDirection Domain Type

### Enabled (walking skeleton partial)
1. **Ember turns left and right, and the facing direction changes** — walking skeleton; covers both US-TM-01 and US-TM-02

### Disabled
2. New run initialises to North facing
3. `withFacingDirection` returns a copied state with updated facing
4. All four cardinal directions are representable

---

## US-TM-02: RulesEngine Turn Command

### Disabled (after walking skeleton is green)
5. Complete turn rotation table correct for all 8 combinations
6. Turning has no side effects on HP, Dash charges, Special charge, or position
7. Four consecutive left turns return to original facing
8. Four consecutive right turns return to original facing

**Error/edge in US-TM-02**: scenarios 6 (side-effects = absence of change), 7+8 (rotation cycle).

---

## US-TM-03: 2D Floor Model and Facing-Relative Movement

### Disabled
1. playerPosition has x and y integer fields
2. New run starts at the floor entry cell (7, 0)
3. Forward while facing North advances by (dx:0, dy:+1)
4. Forward while facing East advances by (dx:+1, dy:0)
5. Forward while facing South retreats by (dx:0, dy:-1)
6. Forward while facing West retreats by (dx:-1, dy:0)
7. Backward is the inverse delta for all four facings
8. **[error]** Ember cannot step into a wall cell — position unchanged
9. **[error]** Movement clamped at south boundary (y=0)
10. **[error]** Movement clamped at west boundary via wall collision at x=0
11. **[integration]** Encounter proximity check fires when Ember steps onto encounter cell
12. **[integration]** Win condition checked when Ember reaches exit with egg
13. Generated floor has 15×7 grid dimensions
14. Main corridor cells at x=7 are passable
15. Branch corridor cells at y=3 from x=2 to x=7 are passable
16. Landmark positions match L-shaped corridor topology

---

## US-TM-04: 2D Minimap with Facing Indicator

### Disabled
1. Minimap shows `^` when Ember faces North
2. Minimap shows `>` when Ember faces East
3. Minimap shows `v` when Ember faces South
4. Minimap shows `<` when Ember faces West
5. **[error]** Player marker overrides encounter landmark at same cell
6. **[error]** Player marker overrides entry landmark at start
7. Minimap updates same frame as turn command
8. Each minimap panel row fits within 19-column panel width
9. Minimap renders wall cells as `#` and corridor cells distinctly

---

## US-TM-05: Turn Key Bindings

### Disabled
1. Lowercase `a` produces turn-left command
2. Uppercase `A` produces turn-left command
3. Lowercase `d` produces turn-right command
4. Uppercase `D` produces turn-right command
5. Arrow Left escape sequence produces turn-left command
6. Arrow Right escape sequence produces turn-right command
7. **[regression guard]** `w` still produces move-forward
8. **[regression guard]** `s` still produces move-backward
9. **[regression guard]** Arrow Up still produces move-forward
10. **[regression guard]** Arrow Down still produces move-backward
11. Rapid right-then-left returns Ember to original facing (domain round-trip)

*Note*: AC-05-8 (controls hint row) is out of scope per DSGN-01 — no test written.

---

## US-TM-06: Facing Persistence and Combat Turn Blocking

### Disabled
1. Facing persists through floor transition (withCurrentFloor)
2. Facing persists through multiple floor transitions
3. withCurrentFloor does not reset facing to North
4. **[error]** Turn command ignored during combat — facing does not change
5. **[error]** screenMode remains .combat after blocked turn
6. **[error]** Enemy HP unchanged after blocked turn in combat (deltaTime=0)
7. **[error]** All turn directions blocked in combat for all four starting facings
8. Movement still locked in combat regardless of facing (regression of DISC-03)
9. HP unchanged when move blocked in combat at deltaTime=0

---

## Acceptance Criteria Coverage

| AC | Description | Test File | Scenario |
|----|-------------|-----------|----------|
| AC-01-1 | CardinalDirection enum exists | TurningMechanicTests | allFourCardinalDirectionsExist |
| AC-01-2 | GameState.facingDirection field | TurningMechanicTests | newRunInitialisesToNorthFacing |
| AC-01-3 | initial() sets .north | TurningMechanicTests | newRunInitialisesToNorthFacing |
| AC-01-4 | withFacingDirection returns new state | TurningMechanicTests | withFacingDirectionReturnsCopiedState |
| AC-01-5 | Sendable conformance | Compiler-enforced (Swift 6) | — |
| AC-02-1 | Turn left from North → West | TurningMechanicTests | walking skeleton + fullRotationTableIsCorrect |
| AC-02-2 | Turn right from North → East | TurningMechanicTests | walking skeleton + fullRotationTableIsCorrect |
| AC-02-3 | Full rotation table (8 combos) | TurningMechanicTests | fullRotationTableIsCorrect |
| AC-02-4 | Turn does not change HP/dash/special/position | TurningMechanicTests | turningHasNoSideEffectsOnVitalStats |
| AC-02-5 | Four consecutive turns = round trip | TurningMechanicTests | fourConsecutiveLeftTurnsReturnToStart + Right |
| AC-03-1 | playerPosition is 2D | TwoDFloorTests | playerPositionIsTwoDimensional |
| AC-03-2 | Forward North = (0,+1) | TwoDFloorTests | forwardNorthAppliesCorrectDelta |
| AC-03-3 | Forward East = (+1,0) | TwoDFloorTests | forwardEastAppliesCorrectDelta |
| AC-03-4 | Forward South = (0,-1) | TwoDFloorTests | forwardSouthAppliesCorrectDelta |
| AC-03-5 | Forward West = (-1,0) | TwoDFloorTests | forwardWestAppliesCorrectDelta |
| AC-03-6 | Backward = inverse delta | TwoDFloorTests | backwardIsInverseOfForward |
| AC-03-7 | Position clamped to grid bounds | TwoDFloorTests | movementClampedAtSouthBoundary + West |
| AC-03-8 | Encounter proximity check after move | TwoDFloorTests | encounterProximityCheckAppliedAfterMove |
| AC-03-9 | Win condition after move | TwoDFloorTests | winConditionCheckedAfterMoveToExit |
| AC-04-1 | Minimap renders 2D grid | MinimapTests | minimapRendersWallAndCorridorDistinctly |
| AC-04-2 | Minimap in dedicated screen region | MinimapTests | minimapRowsFitWithinPanelWidth |
| AC-04-3 | Player = `^` when facing North | MinimapTests | minimapShowsCaretNorthWhenFacingNorth |
| AC-04-4 | Player = `>` when facing East | MinimapTests | minimapShowsCaretEastWhenFacingEast |
| AC-04-5 | Player = `v` when facing South | MinimapTests | minimapShowsCaretSouthWhenFacingSouth |
| AC-04-6 | Player = `<` when facing West | MinimapTests | minimapShowsCaretWestWhenFacingWest |
| AC-04-7 | Player marker overrides landmarks | MinimapTests | playerMarkerOverridesEncounterLandmark + Entry |
| AC-04-8 | Minimap updates same frame as command | MinimapTests | minimapUpdatesSameFrameAsTurnCommand |
| AC-05-1 | `a` → .turn(.left) | TurnKeyBindingTests | lowercaseAProducesTurnLeft |
| AC-05-2 | `A` → .turn(.left) | TurnKeyBindingTests | uppercaseAProducesTurnLeft |
| AC-05-3 | `d` → .turn(.right) | TurnKeyBindingTests | lowercaseDProducesTurnRight |
| AC-05-4 | `D` → .turn(.right) | TurnKeyBindingTests | uppercaseDProducesTurnRight |
| AC-05-5 | Arrow Left → .turn(.left) | TurnKeyBindingTests | arrowLeftProducesTurnLeft |
| AC-05-6 | Arrow Right → .turn(.right) | TurnKeyBindingTests | arrowRightProducesTurnRight |
| AC-05-7 | W/S/Arrow Up/Down unchanged | TurnKeyBindingTests | wKey+sKey+arrowUp+arrowDown regression |
| AC-05-8 | Controls hint row | **REMOVED** — DSGN-01 out of scope | — |
| AC-06-1 | withCurrentFloor does not reset facing | TurningEdgeCaseTests | facingPersistsThroughFloorTransition |
| AC-06-2 | Turn ignored in .combat | TurningEdgeCaseTests | turnCommandIgnoredInCombat |
| AC-06-3 | Combat state unchanged on blocked turn | TurningEdgeCaseTests | enemyHPUnchangedAfterBlockedTurn |
| AC-06-4 | facingDirection unchanged in combat | TurningEdgeCaseTests | allTurnDirectionsBlockedInCombat |
| AC-06-5 | Movement locked regardless of facing | TurningEdgeCaseTests | movementLockedInCombatRegardlessOfFacing |

---

## Notes on DISCUSS AC vs DESIGN Alignment

- **AC-03-1..8**: DISCUSS user-stories.md described 1D movement; data-models.md confirmed 2D `(dx,dy)` deltas with `Position(x:y:)`. Tests use 2D throughout.
- **AC-06-2**: DISCUSS US-TM-06 technical notes stated "turn rejected/ignored during .combat". WD-08 confirms "BLOCKED". Tests assert `facingDirection` unchanged after `.turn` command in `.combat`.
- **AC-05-8**: DSGN-01 removed the controls hint row. No test written.

---

## Grid Topology Reference (ADR-004)

```
Y=6  . . . . . . . S . . . . . . .   S = staircase / exit
Y=5  . . . . . . . . . . . . . . .
Y=4  . . . . . . . . . . . . . . .
Y=3  . . * . . . . . . . . . . . .   * = egg room, branch x=2..7
Y=2  . . . . . . . . . . . . . . .
Y=1  . . . . . . . . . . . . . . .
Y=0  . . . . . . . E . . . . . . .   E = entry
     0 1 2 3 4 5 6 7 8 9 . . .  14  X
```

Key positions: entry=(7,0), staircase=(7,6), encounter=(7,3), egg=(2,3) [floors 2-4].
Grid size: 15 wide × 7 tall. Font aspect ratio ≈ 2:1 → visual ratio 15:14 ≈ square.
