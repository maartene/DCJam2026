# Definition of Ready Checklist — handcrafted-maps

**Feature**: handcrafted-maps
**Date**: 2026-04-04
**Wave**: DISCUSS → DESIGN handoff gate

Each item is evaluated per story. All 9 items must pass before handoff to solution-architect.

---

## US-HM-01: FloorDefinition data type

| # | DoR Item | Status | Evidence |
|---|----------|--------|----------|
| 1 | Problem statement clear, domain language | PASS | "No way to express a floor layout as static data" — domain terms only, no technical prescription |
| 2 | User/persona with specific characteristics | PASS | Maartene, solo developer, Swift 6.3, jam deadline |
| 3 | ≥3 domain examples with real data | PASS | L-shape floor 1, T-junction floor 3, boss antechamber floor 5 — all with concrete Position values |
| 4 | UAT in Given/When/Then (3-7 scenarios) | PASS | 3 scenarios in user-stories.md; formalized in acceptance-criteria.md AC-HM-01-A/B |
| 5 | AC derived from UAT | PASS | AC-HM-01-A holds grid dimensions; AC-HM-01-B validates row-major layout |
| 6 | Right-sized (1-3 days, 3-7 scenarios) | PASS | ~0.5 day — pure struct definition; 3 UAT scenarios |
| 7 | Technical notes: constraints/dependencies | PASS | Sendable conformance; GameDomain module; zero imports; pure data |
| 8 | Dependencies resolved or tracked | PASS | No dependencies — this story is a prerequisite for US-HM-02 |
| 9 | Outcome KPIs defined | PASS | KPI-HM-05 (developer authoring effort) |

**RESULT: PASS**

---

## US-HM-02: FloorRegistry replaces FloorGenerator

| # | DoR Item | Status | Evidence |
|---|----------|--------|----------|
| 1 | Problem statement clear, domain language | PASS | "Every call returns the same L-shape regardless of floor number" |
| 2 | User/persona with specific characteristics | PASS | Maartene (developer) + game engine (RulesEngine, Renderer) |
| 3 | ≥3 domain examples with real data | PASS | Floor 1 regression, floor 2 egg room, floor 5 boss+exit, RulesEngine movement on floor 2 |
| 4 | UAT in Given/When/Then (3-7 scenarios) | PASS | 5 scenarios; AC-HM-02-A through D |
| 5 | AC derived from UAT | PASS | Each AC maps to a UAT scenario |
| 6 | Right-sized (1-3 days, 3-7 scenarios) | PASS | ~1 day — call site substitution + new type; 5 scenarios |
| 7 | Technical notes: constraints/dependencies | PASS | Stateless enum, Sendable, GameDomain only, FloorGenerator retained |
| 8 | Dependencies resolved or tracked | PASS | Depends on US-HM-01 (FloorDefinition). AC-HM-02-D noted as sketch pending floor 2 topology. |
| 9 | Outcome KPIs defined | PASS | KPI-HM-03 (regression-free), KPI-HM-04 (landmark correctness) |

**RESULT: PASS**

*Note: AC-HM-02-D is a sketch scenario. The full test body is authored in DELIVER wave once floor 2's topology is known. This does not block handoff — the scenario intent is clear and the test structure is defined.*

---

## US-HM-03: Floor label in top border

| # | DoR Item | Status | Evidence |
|---|----------|--------|----------|
| 1 | Problem statement clear, domain language | PASS | "Label at row 2 overwrites the top row of the minimap" — observable, domain-language |
| 2 | User/persona with specific characteristics | PASS | Rowan (player, navigator) + Maartene (developer) |
| 3 | ≥3 domain examples with real data | PASS | Floor 1/5 label, Floor 5/5 label, combat screen no-label |
| 4 | UAT in Given/When/Then (3-7 scenarios) | PASS | 3 scenarios: label in row 1, absent from row 2, absent in combat |
| 5 | AC derived from UAT | PASS | AC-HM-03-A/B/C map to the 3 UAT scenarios |
| 6 | Right-sized (1-3 days, 3-7 scenarios) | PASS | ~0.5 day — single rendering change; 3 scenarios |
| 7 | Technical notes: constraints/dependencies | PASS | drawChrome needs screen-mode awareness; one approach noted; DESIGN decides |
| 8 | Dependencies resolved or tracked | PASS | Independent story; can be developed in parallel with US-HM-01/02 |
| 9 | Outcome KPIs defined | PASS | KPI-HM-02 (row 2 availability) |

**RESULT: PASS**

---

## US-HM-04: Minimap renders dynamic-sized floors

| # | DoR Item | Status | Evidence |
|---|----------|--------|----------|
| 1 | Problem statement clear, domain language | PASS | "Test helpers hardcode height=7; wrong row assertions for taller floors" |
| 2 | User/persona with specific characteristics | PASS | Maartene (test maintainability) + Rowan (correct minimap) |
| 3 | ≥3 domain examples with real data | PASS | Floor 1 (15×7, row 8), Floor 3 (19×10, row 11), Floor 5 (13×8, row 9) |
| 4 | UAT in Given/When/Then (3-7 scenarios) | PASS | 3 scenarios: floor 1 position, height-10 position, no overflow col 79 |
| 5 | AC derived from UAT | PASS | AC-HM-04-A/B/C |
| 6 | Right-sized (1-3 days, 3-7 scenarios) | PASS | ~0.5 day — test helper updates + verify loop; 3 scenarios |
| 7 | Technical notes: constraints/dependencies | PASS | Renderer loop already correct; test helper updates noted; legend overlap constraint documented |
| 8 | Dependencies resolved or tracked | PASS | Depends on US-HM-02 (floors with varying sizes must exist before this is meaningful) |
| 9 | Outcome KPIs defined | PASS | KPI-HM-04 (landmark correctness covers position accuracy) |

**RESULT: PASS**

---

## US-HM-05: Five distinct handcrafted floor layouts

| # | DoR Item | Status | Evidence |
|---|----------|--------|----------|
| 1 | Problem statement clear, domain language | PASS | "All 5 floors look identical — no sense of progress or place" — Rowan's experience |
| 2 | User/persona with specific characteristics | PASS | Rowan, jam player/judge, 15 minutes in |
| 3 | ≥3 domain examples with real data | PASS | Floor 2 T-junction with egg on west branch, Floor 4 room-and-hall, Floor 5 boss antechamber |
| 4 | UAT in Given/When/Then (3-7 scenarios) | PASS | 5 scenarios: distinct topology, egg rooms 2-4, floor 5 boss+exit, passable landmarks, size constraints |
| 5 | AC derived from UAT | PASS | AC-HM-05-A/B/C/D map to all 5 UAT scenarios |
| 6 | Right-sized (1-3 days, 3-7 scenarios) | PASS | ~1.5 days — authoring 5 `[String]` character grids; 5 scenarios |
| 7 | Technical notes: constraints/dependencies | PASS | Pure Swift literals, no external data, floor 1 must match FloorGenerator exactly |
| 8 | Dependencies resolved or tracked | PASS | Depends on US-HM-02 (FloorRegistry must exist); floor 2-5 exact topologies are DESIGN wave deliverable |
| 9 | Outcome KPIs defined | PASS | KPI-HM-01 (topology distinctness) |

**RESULT: PASS**

*Note: The exact `[String]` character grids for floors 2-5 are authored in the DESIGN wave. Requirements specify the shape concepts (T-junction, zigzag, room-and-hall, boss antechamber) and all constraints. DoR is met because the acceptance criteria and constraints are fully defined.*

---

## Overall Handoff Gate

| Story | DoR Result |
|-------|-----------|
| US-HM-01 | PASS |
| US-HM-02 | PASS |
| US-HM-03 | PASS |
| US-HM-04 | PASS |
| US-HM-05 | PASS |

### HANDOFF STATUS: APPROVED

All 5 stories pass all 9 DoR items. The feature is ready for handoff to solution-architect (DESIGN wave).

**Open items for DESIGN wave** (non-blocking):
1. Exact `[String]` character grids for floors 2-5 — shape concepts defined in requirements; implementation is DESIGN/DELIVER
2. Legend overlap handling for taller floors (REQ-HM-04 constraint documented; resolution is DESIGN decision)
3. `drawChrome` refactor approach for screen-mode-aware top border (Technical Notes in US-HM-03; approach is DESIGN decision)
4. Full body of AC-HM-02-D — requires floor 2 topology to be known
