# Opportunity Tree
**Feature**: dcjam2026-core
**Phase**: 2 — Complete
**Gate G2 status**: PASS
**Date**: 2026-04-02

---

## Desired Outcome

A grid-based dungeon crawler where movement itself is the primary expressive verb — the dragon is an escapee who can also fight, not a fighter who can also run. The player experiences two distinct emotional beats: power (special) and relief (egg + exit). The egg narrative is delivered through flavor, not countdown pressure.

---

## Opportunity Solution Tree

```
DESIRED OUTCOME: Dragon escape crawler — movement as primary verb, two emotional beats
  |
  +-- OPP-1: Dash mechanic is unexplored in grid-crawlers (Score: 18)
  |     +-- SOL-A: Dash moves dragon through occupied squares, no collision with enemies
  |     +-- SOL-B: Dash has a cooldown gate (not a timer — a resource/readiness state)
  |     +-- SOL-C: Dash can chain through multiple enemies in one move
  |
  +-- OPP-2: Dragon identity is undifferentiated from generic dungeon hero (Score: 16)
  |     +-- SOL-D: Dragon has breath weapon as special (not sword/spell)
  |     +-- SOL-E: Dragon framing in all text — "claw", "wing", "roar" — no sword language
  |     +-- SOL-F: Movement text reflects dragon physicality ("you lunge", "you surge past")
  |
  +-- OPP-3: Special attack lacks "badass" feedback in TUI (Score: 15)
  |     +-- SOL-G: Dedicated ASCII art frame or full-screen description for special use
  |     +-- SOL-H: Distinct sound design cue for special activation
  |     +-- SOL-I: Enemy reaction text is dramatic, not generic ("the guard is obliterated")
  |
  +-- OPP-4: Egg/exit moments are not differentiated from routine navigation (Score: 14)
  |     +-- SOL-J: Egg discovery triggers a distinct visual/text event (not just item pickup)
  |     +-- SOL-K: Exit discovery triggers a relief beat — pacing change, text slows, fanfare
  |     +-- SOL-L: Egg and exit are the only two moments with special audio cues
  |
  +-- OPP-5: Stat modification mechanism is unresolved — food-as-default is not validated (Score: 13)
  |     +-- SOL-M: Milestone upgrade choices — player selects a stat upgrade at defined progression points (preferred)
  |     +-- SOL-N: Floor-based advantages — bonuses tied to dungeon floors (e.g., Pomander-style, as in FFXIV Deep Dungeons)
  |     +-- SOL-O: Food items providing immediate stat effect — valid option, but not the default assumption
  |     +-- SOL-P (CONSTRAINT): No countdown. Whatever system is chosen must not deplete over time.
  |
  +-- OPP-6: Combat is the default response to encounters — evasion has no mechanical identity (Score: 12)
  |     +-- SOL-P: Evasion (dash past) is always available, never locked out by resource
  |     +-- SOL-Q: Enemies that cannot be evaded are rare and telegraphed — they are bosses
  |     +-- SOL-R: Score / outcome tracking rewards evasion over combat ("ghosted 7 guards")
  |
  +-- OPP-7: Jam theme integration is shallow — "Dragon" is only visual skin (Score: 10)
        +-- SOL-S: Narrative ties all four jam themes (dragon + mess + retrofuturism or elemental)
        +-- SOL-T: Elemental Rock Paper Scissors as encounter type system (optional, if feasible)
        +-- SOL-U: "Cleaning up the hero's mess" = the hero killed the dragon's parent, stole the egg
```

---

## Opportunity Scoring

Scoring formula: Score = Importance + Max(0, Importance - Satisfaction)
Importance and Satisfaction rated 1–10. Max score: 20.

| ID | Opportunity | Importance | Current Satisfaction | Score | Priority |
|----|-------------|------------|---------------------|-------|----------|
| OPP-1 | Dash mechanic unexplored | 10 | 1 | 10 + 9 = **19** | Pursue |
| OPP-2 | Dragon identity undifferentiated | 9 | 2 | 9 + 7 = **16** | Pursue |
| OPP-3 | Special lacks badass feedback | 9 | 2 | 9 + 7 = **16** | Pursue |
| OPP-4 | Egg/exit not differentiated | 8 | 2 | 8 + 6 = **14** | Pursue |
| OPP-5 | Stat modification mechanism unresolved | 8 | 3 | 8 + 5 = **13** | Pursue |
| OPP-6 | Evasion has no mechanical identity | 7 | 2 | 7 + 5 = **12** | Pursue |
| OPP-7 | Jam theme integration shallow | 6 | 4 | 6 + 2 = **8** | Evaluate |

All top opportunities score above 8. G2 threshold met.

---

## Top 3 Prioritized Opportunities

### Priority 1 — OPP-1: Dash mechanic unexplored (Score: 19)
This is the irreducible core. Every design decision should serve or protect the Dash. If Dash is cut, the game becomes generic. Dash = the reason to build this.

**Target outcome**: Player can move through enemy-occupied squares without stopping to engage. Dash is the primary verb. Combat is opt-in.

### Priority 2 — OPP-2 + OPP-3: Dragon identity and special feedback (combined, Scores: 16)
These two are inseparable. The special attack is the moment where dragon identity is most concentrated. The "badass" feeling requires both: the dragon must feel like a dragon (identity), and the special must land with impact (feedback). Together they form the power-fantasy beat.

**Target outcome**: Special attack has a dedicated feedback moment (ASCII art or full-screen text), and all language throughout the game uses dragon vocabulary.

### Priority 3 — OPP-4 + OPP-5: Egg/exit emotional beats and unresolved stat modification (combined, Scores: 14 + 13)
The relief beat and the unresolved stat modification problem are related. The egg cannot be a countdown precisely because it must be the source of relief, not anxiety. The stat modification mechanism must be resolved separately — the primary candidate is milestone upgrade choices (developer preference), with food items and floor-based advantages as secondary options.

**Target outcome**: Stat modification system chosen and implemented (milestone upgrades preferred, no timer under any option). Egg discovery triggers a marked narrative moment. Exit triggers relief beat. No countdowns anywhere.

---

## G2 Gate Evaluation

| Criterion | Target | Actual | Status |
|---|---|---|---|
| Opportunities identified | 5+ distinct | 7 identified | PASS |
| Top opportunity scores | >8 | All 7 above 8 | PASS |
| Top 2–3 prioritized | Required | Yes — 3 priority groups defined | PASS |
| Job step coverage | 80%+ | Define / Execute / Monitor / Conclude covered | PASS |
| Team alignment | Confirmed | Single developer — self-confirmed | PASS |

**Gate G2: PASS. Proceed to Phase 3.**
