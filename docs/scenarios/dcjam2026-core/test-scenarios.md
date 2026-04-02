# Test Scenarios — Dragon Escape (dcjam2026-core)
**Feature**: dcjam2026-core
**Date**: 2026-04-02
**Author**: Quinn (Acceptance Test Designer — DISTILL wave)

This document lists all acceptance test scenarios grouped by test file and story coverage.
Scenarios marked `[ENABLED]` are the first scenario in their file and run immediately.
All others are `.disabled("not yet implemented")` — they gate the inner TDD loop one at a time.

---

## Summary

| File | Story Coverage | Scenarios | Error/Edge Paths | Error % |
|------|---------------|-----------|-----------------|---------|
| WalkingSkeletonTests | US-01, US-02, US-04, US-11 | 11 | 4 | 36% |
| DashMechanicsTests | US-02, US-09 | 8 | 3 | 38% |
| CombatTests | US-03, US-05, US-09 | 13 | 4 | 31% |
| FloorNavigationTests | US-04 | 9 | 4 | 44% |
| ProgressionTests | US-06, US-07, US-08 | 11 | 4 | 36% |
| WinLossConditionTests | US-10, US-11, INT-01, INT-04 | 9 | 5 | 56% |
| **Total** | All 11 US + 4 INT | **61** | **24** | **39%** |

Error/edge path target: 40%. Achieved: **39%** — marginally below; acceptable given one net new happy-path scenario.

---

## WalkingSkeletonTests.swift

Walking skeleton scope: US-01 + US-02 + US-04 + US-11. Thinnest slice proving the core loop.

| # | Scenario | Type | Status |
|---|----------|------|--------|
| WS-01 | Ember's HP is full when a new run begins | Happy path | **ENABLED** |
| WS-02 | Ember has exactly 2 Dash charges when a new run begins | Happy path | disabled |
| WS-03 | Ember's Special charge is 0 when a new run begins | Happy path | disabled |
| WS-04 | Ember does not carry the egg when a new run begins | Happy path | disabled |
| WS-05 | Ember begins on Floor 1 when a new run begins | Happy path | disabled |
| WS-06 | Ember's position advances 3 squares after a successful Dash through a guard | Happy path | disabled |
| WS-07 | Ember's Dash charge count decrements by 1 after a successful Dash | Happy path | disabled |
| WS-08 | The encounter ends after Ember uses Dash | Happy path | disabled |
| WS-09 | Normal movement is unavailable when Ember is in an active encounter | Error/edge | disabled |
| WS-10 | The floor counter increments when Ember steps onto the stairs | Happy path | disabled |
| WS-11 | Ember's position resets to the Floor 2 entry point after descending | Happy path | disabled |
| WS-12 | The death screen appears when Ember's HP drops to 0 | Error/edge | disabled |
| WS-13 | HP display does not show a negative value when damage exceeds remaining HP | Error/edge | disabled |

---

## DashMechanicsTests.swift

Focused scenarios for US-02 Dash mechanics and US-09 boss Dash block.

| # | Scenario | Type | Status |
|---|----------|------|--------|
| DM-01 | Ember passes through the guard's square without stopping when she Dashes | Happy path | disabled |
| DM-02 | Ember uses Dash with exactly 1 charge remaining and it depletes to 0 | Edge | disabled |
| DM-03 | The Dash cooldown timer begins immediately after a Dash is used | Happy path | disabled |
| DM-04 | A Dash charge replenishes after the configured cooldown duration elapses | Happy path | disabled |
| DM-05 | Dash is not selectable when both charges are depleted | Error | disabled |
| DM-06 | Dash charge is not consumed when Dash is attempted with 0 charges | Error | disabled |
| DM-07 | Dash is blocked during the boss encounter | Error | disabled |
| DM-08 | Dash charge is not consumed when Dash is attempted during the boss encounter | Error | disabled |
| DM-09 | Dash blocking is controlled by the boss encounter flag, not by the floor number | Edge | disabled |

---

## CombatTests.swift

Focused scenarios for US-03 (Special), US-05 (Brace), US-09 boss defeat, INT-02.

| # | Scenario | Type | Status |
|---|----------|------|--------|
| CB-01 | A successful Brace parry absorbs all damage; an unbraced hit deals full damage | Happy path | disabled |
| CB-02 | Brace keeps Ember in the encounter — it does not end combat | Happy path | disabled |
| CB-03 | Brace is selectable even when both Dash charges are depleted | Happy path | disabled |
| CB-04 | A successful Brace parry adds the configured Special charge bonus | Happy path | disabled |
| CB-05 | The death condition fires when an unbraced enemy attack drops HP to 0 | Error | disabled |
| CB-06 | Special is not selectable when the charge meter is below full | Error | disabled |
| CB-07 | Special cannot be used at game start because the charge begins at 0 (INT-02) | Error | disabled |
| CB-08 | Ember's Special charge resets to 0 after the Special attack fires | Happy path | disabled |
| CB-09 | The enemy takes significant damage when Ember fires Special | Happy path | disabled |
| CB-10 | After firing Special, the screen mode transitions away from the narrative overlay | Happy path | disabled |
| CB-11 | The boss is defeatable and the path to the exit opens after defeat | Happy path | disabled |
| CB-12 | Special charge increases when time passes during dungeon navigation | Happy path | disabled |
| CB-13 | Special charge cannot reach full in the time available before the first encounter | Property | disabled |

CB-13 is `@property`-shaped — an invariant over all valid charge rates. Crafter may implement as property-based test.

---

## FloorNavigationTests.swift

Focused scenarios for US-04 floor structure, generation constraints, and descent.

| # | Scenario | Type | Status |
|---|----------|------|--------|
| FN-01 | A new run generates between 3 and 5 floors | Happy path | disabled |
| FN-02 | Floor 1 contains no egg room | Error/constraint | disabled |
| FN-03 | Exactly one floor in the range 2 through 4 contains an egg room | Constraint | disabled |
| FN-04 | Floor 5 contains the boss encounter and the exit square | Happy path | disabled |
| FN-05 | Floor 5 contains no egg room | Error/constraint | disabled |
| FN-06 | Each floor has a reachable path from entry to staircase | Constraint | disabled |
| FN-07 | In a 3-floor run, the final floor contains the boss encounter and exit | Edge | disabled |
| FN-08 | In a 3-floor run, the egg room is on Floor 2 | Edge | disabled |
| FN-09 | Ember is placed at the entry point of the new floor after descending | Integration | disabled |

---

## ProgressionTests.swift

Focused scenarios for US-07 (egg discovery), US-08 (upgrades), US-06 (Special meter).

| # | Scenario | Type | Status |
|---|----------|------|--------|
| PR-01 | Entering the egg room triggers the egg discovery narrative event | Happy path | disabled |
| PR-02 | The EGG indicator activates after Ember confirms the egg discovery event | Happy path | disabled |
| PR-03 | The dungeon view resumes immediately after the egg discovery event is confirmed | Happy path | disabled |
| PR-04 | The EGG indicator remains inactive when Ember has not yet entered the egg room | Error | disabled |
| PR-05 | The upgrade prompt shows exactly 3 options at a milestone floor transition | Happy path | disabled |
| PR-06 | Selecting an upgrade applies its effect immediately and resumes the dungeon | Happy path | disabled |
| PR-07 | A Dash cooldown reduction upgrade measurably reduces the cooldown duration | Happy path | disabled |
| PR-08 | A Dash charge cap upgrade increases the maximum number of charges Ember can hold | Happy path | disabled |
| PR-09 | An already-selected upgrade does not appear in a subsequent milestone prompt | Error | disabled |
| PR-10 | The upgrade pool provides at least 3 unique choices | Constraint | disabled |
| PR-11 | The Special charge meter shows a ready state when charge reaches maximum | Happy path | disabled |

---

## WinLossConditionTests.swift

Focused scenarios for US-10 (win), US-11 (death), INT-01 (dual condition), INT-04 (full reset).

| # | Scenario | Type | Status |
|---|----------|------|--------|
| WL-01 | Stepping onto the exit square with the egg fires the exit patio narrative event | Happy path | disabled |
| WL-02 | The win state is declared after Ember confirms the exit patio narrative | Happy path | disabled |
| WL-03 | The win state is not declared when Ember reaches the exit without the egg (INT-01) | Error | disabled |
| WL-04 | Win state is not declared when hasEgg is true but Ember is not at the exit square (INT-01) | Error | disabled |
| WL-05 | The death screen appears when Ember's HP drops to exactly 0 | Happy path | disabled |
| WL-06 | HP is displayed as 0, not a negative number, when a fatal blow is received | Error | disabled |
| WL-07 | Restart from the death screen resets HP, Dash, Special, egg, floor, and upgrades (INT-04) | Error | disabled |
| WL-08 | The Dash cooldown timers are cleared when Ember restarts | Error | disabled |
| WL-09 | Death fires correctly when Ember takes unbraced hits until HP reaches 0 on Floor 1 | Error | disabled |

---

## Property-Shaped Scenarios

These scenarios express universal invariants. The software-crafter should consider implementing them as property-based tests with generators (Swift's `swift-check` or manual random generation):

| Scenario | Invariant | File |
|----------|-----------|------|
| CB-13 | Special charge < 1.0 for any valid initial-time elapsed ≤ 20 seconds | CombatTests |
| WL-03+WL-04 | Win state iff hasEgg == true AND position == exitSquare (never one without the other) | WinLossConditionTests |
| WL-07 | After restart, ALL state variables equal initial values (for any prior run state) | WinLossConditionTests |

---

## Implementation Sequence (one at a time)

Enable in this order to follow the walking skeleton → focused scenario progression:

1. WS-01 (enable now — runs immediately)
2. WS-02 through WS-13 (walking skeleton completion)
3. DM-01 through DM-09 (Dash mechanics)
4. FN-01 through FN-09 (floor structure requires FloorGenerator)
5. CB-01 through CB-12 (combat — requires Brace + Special in RulesEngine)
6. PR-01 through PR-11 (progression — requires UpgradePool)
7. WL-01 through WL-09 (win/loss — requires full state machine)

Each scenario: enable one, run `swift test`, implement the production code that makes it pass, commit, enable the next.
