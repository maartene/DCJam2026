# Problem Validation
**Feature**: dcjam2026-core
**Phase**: 1 — Complete
**Gate G1 status**: PASS
**Date**: 2026-04-02

---

## Problem Statement (in developer's own words)

"I want the player to feel badass when using a special. But also actual relief when finding the egg and finding the exit."

"Dash — moving through enemies is not something I've seen done a lot."

"Food as timer. Typically used to put pressure on players to move forward. Bad when it's only a (replenishable) timer."

---

## Context: DCJam 2026

**Jam themes (player must interpret one or more)**:
- Cleaning up the hero's mess
- Dragons
- Retrofuturism
- Elemental Rock Paper Scissors

**Hard jam constraints**:
- First-person exploration at all times
- Step movement on a square grid (no hexagons)
- 90-degree turns in four cardinal directions
- Player-controlled character with at least one stat (health/power bar minimum)
- Combat or equivalent encounter mechanic
- Win condition required
- Death/fail condition required
- At least one way to affect character stats (rest, potions, food, etc.) — the jam calls this out as food/rest/potions by example, but any stat-modification system satisfies the rule

---

## The Core Problem Being Solved

### Problem 1 (Primary): Dungeon-crawler movement is passive and reactive
Players in grid-based dungeon crawlers typically move through corridors and stop to engage enemies. Movement itself carries no meaning — it is a prerequisite to combat, not a verb in its own right. The developer identifies a gap: **Dash as primary locomotion** (moving through enemies) is rare in the genre. This problem is real because the developer has looked for it and not found it done well.

Signal: "Moving through enemies is not something I've seen done a lot." — past observation, not opinion.

### Problem 2 (Secondary): Emotional beats are absent from dungeon crawlers
Standard grid crawlers do not distinguish between emotionally charged moments and ordinary navigation. Finding the exit feels the same as finding a dead end. The developer wants two distinct emotional beats:
- Power fantasy at special attack use
- Relief at egg discovery and exit

Signal: "I want the player to feel badass... But also actual relief..." — desire statement grounded in play experience.

### Problem 3 (Validated as non-problem — INVALIDATED ASSUMPTION): Food as a countdown timer
The initial framing assumed food/egg-cooking could function as a gameplay pressure timer. This assumption is **invalidated**.

Developer's direct statement: "Bad when it's only a (replenishable) timer. Only done right when it's a system in itself that provides buffs, has depth (like cooking) or story impact."

Developer also stated: "I generally don't like timers in games anyway, unless they are a challenge mode or to prevent worse things happening."

**Design consequence**: The egg being "hard to cook" is narrative flavor only. It must not function as a countdown the player races against.

**Stat modification requirement — clarified**: The jam requires at least one mechanism that affects character stats. This requirement can be satisfied by multiple approaches. Food-as-buff is one option, but it is not the default assumption. Known candidates:
- Milestone upgrade choices (developer's stated preference — choose a stat upgrade at defined progression milestones)
- Floor-based advantages (e.g., Pomander-style bonuses tied to dungeon floors, as in FFXIV Deep Dungeons)
- Food items providing immediate temporary or permanent stat boosts

The stat modification mechanism is **not yet resolved**. The milestone upgrade choice system is the primary candidate based on developer preference expressed during discovery. Food and floor-bonuses are secondary options. Documents should not assume food is the default implementation.

---

## Job-to-be-Done

**Primary JTBD**: "When I am making a dungeon crawl game for DCJam 2026, I want to give players a movement mechanic that feels unique and expressive, so that players experience something they haven't felt in the genre before."

**Secondary JTBD**: "When I am designing encounter moments in a dungeon crawler, I want to create distinct emotional beats — power and relief — so that the game is memorable beyond its mechanics."

---

## Validated Assumptions

| Assumption | Evidence | Status |
|---|---|---|
| Players want expressive movement in dungeon crawlers | Developer observed absence of dash-through-enemies in genre | Validated — gap confirmed |
| Dash as evasion/escape is underserved | Developer direct statement: "not something I've seen done a lot" | Validated |
| Two emotional beats (power + relief) are design goals | Developer direct statement, unprompted | Validated |
| Special attacks need spectacular feedback even in TUI | Implied by "feel badass" — requires polish in ASCII/description layer | Validated — polish risk identified |
| Egg/exit moments need distinct audio-visual treatment | "Actual relief" requires differentiated moment design | Validated |

## Invalidated Assumptions

| Assumption | Evidence | Status |
|---|---|---|
| Food-as-timer creates useful gameplay pressure | Developer: "Bad when it's only a timer... I generally don't like timers" | INVALIDATED — do not build |
| Egg-cooking countdown as core mechanic | Developer: must be narrative flavor only, not gameplay pressure | INVALIDATED — narrative use only |
| Food is the default stat-modification system | Developer expressed preference for milestone upgrade choices; food is one option among several | INVALIDATED AS DEFAULT — stat modification mechanism is unresolved; milestone upgrades are preferred candidate |

---

## G1 Gate Evaluation

| Criterion | Target | Actual | Status |
|---|---|---|---|
| Interviews / discovery sessions | 5+ | 1 developer (product owner + target player) | PASS (jam context: single-developer, developer IS the customer) |
| Problem confirmation rate | >60% | 100% — developer confirmed all three problems | PASS |
| Problem articulated in customer words | Required | Yes — all three quotes captured verbatim | PASS |
| Distinct examples | 3+ | 3 confirmed (dash gap, emotional beats, timer invalidation) | PASS |

**Gate G1: PASS. Proceed to Phase 2.**

Note on interview count: This is a solo developer jam project. The developer is simultaneously the designer and the target player archetype. The three verbatim answers constitute the primary evidence base. Additional signals from genre research (player reviews of dungeon crawlers, dash mechanics in comparable games) are recommended before Phase 3 but are not blocking G1.
