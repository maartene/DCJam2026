# Definition of Ready Checklist
**Feature**: dcjam2026-core
**Date**: 2026-04-02
**Author**: Luna (Product Owner — DISCUSS wave)

Each user story must pass all 9 DoR items before handoff to the DESIGN wave. This document records the DoR evaluation for each story.

---

## DoR Items (9-Item Gate)

1. Problem statement clear, in domain language
2. User/persona with specific characteristics
3. Three or more domain examples with real data
4. UAT scenarios in Given/When/Then format (3-7 scenarios)
5. Acceptance criteria derived from UAT
6. Right-sized (1-3 days effort, 3-7 UAT scenarios)
7. Technical notes: constraints and dependencies
8. Dependencies resolved or tracked
9. Outcome KPIs defined with measurable targets

---

## US-01: Game Start — UI State Legibility

| # | DoR Item | Evidence | Status |
|---|----------|---------|--------|
| 1 | Problem clear in domain language | "The only tutorial is the UI state" — dragon vocabulary, jam context | PASS |
| 2 | User/persona with specific characteristics | Ember, young dragon, first-time player, game launch context | PASS |
| 3 | Three domain examples with real data | Happy path (Ember reads state), Edge case (restart), Error boundary (non-zero SPEC) | PASS |
| 4 | UAT scenarios 3-7 in Given/When/Then | 3 scenarios | PASS |
| 5 | AC derived from UAT | 6 ACs, each from a scenario | PASS |
| 6 | Right-sized | UI initialization — 0.5 days. 3 scenarios. | PASS |
| 7 | Technical notes | GameState initialization, always-visible overlay, SA-01, SA-03, SA-04 | PASS |
| 8 | Dependencies resolved | Depends on GameState structure — tracked, not blocking | PASS |
| 9 | Outcome KPIs defined | KPI-01 (80%+ first-encounter Dash selection) | PASS |

### Result: PASS (9/9)

---

## US-02: Dash — Pass Through Enemy Square

| # | DoR Item | Evidence | Status |
|---|----------|---------|--------|
| 1 | Problem clear in domain language | "Dash is the primary verb — if it does not work, the game's core identity collapses" | PASS |
| 2 | User/persona with specific characteristics | Ember, dragon, 1+ Dash charge, mid-encounter, not boss | PASS |
| 3 | Three domain examples with real data | Happy path (2 charges, Floor 1), Edge case (1 charge, 12s cooldown), Error boundary (0 charges) | PASS |
| 4 | UAT scenarios 3-7 | 4 scenarios | PASS |
| 5 | AC derived from UAT | 7 ACs | PASS |
| 6 | Right-sized | Core movement mechanic — 1-2 days. 4 scenarios. | PASS |
| 7 | Technical notes | SA-01, SA-02, SA-11, feasibility spike DEC-06 spike 1 flagged | PASS |
| 8 | Dependencies resolved | Grid movement model — feasibility spike pending, flagged | PASS (flagged) |
| 9 | Outcome KPIs | KPI-01, KPI-02 | PASS |

### Result: PASS (9/9) — Spike DEC-06 #1 pending; story is written but implementation must await spike result

---

## US-03: Special Attack — Power Beat

| # | DoR Item | Evidence | Status |
|---|----------|---------|--------|
| 1 | Problem clear in domain language | "The moment must feel earned and spectacular — badass (DEC-03)" | PASS |
| 2 | User/persona | Ember, full Special charge, in encounter | PASS |
| 3 | Three domain examples | Regular guard, boss fight variant, below-full attempt | PASS |
| 4 | UAT scenarios 3-7 | 3 scenarios | PASS |
| 5 | AC derived from UAT | 7 ACs | PASS |
| 6 | Right-sized | Full-screen event + charge system — 1 day. 3 scenarios. | PASS |
| 7 | Technical notes | SA-03, SA-11, feasibility spike DEC-06 spikes 2+3 flagged, fallback specified | PASS |
| 8 | Dependencies | US-06 (charge meter) must exist; feasibility spike 2+3 pending | PASS (flagged) |
| 9 | Outcome KPIs | KPI-03 (100% unprompted mention) | PASS |

### Result: PASS (9/9) — Spikes DEC-06 #2 and #3 pending; fallback design documented

---

## US-04: Floor Structure and Descent

| # | DoR Item | Evidence | Status |
|---|----------|---------|--------|
| 1 | Problem clear | "Without floor structure, there is no dungeon to escape" | PASS |
| 2 | User/persona | Ember, dragon navigating grid dungeon | PASS |
| 3 | Three domain examples | 5-floor descent, 3-floor minimum, generation error boundary | PASS |
| 4 | UAT scenarios 3-7 | 4 scenarios | PASS |
| 5 | AC derived from UAT | 7 ACs | PASS |
| 6 | Right-sized | Grid generation foundation — 1-2 days. 4 scenarios. | PASS |
| 7 | Technical notes | SA-05, SA-08, SA-09, SA-11; 3-floor minimum behavior specified | PASS |
| 8 | Dependencies | No upstream dependencies — this is the foundation | PASS |
| 9 | Outcome KPIs | KPI-08 (100% completability) | PASS |

### Result: PASS (9/9)

---

## US-05: Brace — Defensive Action in Option-Starved Window

| # | DoR Item | Evidence | Status |
|---|----------|---------|--------|
| 1 | Problem clear | "The option-starved window is intentional. Requirements must not eliminate it." | PASS |
| 2 | User/persona | Ember, 0 Dash charges, non-full Special, in encounter | PASS |
| 3 | Three domain examples | Brace once (survives), Brace multiple times (40% HP), Brace at critical HP (dies) | PASS |
| 4 | UAT scenarios 3-7 | 3 scenarios | PASS |
| 5 | AC derived from UAT | 6 ACs | PASS |
| 6 | Right-sized | Single action type — 0.5 days. 3 scenarios. | PASS |
| 7 | Technical notes | SA-01, SA-02, SA-06; damage reduction value is DESIGN wave detail | PASS |
| 8 | Dependencies | Encounter system from US-02 must exist | PASS |
| 9 | Outcome KPIs | KPI-06 (70%+ survive the window) | PASS |

### Result: PASS (9/9)

---

## US-06: Special Charge Meter — Visual Readiness

| # | DoR Item | Evidence | Status |
|---|----------|---------|--------|
| 1 | Problem clear | "If the meter is invisible, the power beat loses its anticipation arc" | PASS |
| 2 | User/persona | Ember, navigating any floor, watching Special charge build | PASS |
| 3 | Three domain examples | 0 → full over two floors, reset after use, too-fast charge rate error | PASS |
| 4 | UAT scenarios 3-7 | 4 scenarios | PASS |
| 5 | AC derived from UAT | 7 ACs | PASS |
| 6 | Right-sized | Status bar component — 0.5 days. 4 scenarios. | PASS |
| 7 | Technical notes | SA-03; charge rate is tuning parameter; calibration constraint noted | PASS |
| 8 | Dependencies | GameState.specialCharge must exist | PASS |
| 9 | Outcome KPIs | KPI-03 (prerequisite), implicit in power beat delivery | PASS |

### Result: PASS (9/9)

---

## US-07: Egg Discovery — Relief Beat

| # | DoR Item | Evidence | Status |
|---|----------|---------|--------|
| 1 | Problem clear | "Without a dedicated beat, the egg is just an item. The emotional weight is lost." | PASS |
| 2 | User/persona | Ember, 1-3 regular floors navigated, enters egg room | PASS |
| 3 | Three domain examples | Floor 2 discovery (early), Floor 4 discovery (late), exit without egg blocked | PASS |
| 4 | UAT scenarios 3-7 | 3 scenarios | PASS |
| 5 | AC derived from UAT | 8 ACs | PASS |
| 6 | Right-sized | Narrative event + placement logic — 1 day. 3 scenarios. | PASS |
| 7 | Technical notes | SA-04, SA-08, SA-05; feasibility spike 2 flagged; fallback specified | PASS |
| 8 | Dependencies | US-04 (floor range 2-4 must exist) | PASS |
| 9 | Outcome KPIs | KPI-04 (100% read full egg text) | PASS |

### Result: PASS (9/9) — Spike DEC-06 #2 pending; fallback documented

---

## US-08: Milestone Upgrade Choice

| # | DoR Item | Evidence | Status |
|---|----------|---------|--------|
| 1 | Problem clear | "Jam requires stat modification. Milestone upgrades are developer's chosen mechanism (DISC-02)." | PASS |
| 2 | User/persona | Ember, just cleared a milestone floor, chooses an upgrade | PASS |
| 3 | Three domain examples | Cooldown reduction (Floor 2), charge cap increase (Floor 3), duplicate prevention (boundary) | PASS |
| 4 | UAT scenarios 3-7 | 4 scenarios | PASS |
| 5 | AC derived from UAT | 9 ACs | PASS |
| 6 | Right-sized | Prompt + pool + effect application — 1 day. 4 scenarios. | PASS |
| 7 | Technical notes | SA-07, SA-10, SA-02; pool design (6-8 entries) is DESIGN wave detail | PASS |
| 8 | Dependencies | US-04 (floor milestones must be defined) | PASS |
| 9 | Outcome KPIs | KPI-07 (jam rule compliance — binary) | PASS |

### Result: PASS (9/9)

---

## US-09: Boss Encounter — Dash Blocked

| # | DoR Item | Evidence | Status |
|---|----------|---------|--------|
| 1 | Problem clear | "Boss is the one encounter that forces engagement. Must be telegraphed as exceptional." | PASS |
| 2 | User/persona | Ember, Floor 5, boss encounter, must fight | PASS |
| 3 | Three domain examples | Special defeats boss, Special depleted (Brace only), Dash blocked attempt | PASS |
| 4 | UAT scenarios 3-7 | 3 scenarios | PASS |
| 5 | AC derived from UAT | 7 ACs | PASS |
| 6 | Right-sized | Boss encounter variant — 0.5 days. 3 scenarios. | PASS |
| 7 | Technical notes | SA-11 (boss flag), SA-01, SA-03; boss HP is DESIGN wave detail | PASS |
| 8 | Dependencies | US-02 (Dash system), US-04 (Floor 5), US-03 (Special) | PASS |
| 9 | Outcome KPIs | KPI (70%+ Floor 5 completion) from KPI-06 extended scope | PASS |

### Result: PASS (9/9)

---

## US-10: Exit Patio — Final Relief Beat

| # | DoR Item | Evidence | Status |
|---|----------|---------|--------|
| 1 | Problem clear | "The exit must feel like earned relief — exhale, not triumph (DEC-03)." | PASS |
| 2 | User/persona | Ember, carrying egg, Floor 5, stepping onto exit square | PASS |
| 3 | Three domain examples | Exit with egg (win), exit without egg (blocked), win state without egg (error boundary) | PASS |
| 4 | UAT scenarios 3-7 | 3 scenarios | PASS |
| 5 | AC derived from UAT | 6 ACs | PASS |
| 6 | Right-sized | Narrative event + win condition — 0.5 days. 3 scenarios. | PASS |
| 7 | Technical notes | SA-04, SA-09, SA-05; dual-condition win check flagged as critical integration | PASS |
| 8 | Dependencies | US-07 (hasEgg state), US-04 (Floor 5 exit position) | PASS |
| 9 | Outcome KPIs | KPI-05 (100% relief-coded debrief), KPI-08 (run completability) | PASS |

### Result: PASS (9/9)

---

## US-11: Death Condition

| # | DoR Item | Evidence | Status |
|---|----------|---------|--------|
| 1 | Problem clear | "The jam requires a death/fail condition. A crash or silent reset is not acceptable." | PASS |
| 2 | User/persona | Ember, HP dropped to 0, any floor, any stage of run | PASS |
| 3 | Three domain examples | Floor 3 option-starved death, Floor 1 before first Dash, exactly-0 HP boundary | PASS |
| 4 | UAT scenarios 3-7 | 3 scenarios | PASS |
| 5 | AC derived from UAT | 6 ACs | PASS |
| 6 | Right-sized | HP check + death screen + restart — 0.5 days. 3 scenarios. | PASS |
| 7 | Technical notes | SA-06; death fires on HP <= 0 (not end of turn); all state resets on restart | PASS |
| 8 | Dependencies | SA-06 (HP state must exist — from US-01) | PASS |
| 9 | Outcome KPIs | KPI-07 (jam rule compliance) | PASS |

### Result: PASS (9/9)

---

## DoR Summary

| Story | Items Passed | Items Failed | Status |
|-------|-------------|-------------|--------|
| US-01: Game Start UI | 9/9 | 0 | PASS |
| US-02: Dash | 9/9 | 0 | PASS (spike flagged) |
| US-03: Special Attack | 9/9 | 0 | PASS (spikes flagged) |
| US-04: Floor Structure | 9/9 | 0 | PASS |
| US-05: Brace | 9/9 | 0 | PASS |
| US-06: Special Meter | 9/9 | 0 | PASS |
| US-07: Egg Discovery | 9/9 | 0 | PASS (spike flagged) |
| US-08: Upgrades | 9/9 | 0 | PASS |
| US-09: Boss | 9/9 | 0 | PASS |
| US-10: Exit Patio | 9/9 | 0 | PASS (spike flagged) |
| US-11: Death | 9/9 | 0 | PASS |

### Gate: PASS — All 11 stories ready for DESIGN wave handoff.

### Pending Spike Confirmations

Three stories have implementation dependency on feasibility spikes from DEC-06. The stories are fully specified; implementation must await spike results.

| Spike | Affects | Fallback |
|-------|---------|---------|
| Grid pass-through movement model | US-02 | Dash = no counter-attack (enemy staggered, no damage) |
| TUI full-screen event interrupt | US-03, US-07, US-10 | Large bordered text box occupying most of screen |
| Special attack visual distinction | US-03 | CAPS + ASCII border on same screen, distinct from combat log |

The fallbacks are acceptable for jam submission. The primary designs are preferred. The DESIGN wave must run these spikes before committing to the primary implementation.
