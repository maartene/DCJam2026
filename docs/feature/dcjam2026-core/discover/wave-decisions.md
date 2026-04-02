# Wave Decisions
**Feature**: dcjam2026-core
**Date**: 2026-04-02
**Author**: Scout (Product Discovery Facilitator)

This document records every significant design decision made during discovery, the evidence behind it, and what was explicitly ruled out. It serves as the handoff record to the product-owner wave.

---

## Decision Log

---

### DEC-01: Dash is the primary verb. Combat is opt-in.

**Date**: 2026-04-02
**Status**: FINAL

**Decision**: The game's primary locomotion mechanic is Dash — moving through enemy-occupied squares without engaging them. Combat exists but is a last resort, not the default.

**Evidence**:
- Developer Answer C (verbatim): "Dash — moving through enemies is not something I've seen done a lot."
- Developer framed Dash as the one mechanic that, if removed, makes the game not worth building.
- Genre gap confirmed: developer has actively looked and not found this done well.

**What this rules out**:
- Combat-forward design where the player is expected to engage most enemies
- Dash as a "bonus ability" — it must be available from turn 1
- Any mechanic that makes Dash less accessible than normal movement

**Implication for product-owner**: All requirements flowing from this decision must treat Dash as the core gameplay loop, not a special case.

---

### DEC-02: No timers. Stat modification mechanism is unresolved — milestone upgrades are the primary candidate.

**Date**: 2026-04-02
**Status**: FINAL for timer constraint — OPEN for stat modification mechanism

**Decision (hard constraint)**: No timer mechanics in the default game. The egg-cooking narrative is flavor text only — it does not function as a countdown.

**Decision (open)**: The jam requires at least one way to affect character stats. The specific mechanism is not yet resolved. Candidates, in priority order:
1. Milestone upgrade choices (developer's stated preference — select a stat upgrade at defined progression milestones)
2. Floor-based advantages (Pomander-style bonuses tied to dungeon floors, as in FFXIV Deep Dungeons)
3. Food items providing immediate stat boosts (valid option, but not the default assumption)

Food is **not** assumed to be the implementation. Documents must not treat food as the default stat-modification system. The mechanism selection is a product-owner decision to be made during the DISCUSS wave with the developer.

**Evidence**:
- Developer Answer B (verbatim): "Bad when it's only a (replenishable) timer. Only done right when it's a system in itself that provides buffs, has depth (like cooking) or story impact."
- Developer explicit preference: "I generally don't like timers in games anyway, unless they are a challenge mode."
- Developer clarification (post-discovery): Milestone upgrade choices are the preferred approach; food is one option among several, not the default.

**What this rules out**:
- Egg-cooking countdown as a gameplay mechanic
- Food depletion over time (hunger system)
- Any default-mode timer that creates anxiety pressure
- Assuming food is the stat modification system without explicit developer confirmation

**What is permitted**:
- An optional "swift completion" challenge mode with a timer, if the developer chooses to add it post-jam
- Structural timers if needed to prevent broken states (unlikely in a jam game)

**Implication for product-owner**: If any requirement mentions a countdown, timer, or depletion mechanic as a default feature, it must be challenged and traced back to this decision. The stat modification mechanism must be confirmed with the developer before writing requirements for it.

---

### DEC-03: Two emotional beats must be explicitly designed.

**Date**: 2026-04-02
**Status**: FINAL

**Decision**: Two moments in the game must receive dedicated design attention to achieve distinct emotional beats:
1. Special attack use → "badass" / power fantasy
2. Egg discovery + exit → "actual relief"

These are not the same moment and must not be designed the same way.

**Evidence**:
- Developer Answer A (verbatim): "I want the player to feel badass when using a special. But also actual relief when finding the egg and finding the exit."
- The developer used the word "actual" before "relief" — this signals that standard dungeon-crawler exits do not currently deliver this. It must be explicitly created.

**What this rules out**:
- Treating egg pickup as a standard item acquisition event
- Treating exit as a standard trigger with no moment of pause
- Using identical feedback for special attack and normal attack

**Implication for product-owner**: Requirements for special attack, egg discovery, and exit must each include a distinct feedback specification. Generic "show notification" is not acceptable for these three moments.

---

### DEC-04: Dragon identity is expressed through vocabulary, not only visuals.

**Date**: 2026-04-02
**Status**: FINAL

**Evidence**:
- The game is TUI (terminal user interface / ASCII). The primary layer of identity expression is text.
- Developer Answer A implies the dragon must feel like a creature with physical presence: "badass" is a bodily feeling, not an abstract score increase.
- Dash implies a specific kind of movement — surge, lunge, burst through — not "walk to adjacent square."

**Decision**: All combat and movement strings in the game must use dragon-appropriate vocabulary. Claw, fang, wing, roar, lunge, surge. No sword swings, no spell casts, no "attack" as a naked verb.

**What this rules out**:
- Generic combat text that could belong to any dungeon-crawler protagonist
- Reusing any template combat strings from non-dragon sources

**Implication for product-owner**: A content/text requirement exists for all combat and movement strings. This is not cosmetic — it is identity-layer design.

---

### DEC-05: Jam theme integration — dragon + "cleaning up the hero's mess"

**Date**: 2026-04-02
**Status**: RECOMMENDED (not hard-constrained)

**Decision**: The strongest jam theme combination is Dragons + "Cleaning up the hero's mess." The narrative frame: the hero adventured through a dragon's home, killed the dragon's parent (the mess), and stole the egg. The player is the young dragon reclaiming it.

**Evidence**:
- Jam rules require interpretation of at least one theme.
- This framing gives the egg narrative meaning, makes the exit emotionally loaded (escape with the egg = restore what was taken), and positions the player as a sympathetic escapee rather than an aggressor.
- "Cleaning up the hero's mess" directly maps to the dragon's JTBD.

**What this enables**:
- The hero's body/weapons/gear scattered through the dungeon can be environmental storytelling
- Enemies are guards left behind by the hero, not random monsters
- The egg is a personal mission, not a treasure hunt

**Implication for product-owner**: Narrative requirements should reference this framing. It is a recommendation, not a hard constraint — the developer may choose a different narrative approach.

---

### DEC-08: Dash charges — 2 charges, ~45s cooldown, configurable, progression tie-in

**Date**: 2026-04-02
**Status**: FINAL

**Decision**: Dash starts with a cap of 2 charges. Each charge replenishes on a cooldown of approximately 45 seconds (configurable). Progression upgrades can lower the cooldown or increase the charge cap — these are the primary upgrade levers tied to the stat modification system.

**Evidence**:
- Developer answer (2026-04-02): "Starts with cap of 2 charges, each replenishing on cooldown (~45s, configurable). Progression tie-in: upgrades can lower cooldown or increase charge cap."

**What this resolves**:
- Open question on whether Dash has a resource gate (it does — 2 charges)
- Open question on what refills Dash charges (time-based cooldown, not room completion or food)
- Confirms that Dash is nearly always available (2 charges + ~45s refill = persistent availability, not a scarce resource)

**What this rules out**:
- Dash as unlimited / always available with no resource constraint
- Dash charges refilling from food, room completion, or enemy kills (none of these — cooldown only, unless a future design adds them)
- Single-charge Dash (cap is 2, so the player almost always has one available)

**Design implication**: Two charges means the player is rarely truly out of Dash. The resource model reinforces Dash as the primary locomotion verb — it is throttled, not locked. The ~45s cooldown is the strategic layer: use both charges and you have a brief window of vulnerability, not a long deprivation.

**Implication for product-owner**: Requirements for Dash must include: (a) charge count display in UI, (b) cooldown timer / readiness indicator, (c) upgrade path hooks for cooldown reduction and charge cap increase.

---

### DEC-09: Elemental Rock Paper Scissors — out of scope

**Date**: 2026-04-02
**Status**: FINAL

**Decision**: The Elemental RPS jam theme is not incorporated into the game design. It is explicitly out of scope.

**Evidence**:
- Developer answer (2026-04-02): "Out. Not in scope."

**What this rules out**:
- Any elemental type system applied to enemies, attacks, or abilities
- Any damage modifier based on elemental affinity
- SOL-T from the OST (Elemental Rock Paper Scissors as encounter type system) — cancelled

**Implication for product-owner**: No requirements related to elemental types, affinities, or RPS mechanics. If the jam judges ask about elemental theme interpretation, the answer is: the game uses the "Dragons" and "Cleaning up the hero's mess" themes; Elemental RPS is not interpreted.

---

### DEC-10: Special attack — available from start, no initial charge (organic Dash teaching)

**Date**: 2026-04-02
**Status**: FINAL

**Decision**: The special attack is unlocked from the start of the game but has no charge in the initial state — the charge meter starts empty. Because the cooldown for special is long enough that the special is not yet available when the player first encounters an enemy, Dash becomes the logical first choice without any tutorial instruction.

**Evidence**:
- Developer answer (2026-04-02): "Starts unlocked but with no charge (charge meter starts empty). Cooldown is long enough that on the first enemy encounter, Dash is the logical choice. This elegantly solves the 'how to teach players that Dash is primary' problem — no tutorial needed, the mechanics teach themselves."

**What this resolves**:
- Open question on whether special is locked or available at start (available — but empty)
- The usability risk in G3 (lean-canvas.md Risk 2): "how do players learn Dash is primary" — resolved by mechanical state, not tutorial text

**What this rules out**:
- Tutorial pop-up explaining that Dash is the primary verb
- Locking special behind an unlock condition (it is available but uncharged)
- Any design where the special is recharged fast enough to be the first-encounter option

**Design elegance note**: This decision converts a usability risk into a mechanical teaching moment. The first encounter communicates the game's design philosophy without a word of tutorial text. The developer identified this as an organic solution.

**Implication for product-owner**: Requirements for the special attack must specify: (a) starts available, (b) charge meter starts at 0, (c) charge rate is calibrated so that first-encounter special use is not possible. The UI must show the charge meter clearly so the player reads "empty" and naturally looks for the other option.

---

### DEC-11: Floor count — minimum 3, target 5, defined structure

**Date**: 2026-04-02
**Status**: FINAL

**Decision**:
- Minimum viable: 3 floors
- Target for submission: 5 floors
- Floor structure (5-floor target):
  - Floor 1: Starter floor (introduces mechanics, low threat, teaches Dash via DEC-10)
  - Floors 2–4: Regular floors (one of these contains the egg)
  - Floor 5: Boss floor + exit patio (boss encounter, then the exit relief beat)

**Evidence**:
- Developer answer (2026-04-02): "Minimum: 3 floors. Target: 5 floors — Floor 1: starter floor, Floors 2-4: regular floors (one contains the egg), Floor 5: boss + exit patio."

**What this resolves**:
- Open question on level count (was fully unresolved)
- Placement of the egg: it is on one of Floors 2–4, not Floor 1 (no free egg) and not Floor 5 (the boss floor has the exit, not the egg)
- The two emotional beats now have structural homes: egg discovery on a mid-floor, exit relief beat on Floor 5 after the boss

**What this rules out**:
- Single-floor structure (too few beats)
- Egg on Floor 1 (too fast, no earned relief)
- Egg and exit on the same floor other than as stated (egg is mid-game, exit is Floor 5)
- More than 5 floors for the jam entry (scope discipline — 3 is the floor, 5 is the ceiling)

**Implication for product-owner**: Floor structure must be treated as a first-class requirement, not an implementation detail. Each floor type (starter / regular / boss) has different generation constraints. The product-owner must write separate requirements for Floor 1 (tutorial context), Floors 2–4 (egg placement logic), and Floor 5 (boss + exit patio design).

---

### DEC-12: Scope — jam-only

**Date**: 2026-04-02
**Status**: FINAL

**Decision**: This entry is scoped for the jam only. Post-jam expansion is acknowledged as a possibility (every jam entry tests a concept) but is explicitly out of scope for this discovery and the resulting requirements.

**Evidence**:
- Developer answer (2026-04-02): "Jam-only (with acknowledgment that every jam entry tests a concept)."
- lean-canvas.md Section 6 (Revenue Streams) previously noted post-jam potential as an aside — that framing is now formalized as out of scope.

**What this rules out**:
- Requirements designed for post-jam expansion (save systems, content pipelines, modding hooks, etc.)
- Any feature that is not necessary for a completable 3–5 floor jam submission
- Feasibility spikes for features only relevant to a longer-form product

**What this permits**:
- Architecture decisions that do not actively prevent future expansion (i.e., don't foreclose it — but don't design for it)
- Post-jam feedback collection as a concept test (passive, no build required)

**Implication for product-owner**: Every user story must pass a jam-scope filter: "Is this necessary for a playable, submittable jam entry?" If not, it is post-jam scope and must be deferred.

---

### DEC-06: Feasibility spikes required before feature requirements

**Date**: 2026-04-02
**Status**: BLOCKING for G3/G4

**Decision**: Three technical questions must be answered before writing feature requirements for the core mechanics. These are not design decisions — they are feasibility checkpoints.

1. Can the grid movement model support pass-through (Dash) as a distinct movement mode from normal movement?
2. Can the TUI layer interrupt dungeon rendering for a full-screen narrative event (egg discovery, exit)?
3. Can the special attack render visually distinct from normal combat in a terminal environment?

**What this rules out**:
- Writing detailed feature requirements before spike results are known
- Assuming the Swift/terminal stack supports all three without testing

**Implication for product-owner**: Do not generate user stories for Dash, egg discovery, or special attack until the developer has run these spikes and reported results. The fallback designs in solution-testing.md are available if any spike fails.

---

### DEC-07: Combat must support movement — Dash takes priority over "no movement in combat"

**Date**: 2026-04-02
**Status**: FINAL — supersedes earlier interview statement

**Decision**: During discovery the developer stated that fights occur without movement. This contradicts the Dash mechanic, which by definition requires movement through enemy-occupied squares. **Dash takes priority.** Combat must support at least the degree of movement that Dash requires to function.

The "no movement in combat" statement from the interview is superseded. It likely reflected a mental model of turn-based static combat, but that model is incompatible with the game's irreducible core mechanic.

**What this means in practice**:
- The player can move during a combat encounter — at minimum to execute a Dash
- Whether non-Dash movement is also permitted (e.g., repositioning, retreating) is a separate open design question
- Combat design must not lock the player in place in a way that prevents Dash activation

**What this rules out**:
- Fully static combat in which the player cannot move at all
- Any design where Dash is disabled or unavailable during an active combat encounter

**Implication for product-owner**: Combat requirements must not include a "no movement" constraint. Movement in combat is at minimum "at least Dash-capable." Full movement freedom in combat is a separate decision the developer has not yet made.

---

## Ruled-Out Design Directions

These directions were explicitly considered and rejected during discovery. They must not re-enter requirements without new evidence.

| Direction | Reason Rejected | Evidence |
|---|---|---|
| Food-as-timer / hunger system | Developer explicit preference against timers as default mechanics | Answer B |
| Egg-cooking countdown | Invalidated — narrative flavor only | Answer B |
| Food as the default stat-modification system | Developer prefers milestone upgrade choices; food is one option among several | Developer clarification (post-discovery) |
| Fully static combat (no movement allowed) | Contradicts Dash mechanic; Dash takes priority — superseded by DEC-07 | DEC-07 |
| Combat-first encounter design | Dash is primary verb; combat is last resort | Answer C |
| Generic combat text strings | Dragon identity requires specific vocabulary | Answer A + DEC-04 |
| Dash as locked or resource-gated ability | Would undermine it as primary verb — must be accessible | DEC-01 |
| Elemental Rock Paper Scissors system | Developer: explicitly out of scope | DEC-09 |
| Tutorial text to teach Dash priority | DEC-10: mechanical state teaches this organically — empty special charge on encounter 1 | DEC-10 |
| Post-jam expansion features in jam requirements | Scope is jam-only; expansion is not in scope | DEC-12 |

---

## Open Questions

### Resolved (2026-04-02)

These questions were open at discovery close and have since been answered by the developer. See the corresponding DEC entries for full rationale.

| # | Question | Resolution | DEC |
|---|----------|------------|-----|
| 1 | Dash charges: charge model and refill | 2 charges, ~45s cooldown, configurable. Progression can lower cooldown or raise cap. | DEC-08 |
| 5 | Elemental Rock Paper Scissors: in scope? | Out of scope. Not incorporated. | DEC-09 |
| 7 | Special attack unlock: locked or available from start? | Available from start, charge meter begins empty. First encounter teaches Dash organically. | DEC-10 |
| 6 | Level count: how many floors? | Minimum 3, target 5. Defined structure: Floor 1 starter, Floors 2–4 regular (egg on one), Floor 5 boss + exit. | DEC-11 |
| 8 | Post-jam potential: jam-only or expand? | Jam-only. Expansion acknowledged as possible concept test but explicitly out of scope. | DEC-12 |

### Still Open (for product-owner wave)

These three questions remain unresolved and must be confirmed with the developer before the corresponding requirements are written:

1. **Slash attack — omit or retain?**: The developer is considering removing the slash attack entirely, leaving the combat action set as: Brace, Special, Dash. Risk if omitted: players may feel option-starved in situations where Dash is on cooldown and Special charge needs to be conserved. Do not assume it is included or excluded until the developer makes an explicit call.

2. **Stat modification mechanism**: Milestone upgrade choices are the developer's stated preference, but the mechanism has not been formally decided. Options: (a) milestone upgrade choices — choose a stat upgrade at defined progression milestones, (b) floor-based advantages (Pomander-style), (c) food items providing immediate stat effect. Confirm selection before writing requirements. (See also DEC-02. Note: DEC-08 establishes that charge cap and cooldown are upgrade levers — these feed whichever mechanism is chosen.)

3. **Non-Dash movement in combat**: DEC-07 establishes that Dash movement must be possible in combat. Whether the player can also reposition or retreat freely (non-Dash movement) during a combat encounter is not yet decided.

---

## Handoff Status

| Phase | Gate | Status |
|---|---|---|
| Phase 1: Problem Validation | G1 | PASS |
| Phase 2: Opportunity Mapping | G2 | PASS |
| Phase 3: Solution Testing | G3 | PENDING — feasibility spikes required (design decisions now complete) |
| Phase 4: Market Viability | G4 | PASS (conditional on G3 feasibility spikes) |

**Decisions DEC-01 through DEC-12 are finalized.** Five previously open questions are now resolved (DEC-08 through DEC-12). Three questions remain open for the product-owner wave (slash attack, stat modification mechanism, non-Dash combat movement).

**G3 assessment**: The five new decisions close all remaining design unknowns. G3 is no longer blocked on design — it is blocked only on the three feasibility spikes (DEC-06). Those spikes are a build activity, not a discovery activity. The product-owner wave may begin requirements work on all finalized decisions immediately. Spike-dependent requirements (Dash pass-through, full-screen TUI event, special attack visual distinction) should be flagged as "pending spike confirmation" in the backlog.

**Handoff to product-owner is ready.**
