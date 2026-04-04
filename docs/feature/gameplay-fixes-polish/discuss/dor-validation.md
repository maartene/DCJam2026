# Definition of Ready Validation — Gameplay Fixes and Polish

---

## Story: US-GPF-01 — Guard Cleared After Defeat

| DoR Item | Status | Evidence |
|----------|--------|----------|
| Problem statement clear, domain language | PASS | "Guard re-triggers combat after defeat; minimap shows stale G symbol" — domain terms, player impact stated |
| User/persona identified with specific characteristics | PASS | "Ember's player, navigating a cleared corridor after a successful fight" |
| 3+ domain examples with real data | PASS | Kai (standard defeat), Sakura (Special kill), Tomás (Dash bypass — not a clear) |
| UAT scenarios in Given/When/Then (3-7) | PASS | 5 scenarios: cleared minimap, no re-trigger, Dash does not clear, floor reset, boss cleared |
| AC derived from UAT | PASS | 6 AC items, each traceable to a scenario |
| Right-sized (1-3 days, 3-7 scenarios) | PASS | ~1 day effort; 5 scenarios; demonstrable in single session |
| Technical notes identify constraints | PASS | GameState field needed; FloorMap stays immutable; applyMove + minimapChar both must consult cleared set; Dash must NOT set cleared flag |
| Dependencies resolved or tracked | PASS | No external dependencies; DESIGN wave owns field choice |

### DoR Status: PASSED

---

## Story: US-GPF-02 — Head Warden Boss

| DoR Item | Status | Evidence |
|----------|--------|----------|
| Problem statement clear, domain language | PASS | "Cat art contradicts human-antagonist premise; narrative incoherence at climactic moment" |
| User/persona identified with specific characteristics | PASS | "Any player or judge who reaches floor 5; context: climactic final encounter" |
| 3+ domain examples with real data | PASS | Hiroshi (judge, first impression), Emre (reads thoughts during combat), Fatima (minimap symbol check) |
| UAT scenarios in Given/When/Then (3-7) | PASS | 5 scenarios: HUD name, art constraints, thought text, guard unaffected, minimap unchanged |
| AC derived from UAT | PASS | 5 AC items, each traceable to a scenario |
| Right-sized (1-3 days, 3-7 scenarios) | PASS | ~1 day effort; 5 scenarios; demonstrable immediately |
| Technical notes identify constraints | PASS | Changes confined to Renderer.swift; ~15-20 lines; no domain model changes; DEC-04 applies to thought text |
| Dependencies resolved or tracked | PASS | No external dependencies; independent of US-GPF-01 and US-GPF-03 |

### DoR Status: PASSED

---

## Story: US-GPF-03 — Minimap Legend

| DoR Item | Status | Evidence |
|----------|--------|----------|
| Problem statement clear, domain language | PASS | "Minimap symbols are unlegended; players cannot decode guard/egg/exit symbols without trial and error" |
| User/persona identified with specific characteristics | PASS | "First-time player or jam judge; context: any dungeon floor in navigation mode" |
| 3+ domain examples with real data | PASS | Hiroshi (floor 1, identifies guard), Sakura (floor 2, egg room), Tomás (floor 5, exit symbol) |
| UAT scenarios in Given/When/Then (3-7) | PASS | 5 scenarios: legend present, colours match, row 17 safe, absent in combat, readable with all symbols |
| AC derived from UAT | PASS | 6 AC items, each traceable to a scenario |
| Right-sized (1-3 days, 3-7 scenarios) | PASS | ~0.5 day effort; 5 scenarios; demonstrable immediately |
| Technical notes identify constraints | PASS | Rows 9-16 cols 61-79; dungeon mode only; reuse existing ANSIColors constants; ~20-30 lines |
| Dependencies resolved or tracked | PASS | No external dependencies; independent of US-GPF-01 and US-GPF-02 |

### DoR Status: PASSED

---

## Overall Feature DoR: ALL 3 STORIES PASSED
