# Handoff Summary — DISCUSS Wave
**Feature**: dcjam2026-core
**From**: Scout (Product Discovery Facilitator)
**To**: Product Owner (DISCUSS wave)
**Date**: 2026-04-02
**Gate status**: G1 PASS | G2 PASS | G3 PENDING (spikes only) | G4 PASS

---

## What This Document Is

A concise handoff brief for the product-owner wave. It covers: what is settled and why, what remains open, the implied user stories, and the three constraints the product-owner must enforce throughout requirements work.

The full evidence base lives in the six discovery artifacts. This document is a navigation guide, not a substitute.

---

## What Is Settled

All design decisions are final unless new evidence emerges. Do not reopen these in requirements sessions without developer confirmation.

### The core mechanic

Dash is the irreducible core. The dragon moves through enemy-occupied squares without engaging. Combat is opt-in. If Dash is cut, the game is not worth building (developer's own framing).

- Dash starts with 2 charges
- Each charge replenishes on ~45s cooldown (configurable)
- Progression upgrades can lower cooldown or increase charge cap
- Source: DEC-01, DEC-08

### The organic teaching moment

The special attack is available from the start but has an empty charge meter. On the first enemy encounter: special is visibly empty, Dash is visibly ready. No tutorial text needed. The game state teaches Dash priority.

This resolves the single largest usability risk identified in discovery. The UI must make both states (Dash: 2 charges / Special: empty) readable at a glance — if the UI fails here, the teaching moment fails.

- Source: DEC-10

### The floor structure

- Minimum: 3 floors
- Target: 5 floors
- Floor 1: Starter (mechanics introduction, first Dash moment)
- Floors 2–4: Regular floors (one contains the egg)
- Floor 5: Boss encounter + exit patio (relief beat)

The egg must not appear on Floor 1 (no earned relief) or Floor 5 (that floor belongs to the boss and exit). Egg placement on Floors 2–4 should not be systematically biased toward Floor 2.

- Source: DEC-11

### The emotional beats

Two moments must receive dedicated design attention:
1. Special attack use — "badass" / power fantasy (full-screen or ASCII-bordered feedback)
2. Egg discovery + exit — "actual relief" (pacing shift, distinct text, not a routine item pickup)

These are different moments and must not be designed the same way. Generic "show notification" is not acceptable for either.

- Source: DEC-03

### Dragon vocabulary

All combat and movement strings use dragon-appropriate vocabulary: claw, fang, wing, roar, lunge, surge. No sword swings, no spell casts, no naked "attack" verb. This is identity-layer design, not cosmetic.

- Source: DEC-04

### Narrative frame

The recommended (not hard-required) framing: the hero adventured through the dragon's home, killed the dragon's parent, and stole the egg. The player is the young dragon reclaiming it. This gives the egg narrative weight, makes the exit emotionally loaded, and directly interprets the "Cleaning up the hero's mess" jam theme.

- Source: DEC-05

### What is out of scope

- Elemental Rock Paper Scissors: explicitly out. No elemental types, affinities, or damage modifiers. (DEC-09)
- Food-as-timer / egg-cooking countdown: invalidated. No default timers anywhere. (DEC-02)
- Post-jam expansion features: jam-only scope. Every requirement must pass the filter: "Is this necessary for a playable, submittable 3–5 floor jam entry?" (DEC-12)
- Tutorial text explaining that Dash is primary: the mechanic teaches this itself. (DEC-10)

---

## What Remains Open

Three questions must be confirmed with the developer before writing requirements for the affected areas. Do not assume defaults.

### 1. Slash attack — omit or retain?

The developer is considering removing the slash attack, leaving the action set as: Brace, Special, Dash. This is the most consequential open question for combat design. If slash is removed, the player's only options when Dash is on cooldown and Special is not yet charged are Brace or wait. This may be the intended tension — but it must be the developer's explicit call.

**Do not write combat action requirements until this is confirmed.**

### 2. Stat modification mechanism

The jam requires at least one way to affect character stats. The primary candidate is milestone upgrade choices (developer's stated preference) with Dash charge cap and cooldown as the primary upgrade levers (established by DEC-08). Secondary options: floor-based advantages (Pomander-style), food items.

**Confirm the mechanism before writing progression requirements.** All three options satisfy the jam rule — this is a design choice, not a constraint question.

### 3. Non-Dash movement in combat

DEC-07 establishes that Dash must be possible during combat. Whether the player can also reposition or retreat freely (non-Dash movement) during a combat encounter is not decided. Combat requirements must flag this as pending until confirmed.

---

## Implied User Stories

These are discovery-derived starting points for the product-owner's backlog, not finished stories. They are organized by the floor structure to reflect delivery sequence.

### Floor 1 — Starter floor

- As a player on my first encounter, I see the Dash charges are ready and the special charge meter is empty, so I try Dash first without being told to.
- As a player, I can execute a Dash through an enemy-occupied square so the enemy does not block my path or counterattack.
- As a player, I see my Dash charge count and cooldown state clearly in the UI at all times.

### Floors 2–4 — Regular floors

- As a player, I find the egg on one of the regular floors and experience a distinct narrative moment — not a standard item pickup.
- As a player, I encounter combat situations where Dash, Special, and (if retained) Slash / Brace are available, so encounters have strategic texture.
- As a player, I see my special charge meter fill over time so I understand when the power moment is approaching.
- As a player, I can select an upgrade at a progression milestone so my Dash cooldown or charge cap improves.

### Floor 5 — Boss + exit patio

- As a player, I encounter a boss that cannot simply be Dashed through (telegraphed as an exception to the rule).
- As a player, I activate the special attack and experience a dedicated full-screen or framed feedback moment with dragon-appropriate text.
- As a player, I reach the exit after the boss and experience a pacing shift — relief, not triumph. The moment is slow, distinct, and earned.

### Throughout — Dragon identity

- As a player, every combat and movement string uses dragon vocabulary (claw, fang, wing, lunge, surge) with no generic dungeon-hero language.
- As a player, I am never told I "attack" — I lunge, rake, or breathe.

### Jam compliance

- As the developer, I can submit a playable entry with a minimum of 3 floors before the jam deadline.
- As the developer, the shipped game contains no default timer mechanics.

---

## Three Constraints the Product-Owner Must Enforce

These are non-negotiable. If any requirement violates them, it must be rejected and traced back to the evidence.

**1. No timers as default mechanics.** Cooldowns (like Dash charge refill) are not timers — they are readiness states. A countdown the player races against is a timer. If anyone proposes a default-mode timer, cite DEC-02 and Answer B verbatim.

**2. Dash is always nearly available.** With 2 charges and a ~45s cooldown, the player is rarely out of Dash. Any requirement that makes Dash scarce, locked, or unavailable for extended periods contradicts DEC-01 and DEC-08.

**3. Jam scope only.** Every story must be necessary for a submittable jam entry. Features that are "nice to have" or "good for a future release" are post-jam scope. Cite DEC-12 and the hard deadline when pushing back.

---

## Discovery Artifacts — Full Reference

All artifacts are in `docs/feature/dcjam2026-core/discover/`:

| File | Contents |
|------|----------|
| `problem-validation.md` | Validated problem, JTBD, G1 gate — PASS |
| `opportunity-tree.md` | OST with 7 opportunities scored, top 3 prioritized, G2 gate — PASS |
| `solution-testing.md` | 4 hypotheses, feasibility spikes, G3 gate — PENDING (spikes only) |
| `lean-canvas.md` | Full Lean Canvas, 4 big risks, Go/No-Go — GO, G4 gate — PASS |
| `wave-decisions.md` | 12 decisions, ruled-out directions, resolved and open questions |
| `interview-log.md` | Verbatim developer answers, 10 signals extracted |

---

## Go / No-Go

**GO.**

The concept is validated. The design space is defined. The unknowns are bounded. The three feasibility spikes are a build activity, not a discovery blocker — they can run in parallel with requirements work on the finalized decisions.

The product-owner may begin writing requirements immediately for:
- Dash mechanic (DEC-01, DEC-07, DEC-08)
- Dragon vocabulary / identity (DEC-04)
- Special attack feedback design (DEC-03, DEC-10)
- Floor structure (DEC-11)
- Egg discovery and exit relief beats (DEC-03, DEC-11)
- Narrative framing (DEC-05)

Requirements for combat actions (slash/brace), stat modification, and non-Dash combat movement must wait for the three open question confirmations.
