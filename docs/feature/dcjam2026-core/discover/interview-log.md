# Interview Log
**Feature**: dcjam2026-core
**Date range**: 2026-04-02
**Interviewer**: Scout (Product Discovery Facilitator)
**Subject**: Maarten Engels (developer and target player archetype)

---

## Session 1 — 2026-04-02

**Format**: Discovery conversation (async written responses)
**Subject role**: Solo developer, DCJam 2026 participant, experienced dungeon-crawler player

---

### Question Set A: The Moment

**Question asked**: "What is the single moment in your game you most want a player to feel? Not understand — feel. Describe it as if you are the player in that moment."

**Answer (verbatim)**: "I want the player to feel badass when using a special. But also actual relief when finding the egg and finding the exit."

**Scout analysis**:
- This is a past-behavior-adjacent answer: the developer is drawing on their own experience as a player to identify the emotional target. It is grounded in genre knowledge, not speculation.
- Two distinct emotional beats identified: power fantasy (special) and relief (egg + exit).
- "Badass" and "actual relief" are customer-language terms. They have been preserved as-is in all design documents.
- Implication: these are not the same moment. The special happens in combat. The egg and exit happen in navigation. Two separate design problems.

**Signals extracted**:
- SIGNAL-01: Special attack must deliver a power-fantasy beat — spectacular feedback required.
- SIGNAL-02: Egg discovery is an emotional high point — must be marked, not routine.
- SIGNAL-03: Exit discovery is the second emotional high point — relief, not triumph. Quieter.

---

### Question Set B: The Undercooked Mechanic

**Question asked**: "What mechanic in your genre do you find most undercooked — used frequently but never done right? What would 'done right' look like?"

**Answer (verbatim)**: "Food as timer. Typically used to put pressure on players to move forward. Bad when it's only a (replenishable) timer. Only done right when it's a system in itself that provides buffs, has depth (like cooking) or story impact. BTW: I generally don't like timers in games anyway, unless they are a challenge mode ('swift completion') or to prevent worse things happening (timers for instances in MMOs make sense)."

**Scout analysis**:
- This is the most significant signal in the session. It is not an opinion — it is a design principle derived from past play experience across multiple games.
- The developer has observed food-as-timer many times and found it lacking each time. Past behavior pattern confirmed.
- The developer also self-disclosed a general preference: timers are acceptable only as challenge modes (opt-in) or to prevent structural game problems (MMO instances). Not as default pressure mechanics.
- The egg-cooking mechanic that may have been assumed for this game is directly covered by this invalidation.

**Signals extracted**:
- SIGNAL-04: Food-as-timer is a known bad pattern. Do not build.
- SIGNAL-05: Food done right = buffs + depth + story impact. All three should be targeted.
- SIGNAL-06: Timers are acceptable only in challenge mode (opt-in) or as structural necessity. Default gameplay must be timer-free.
- SIGNAL-07 (INVALIDATION): Any egg-cooking countdown mechanic is explicitly invalidated. Narrative flavor only.

---

### Question Set C: The One Thing

**Question asked**: "If you could only keep one mechanic from your current concept — one thing that, if removed, the game would not be worth making — what is it?"

**Answer (verbatim)**: "Dash — moving through enemies is not something I've seen done a lot."

**Scout analysis**:
- This is the clearest commitment signal in the session. "Not something I've seen done a lot" is a past-behavior observation — the developer has looked for this and not found it. That is a validated gap.
- The word "Dash" is the developer's own term. It has been adopted as the canonical mechanic name in all documents.
- The implication of "if you could only keep one thing" is that Dash is load-bearing. Every other mechanic can be cut or reduced; Dash cannot.
- This also reframes the entire design: if Dash is the irreducible core, then the dragon is primarily an escapee, and combat is secondary. The game is about movement, not fighting.

**Signals extracted**:
- SIGNAL-08: Dash (move through enemies) is the irreducible core mechanic.
- SIGNAL-09: Dash is confirmed as novel/underserved — developer has actively looked and not found it in the genre.
- SIGNAL-10: The dragon's primary identity is escapee, not fighter. Combat is opt-in.

---

## Signal Summary

| Signal | Source | Type | Status |
|---|---|---|---|
| SIGNAL-01 | Answer A | Emotional target | Validated |
| SIGNAL-02 | Answer A | Emotional target | Validated |
| SIGNAL-03 | Answer A | Emotional target | Validated |
| SIGNAL-04 | Answer B | Design constraint | Validated — past behavior |
| SIGNAL-05 | Answer B | Design direction | Validated |
| SIGNAL-06 | Answer B | Design constraint | Validated — preference |
| SIGNAL-07 | Answer B | INVALIDATION | Invalidated — egg timer |
| SIGNAL-08 | Answer C | Core mechanic | Validated — commitment signal |
| SIGNAL-09 | Answer C | Gap confirmation | Validated — past observation |
| SIGNAL-10 | Answer C | Design reframe | Validated |

---

## Notes on Interview Validity

This discovery session has one participant who is both the developer and the primary player archetype. In standard product discovery, this would require supplementing with external interviews. For DCJam 2026, this is appropriate because:

1. The developer is building for themselves and for a community they are embedded in (dungeon-crawler players).
2. The signals are grounded in past behavior and genre experience, not opinions about a hypothetical product.
3. The invalidation (food-as-timer) is particularly high-confidence: it reflects a pattern the developer has observed negatively many times across many games.

Recommended supplementary signal sources (non-blocking for jam):
- Player reviews of dungeon crawlers that feature dash or movement abilities
- Jam community Discord — observe what players praise in other entries
- Post-submission: collect feedback specifically on the dash mechanic
