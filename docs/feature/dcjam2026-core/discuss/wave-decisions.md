# Wave Decisions — DISCUSS Wave
**Feature**: dcjam2026-core
**Date**: 2026-04-02
**Author**: Luna (Product Owner — DISCUSS wave)

This document records all decisions locked at the start of the DISCUSS wave, incorporating the three resolved open questions from the DISCOVER wave handoff.

---

## Resolved Open Questions (Pre-DISCUSS)

These three questions were open at DISCOVER handoff and have now been confirmed by the developer.

---

### DISC-01: Combat action set — Brace + Dash + Special only (no slash/melee)

**Date**: 2026-04-02
**Status**: FINAL

**Decision**: The player's combat action set is exactly three verbs: Brace, Dash, Special. No slash or physical melee attack.

**Developer quote**: "less == more. Start with Brace + Dash + Special. If it feels bad because you need to wait too much, we can see if a physical melee attack helps."

**Implication**: The window when Dash is on cooldown AND Special is uncharged is intentional strategic pressure. The player's only non-movement option is Brace. This is a design choice, not a gap. If playtesting reveals this window feels oppressive, a melee attack is the named fallback — but it is out of scope for this development cycle.

**What this rules out**:
- Any melee/slash attack requirement in this release
- Requirements that treat the "Dash on cooldown + Special empty" state as a problem to fix

**Implication for requirements**: Combat stories must be written around Brace + Dash + Special. The strategic tension of the option-starved window must be acknowledged in requirements, not eliminated.

---

### DISC-02: Stat modification mechanism — Milestone upgrade choices (Option A)

**Date**: 2026-04-02
**Status**: FINAL (Option A selected)

**Decision**: Stat modification is implemented via milestone upgrade choices. At defined progression milestones (after clearing certain floors), the player chooses from a pool of upgrades. Pool size: 6-8 upgrades. Primary upgrade levers: Dash cooldown reduction and Dash charge cap increase.

**Developer quote**: "Let's go A. If there's time left, it should probably be spent on tuning the options."

**Implication**: The upgrade pool design is important but secondary to the core loop. Floor bonuses (Option B, Pomander-style) are a possible supplement if development reaches a slack period — not in scope now.

**What this rules out**:
- Food as the default stat-modification mechanic (still valid as flavor, not as stats)
- Floor-based Pomander-style bonuses (possible supplement only, not in scope)
- Any depletion-based or timer-based stat system

**Implication for requirements**: One story required for milestone upgrade prompt. Pool definition (6-8 upgrades) is a design detail for the DESIGN wave — requirements specify the interaction pattern, not the specific upgrades.

---

### DISC-03: Combat movement — No free movement; Dash breaks out and makes progress

**Date**: 2026-04-02
**Status**: FINAL

**Decision**: Normal step movement is locked when the player is adjacent to an enemy (i.e., in an active encounter). Dash is the only way to leave the encounter. When the player Dashes during an encounter, they exit the encounter AND advance 3 squares forward — moving closer to the dungeon exit.

**Developer quote**: "What differentiates this from a 'run' action is that 'run' is typically an escape — you get out of the encounter but don't make progress. Dash means progress because you get further in the dungeon → closer to the exit."

**Implication**: Dash is not an escape mechanic. It is a forward-movement mechanic that also exits encounters. This distinction is the core differentiation of the game. Using Dash in combat is always the optimal move if the player wants to reach the exit — it is simultaneously evasion and progression.

**What this rules out**:
- Free repositioning or retreating during encounters
- Dash framed as "run away" — it is always forward
- Movement-locked combat that prevents Dash (superseded by DEC-07)

**Implication for requirements**: Combat requirements must specify that normal movement is locked in encounters. Dash in combat must be specified as "exit encounter + advance 3 squares." The exit-and-advance behavior is the mechanic that must be tested.

---

### DISC-04: Screen layout — three-region TUI as defined by developer mockup

**Date**: 2026-04-02
**Status**: FINAL

**Decision**: The main game screen has exactly three fixed regions: (1) first-person 3D view (upper, primary play area), (2) status line (single line), (3) Thoughts panel (bottom, dragon inner monologue). The developer provided an authoritative ASCII mockup establishing this layout, recorded in REQ-12 and `journey-dragon-escape-visual.md`.

**Status line content**: HP bar, EGG indicator, and all three actions with keyboard shortcuts — `(1)DASH [N](cd=Xs)`, `(2)BRACE`, `(3)SPEC [====]` — displayed on a single line at all times during dungeon navigation.

**Thoughts panel**: A scrolling log of dragon-voice inner monologue triggered by game events. Not a system log. Examples: "I can feel my egg on this floor!", "That was easy", "I'm yearning for the light."

**Combat screen**: Combat CAN take place on a separate dedicated screen (jam rules explicitly allow this as an exception to first-person exploration). When combat ends, the three-region layout resumes immediately.

**Combat mode — real-time (CORRECTION)**: Combat is real-time, not turn-based. A prior note in discovery contained a typo stating "turn-based" — that was incorrect and has been corrected here. The developer confirmed combat is real-time. The UI must make this apparent; no Wizardry-style turn menu feel.

**Implication for requirements**: REQ-12 (screen layout) and REQ-13 (combat screen) define the structural and combat display requirements respectively. SA-13 (ScreenLayout) is the shared artifact tracking layout restoration after full-screen events.

**What this rules out**:
- Hidden or collapsible status line during navigation
- Thoughts panel used for system/debug messages
- Turn-based combat UI (per-turn numbered menus with waiting cursor)

---

## Inherited Decisions (from DISCOVER wave — all FINAL)

| Decision | Summary | Source |
|----------|---------|--------|
| DEC-01 | Dash is primary verb. Combat is opt-in. | discover/wave-decisions.md |
| DEC-02 | No timers as default mechanics. | discover/wave-decisions.md |
| DEC-03 | Two emotional beats explicitly designed: power (special) and relief (egg + exit). | discover/wave-decisions.md |
| DEC-04 | Dragon vocabulary in all combat/movement strings. | discover/wave-decisions.md |
| DEC-05 | Narrative frame: dragon reclaiming stolen egg from the hero who killed its parent. | discover/wave-decisions.md |
| DEC-08 | Dash: 2 charges, ~45s cooldown, configurable. Progression upgrades: cooldown reduction + charge cap increase. | discover/wave-decisions.md |
| DEC-09 | Elemental Rock Paper Scissors: explicitly out of scope. | discover/wave-decisions.md |
| DEC-10 | Special starts available but with empty charge meter. First encounter teaches Dash organically. | discover/wave-decisions.md |
| DEC-11 | Floor structure: minimum 3, target 5. Floor 1 starter, Floors 2-4 regular (egg on one), Floor 5 boss + exit patio. | discover/wave-decisions.md |
| DEC-12 | Scope: jam-only. Every feature must be necessary for a submittable entry. | discover/wave-decisions.md |

---

## Three Non-Negotiable Constraints (inherited)

1. **No timers as default mechanics.** Cooldown (Dash charge refill) is a readiness state, not a timer. Any countdown mechanic in the default game is a violation of DEC-02.
2. **Dash is always nearly available.** 2 charges + ~45s cooldown = persistent availability. Requirements that make Dash scarce contradict DEC-01 and DEC-08.
3. **Jam scope only.** Every story must be necessary for a submittable jam entry. DEC-12 is a hard filter.

---

## What Is Out of Scope (consolidated)

| Feature | Reason |
|---------|--------|
| Slash / melee attack | DISC-01: post-jam fallback only |
| Floor-based stat bonuses (Pomander) | DISC-02: possible supplement, not in scope |
| Food-as-stat-modification | DEC-02: not the default system |
| Egg-cooking countdown | DEC-02: narrative flavor only |
| Elemental RPS | DEC-09: explicitly excluded |
| Free repositioning in combat | DISC-03: only Dash can exit encounters |
| Post-jam expansion features | DEC-12: jam scope only |
| Tutorial text for Dash | DEC-10: mechanical state teaches organically |
