# Lean Canvas
**Feature**: dcjam2026-core
**Phase**: 4 — Complete
**Gate G4 status**: PASS (conditional on feasibility spikes — design decisions finalized 2026-04-02)
**Date**: 2026-04-02
**Last updated**: 2026-04-02 — five open questions resolved, DEC-08 through DEC-12 added

---

## One-Page Business Model

Note: For a game jam, "business model" means: what is the value exchange, what are the constraints, and what does success look like? Revenue is replaced by jam submission goals.

---

### 1. Problem (Phase 1 validated)

1. Grid-based dungeon crawlers have no expressive movement — the player is reactive, not active.
2. Dungeon crawlers lack differentiated emotional beats — power moments and relief moments feel identical to ordinary navigation.
3. Food-as-timer is an overused pattern that adds anxiety without depth.

---

### 2. Customer Segments (by JTBD)

**Primary**: Solo developer making a jam entry who wants to build something mechanically novel in the dungeon-crawler genre.

**Secondary (intended players)**: DCJam 2026 participants and judges who play grid-based dungeon crawlers and are looking for a memorable standout entry. Specifically: players who have felt that dungeon crawlers are too combat-mandatory and want an escape/evasion fantasy.

**Segment by JTBD, not demographics**:
- "Play a dungeon crawler where I feel like a creature that *escapes*, not a hero that *fights*."
- "Experience a grid crawler where movement has meaning beyond getting to the next fight."

---

### 3. Unique Value Proposition

**For the player**: "You are a dragon. You don't fight your way out — you dash through them. The guards never know what hit them."

**For the jam judge**: A grid crawler that inverts the combat-mandatory assumption: evasion is the primary verb, combat is the last resort. First-person TUI with a mechanic the judge has not seen before.

---

### 4. Solution (top features for top problems)

1. **Dash mechanic**: Move through enemy-occupied squares. Primary locomotion. Combat is opt-in. Starts with 2 charges; each replenishes on ~45s cooldown (configurable). Progression upgrades reduce cooldown or raise charge cap. (DEC-08)
2. **Special attack with full-screen feedback**: Available from the start but with an empty charge meter — first encounter teaches Dash priority organically without a tutorial. Dedicated visual/text moment delivers the "badass" beat once charged. Dragon vocabulary throughout. (DEC-10, DEC-03, DEC-04)
3. **Egg discovery + exit relief beats**: Marked narrative moments at the two emotional peaks. Floor structure: Floor 1 starter, Floors 2–4 regular (egg on one mid-floor), Floor 5 boss + exit patio. Minimum 3 floors, target 5. (DEC-11) Stat modification system satisfies the jam constraint — primary candidate is milestone upgrade choices (feeds into Dash charge cap / cooldown upgrades); food items and floor bonuses are secondary options. No timer under any option. (DEC-02)

---

### 5. Channels (jam context)

- itch.io submission (DCJam 2026 platform)
- Jam Discord / community sharing
- Developer's personal network

**Channel validation**: itch.io is the only required channel. No additional channel validation needed for jam scope.

---

### 6. Revenue Streams (jam context)

- No revenue. Success metric = jam ranking, player feedback, personal satisfaction of building something novel.
- Scope is jam-only. Post-jam expansion is acknowledged as possible (every jam entry tests a concept) but is explicitly out of scope for this discovery and all requirements flowing from it. (DEC-12)

---

### 7. Cost Structure

- Developer time (solo): primary constraint. Hard deadline = jam end date.
- Swift toolchain (already in use — Package.swift present in repo)
- Zero external costs for jam submission

**Critical cost constraint**: Every mechanic must be buildable by one developer before the jam deadline. Complexity must be ruthlessly controlled.

---

### 8. Key Metrics (jam scope)

| Metric | Target |
|---|---|
| Jam entry submitted before deadline | Yes / No |
| Dash mechanic working and playable (2 charges, cooldown functional) | Yes / No |
| Both emotional beats implemented (special + egg/exit) | Yes / No |
| No timer mechanics in shipped game | Yes / No |
| Stat modification mechanism implemented (milestone upgrades preferred, Dash upgrades as primary lever) | Yes / No |
| Floor structure complete (minimum 3, target 5 with defined roles) | Yes / No |
| Special available from start, empty on first encounter (organic Dash teaching) | Yes / No |
| Developer personal satisfaction with the result | Subjective — "did I build what I wanted?" |

---

### 9. Unfair Advantage

The specific combination of:
- Dragon-as-escapee framing (not dragon-as-fighter)
- Dash-through-enemies as primary locomotion in a grid crawler (2 charges, persistent availability — not a scarce resource)
- Special attack teaching Dash priority organically through mechanical state (no tutorial required)
- Two distinct emotional beats (power + relief) explicitly designed
- Defined 5-floor arc with egg mid-game and boss + exit patio as the climax
- Stat modification system (milestone upgrades preferred, with Dash cooldown / charge cap as primary upgrade levers)

No other jam entry is likely to have derived this specific mechanic from this specific design conversation. The concept is novel because it inverts the genre assumption.

---

## 4 Big Risks Assessment

### Risk 1: Value — Will players want this?

**Question**: Will players who pick up this entry find the dash mechanic and dragon-escapee framing compelling?

**Evidence**: Developer (as representative player) confirmed the gap exists — "not something I've seen done a lot." Gap = underserved need.

**Risk level**: YELLOW — validated by one developer. Not tested with external players.

**Mitigation**: The jam context is the test. If the entry scores well on "originality" or players mention the dash in feedback, the value assumption is confirmed.

### Risk 2: Usability — Can players use this?

**Question**: Will first-time players understand that dash is the primary verb, not a special ability?

**Risk level**: YELLOW — mechanically addressed, not yet playtested.

**Resolution via DEC-10**: The special attack starts available but with an empty charge meter. On the first enemy encounter, the special is visibly unavailable; Dash is visibly ready. The player naturally selects Dash without being told to. This eliminates the need for tutorial text to explain mechanic priority — the game state itself teaches the lesson.

**Remaining mitigation**: Dash must be bound to an obvious key and labeled in the UI from the first moment. The charge meter for both Dash and Special must be readable at a glance. If players can't read the state, the organic teaching moment fails.

**Key usability assumption**: Clarity of UI state (Dash: 2 charges ready / Special: empty) is the entire tutorial. This is achievable in TUI but must be explicitly designed — it cannot be an afterthought.

### Risk 3: Feasibility — Can we build this?

**Question**: Can the dash movement (pass-through occupied squares), full-screen narrative events, and distinct special attack feedback all be implemented before the jam deadline?

**Risk level**: YELLOW — Swift package structure is present (Package.swift, Sources/) but no engine loop has been examined yet.

**Required spikes** (must happen before coding game content):
1. Dash collision model in grid — can the grid support pass-through as a movement mode?
2. Full-screen event pause — can the TUI layer interrupt normal dungeon display for a narrative moment?
3. Special attack visual distinction — can a "big moment" be rendered differently from normal combat in terminal?

**Mitigation**: If any spike fails, fall back: (1) Dash as "enemies staggered, no counter-attack" instead of full pass-through. (2) Egg discovery as a multi-line text box, not full-screen. (3) Special attack as caps-lock + ASCII border, not art frame.

### Risk 4: Viability — Does this work for the jam?

**Question**: Does the design satisfy all hard jam rules?

**Jam rule audit**:
- First-person exploration: YES — grid crawler, first-person view
- Step movement on square grid: YES — grid movement, dash is multi-step or pass-through on same grid
- 90-degree turns: YES — standard grid crawler
- Player character with at least one stat: YES — health bar minimum, plus dash charges
- Combat or encounter mechanic: YES — combat exists as opt-in, special attack
- Win condition: YES — escape with the egg, reach the exit
- Death/fail condition: YES — health depleted
- At least one way to affect stats: YES — jam constraint satisfied; specific mechanism (milestone upgrades / food / floor bonuses) is an open design decision, all options comply
- Theme interpretation: YES — Dragon theme + "Cleaning up the hero's mess" (hero killed dragon's parent, stole the egg — player is the dragon reclaiming it). Elemental Rock Paper Scissors: explicitly not used (DEC-09). Retrofuturism: optional, not required.

**Risk level**: GREEN — all jam rules satisfied by the current design.

---

## G4 Gate Evaluation

| Criterion | Target | Actual | Status |
|---|---|---|---|
| Lean Canvas complete | Yes | Yes | PASS |
| All 4 risks addressed | All green or yellow | 1 green, 3 yellow | PASS (yellow = known, mitigated) |
| Go/No-Go documented | Required | GO — see below | PASS |
| Stakeholder sign-off | Required | Single developer — self sign-off | PASS (jam context) |

**Gate G4: PASS (conditional on feasibility spikes passing).**

---

## Go/No-Go Decision

**DECISION: GO**

**Rationale**:
- The core mechanic (Dash) is novel, technically plausible, and directly derived from a validated gap.
- The two emotional beats are clear design targets, not vague aspirations.
- The invalidated assumption (food-as-timer) has been explicitly removed from scope.
- All jam hard rules are satisfied.
- The dragon-as-escapee framing is internally coherent and differentiated.

**Conditions**:
1. All three feasibility spikes must pass before writing game content code.
2. If Dash pass-through is not implementable, pivot to "Dash = no counter-attack" — do not cut the mechanic, reduce its scope.
3. Timer mechanics must not appear anywhere in the shipped game. If a deadline pressure mechanism is added during development, it must be challenge-mode only (opt-in, not default).
