# Shared Artifacts Registry
**Feature**: dcjam2026-core
**Date**: 2026-04-02
**Author**: Luna (Product Owner — DISCUSS wave)

This registry defines every shared data artifact that crosses story or component boundaries. Each entry specifies the single source of truth, which stories read it, and the integration risk.

---

## Registry

### SA-01: GameState.dashCharges

| Field | Value |
|-------|-------|
| Description | Current number of available Dash charges (0, 1, or 2) |
| Type | Integer, 0 to dashChargesCap |
| Default | 2 at game start |
| Source of truth | GameState (single game session object) |
| Modified by | Dash action (decrements), cooldown completion (increments) |
| Read by | Status bar display, encounter action list, Dash action handler |
| Stories | US-01, US-02, US-05 |
| Integration risk | HIGH — status bar and action list must both reflect the same value; stale reads cause wrong action availability |

---

### SA-02: GameState.dashCooldownRemaining

| Field | Value |
|-------|-------|
| Description | Seconds remaining until the next Dash charge replenishes |
| Type | Float, 0.0 to ~45.0 (configurable) |
| Default | 0.0 at game start (no cooldown active) |
| Source of truth | GameState |
| Modified by | Dash action (starts cooldown timer), game loop (decrements each tick) |
| Read by | Status bar display (cooldown indicator), Brace screen display |
| Stories | US-02, US-05 |
| Integration risk | MEDIUM — cooldown must tick on the game loop, not only on player input |

---

### SA-03: GameState.specialCharge

| Field | Value |
|-------|-------|
| Description | Current special charge level, 0 (empty) to specialChargeMax (full) |
| Type | Float or stepped integer |
| Default | 0 at game start (empty — DEC-10) |
| Source of truth | GameState |
| Modified by | Passage of time / game ticks (increments), Special use (resets to 0) |
| Read by | Status bar display, encounter action list, Special action handler |
| Stories | US-01, US-03, US-06 |
| Integration risk | HIGH — must be 0 at first encounter (DEC-10 organic teaching); charge rate must be calibrated so Special cannot be used at first encounter |

---

### SA-04: GameState.hasEgg

| Field | Value |
|-------|-------|
| Description | Whether Ember is carrying the egg |
| Type | Boolean |
| Default | false at game start |
| Source of truth | GameState |
| Modified by | Egg room entry event (sets to true) |
| Read by | Status bar EGG indicator, win condition check, exit square handler |
| Stories | US-07, US-10 |
| Integration risk | HIGH — win condition requires BOTH hasEgg == true AND player at exit; exit check must read this value |

---

### SA-05: GameState.currentFloor

| Field | Value |
|-------|-------|
| Description | The floor number the player is currently on (1 through 5) |
| Type | Integer, 1 to maxFloors |
| Default | 1 at game start |
| Source of truth | GameState |
| Modified by | Stairs action (increments) |
| Read by | Floor display, egg room placement logic, boss encounter flag, exit patio trigger |
| Stories | US-04, US-07, US-09, US-10 |
| Integration risk | MEDIUM — multiple systems read this; floor-specific behaviors (boss, egg, exit) must key off this value |

---

### SA-06: GameState.hp

| Field | Value |
|-------|-------|
| Description | Player's current hit points |
| Type | Integer, 0 to maxHp |
| Default | maxHp at game start |
| Source of truth | GameState |
| Modified by | Enemy attacks (decrements), upgrade effects (modifies maxHp) |
| Read by | Status bar HP bar, death condition check |
| Stories | US-02, US-08, US-11 |
| Integration risk | MEDIUM — death check must read 0 condition; HP display must render as bar not raw number |

---

### SA-07: GameState.activeUpgrades

| Field | Value |
|-------|-------|
| Description | List of upgrade IDs the player has selected at milestones this run |
| Type | Array of upgrade IDs |
| Default | Empty at game start |
| Source of truth | GameState |
| Modified by | Milestone upgrade selection |
| Read by | Dash cooldown calculator, HP max calculator, Special charge rate calculator |
| Stories | US-08 |
| Integration risk | MEDIUM — upgrade effects must be applied to the right derived values, not stored as overrides |

---

### SA-08: FloorMap.eggRoomId

| Field | Value |
|-------|-------|
| Description | The room/square identifier for the egg room on the current run |
| Type | Room or square identifier |
| Default | Assigned at floor generation time |
| Source of truth | FloorMap (generated per run) |
| Constraints | Must be on one of floors 2–4; not Floor 1; not Floor 5; placement not biased toward Floor 2 |
| Read by | Egg discovery event trigger |
| Stories | US-07 |
| Integration risk | MEDIUM — placement logic must enforce floor constraints; event must fire exactly once per run |

---

### SA-09: FloorMap.exitPosition

| Field | Value |
|-------|-------|
| Description | The grid position of the dungeon exit on Floor 5 |
| Type | Grid coordinate |
| Default | Assigned at Floor 5 generation time |
| Source of truth | FloorMap |
| Read by | Win condition check (position == exit AND hasEgg), exit patio event trigger |
| Stories | US-10 |
| Integration risk | HIGH — win condition must check both SA-04 (hasEgg) and player position matching this value |

---

### SA-10: UpgradePool

| Field | Value |
|-------|-------|
| Description | The full set of available upgrade options for milestone prompts |
| Type | Array of upgrade definitions (id, label, description, effect) |
| Default | 6–8 upgrades defined at design time |
| Source of truth | Game design data (static, defined in DESIGN wave) |
| Constraints | Must include at minimum: Dash cooldown reduction, Dash charge cap increase. Other entries fill to 6–8. |
| Read by | Milestone upgrade prompt (draws 3 at random), GameState.activeUpgrades |
| Stories | US-08 |
| Integration risk | LOW — static data; risk is in the draw (must not repeat selected upgrades in same run) |

---

### SA-12: ThoughtsLog

| Field | Value |
|-------|-------|
| Description | The ordered list of dragon inner-monologue lines shown in the Thoughts panel |
| Type | Array of strings (most recent last) |
| Default | Empty at game start |
| Source of truth | GameState or dedicated ThoughtsLog component |
| Modified by | Game event triggers: entering a floor, encountering an enemy, using Dash, finding the egg, taking damage, bracing, etc. |
| Read by | Thoughts panel (Region 3 of main screen layout) |
| Stories | US-01 (game start), US-02 (Dash), US-03 (Special), US-05 (Brace), US-07 (Egg), US-10 (Exit) |
| Integration risk | LOW — display-only; risk is that events do not fire their thought triggers, leaving the panel empty |

---

### SA-13: ScreenLayout

| Field | Value |
|-------|-------|
| Description | The three fixed regions of the main game screen: (1) first-person 3D view, (2) status line, (3) Thoughts panel |
| Type | Structural layout definition (not a runtime value) |
| Default | Three regions always rendered during dungeon navigation |
| Source of truth | DISC-04 developer mockup (authoritative) |
| Constraints | Regions must not overlap; status line is always exactly one line; Thoughts panel shows at minimum 3 lines; layout resumes immediately after full-screen narrative events |
| Read by | Renderer / TUI layout manager |
| Stories | US-01 (status line), all navigation stories |
| Integration risk | MEDIUM — full-screen narrative events (egg, special, exit) must correctly restore this layout on dismissal |

---

### SA-11: BossEncounterFlag

| Field | Value |
|-------|-------|
| Description | Whether the current encounter is the boss (Dash-blocked) encounter |
| Type | Boolean, per-encounter |
| Default | false for all regular encounters |
| Source of truth | FloorMap / encounter definition |
| Constraints | Only one boss encounter exists, on Floor 5 |
| Read by | Encounter action list (blocks Dash when true), boss-specific encounter text |
| Stories | US-09 |
| Integration risk | MEDIUM — Dash blocking must read this flag, not infer from floor number alone |

---

## Integration Risk Summary

| Risk Level | Count | Artifacts |
|------------|-------|-----------|
| HIGH | 3 | SA-01 (dash charges), SA-03 (special charge start=0), SA-04 + SA-09 (win condition pair) |
| MEDIUM | 6 | SA-02, SA-05, SA-06, SA-07, SA-08, SA-11, SA-13 (screen layout restoration) |
| LOW | 2 | SA-10, SA-12 (thoughts log) |

### Critical Integration Checkpoint: Win Condition

The win condition requires BOTH SA-04 (hasEgg == true) AND player position == SA-09 (exitPosition). These are two independent state variables from two different sources. The win condition check must query both. Testing must verify that neither condition alone triggers the win state.

### Critical Integration Checkpoint: First Encounter Teaching Moment

SA-03 (specialCharge) must be 0 at the moment the player first encounters an enemy. This is a calibration requirement — the Special charge rate must be slow enough that no natural charge accumulation between game start and the first encounter can fill the meter. The DESIGN wave must specify the charge rate with this constraint in mind.
