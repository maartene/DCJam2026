# Definition of Ready Checklist: Turning Mechanic

Validated against all 9 DoR items. Each story must pass before handoff to DESIGN wave.

---

## US-TM-01: CardinalDirection Domain Type

| DoR Item | Status | Evidence |
|----------|--------|----------|
| Problem statement clear, domain language | PASS | "Without a facing direction type, the game cannot represent which way Ember is looking" |
| User/persona with specific characteristics | PASS | Ember — young dragon navigating dungeon corridors; developer as proxy player |
| 3+ domain examples with real data | PASS | New game (North default), staircase transition (East persists), restart (resets to North) |
| UAT in Given/When/Then (3-7 scenarios) | PASS | 3 scenarios covering initial state, updater, and full enum |
| AC derived from UAT | PASS | 5 AC items all trace to UAT scenarios |
| Right-sized (1-3 days, 3-7 scenarios) | PASS | 0.5 days; pure type definition; 3 scenarios |
| Technical notes: constraints/dependencies | PASS | GameDomain isolation rule, Sendable conformance, no reference types |
| Dependencies resolved or tracked | PASS | None — first story in chain |
| Outcome KPIs defined | PASS | KPI-1 jam compliance, KPI-2 orientation |

### DoR Status: PASSED

---

## US-TM-02: RulesEngine Turn Command

| DoR Item | Status | Evidence |
|----------|--------|----------|
| Problem statement clear, domain language | PASS | "Without a turn command, pressing A/D has no effect and the jam rule is unmet" |
| User/persona with specific characteristics | PASS | Ember mid-navigation, wanting to face a new direction |
| 3+ domain examples with real data | PASS | North→West (turn left), West→North (turn right), four turns return to original |
| UAT in Given/When/Then (3-7 scenarios) | PASS | 4 scenarios covering left, right, full table, and no-cost |
| AC derived from UAT | PASS | 5 AC items; rotation table and no-cost both covered |
| Right-sized (1-3 days, 3-7 scenarios) | PASS | 0.5 days; one pure function + enum case; 4 scenarios |
| Technical notes: constraints/dependencies | PASS | Rotation table single-definition rule, Sendable, combat mode unconditional |
| Dependencies resolved or tracked | PASS | Depends on US-TM-01 (first in chain) |
| Outcome KPIs defined | PASS | KPI-1 jam compliance |

### DoR Status: PASSED

---

## US-TM-03: Facing-Relative Movement Delta

| DoR Item | Status | Evidence |
|----------|--------|----------|
| Problem statement clear, domain language | PASS | "Forward must mean in the direction I am facing; current hardcoded +1 is wrong after turning" |
| User/persona with specific characteristics | PASS | Ember after turning to face South, expecting W to move toward entry |
| 3+ domain examples with real data | PASS | Forward-North (pos 3→4), forward-South (pos 3→2), backward-West (pos 3→4) |
| UAT in Given/When/Then (3-7 scenarios) | PASS | 6 scenarios covering all 4 facings + backward + boundary clamp |
| AC derived from UAT | PASS | 8 AC items; delta table, clamp, and existing rules all covered |
| Right-sized (1-3 days, 3-7 scenarios) | PASS | 1 day; modify one RulesEngine function; 6 scenarios |
| Technical notes: constraints/dependencies | PASS | 1D map note, delta must not be hardcoded, existing rules preserved |
| Dependencies resolved or tracked | PASS | Depends on US-TM-01, US-TM-02 |
| Outcome KPIs defined | PASS | KPI-1 jam compliance, guardrail (no movement regression) |

### DoR Status: PASSED

---

## US-TM-04: Minimap Facing Indicator

| DoR Item | Status | Evidence |
|----------|--------|----------|
| Problem statement clear, domain language | PASS | "Without a facing indicator, player must mentally track orientation — error-prone and frustrating" |
| User/persona with specific characteristics | PASS | Ember at any moment during exploration, needing immediate facing confirmation |
| 3+ domain examples with real data | PASS | Floor 2 pos 4 facing North (○^), after turn West (○<), floor 3 past egg facing East (○>) |
| UAT in Given/When/Then (3-7 scenarios) | PASS | 4 scenarios: all 4 carets, Facing label, same-frame update, landmark override |
| AC derived from UAT | PASS | 7 AC items; all 4 carets, label, override, width constraint |
| Right-sized (1-3 days, 3-7 scenarios) | PASS | 0.5 days; modify one Renderer function; 4 scenarios |
| Technical notes: constraints/dependencies | PASS | No cached copy, 2-char marker, 78-char width constraint |
| Dependencies resolved or tracked | PASS | Depends on US-TM-01 (facingDirection field) |
| Outcome KPIs defined | PASS | KPI-2 orientation speed |

### DoR Status: PASSED

---

## US-TM-05: Turn Key Bindings

| DoR Item | Status | Evidence |
|----------|--------|----------|
| Problem statement clear, domain language | PASS | "Without bindings, the feature is invisible to the player and the jam rule is unmet" |
| User/persona with specific characteristics | PASS | Ember at keyboard during dungeon exploration |
| 3+ domain examples with real data | PASS | A key (0x61→turn left), Arrow Right escape sequence, D then A rapid-press |
| UAT in Given/When/Then (3-7 scenarios) | PASS | 5 scenarios: a, A, d, D, Arrow Left, Arrow Right, controls hint |
| AC derived from UAT | PASS | 8 AC items; all 4 keys × 2 cases + unchanged existing + controls hint |
| Right-sized (1-3 days, 3-7 scenarios) | PASS | 0.5 days; add 4 cases to switch statement + hint update; 5 scenarios |
| Technical notes: constraints/dependencies | PASS | Escape byte values documented, case-insensitive pattern noted |
| Dependencies resolved or tracked | PASS | Depends on US-TM-02 (turn command exists) |
| Outcome KPIs defined | PASS | KPI-1 jam compliance (keyboard-invoked requirement) |

### DoR Status: PASSED

---

## US-TM-06: Facing Persistence and Combat Turn Acceptance

| DoR Item | Status | Evidence |
|----------|--------|----------|
| Problem statement clear, domain language | PASS | "Two edge cases unverified: floor transition facing persistence and combat turn acceptance" |
| User/persona with specific characteristics | PASS | Ember transitioning floors or in a combat encounter |
| 3+ domain examples with real data | PASS | East persists to floor 3, turn right in combat (North→East encounter unchanged), movement locked after turning in combat |
| UAT in Given/When/Then (3-7 scenarios) | PASS | 3 scenarios: floor transition, combat turn, combat movement lock |
| AC derived from UAT | PASS | 4 AC items tracing to all 3 scenarios |
| Right-sized (1-3 days, 3-7 scenarios) | PASS | 0.5 days; verification/test story; 3 scenarios |
| Technical notes: constraints/dependencies | PASS | withCurrentFloor isolation note, unconditional turn processing note |
| Dependencies resolved or tracked | PASS | Depends on US-TM-01..05 |
| Outcome KPIs defined | PASS | KPI-3 no regression |

### DoR Status: PASSED

---

## Overall Feature DoR Gate

| Story | DoR Status |
|-------|-----------|
| US-TM-01 | PASSED |
| US-TM-02 | PASSED |
| US-TM-03 | PASSED |
| US-TM-04 | PASSED |
| US-TM-05 | PASSED |
| US-TM-06 | PASSED |

### Feature DoR Status: PASSED — all 6 stories ready for DESIGN wave
