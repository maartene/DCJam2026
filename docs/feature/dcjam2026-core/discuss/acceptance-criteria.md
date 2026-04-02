# Acceptance Criteria — Dragon Escape
**Feature**: dcjam2026-core
**Date**: 2026-04-02
**Author**: Luna (Product Owner — DISCUSS wave)

This document consolidates all acceptance criteria across all user stories in a single reference. Each criterion links to its parent story and the shared artifact it tests.

---

## US-01: Game Start — UI State Legibility

| # | Criterion | Shared Artifact | Status |
|---|-----------|----------------|--------|
| 1.1 | HP bar displays at full on game start | SA-06 | To verify |
| 1.2 | DASH indicator shows exactly 2 charges on game start | SA-01 | To verify |
| 1.3 | SPEC meter shows 0 (empty) on game start — not partial, not full | SA-03 | To verify |
| 1.4 | EGG indicator shows inactive on game start | SA-04 | To verify |
| 1.5 | All five status bar elements are visible simultaneously | — | To verify |
| 1.6 | After restart, all five elements reset to initial values | SA-01, SA-03, SA-04, SA-05, SA-06 | To verify |

---

## US-02: Dash — Pass Through Enemy Square

| # | Criterion | Shared Artifact | Status |
|---|-----------|----------------|--------|
| 2.1 | Dash action passes Ember through enemy square without blocking exchange | SA-01, SA-11 | To verify |
| 2.2 | Ember's position advances exactly 3 squares forward after successful Dash | FloorMap | To verify |
| 2.3 | Dash charge count decrements by 1 on use | SA-01 | To verify |
| 2.4 | Combat log uses dragon vocabulary for Dash text | — | To verify |
| 2.5 | Dash is unavailable (shown but not selectable) when charge count is 0 | SA-01 | To verify |
| 2.6 | Normal movement is locked when adjacent to an enemy | — | To verify |
| 2.7 | The encounter ends after a successful Dash | — | To verify |

---

## US-03: Special Attack — Power Beat

| # | Criterion | Shared Artifact | Status |
|---|-----------|----------------|--------|
| 3.1 | Full-screen or ASCII-bordered visual event fires on Special activation | SA-03 | To verify |
| 3.2 | Special event text uses dragon vocabulary (fire, breath, roar, fang, or claw) | — | To verify |
| 3.3 | Special event is visually distinct from Brace or standard combat text | — | To verify |
| 3.4 | Enemy is defeated or takes significant damage after Special | — | To verify |
| 3.5 | Special charge meter resets to 0 after use | SA-03 | To verify |
| 3.6 | Special is not selectable when charge is below full | SA-03 | To verify |
| 3.7 | Special cannot be activated on the first enemy encounter (charge starts at 0) | SA-03 | To verify |

---

## US-04: Floor Structure and Descent

| # | Criterion | Shared Artifact | Status |
|---|-----------|----------------|--------|
| 4.1 | Game generates between 3 and 5 floors per run | SA-05 | To verify |
| 4.2 | Each floor is navigable (no inescapable dead ends before stairs) | FloorMap | To verify |
| 4.3 | Descending stairs increments floor counter and moves player to next floor entry | SA-05 | To verify |
| 4.4 | Floor 1 contains no egg room | SA-08 | To verify |
| 4.5 | Exactly one floor in range 2–4 contains an egg room | SA-08 | To verify |
| 4.6 | Floor 5 (or final floor in 3-floor run) contains the boss and exit | SA-11, SA-09 | To verify |
| 4.7 | Floor 5 contains no egg room | SA-08 | To verify |

---

## US-05: Brace — Defensive Action in Option-Starved Window

| # | Criterion | Shared Artifact | Status |
|---|-----------|----------------|--------|
| 5.1 | Brace action is always available in encounters | — | To verify |
| 5.2 | Brace reduces incoming damage to less than the unbraced default | SA-06 | To verify |
| 5.3 | Brace combat text uses dragon vocabulary (wings, scales, endure) | — | To verify |
| 5.4 | Dash cooldown indicator is visible during the Brace state | SA-02 | To verify |
| 5.5 | Brace does not end the encounter — Ember remains in encounter after bracing | — | To verify |
| 5.6 | Death condition fires correctly if HP reaches 0 after a Brace | SA-06 | To verify |

---

## US-06: Special Charge Meter — Visual Readiness

| # | Criterion | Shared Artifact | Status |
|---|-----------|----------------|--------|
| 6.1 | SPEC meter is visible in status bar from game start | SA-03 | To verify |
| 6.2 | SPEC meter shows 0 at game start | SA-03 | To verify |
| 6.3 | SPEC meter increases incrementally over time during play | SA-03 | To verify |
| 6.4 | SPEC meter shows a distinct "full / ready" state when max value reached | SA-03 | To verify |
| 6.5 | SPEC meter resets to 0 after Special is used | SA-03 | To verify |
| 6.6 | Special not selectable in action list when SPEC is below full | SA-03 | To verify |
| 6.7 | Special is selectable in action list when SPEC is full | SA-03 | To verify |

---

## US-07: Egg Discovery — Relief Beat

| # | Criterion | Shared Artifact | Status |
|---|-----------|----------------|--------|
| 7.1 | Entering the egg room triggers full-screen or large-text narrative event | SA-08 | To verify |
| 7.2 | Narrative event text is distinct from item pickup or room description text | — | To verify |
| 7.3 | Screen holds until player presses a key | — | To verify |
| 7.4 | EGG indicator activates in status bar after confirmation | SA-04 | To verify |
| 7.5 | Egg room is not on Floor 1 | SA-08, SA-05 | To verify |
| 7.6 | Egg room is not on Floor 5 | SA-08, SA-05 | To verify |
| 7.7 | Egg room appears on exactly one floor in range 2–4 per run | SA-08 | To verify |
| 7.8 | Win condition requires hasEgg == true | SA-04 | To verify |

---

## US-08: Milestone Upgrade Choice

| # | Criterion | Shared Artifact | Status |
|---|-----------|----------------|--------|
| 8.1 | Upgrade prompt fires at defined milestone floors | SA-05 | To verify |
| 8.2 | Prompt displays exactly 3 options drawn from pool of 6–8 | SA-10 | To verify |
| 8.3 | Player selects one option; it applies immediately | SA-07 | To verify |
| 8.4 | Upgrade effect persists for the rest of the run | SA-07 | To verify |
| 8.5 | Upgrade names use dragon-appropriate language | — | To verify |
| 8.6 | Dash cooldown reduction upgrade reduces actual cooldown time | SA-02, SA-07 | To verify |
| 8.7 | Dash charge cap increase raises the cap (visible in status bar) | SA-01, SA-07 | To verify |
| 8.8 | Already-selected upgrades are not offered again in the same run | SA-10, SA-07 | To verify |
| 8.9 | Jam stat-modification rule satisfied by this mechanism | — | To verify |

---

## US-09: Boss Encounter — Dash Blocked

| # | Criterion | Shared Artifact | Status |
|---|-----------|----------------|--------|
| 9.1 | Dash is shown but not selectable during boss encounter | SA-11, SA-01 | To verify |
| 9.2 | A message explains the boss cannot be Dashed through | SA-11 | To verify |
| 9.3 | Dash charge count not decremented on blocked Dash attempt | SA-01 | To verify |
| 9.4 | Boss can be defeated using Brace and Special | SA-03, SA-06 | To verify |
| 9.5 | After boss defeated, exit square becomes reachable | SA-09 | To verify |
| 9.6 | Dash blocking uses SA-11 flag (not floor number as proxy) | SA-11 | To verify |
| 9.7 | Boss is on Floor 5 (or final floor in 3-floor run) | SA-05, SA-11 | To verify |

---

## US-10: Exit Patio — Final Relief Beat

| # | Criterion | Shared Artifact | Status |
|---|-----------|----------------|--------|
| 10.1 | Stepping onto exit square with egg triggers full-screen narrative event | SA-04, SA-09 | To verify |
| 10.2 | Event text references egg, hero, and journey in dragon voice | — | To verify |
| 10.3 | Screen holds until player presses a key | — | To verify |
| 10.4 | Win state declared only when hasEgg == true AND player at exit square | SA-04, SA-09 | To verify |
| 10.5 | Win state is not declared when hasEgg == false, regardless of position | SA-04 | To verify |
| 10.6 | Exit event is visually and narratively distinct from egg discovery event | — | To verify |

---

## US-11: Death Condition

| # | Criterion | Shared Artifact | Status |
|---|-----------|----------------|--------|
| 11.1 | Death condition fires when GameState.hp <= 0 | SA-06 | To verify |
| 11.2 | Death screen displays with dragon-vocabulary text | — | To verify |
| 11.3 | Restart option is presented after death | — | To verify |
| 11.4 | Selecting restart resets all game state to initial values | SA-01 through SA-07 | To verify |
| 11.5 | Death screen is visually distinct from win state | — | To verify |
| 11.6 | HP display does not show negative values | SA-06 | To verify |

---

## US-12: Main Screen Layout — Three-Region TUI

| # | Criterion | Shared Artifact | Status |
|---|-----------|----------------|--------|
| 12.1 | Main screen renders exactly three regions: first-person 3D view, status line, Thoughts panel | SA-13 | To verify |
| 12.2 | Status line is always exactly one line and is never hidden during dungeon navigation | SA-13 | To verify |
| 12.3 | Status line shows keyboard shortcuts `(1)`, `(2)`, `(3)` for Dash, Brace, and Special at all times | SA-13 | To verify |
| 12.4 | Thoughts panel is labeled "Thoughts" and displays at least 3 lines of text area | SA-12, SA-13 | To verify |
| 12.5 | Thoughts panel displays dragon inner-monologue text in dragon voice, not system messages | SA-12 | To verify |
| 12.6 | On dismissal of a full-screen narrative event (egg, special, exit), the three-region layout resumes immediately | SA-13 | To verify |
| 12.7 | The three regions do not overlap at any supported terminal width | SA-13 | To verify |

---

## US-13: Combat Screen — Real-Time, Visually Distinct

| # | Criterion | Shared Artifact | Status |
|---|-----------|----------------|--------|
| 13.1 | Combat screen is visually distinct from the dungeon navigation screen | SA-13 | To verify |
| 13.2 | Combat screen UI communicates real-time action — no turn-based numbered menu with blinking cursor | — | To verify |
| 13.3 | All three actions are visible on the combat screen with keyboard shortcuts: `(1)DASH`, `(2)BRACE`, `(3)SPEC` | SA-01, SA-03 | To verify |
| 13.4 | Dash action is shown as unavailable when charge count is 0 (in real time, without requiring a player action to update) | SA-01 | To verify |
| 13.5 | Special action is shown as unavailable when charge meter is below full (in real time) | SA-03 | To verify |
| 13.6 | Boss encounter Dash blocking (REQ-09) is visible on the combat screen | SA-11 | To verify |
| 13.7 | On return to dungeon navigation after combat, the three-region main layout resumes immediately | SA-13 | To verify |

---

## Critical Integration Acceptance Criteria

These criteria span multiple stories and must be tested holistically:

| # | Criterion | Stories | Risk |
|---|-----------|---------|------|
| INT-01 | Win condition requires BOTH hasEgg == true AND player position == exit square. Neither alone triggers win. | US-07, US-10 | HIGH |
| INT-02 | Special charge is 0 at the moment of first enemy encounter on Floor 1. Charge rate does not allow accumulation in the time between game start and first encounter. | US-01, US-03, US-06 | HIGH |
| INT-03 | Dash charge display in status bar and Dash availability in encounter action list always reflect the same underlying value. No stale reads. | US-01, US-02 | HIGH |
| INT-04 | On restart, ALL state variables reset: hp, dashCharges, dashCooldown, specialCharge, hasEgg, currentFloor, activeUpgrades. No carry-over from previous run. | US-11 | MEDIUM |
