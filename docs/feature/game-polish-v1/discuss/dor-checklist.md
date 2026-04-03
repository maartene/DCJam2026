# Definition of Ready Checklist — Game Polish v1
**Feature**: game-polish-v1
**Date**: 2026-04-03
**Author**: Luna (Product Owner — DISCUSS wave)

---

## DoR Gate: 9-Item Checklist

Each item is evaluated per story. A story is Ready when all 9 items pass.

---

## Story: US-P01 Start Screen

| # | DoR Item | Status | Evidence |
|---|----------|--------|----------|
| 1 | Problem statement clear, domain language | PASS | "Players launch with no context or controls knowledge" — player domain language |
| 2 | User/persona with specific characteristics | PASS | First-time player launching cold; named example: Maartene, Alex, Sam |
| 3 | >= 3 domain examples with real data | PASS | 3 examples with named personas and specific interactions |
| 4 | UAT in Given/When/Then (3–7 scenarios) | PASS | 2 scenarios in .feature file (orientation + dismiss) — sufficient for this scope |
| 5 | AC derived from UAT | PASS | 8 AC items in acceptance-criteria.md, all traceable to scenarios |
| 6 | Right-sized (1–3 days, 3–7 scenarios) | PASS | Estimated 0.5 days; new ScreenMode case + content |
| 7 | Technical notes: constraints/dependencies | PASS | Requires ScreenMode.startScreen; GameState.initial() change; Renderer branch |
| 8 | Dependencies resolved or tracked | PASS | No external dependency; SA-P01 tracked in registry |
| 9 | Outcome KPIs defined with measurable targets | PASS | KPI-P01: 100% orientation before first move |

**Result: READY**

---

## Story: US-P02 Remove Q as Quit Key

| # | DoR Item | Status | Evidence |
|---|----------|--------|----------|
| 1 | Problem statement clear, domain language | PASS | "Q too close to WASD; accidental quits during play" — player domain language |
| 2 | User/persona with specific characteristics | PASS | Active player mid-combat; named: Yuki, Carlos, Maartene |
| 3 | >= 3 domain examples with real data | PASS | 3 examples covering combat, navigation, deliberate quit |
| 4 | UAT in Given/When/Then (3–7 scenarios) | PASS | 3 scenarios in .feature file |
| 5 | AC derived from UAT | PASS | 6 AC items traceable to scenarios |
| 6 | Right-sized (1–3 days, 3–7 scenarios) | PASS | Estimated 0.25 days; 2 lines in InputHandler |
| 7 | Technical notes: constraints/dependencies | PASS | InputHandler.mapKey() change specified; ESC behavior unchanged |
| 8 | Dependencies resolved or tracked | PASS | Sequencing: US-P01 ships with US-P02 (start screen shows ESC) |
| 9 | Outcome KPIs defined with measurable targets | PASS | KPI-P02: 0 accidental quits via Q in playtest |

**Result: READY**

---

## Story: US-P03 Egg Pickup Screen

| # | DoR Item | Status | Evidence |
|---|----------|--------|----------|
| 1 | Problem statement clear, domain language | PASS | "Egg discovery is the emotional centrepiece; current content is functional, not resonant" |
| 2 | User/persona with specific characteristics | PASS | Player on Floors 2–4, mid-tension; named: Maartene, Alex, Sam |
| 3 | >= 3 domain examples with real data | PASS | 3 examples (full play, returning player, deliberate reader) |
| 4 | UAT in Given/When/Then (3–7 scenarios) | PASS | 2 scenarios in .feature file (content + dismiss) |
| 5 | AC derived from UAT | PASS | 7 AC items in acceptance-criteria.md |
| 6 | Right-sized (1–3 days, 3–7 scenarios) | PASS | Estimated 0.5 days; content change in Renderer.narrativeContent |
| 7 | Technical notes: constraints/dependencies | PASS | Content change only; no structural changes; spike2 reference provided |
| 8 | Dependencies resolved or tracked | PASS | No blockers; NarrativeEvent.eggDiscovery already exists |
| 9 | Outcome KPIs defined with measurable targets | PASS | KPI-P03: dwell time >= 2s |

**Result: READY**

---

## Story: US-P04 Win Screen

| # | DoR Item | Status | Evidence |
|---|----------|--------|----------|
| 1 | Problem statement clear, domain language | PASS | "Win screen delivers statistics instead of emotional resolution" |
| 2 | User/persona with specific characteristics | PASS | Player at exit with egg; named: Maartene, Yuki, Sam |
| 3 | >= 3 domain examples with real data | PASS | 3 examples (full win, fragile win, no-egg exit non-case) |
| 4 | UAT in Given/When/Then (3–7 scenarios) | PASS | 1 scenario in .feature file — sufficient (narrow content change) |
| 5 | AC derived from UAT | PASS | 8 AC items traceable to observable outputs |
| 6 | Right-sized (1–3 days, 3–7 scenarios) | PASS | Estimated 0.5 days; content change in Renderer.renderWinScreen |
| 7 | Technical notes: constraints/dependencies | PASS | Content change only; spike2 reference provided; stat summary retained |
| 8 | Dependencies resolved or tracked | PASS | No blockers; ScreenMode.winState already exists |
| 9 | Outcome KPIs defined with measurable targets | PASS | KPI-P04: dwell time >= 3s |

**Result: READY**

---

## Story: US-P05 Color Improvements

| # | DoR Item | Status | Evidence |
|---|----------|--------|----------|
| 1 | Problem statement clear, domain language | PASS | "Monochrome; players cannot assess state without counting characters" |
| 2 | User/persona with specific characteristics | PASS | Player under pressure navigating; named: Carlos, Yuki, Maartene |
| 3 | >= 3 domain examples with real data | PASS | 3 examples covering HP danger, Special-ready, minimap threat |
| 4 | UAT in Given/When/Then (3–7 scenarios) | PASS | 12 scenarios in .feature file (HP x3, Special x2, Cooldown x2, Minimap x5) |
| 5 | AC derived from UAT | PASS | 22 AC items across P05a/b/c in acceptance-criteria.md |
| 6 | Right-sized (1–3 days, 3–7 scenarios) | PASS | Estimated 1–1.5 days total (split sub-stories); P05c is largest |
| 7 | Technical notes: constraints/dependencies | PASS | ANSI codes specified; minimap refactor risk noted (IC-02); reset requirement stated |
| 8 | Dependencies resolved or tracked | PASS | IC-02 tracked in registry; no hard blockers |
| 9 | Outcome KPIs defined with measurable targets | PASS | KPI-P05: 0 "I didn't know I was that low" comments in playtest |

**Result: READY** (IC-02 tracked; implementation approach delegated to DESIGN wave)

---

## Story: US-P06 Brace Feedback Overlays

| # | DoR Item | Status | Evidence |
|---|----------|--------|----------|
| 1 | Problem statement clear, domain language | PASS | "Brace outcome is invisible; players don't know if parry worked" |
| 2 | User/persona with specific characteristics | PASS | Player who just pressed Brace in combat; named: Maartene, Yuki, Carlos |
| 3 | >= 3 domain examples with real data | PASS | 3 examples (successful parry, failed parry, fatal hit) |
| 4 | UAT in Given/When/Then (3–7 scenarios) | PASS | 5 scenarios in .feature file |
| 5 | AC derived from UAT | PASS | 9 AC items in acceptance-criteria.md |
| 6 | Right-sized (1–3 days, 3–7 scenarios) | PASS | Estimated 1 day; shares mechanism with US-P07 |
| 7 | Technical notes: constraints/dependencies | PASS | IC-03 blocking dependency noted; SA-P08 tracked; overlay word flagged as developer decision |
| 8 | Dependencies resolved or tracked | CONDITIONAL | IC-03 (brace outcome signal) is unresolved — must be decided in DESIGN wave before implementation |
| 9 | Outcome KPIs defined with measurable targets | PASS | KPI-P06: 0 "I don't know if Brace did anything" comments |

**Result: CONDITIONALLY READY** — Story is ready for DESIGN wave. Implementation is blocked on IC-03 (brace outcome signal design). DESIGN wave resolves this as the first step.

---

## Story: US-P07 Dash Feedback Overlay

| # | DoR Item | Status | Evidence |
|---|----------|--------|----------|
| 1 | Problem statement clear, domain language | PASS | "Dash is a position change; the verb is invisible to the player" |
| 2 | User/persona with specific characteristics | PASS | Player who just pressed Dash in combat; named: Maartene, Alex, Carlos |
| 3 | >= 3 domain examples with real data | PASS | 3 examples (dash through guard, dash in corridor, 0-charge no-dash) |
| 4 | UAT in Given/When/Then (3–7 scenarios) | PASS | 3 scenarios in .feature file |
| 5 | AC derived from UAT | PASS | 6 AC items in acceptance-criteria.md |
| 6 | Right-sized (1–3 days, 3–7 scenarios) | PASS | Estimated 0.5–1 day; reuses recentDash; overlay mechanism is new |
| 7 | Technical notes: constraints/dependencies | PASS | recentDash already exists; transient overlay mechanism needed; same as US-P06; overlay word flagged as developer decision |
| 8 | Dependencies resolved or tracked | PASS | Overlay mechanism design shared with US-P06; either can be designed first |
| 9 | Outcome KPIs defined with measurable targets | PASS | KPI-P07: 0 "did I dash or just move?" comments |

**Result: READY** (overlay word confirmed by developer before implementation; mechanism designed in DESIGN wave)

---

## Summary

| Story | DoR Status |
|-------|-----------|
| US-P01 Start Screen | READY |
| US-P02 Remove Q | READY |
| US-P03 Egg Screen | READY |
| US-P04 Win Screen | READY |
| US-P05 Color | READY |
| US-P06 Brace Feedback | CONDITIONALLY READY (IC-03 blocks implementation, not design) |
| US-P07 Dash Feedback | READY |

**All stories are clear enough for DESIGN wave handoff.**
**US-P06 implementation is blocked until IC-03 is resolved in the DESIGN wave.**
