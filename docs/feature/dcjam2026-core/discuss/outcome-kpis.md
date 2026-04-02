# Outcome KPIs — Dragon Escape
**Feature**: dcjam2026-core
**Date**: 2026-04-02
**Author**: Luna (Product Owner — DISCUSS wave)

KPIs are organized by the behavior change they measure. In a jam context, measurement is primarily playtester observation and post-session debrief. Quantitative targets reflect the minimum quality bar for jam submission confidence.

---

## KPI-01: Organic Dash Teaching

**Story**: US-01, US-02
**Traces to**: DEC-10

- **Who**: Players experiencing their first enemy encounter
- **Does what**: Select Dash without reading a tutorial or being prompted
- **By how much**: 80%+ of first-encounter actions across playtesters are Dash (not Brace or Special)
- **Measured by**: Playtester observation — note first action taken on first encounter
- **Baseline**: Without the empty-Special / ready-Dash UI contrast, first-encounter action is random (~33% Dash if three equal options)
- **Target rationale**: A hit rate above 80% confirms the mechanical state is teaching the mechanic. Below 50% means the UI is failing.

---

## KPI-02: Dash as Primary Encounter Verb (Not Last Resort)

**Story**: US-02
**Traces to**: DEC-01

- **Who**: Players across all regular floor encounters in a full run
- **Does what**: Choose Dash as their encounter resolution over Brace
- **By how much**: Dash used in >60% of non-boss encounters per run
- **Measured by**: Playtester observation — count Dash vs Brace vs Special per run
- **Baseline**: Standard dungeon crawlers: 0% evasion (all encounters are combat)
- **Target rationale**: If players Brace more than they Dash, Dash is functioning as a fallback, not the primary verb. The design has failed its core intent.

---

## KPI-03: Power Beat Recognition (Special Attack)

**Story**: US-03
**Traces to**: DEC-03

- **Who**: Players who successfully use the Special for the first time
- **Does what**: Describe the moment as "powerful," "satisfying," or "cool" in post-session debrief
- **By how much**: 100% of playtesters who use Special mention it unprompted in debrief
- **Measured by**: Post-session verbal debrief — open question: "Was there a moment that stood out?"
- **Baseline**: Without distinct Special feedback, the moment is a combat resolution like any other
- **Target rationale**: The developer's design intent is "badass." If no one mentions it, the moment has not landed.

---

## KPI-04: Egg Discovery as Emotional Beat (Not Item Pickup)

**Story**: US-07
**Traces to**: DEC-03

- **Who**: Players who reach the egg room
- **Does what**: Pause and read the full egg discovery text before pressing to continue
- **By how much**: 100% of playtesters read the full egg discovery text (no immediate button-press skip)
- **Measured by**: Playtester observation — note pause duration on egg discovery event
- **Baseline**: Without the hold-to-continue design, players skip narrative events immediately
- **Target rationale**: The event only delivers its relief if the player actually reads it. A mandatory pause enforces this; 100% is achievable by design.

---

## KPI-05: Exit Relief Beat Recognition

**Story**: US-10
**Traces to**: DEC-03

- **Who**: Players who complete a full run to the exit
- **Does what**: Describe the ending as "relief," "earned," or "satisfying" (as opposed to "triumphant" or "abrupt")
- **By how much**: 100% of players who complete a run describe the ending with a relief-coded word in debrief
- **Measured by**: Post-session open question: "How did the ending feel?" — code response as relief / triumph / neutral / flat
- **Baseline**: Standard dungeon crawler exit: "Level complete" flash. Typically coded as "neutral" or "abrupt" in player feedback.
- **Target rationale**: The developer explicitly wants "actual relief" (DEC-03). If players say "triumphant" or "fine," the design has missed. If they say "exhale" or "finally," it has landed.

---

## KPI-06: Option-Starved Window Survivability

**Story**: US-05
**Traces to**: DISC-01

- **Who**: Players who enter the option-starved window (both Dash charges depleted, Special not full)
- **Does what**: Continue the run after the window rather than abandon
- **By how much**: 70%+ of players who enter the option-starved window survive it and continue
- **Measured by**: Playtester observation — track if option-starved window leads to death or continuation
- **Baseline**: If Brace does not reduce damage meaningfully, the window is a near-death trap and run abandonment will be high
- **Target rationale**: The window is intentional tension, not a punishment zone. If it kills >30% of players who enter it, the Brace damage reduction needs tuning.

---

## KPI-07: Jam Rule Compliance (Binary)

**Story**: US-08, US-11, US-04
**Traces to**: DEC-12

- **Who**: Developer (jam submission)
- **Does what**: Submit a game that passes all jam rule checks
- **By how much**: 100% — all jam rules satisfied
- **Measured by**: Jam rule checklist reviewed by developer before submission
- **Baseline**: Without US-08 (stat modification) and US-11 (death), two jam rules are violated
- **Target rationale**: Jam rules are non-negotiable. Binary pass/fail.

---

## KPI-08: Run Completability

**Story**: US-04, US-10
**Traces to**: DEC-12

- **Who**: Developer during jam playtesting
- **Does what**: Complete a full run from Floor 1 to exit patio win state
- **By how much**: 100% — at least one complete run demonstrable before submission
- **Measured by**: Developer playtesting
- **Baseline**: Without completable run, the game cannot be submitted
- **Target rationale**: A game that cannot be completed from start to win state is not a jam entry.

---

## KPI-09: Dragon Identity Immersion (Vocabulary)

**Story**: All stories (DEC-04 pervasive)
**Traces to**: DEC-04

- **Who**: Players across a full run
- **Does what**: Use dragon vocabulary in post-session feedback unprompted ("I surged past," "the scales," "fire")
- **By how much**: At least 1 playtester per session uses dragon vocabulary in debrief without being prompted
- **Measured by**: Post-session debrief — note if dragon vocabulary appears in player language
- **Baseline**: In a generic dungeon crawler, players say "I attacked" or "I fought." In this game, they should say "I dashed through" or "I breathed fire."
- **Target rationale**: If players absorb dragon vocabulary, the identity layer is working. If they revert to generic language, the text strings have not differentiated the experience.

---

## KPI Summary Table

| KPI | Story | Target | Measurement | Priority |
|-----|-------|--------|-------------|----------|
| KPI-01: Organic Dash teaching | US-01, US-02 | 80%+ first Dash on encounter 1 | Observation | Critical |
| KPI-02: Dash as primary verb | US-02 | >60% Dash in non-boss encounters | Observation | Critical |
| KPI-03: Power beat recognition | US-03 | 100% mention Special unprompted | Debrief | High |
| KPI-04: Egg as emotional beat | US-07 | 100% read full egg text | Observation | High |
| KPI-05: Exit relief beat | US-10 | 100% relief-coded debrief | Debrief | High |
| KPI-06: Option-starved survivability | US-05 | 70%+ survive the window | Observation | Medium |
| KPI-07: Jam compliance | US-08, US-11 | 100% rules satisfied | Checklist | Critical |
| KPI-08: Run completability | US-04, US-10 | 100% at least one complete run | Developer test | Critical |
| KPI-09: Dragon vocabulary absorption | All | 1+ player uses dragon words unprompted | Debrief | Medium |
