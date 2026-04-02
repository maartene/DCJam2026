# Solution Testing
**Feature**: dcjam2026-core
**Phase**: 3 — In Progress
**Gate G3 status**: PENDING — feasibility spikes required (design decisions finalized 2026-04-02)
**Date**: 2026-04-02
**Last updated**: 2026-04-02 — Dash charges, special unlock, floor structure, and scope decisions incorporated

---

## Overview

Phase 3 validates that the solutions for the top three priority opportunities actually work when a player touches them. For a jam game, "testing" means internal playtesting and developer self-evaluation against the emotional targets, not a formal usability lab.

The three hypotheses below map directly to the three priority opportunity groups from the OST.

---

## Hypothesis 1 — Dash as Primary Verb

**Hypothesis**:
We believe implementing Dash (move through enemy squares without engaging) for the dragon player will achieve the feeling of "moving through enemies is something special" that is currently missing from the genre.
We will know this is TRUE when: the developer plays a session and chooses Dash over combat in more than 50% of encounters by personal preference.
We will know this is FALSE when: Dash feels like a novelty but combat still feels like the natural response, or when Dash trivializes all tension (becomes too powerful).

**Assumptions to test first** (highest risk):

| Assumption | Risk Score | Test Method |
|---|---|---|
| Dash through occupied squares is implementable on a square grid in the jam timeline | Impact 3, Uncertainty 2, Ease 2 = **13** | Technical spike — build Dash move in isolation |
| Dash feels meaningfully different from walking, not just "skipping combat" | Impact 3, Uncertainty 2, Ease 1 = **12** | Self-playtest with and without Dash enabled |
| Dash does not make all enemies irrelevant (balance risk) | Impact 3, Uncertainty 2, Ease 1 = **12** | Playtest — count how often player is forced to fight |
| Cooldown / charge model for Dash doesn't feel like a timer (invalidated pattern) | Impact 2, Uncertainty 2, Ease 1 = **9** | Playtest — does the cooldown create dread or strategy? |

**Smallest testable thing**: Implement one corridor with three enemies. Dash straight through all three. Observe: does it feel satisfying or does it feel like the designer is absent?

**Design constraints** (updated per DEC-08):
- Dash has 2 charges, each replenishing on ~45s cooldown (configurable). Two charges means the player is rarely truly out of Dash — the resource model reinforces Dash as primary locomotion, not a scarce combat tool.
- Refill is time-based (cooldown), not pickup-based. Using both charges creates a brief window of vulnerability, not a long deprivation.
- Cooldown / charge display in UI is a hard requirement — if the player cannot read their Dash state at a glance, the organic teaching moment (DEC-10) fails.
- Progression ties in: upgrades can lower cooldown or increase charge cap. These are the primary stat modification levers.

---

## Hypothesis 2 — Dragon Identity + Special Attack Feedback

**Hypothesis**:
We believe using dragon-specific vocabulary throughout the game and adding a dedicated full-screen moment for the special attack will achieve the "badass" feeling the developer identified.
We will know this is TRUE when: the developer activates the special and says (internally or externally) "yes, that's it."
We will know this is FALSE when: the special activation feels like any other attack with a bigger number.

**Assumptions to test first**:

| Assumption | Risk Score | Test Method |
|---|---|---|
| A text-based game can deliver "badass" without visual spectacle | Impact 3, Uncertainty 3, Ease 1 = **16** | Write the special attack description. Read it aloud. Does it land? |
| Dragon vocabulary ("lunge", "roar", "claw") is consistently maintained | Impact 2, Uncertainty 1, Ease 1 = **8** | Review all combat strings — any sword/spell language? |
| Special attack is distinct enough from normal attacks in TUI feedback | Impact 3, Uncertainty 2, Ease 1 = **12** | Side-by-side comparison: normal attack vs special attack |

**Smallest testable thing**: Write three versions of the special attack description. Show them to one other person (or read them cold after 24 hours). Which one delivers impact?

**Design constraints** (updated per DEC-10):
- Special starts available but with an empty charge meter. First encounter: special is visibly empty, Dash is visibly ready. The game state teaches Dash priority without tutorial text.
- Charge rate must be calibrated so the special is not usable on the first encounter. This is a balance requirement, not a suggestion.
- The special must be a breath weapon or something physically dragon-appropriate. Not a fireball spell — a breath. Not a sword swing — a claw rend. Language is the entire visual layer in TUI.

---

## Hypothesis 3 — Egg/Exit Relief Beats + Stat Modification System

**Hypothesis**:
We believe treating egg discovery and exit as marked narrative moments (distinct visual event, pacing shift, unique text) will achieve the "actual relief" emotional beat the developer identified.
We will know this is TRUE when: during playtest, the egg-find and exit moments feel noticeably different from routine movement — the developer pauses, reads, and feels the weight.
We will know this is FALSE when: egg pickup and exit feel like any other item/tile interaction.

**Note on stat modification**: The jam requires at least one stat-affecting mechanism. The mechanism is not yet formally decided, but DEC-08 establishes that Dash charge cap and cooldown are the primary upgrade levers — these feed into whichever stat modification system is chosen. Milestone upgrade choices remain the preferred candidate. Food items and floor-based advantages are secondary options. The stat modification mechanism is a remaining open question for the product-owner wave.

**Assumptions to test first**:

| Assumption | Risk Score | Test Method |
|---|---|---|
| A full-screen text event on egg discovery is implementable in TUI | Impact 2, Uncertainty 1, Ease 1 = **8** | Spike: pause game loop, display multi-line text, resume |
| Milestone upgrade choices (primary stat-mod candidate) create meaningful decisions without feeling like a detour | Impact 2, Uncertainty 2, Ease 1 = **9** | Design two or three upgrade options. Present them cold — is there a real choice, or is one always correct? |
| Two distinct audio/visual cues (egg vs exit) are achievable in jam timeline | Impact 2, Uncertainty 2, Ease 2 = **11** | Check terminal output capabilities — color, beep, or similar |

**Smallest testable thing**: Write the egg-discovery text event. It must communicate: you found what you came for. The danger was worth it. Now get out.

**Design constraint**: No timer anywhere in any stat modification system. Whatever mechanism is chosen — milestone upgrades, food items, or floor bonuses — must not deplete over time. The egg is the narrative goal, not a cooking countdown.

---

## Hypothesis 4 — Floor Structure and Game Arc

**Hypothesis**:
We believe a 5-floor structure (starter / regular x3 / boss+exit) will deliver a complete and satisfying arc within jam scope. The minimum of 3 floors is the fallback if deadline pressure requires cuts.
We will know this is TRUE when: the developer completes a full run through all 5 floors and the egg discovery on a mid-floor and the exit relief on Floor 5 both land as distinct emotional moments.
We will know this is FALSE when: the arc feels too short (3 floors with no buildup) or the egg and exit feel rushed because they are too close together.

**Assumptions to test first** (per DEC-11):

| Assumption | Risk Score | Test Method |
|---|---|---|
| Egg on a mid-floor (Floors 2–4) creates earned anticipation before the boss floor | Impact 3, Uncertainty 2, Ease 1 = **12** | Playtest: does finding the egg feel like a turning point, or just an item pickup? |
| Floor 5 boss + exit patio delivers the relief beat after tension | Impact 3, Uncertainty 2, Ease 1 = **12** | Playtest: does exiting after the boss feel like relief, or just completion? |
| 5-floor structure is buildable before deadline | Impact 3, Uncertainty 2, Ease 2 = **13** | Scope check: how long does one floor take to implement? x5 must fit in jam timeline. |
| Floor 1 starter teaches Dash without feeling like a forced tutorial | Impact 2, Uncertainty 2, Ease 1 = **9** | Playtest: does the developer choose Dash on the first encounter without deliberating? |

**Smallest testable thing**: Build Floor 1 only. Confirm: (1) player encounters an enemy, (2) Dash is ready, (3) Special is empty, (4) player Dashes without prompting. If this works, the teaching loop is validated.

**Design constraint**: Egg placement on Floors 2–4 must not be random in a way that allows it to appear on Floor 2 every run — that would collapse the mid-game tension. Egg placement should be weighted toward Floor 3 or randomized across Floors 2–4 with no bias toward Floor 2.

---

## Feasibility Spikes Required (Pre-Build)

These technical questions must be answered before writing game code:

1. **Dash through occupied squares**: Is the movement grid collision model flexible enough to allow pass-through on Dash and block on normal move?
2. **Full-screen event in TUI**: Can the game pause the dungeon view and display a full-screen narrative moment, then return to play?
3. **Distinct feedback for special attack**: Can the TUI layer support a visually distinct presentation (e.g., border, color, ASCII art frame) for the special use?
4. **Swift/Package structure**: What is the current state of the Swift package — is there an engine loop to hook into?

---

## G3 Gate Criteria (Not Yet Evaluated)

| Criterion | Target | Actual | Status |
|---|---|---|---|
| Task completion | >80% | Not tested | PENDING |
| Value perception | >70% "would use/buy" | Not tested | PENDING |
| Key assumptions validated | >80% proven | Design decisions finalized; build not started | PENDING |
| Users tested | 5+ | 0 | PENDING |

**Gate G3: PENDING — design decisions complete, build not yet started.**

G3 is no longer blocked on design questions. All five previously open questions are resolved (DEC-08 through DEC-12). G3 is now blocked only on the three feasibility spikes (DEC-06) and a self-playtest session.

For a jam with a hard deadline, G3 is satisfied when:
1. All three feasibility spikes pass (or fallback designs confirmed for any that fail)
2. The developer completes one full run of a prototype Floor 1 and confirms: (a) Dash is the natural first choice, (b) Special's empty state is readable and communicates "not yet", (c) the Dash charge UI is legible
3. A full 5-floor run (or 3-floor minimum) confirms egg discovery and exit relief beat land as distinct emotional moments
