# Walking Skeleton: Turning Mechanic

**Feature**: turning-mechanic
**Date**: 2026-04-02
**Author**: Quinn (Acceptance Test Designer — DISTILL wave)

---

## Identification

**Test**: `TurningMechanicTests.swift` — `emberTurnsLeftAndRight()`
**Suite**: `"Turning Mechanic — CardinalDirection and Turn Command"`
**Status**: Enabled (will be RED until implementation ships)

---

## Scenario (Given-When-Then)

```
Given  Ember starts a new run (GameState.initial — facingDirection = .north)
When   RulesEngine processes GameCommand.turn(.left)
Then   Ember's facingDirection is .west

When   RulesEngine processes GameCommand.turn(.right) from the same initial state
Then   Ember's facingDirection is .east
```

---

## Why This Is the Walking Skeleton

This single test proves the minimum end-to-end slice required for the jam rule ("90-degree turns, keyboard-invoked"):

1. `CardinalDirection` enum exists and has at least `.north`, `.east`, `.west`
2. `TurnDirection` enum exists with `.left` and `.right`
3. `GameCommand.turn(TurnDirection)` case exists
4. `GameState` has `facingDirection: CardinalDirection`
5. `GameState.initial` initialises `facingDirection` to `.north`
6. `RulesEngine.apply(command: .turn(.left), to:, deltaTime:)` processes the command
7. The result `GameState` reflects the updated `facingDirection`

This is the thinnest slice that proves the turn command flows from caller through RulesEngine into observable state. It does not require:
- 2D floor movement (US-TM-03)
- Minimap rendering (US-TM-04)
- InputHandler key bindings (US-TM-05)
- Floor transitions or combat blocking (US-TM-06)

---

## Walking Skeleton Litmus Test

1. **Title describes user goal**: "Ember turns left and right, and the facing direction changes" — describes what Ember can do, not what layers the command traverses.
2. **Given/When describe user context and action**: Given = start of a run. When = Ember turns.
3. **Then describes observable outcome**: facingDirection is the observable state change that drives minimap and movement.
4. **Non-technical stakeholder confirmation**: "Yes — I need to know the game records which way Ember is facing after a turn." Confirmed.

---

## Expected Failure Mode

The test will fail to compile until `CardinalDirection`, `TurnDirection`, and `GameCommand.turn` are added to `GameDomain`, and `GameState.facingDirection` is added. That is the correct RED state — the failing outer loop that triggers the inner TDD loop.

---

## Handoff Sequence

The walking skeleton defines the starting point for the DELIVER wave one-at-a-time sequence:

1. Enable: `emberTurnsLeftAndRight()` (walking skeleton) — **currently enabled**
2. Next: `newRunInitialisesToNorthFacing`
3. Next: `withFacingDirectionReturnsCopiedState`
4. Next: `allFourCardinalDirectionsExist`
5. Next: `fullRotationTableIsCorrect`
6. ...continue through all 46 scenarios in the order listed in test-scenarios.md

Each scenario is enabled only after the previous passes and is committed.
