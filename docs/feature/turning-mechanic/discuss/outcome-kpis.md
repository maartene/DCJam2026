# Outcome KPIs: Turning Mechanic

## Feature: turning-mechanic

### Objective

By jam submission, Ember can orient in four cardinal directions and navigate relative to facing, satisfying DCJam 2026 rules and never feeling lost in the dungeon.

---

### Outcome KPIs

| # | Who | Does What | By How Much | Baseline | Measured By | Type |
|---|-----|-----------|-------------|----------|-------------|------|
| KPI-1 | DCJam 2026 judges | Verify 90-degree turning in four cardinal directions, keyboard-invoked | 100% of judge checks pass (binary) | 0 — feature does not exist | Manual jam submission review | Lagging (compliance gate) |
| KPI-2 | Ember (the player / developer during playtesting) | Identifies current facing direction without counting steps or guessing | Correct facing identified in ≤2 seconds of looking at minimap | No minimap facing indicator exists | Informal playtesting observation during development | Leading |
| KPI-3 | Ember (player) | Reaches target room (egg room, staircase, or exit) on a known floor without backtracking past entry | 0 accidental U-turns on a floor the player has already mapped | Not tracked currently | Manual playtest: count direction reversals on known floors | Leading |

---

### Metric Hierarchy

- **North Star**: KPI-1 — jam compliance (binary gate; without it the entry is disqualified)
- **Leading Indicators**: KPI-2 (orientation speed from minimap) and KPI-3 (navigation efficiency)
- **Guardrail Metrics**: Existing movement behaviour must not regress — `move(.forward)` must still advance `playerPosition` correctly for all prior test cases

---

### Measurement Plan

| KPI | Data Source | Collection Method | Frequency | Owner |
|-----|------------|-------------------|-----------|-------|
| KPI-1 | Jam rules checklist + unit tests | Unit tests assert turn in all 4 directions, keyboard-invoked | Every build (CI) | Developer |
| KPI-2 | Developer playtesting | Manual — time how long it takes to state "I'm facing West" after a turn | Each playtest session (informal) | Developer |
| KPI-3 | Developer playtesting | Manual — count backtrack events on a floor already navigated | Each playtest session (informal) | Developer |
| Guardrail | Existing unit tests | All existing move/position tests remain green | Every build (CI) | Developer |

---

### Hypothesis

We believe that adding `GameState.facingDirection` with minimap caret display for Ember (the player) will achieve jam compliance (KPI-1) and reduce disorientation (KPI-2).

We will know this is true when:
- All four 90-degree turn directions are keyboard-invokable and unit-tested (KPI-1)
- The developer can state their facing direction within 2 seconds of glancing at the minimap during playtesting (KPI-2)
- No accidental U-turns occur on a floor the developer has already explored (KPI-3)

---

### Notes

This is a jam project with a single developer. "Measured by" is lightweight — unit tests for correctness, informal playtesting for UX quality. No analytics infrastructure is needed or appropriate.

KPI-1 is the only hard gate. KPI-2 and KPI-3 are design quality signals that inform whether the minimap rendering is effective.
