# Handoff Summary — DESIGN Wave
**Feature**: dcjam2026-core
**From**: Luna (Product Owner — DISCUSS wave)
**To**: Solution Architect (DESIGN wave)
**Date**: 2026-04-02
**Gate status**: DoR PASS (11/11 stories) | All DISCUSS phase artifacts complete

---

## What This Document Is

A navigation guide to the DISCUSS wave artifacts. Every design decision made in this wave is documented and traceable. The DESIGN wave should read this first, then the artifacts in the order listed below.

---

## What Is Settled (Do Not Reopen Without Developer Confirmation)

### Core mechanic — Dash
- Dash passes the player through enemy-occupied squares without a blocking encounter.
- Dash exits the encounter AND advances the player 3 squares forward. It is a forward-movement mechanic, not an escape.
- 2 charges at game start. Each replenishes on ~45s cooldown (configurable).
- Normal step movement is locked when adjacent to an enemy. Dash is the only way to move forward.
- Source: DEC-01, DEC-08, DISC-03

### Action set — Brace + Dash + Special only
- No slash or melee attack in this release.
- The option-starved window (0 Dash charges + uncharged Special = Brace only) is intentional design tension.
- If playtesting proves the window feels oppressive, a melee attack is the named fallback — not in scope now.
- Source: DISC-01

### Special attack
- Available from game start, charge meter starts at 0.
- Charge rate calibrated so Special cannot be used at first encounter.
- When fired: full-screen or ASCII-bordered event with dragon vocabulary.
- Source: DEC-03, DEC-10

### Floor structure
- Minimum 3 floors, target 5.
- Floor 1: starter. Floors 2–4: regular (egg on one). Floor 5: boss + exit patio.
- Source: DEC-11

### Stat modification — Milestone upgrade choices
- Pool of 6–8 upgrades. Player sees 3 at each milestone, picks 1.
- Primary levers: Dash cooldown reduction, Dash charge cap increase.
- Source: DISC-02, DEC-08

### Emotional beats — Two distinct designs required
- Special attack: power fantasy / "badass." Full-screen or framed event.
- Egg discovery: actual relief. Full-screen event, hold for player input. Not an item pickup.
- Exit patio: earned relief. Full-screen event, hold for player input. Slow pacing. Not triumph.
- All three must be designed differently from each other and from normal combat text.
- Source: DEC-03

### Dragon vocabulary throughout
- All combat, movement, and narrative strings: dragon vocabulary. No generic dungeon-hero language.
- Source: DEC-04

---

## Three Feasibility Spikes (DESIGN Wave Must Run First)

The DESIGN wave must run these three spikes before committing to primary implementation. Fallback designs are specified for each.

| Spike | Question | Fallback |
|-------|---------|---------|
| Spike 1 | Can the grid movement model support pass-through (Dash) as a distinct mode from normal movement? | Dash = enemy staggered, no counter-attack; player advances normally |
| Spike 2 | Can the TUI layer interrupt dungeon rendering for a full-screen narrative event? | Large bordered text box occupying most of the terminal; dungeon behind it |
| Spike 3 | Can the special attack render visually distinct from normal combat in a terminal environment? | CAPS text + ASCII border on the same screen, separate from combat log |

Source: DEC-06

---

## Artifacts — Full Reference

All artifacts are in `docs/feature/dcjam2026-core/discuss/`:

| File | Contents |
|------|----------|
| `wave-decisions.md` | All DISCUSS-wave decisions including three resolved open questions (DISC-01, DISC-02, DISC-03) |
| `journey-dragon-escape-visual.md` | ASCII journey map, emotional arc, TUI mockups, integration checkpoints |
| `journey-dragon-escape.yaml` | Structured journey schema with steps, shared artifacts, floor structure |
| `journey-dragon-escape.feature` | Gherkin scenarios per journey step (happy path + edge cases) |
| `shared-artifacts-registry.md` | All 11 shared data artifacts with source of truth, read/write owners, integration risks |
| `story-map.md` | Backbone + walking skeleton + 4 release slices. Scope assessment: PASS. |
| `prioritization.md` | Story priority table, jam compliance map, dependency graph, cut sequence |
| `requirements.md` | 11 requirements traced to decisions; dependency matrix |
| `user-stories.md` | 11 user stories in LeanUX template; Ember persona; domain examples; UAT; KPIs |
| `acceptance-criteria.md` | All AC consolidated by story; critical integration criteria |
| `dor-checklist.md` | 9-item DoR evaluated for all 11 stories — all PASS |
| `outcome-kpis.md` | 9 KPIs with targets and measurement methods |

---

## Walking Skeleton (DESIGN wave starting point)

The thinnest end-to-end slice that proves the core loop:

> Player spawns on Floor 1 → encounters one enemy → uses Dash to pass through → reaches stairs → descends → (floors 2+ are empty corridors) → reaches exit → game ends.

Stories: US-01, US-02, US-04, US-11.

This is the first thing to make work. Everything else layers on top.

---

## Release Sequence

| Slice | Outcome | Stories | Estimated Day |
|-------|---------|---------|---------------|
| Slice 0 | Walking skeleton playable | US-01, US-02, US-04, US-11 | Day 1 |
| Slice 1 | Full run completable (start to win state) | US-05, US-06, US-07, US-10 | Day 2 |
| Slice 2 | Full feature set (all jam rules met) | US-03, US-08, US-09 | Day 3 |
| Slice 3 | Polish, tuning, vocabulary pass | — | Day 4 (if time) |

---

## Three Constraints to Enforce in DESIGN Wave

1. **No timers as default mechanics.** Dash cooldown is a readiness state — the player is not racing it. Any countdown mechanic in the default game violates DEC-02.
2. **Dash is always nearly available.** 2 charges + ~45s cooldown = persistent availability. Designs that make Dash feel scarce or locked violate DEC-01 and DEC-08.
3. **Jam scope only.** Every design choice must be necessary for a submittable entry. DEC-12 is a hard filter against scope creep.

---

## What Is Out of Scope

| Feature | Source |
|---------|--------|
| Melee/slash attack | DISC-01 — post-jam fallback only |
| Floor-based Pomander bonuses | DISC-02 — possible supplement, not in scope |
| Food as stat system | DEC-02 |
| Egg-cooking countdown | DEC-02 |
| Elemental RPS | DEC-09 |
| Free repositioning in combat | DISC-03 |
| Post-jam expansion features | DEC-12 |
| Tutorial text | DEC-10 |

---

## Handoff Gate

**Gate: PASS.**

All 11 user stories pass the 9-item Definition of Ready. All journey artifacts are produced. Shared artifacts registry is complete. Story map has walking skeleton and 3 delivery slices. Outcome KPIs are defined with measurable targets.

The DESIGN wave may begin immediately on Slice 0 stories. Spike-dependent stories (US-02, US-03, US-07, US-10) should be implemented after spike results are confirmed — or with fallback implementations as specified.
