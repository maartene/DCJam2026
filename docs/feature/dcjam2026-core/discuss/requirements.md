# Requirements — Dragon Escape
**Feature**: dcjam2026-core
**Date**: 2026-04-02
**Author**: Luna (Product Owner — DISCUSS wave)

All requirements trace to discovery decisions. Every requirement must pass the jam-scope filter: "Is this necessary for a submittable jam entry?" (DEC-12)

---

## REQ-01: Dash — Primary Locomotion Verb

**Traces to**: DEC-01, DEC-07, DEC-08, DISC-03
**Priority**: Must Have

The player can move through enemy-occupied squares using Dash without engaging the enemy in a blocking exchange. Dash is the primary locomotion verb — it is available from the first moment of the game and must never be locked out entirely.

### Rules
- Dash has a cap of 2 charges at game start.
- Each charge replenishes individually on a cooldown of approximately 45 seconds (configurable).
- Dash charges are consumed one per use.
- When the player uses Dash during an active encounter (adjacent enemy), Ember exits the encounter AND advances 3 squares forward.
- Normal step movement is locked when the player is adjacent to an enemy. Dash is the only way to move forward in that state.
- The Dash charge count and cooldown state must be legible in the status bar at all times.
- Dash must not be blocked for any enemy except the boss (see REQ-09).

### What This Is Not
- Dash is not an escape mechanic (the player does not escape, they advance).
- Dash is not infinite (charges are consumed).
- Dash charges are not locked behind a timer the player races against (cooldown is a readiness state, not pressure).

---

## REQ-02: Special Attack — Power Beat

**Traces to**: DEC-03, DEC-04, DEC-10
**Priority**: Must Have

The special attack is available from the start of the game but has an empty charge meter. The charge meter fills over time. When the meter is full, the player may activate the Special.

### Rules
- Special charge starts at 0 at game start (DEC-10).
- Special charge rate must be calibrated so that the special cannot be used on the first enemy encounter.
- When Special is activated (charge == full), a full-screen or ASCII-bordered visual event interrupts the normal dungeon display.
- The special event text uses dragon-specific vocabulary: breath, fire, roar, fang, claw.
- After use, the Special charge meter resets to 0.
- In the encounter action list, Special is shown but marked unavailable when charge is below full.
- The charge meter must be legible in the status bar at all times.

### What This Is Not
- Special is not locked behind an unlock condition (it is available but uncharged).
- The special visual is not the same design as the egg discovery or exit patio events.

---

## REQ-03: Brace — Defensive Action

**Traces to**: DISC-01, DISC-03
**Priority**: Must Have

When an enemy is adjacent, the player can select Brace to absorb reduced damage and wait for Dash charges to replenish or Special to charge.

### Rules
- Brace is always available in encounters.
- Brace reduces incoming damage (exact reduction is a design detail for DESIGN wave).
- Brace combat text uses dragon vocabulary: wings, scales, endurance.
- Brace is the only action available when both Dash charges are depleted and Special is not charged.
- The option-starved window (Brace-only state) is intentional. Requirements must not eliminate it.

---

## REQ-04: Floor Structure

**Traces to**: DEC-11
**Priority**: Must Have

The game has between 3 (minimum viable) and 5 (target) floors. Each floor type has distinct generation rules and content constraints.

### Floor Types
- **Floor 1 (Starter)**: Low enemy density. First encounter is guaranteed to have Dash ready and Special empty. No egg room.
- **Floors 2–4 (Regular)**: Increasing enemy density. Exactly one floor in this range contains the egg room. Egg placement is not biased toward Floor 2.
- **Floor 5 (Boss + Exit)**: Contains the boss encounter. Contains the exit patio. Does not contain the egg room.

### Rules
- Staircase is reachable from the entry point on each floor.
- Descent via staircase increments the floor counter.
- The player's position is reset to the floor entry point on descent.

---

## REQ-05: Egg Discovery — Relief Beat

**Traces to**: DEC-03, DEC-05, DEC-11
**Priority**: Must Have

When the player enters the egg room, a dedicated narrative event fires. This is not a standard item pickup.

### Rules
- A full-screen or large-text narrative event fires on egg room entry.
- The screen holds — the player must press a key to continue.
- After confirmation, the EGG indicator activates in the status bar.
- The event text is written in dragon-narrative voice and references the narrative frame (DEC-05): the egg is personal, the mission is clear.
- The event text is distinct from any standard item pickup or room description text.
- The egg room appears on exactly one floor in the range Floors 2–4.
- The egg cannot appear on Floor 1 or Floor 5.

---

## REQ-06: Exit Patio — Final Relief Beat

**Traces to**: DEC-03, DEC-05, DEC-11
**Priority**: Must Have

When the player reaches the exit square on Floor 5 while carrying the egg, a dedicated narrative event fires. This is the win state.

### Rules
- Win condition requires BOTH: player position == exit square AND hasEgg == true.
- A full-screen narrative event fires with the exit patio description.
- Pacing is slow — text does not rush. The player must press a key to continue.
- Event text references the egg, the hero's mess, and the journey.
- After confirmation, the win state is declared.
- If the player reaches the exit without the egg, the exit is blocked or the player receives a prompt to retrieve the egg first. The win state is not declared.

---

## REQ-07: UI State Legibility

**Traces to**: DEC-08, DEC-10
**Priority**: Must Have

The status bar must display all player state variables readably at all times. This bar is the game's only "tutorial."

### Required elements
- HP bar (visual bar, not raw number)
- DASH charge count (e.g., [2], [1], [0])
- DASH cooldown indicator (visible when at least one charge is on cooldown)
- SPEC charge meter (visual bar, empty = 0, full = ready)
- EGG indicator (inactive / active toggle)

### Rules
- All five elements are visible from game start.
- SPEC meter shows 0 (empty) at game start.
- DASH shows 2 at game start.
- UI updates on every state change — no lag between state and display.
- The action list in encounters reflects live state (e.g., Dash greyed when 0 charges; Special greyed when not full).

---

## REQ-08: Milestone Upgrade Choice

**Traces to**: DISC-02, DEC-08
**Priority**: Must Have (jam stat-modification rule)

At defined progression milestones, the player is presented with an upgrade prompt and chooses one upgrade from a pool.

### Rules
- Upgrade pool contains 6–8 distinct upgrades.
- The prompt displays exactly 3 upgrades drawn from the pool.
- Player selects one upgrade; it applies immediately.
- Upgrade effects persist for the rest of the run.
- Primary upgrade levers: Dash cooldown reduction, Dash charge cap increase.
- Secondary upgrade types may include: max HP increase, Special charge rate improvement.
- Milestones occur at defined floor transitions (design detail for DESIGN wave).
- The upgrade prompt uses dragon-appropriate language for upgrade names.

---

## REQ-09: Boss Encounter — Dash Blocked

**Traces to**: DEC-11, DISC-01
**Priority**: Should Have

The boss on Floor 5 is the only encounter type that cannot be Dashed through. The player must use Brace and Special to defeat the boss.

### Rules
- Dash is shown in the action list but marked unavailable during the boss encounter.
- A brief explanation is displayed: the guardian cannot be passed.
- The boss is the only encounter type where Dash is blocked.
- Boss blocking is defined by an encounter flag (BossEncounterFlag), not inferred from floor number.
- After the boss is defeated, the exit patio is reachable.

---

## REQ-10: Dragon Vocabulary

**Traces to**: DEC-04, DEC-05
**Priority**: Must Have

All combat and movement strings use dragon-appropriate vocabulary. Generic dungeon-hero language is not permitted.

### Rules
- Movement text: surge, lunge, burst, dash through.
- Defensive text: scales, wings, endure, absorb.
- Special attack text: breath, fire, roar, fangs, claw.
- Egg and exit narrative: personal, warm, emotional — not triumphant or heroic.
- The word "attack" as a naked verb is not used. "You attack" → "You lunge," "You rake," "You breathe fire."
- No text strings from generic dungeon-crawler templates.

---

## REQ-11: Death Condition

**Traces to**: DEC-12 (jam requirement)
**Priority**: Must Have

When HP reaches 0, the game enters the death/fail state.

### Rules
- Death fires when GameState.hp <= 0.
- A death screen is shown with dragon-vocabulary message.
- The player is offered a restart option.
- Death is distinct from the win state.

---

## REQ-12: Main Screen Layout — Three-Region TUI

**Traces to**: DISC-04
**Priority**: Must Have

The main game screen is composed of exactly three regions, as established by the developer mockup. These regions are always present during dungeon navigation and must not overlap or obscure each other.

### Regions

1. **First-person 3D view** (upper area, primary play area)
   - Renders an ASCII/character art dungeon view from Ember's perspective.
   - This is the largest region and the player's primary visual focus.

2. **Status line** (single line between 3D view and Thoughts panel)
   - Always visible. Contains all five state indicators on a single line:
     - `HP [=========-] 90%` — health bar
     - `EGG [*]` — egg status indicator (active `[*]` or inactive `[ ]`)
     - `(1)DASH [1](cd=12s)` — keyboard shortcut `1`, current charges `[N]`, cooldown timer when active
     - `(2)BRACE` — keyboard shortcut `2`
     - `(3)SPEC [====]` — keyboard shortcut `3`, charge meter
   - Keyboard shortcuts `1`, `2`, `3` must be visible in the status line at all times.

3. **Thoughts panel** (bottom area, labeled "Thoughts")
   - Scrolling log of dragon inner monologue and important game events.
   - Text is in dragon voice — not a system log.
   - Examples: "I can feel my egg on this floor!", "That was easy", "I'm yearning for the light."

### Developer Mockup (authoritative reference)

```
┌───────────────────────────────────────────────────────────────────────────────────────────────x─┐
│xxxx                                                                                         xxx │
│   xxxx                                                                                    xxx   │
│      xxxxxxx                                                                            xxx     │
│            xxxx                                                                      xxxx       │
│               │xxx                                                                 xxx          │
│               │  xxxxx                                                            xx            │
│               │      xxxxx                                                     xxx              │
│               │          xxxx                                       xxxxxxxxxx│x                │
│               │             xxxx                               xxxxx          │                 │
│               │                xx┌─────────────────────────────┤              │                 │
│               │                  │                             │              │                 │
│               │                  │                             │              │                 │
│               │                  │                             │              │                 │
│               │                  │                             │              │                 │
│               │                  │                             │              │                 │
│               │                  │                             │              │                 │
│               │                  │                             │              │                 │
│               │                  │                             │              │                 │
│               │                  │                             │              │                 │
│               │                  │                             │              │                 │
│               │                  │                             │              │                 │
│               │            xxxxxxx─────────────────────────────┤              │                 │
│               │          xxx                                    xxxxxxxxxxxxxxxx                │
│               │       xxxx                                                      xxxxxxx         │
│               └─xxxxxxx                                                               xxxxx     │
│         xxxxxxxx                                                                          xxx   │
│    xxxxxx                                                                                   xxxx│
─xxxx──────────────────────────────────────────────────────────────────────────────────────────────
│HP [=========-] 90%   EGG [*]   (1)DASH][1](cd=12s)EC [(2)BRACE   (3)SPEC [====]                 │
│                                                                                                 │
┌─Thoughts────────────────────────────────────────────────────────────────────────────────────────┐
│ "I can feel my egg on this floor!"                                                              │
│ "That was easy"                                                                                 │
│ "I'm yearning for the light"                                                                    │
│                                                                                                 │
│                                                                                                 │
└─────────────────────────────────────────────────────────────────────────────────────────────────┘
```

### Rules
- The three-region layout is fixed. No region may be hidden, collapsed, or replaced during dungeon navigation.
- The status line is always a single line — never multi-line in normal navigation mode.
- The Thoughts panel displays at least 3 lines of text at any time.
- Combat may take place on a separate screen (see REQ-13). When returning to navigation, the three-region layout resumes immediately.

### What This Is Not
- This layout is not for the egg discovery, exit patio, or special attack full-screen event screens — those are dedicated narrative overlays.
- The Thoughts panel is not a debug log or system message area.

---

## REQ-13: Combat Screen — Real-Time, Visually Distinct

**Traces to**: DISC-04, DISC-01
**Priority**: Must Have

Combat may take place on a dedicated separate screen (jam rules explicitly permit this). The combat screen must communicate real-time action — not turn-based play.

### Rules
- The combat screen is visually distinct from the dungeon navigation screen.
- Combat is real-time. The UI must make this immediately apparent — no Wizardry-style numbered menu with a blinking cursor waiting for input.
- The player's three actions (Dash = `1`, Brace = `2`, Special = `3`) are available on the combat screen, displayed with their keyboard shortcuts.
- Action availability (Dash greyed when 0 charges, Special greyed when uncharged) must be visible in real time on the combat screen.
- Boss encounter Dash blocking (REQ-09) applies on the combat screen.

### What This Is Not
- Combat is not turn-based. No design may introduce per-turn waiting or numbered menus reminiscent of early CRPG combat.

---

## Requirement Dependency Matrix

| Requirement | Depends On |
|-------------|-----------|
| REQ-01 (Dash) | REQ-04 (Floor grid) |
| REQ-02 (Special) | REQ-07 (UI — charge meter) |
| REQ-03 (Brace) | REQ-01 (encounters exist) |
| REQ-04 (Floors) | — |
| REQ-05 (Egg) | REQ-04 (floor range 2-4) |
| REQ-06 (Exit) | REQ-05 (egg state), REQ-04 (Floor 5) |
| REQ-07 (UI) | REQ-01, REQ-02 (state sources) |
| REQ-08 (Upgrades) | REQ-04 (floor milestones) |
| REQ-09 (Boss) | REQ-04 (Floor 5), REQ-01 (Dash blocking) |
| REQ-10 (Vocabulary) | All text-producing requirements |
| REQ-11 (Death) | REQ-07 (HP state in UI) |
| REQ-12 (Screen Layout) | REQ-07 (status line), REQ-10 (Thoughts text) |
| REQ-13 (Combat Screen) | REQ-01, REQ-03, REQ-02 (actions), DISC-01 (action set) |
