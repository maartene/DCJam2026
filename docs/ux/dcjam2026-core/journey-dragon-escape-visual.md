# Journey Visual: Ember's Escape
**Feature**: dcjam2026-core
**Date**: 2026-04-02
**Author**: Luna (Product Owner — DISCUSS wave)

---

## Emotional Arc Overview

```
EMOTION
  HIGH |                                           [BADASS]          [RELIEF]
       |                                               *                 *
       |                              *           *       *         *       *
  MED  |            *           *         *   *               *
       |       *         *   *
  LOW  |  *
       |
       +----+--------+--------+--------+--------+--------+--------+--------+-->
           START   FLOOR1   FLOOR2   FLOOR3   FLOOR4   FLOOR5   EGG+  PATIO
                  Tutorial  Regular  Regular  Egg Fnd  Boss    Special  Exit

BEATS:  [Orienta- [First    [Learn-  [Tensi-  [RELIEF]  [Boss   [BADASS] [RELIEF
         tion]    Dash!]    ing]      on]      (egg)    dread]           earned]
```

Key emotional waypoints:
- **Orientation**: Player reads their state. Dragon. Dungeon. Goal unclear. Mild tension.
- **First Dash**: Player passes through first enemy. Surprise and delight. "This is the move."
- **Option-starved moment**: Dash on cooldown, Special empty, enemy adjacent. Strategic tension — intentional.
- **Egg discovery**: Mid-dungeon. Named moment. Relief — something is accomplished. Mission clarified.
- **Special attack**: Power fantasy. Full-screen beat. "I am a dragon."
- **Exit patio**: Earned relief. Pacing slows. Not triumph — exhale.

---

## Full Journey Map: Ember's Escape (5-Floor Target)

```
+------------------------------------------------------------------+
|  GAME START                                                      |
|  Player sees title screen. First-person view loads.              |
|  UI shows: [Dragon silhouette] HP bar | DASH [2] | SPEC [----]  |
|                                                                  |
|  Narrative prompt:                                               |
|  "The hero has fled. Your parent lies still.                     |
|   Somewhere in this place, your egg.                            |
|   You know the way out. Move."                                  |
+------------------------------------------------------------------+
                            |
                            v
+------------------------------------------------------------------+
|  FLOOR 1 — STARTER FLOOR                                        |
|                                                                  |
|  Player navigates grid. Empty squares. Learning controls.        |
|  First encounter: guard blocks corridor.                         |
|                                                                  |
|  UI state at first encounter:                                    |
|   DASH  [ 2 charges ] [==========] READY                        |
|   SPEC  [  0 charges ] [----------] EMPTY                       |
|                                                                  |
|  Player sees Special is unavailable. Dash is ready.             |
|  Player selects Dash. No tutorial needed.                        |
|                                                                  |
|  Feedback:                                                       |
|   "You surge past the guard. He never lands a blow.              |
|    The dungeon opens ahead."                                    |
|                                                                  |
|  Emotional beat: DELIGHT / "this is the move"                   |
|  Dash charge: 1 (one charge used)                               |
+------------------------------------------------------------------+
                            |
                            v
+------------------------------------------------------------------+
|  FLOOR 1 continued — OPTION-STARVED WINDOW (intentional)        |
|                                                                  |
|  Second encounter arrives while Dash has 1 charge left.         |
|  Player uses second Dash.                                        |
|  Now: DASH [ 0 charges ] [cooldown ticking] SPEC [--] growing   |
|                                                                  |
|  Third encounter: both Dash charges on cooldown. Spec still low. |
|  Only option: BRACE (absorb blow, wait)                         |
|                                                                  |
|  "You lower your wings and brace. The blow glances off          |
|   your scales. Not ideal."                                       |
|                                                                  |
|  Dash charge recovers. Player Dashes next encounter.            |
|  Emotional beat: TENSION then RELIEF (Dash back)                |
|  Strategic lesson: manage charges, don't burn both recklessly   |
+------------------------------------------------------------------+
                            |
                            v
+------------------------------------------------------------------+
|  FLOOR 1 — STAIRS DOWN                                          |
|                                                                  |
|  Player reaches stairs. Descends.                               |
|  "Floor 2. The air changes. Something ahead."                   |
+------------------------------------------------------------------+
                            |
                            v
+------------------------------------------------------------------+
|  FLOORS 2–4 — REGULAR FLOORS (one contains the egg)            |
|                                                                  |
|  Pattern repeats with increasing enemy density.                 |
|  Special charge meter fills slowly over time.                   |
|  Player learns to read DASH cooldown vs SPEC readiness.         |
|                                                                  |
|  Special becomes available mid-dungeon:                         |
|   SPEC [ full ] [==========] READY                              |
|                                                                  |
|  Player may use Special before or after finding egg.            |
|  (Special is not tied to egg discovery — two separate beats)    |
|                                                                  |
|  UPGRADE MILESTONE (after clearing a floor):                    |
|   +----------------------------------------------+              |
|   |  MILESTONE REACHED                           |              |
|   |                                              |              |
|   |  Choose your path:                           |              |
|   |  [A] Keen lunges — Dash cooldown -5s         |              |
|   |  [B] Iron scales — Max HP +10                |              |
|   |  [C] Deep breath — Special charges faster   |              |
|   |                                              |              |
|   |  Choose: _                                   |              |
|   +----------------------------------------------+              |
|                                                                  |
+------------------------------------------------------------------+
                            |
                            v
+------------------------------------------------------------------+
|  EGG DISCOVERY — RELIEF BEAT #1                                 |
|  (On one floor in Floors 2–4, not Floor 1 or Floor 5)          |
|                                                                  |
|  +----------------------------------------------------------+   |
|  |                                                          |   |
|  |                                                          |   |
|  |   You round a corner.                                    |   |
|  |                                                          |   |
|  |   There.                                                 |   |
|  |                                                          |   |
|  |   In a hollow carved from the dungeon wall —            |   |
|  |   warm, pulse-lit, unmistakable.                        |   |
|  |                                                          |   |
|  |   Your egg.                                              |   |
|  |                                                          |   |
|  |   You take it. It is heavier than you expected.         |   |
|  |   It is not too late.                                    |   |
|  |                                                          |   |
|  |              [ Press any key to continue ]               |   |
|  |                                                          |   |
|  +----------------------------------------------------------+   |
|                                                                  |
|  UI: EGG indicator added to status bar                         |
|  Pacing: screen holds. Text does not rush. Player must press.   |
|  Emotional beat: ACTUAL RELIEF (mission clarified, achieved)    |
+------------------------------------------------------------------+
                            |
                            v
+------------------------------------------------------------------+
|  FLOOR 5 — BOSS FLOOR                                          |
|                                                                  |
|  Boss encounter. Telegraphed as un-Dashable.                    |
|  Pre-encounter text: "The guardian blocks the corridor.         |
|   It does not move. It cannot be passed. Not yet."             |
|                                                                  |
|  Player engages. Combat with Brace + Special.                   |
|                                                                  |
|  SPECIAL ATTACK — POWER BEAT (if used in boss fight):          |
|                                                                  |
|  +===========================================================+  |
|  ||                                                         ||  |
|  ||                                                         ||  |
|  ||       Y O U  O P E N  Y O U R  T H R O A T            ||  |
|  ||                                                         ||  |
|  ||    Fire pours from you like a river reversing.         ||  |
|  ||    The guardian does not scream. It simply ends.       ||  |
|  ||                                                         ||  |
|  ||              [--- ROAR ---]                             ||  |
|  ||                                                         ||  |
|  +===========================================================+  |
|                                                                  |
|  Emotional beat: BADASS / power fantasy                        |
|  Full-screen or ASCII-bordered display. Distinct from combat.  |
+------------------------------------------------------------------+
                            |
                            v
+------------------------------------------------------------------+
|  EXIT PATIO — RELIEF BEAT #2 (EARNED)                          |
|                                                                  |
|  +----------------------------------------------------------+   |
|  |                                                          |   |
|  |                                                          |   |
|  |   Light.                                                 |   |
|  |                                                          |   |
|  |   Not the dungeon's cold lamps.                         |   |
|  |   Real light. Outside.                                   |   |
|  |                                                          |   |
|  |   You hold the egg against your chest.                  |   |
|  |   It is warm. You are warm.                              |   |
|  |   The hero made a mess of things.                       |   |
|  |   You cleaned it up.                                     |   |
|  |                                                          |   |
|  |              [ You escaped. ]                            |   |
|  |                                                          |   |
|  |              [ Press any key ]                           |   |
|  |                                                          |   |
|  +----------------------------------------------------------+   |
|                                                                  |
|  Win state. Pacing: slow. Text does not rush.                  |
|  Emotional beat: RELIEF — not triumph. Exhale, not fist pump.  |
+------------------------------------------------------------------+
```

---

## Main Screen Layout (Developer Mockup — Authoritative)

The main game screen has three fixed regions. This is the authoritative layout established by the developer in DISC-04.

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
│               │                  │   FIRST-PERSON 3D VIEW      │              │                 │
│               │                  │   (primary play area)       │              │                 │
│               │                  │   ASCII dungeon from        │              │                 │
│               │                  │   Ember's perspective       │              │                 │
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
│HP [=========-] 90%   EGG [*]   (1)DASH [1](cd=12s)   (2)BRACE   (3)SPEC [====]                  │
│                                                                                                 │
┌─Thoughts────────────────────────────────────────────────────────────────────────────────────────┐
│ "I can feel my egg on this floor!"                                                              │
│ "That was easy"                                                                                 │
│ "I'm yearning for the light"                                                                    │
│                                                                                                 │
│                                                                                                 │
└─────────────────────────────────────────────────────────────────────────────────────────────────┘
```

**Region 1 — First-person 3D view**: Upper area. ASCII/character art dungeon rendered from Ember's perspective. Primary play area.

**Region 2 — Status line**: Single line. Always visible. Contains all five state indicators plus keyboard shortcuts:
- `HP [=========-] 90%` — health bar (SA-06)
- `EGG [*]` / `EGG [ ]` — egg status (SA-04)
- `(1)DASH [N](cd=Xs)` — shortcut `1`, charges (SA-01), cooldown when active (SA-02)
- `(2)BRACE` — shortcut `2`
- `(3)SPEC [====]` — shortcut `3`, charge meter (SA-03)

**Region 3 — Thoughts panel**: Bottom area, labeled "Thoughts". Scrolling log of dragon inner monologue triggered by game events (SA-12). Not a system log — dragon voice only.

---

## TUI State Mockups

### Status Line States

Game start (all defaults):
```
│HP [==========] 100%   EGG [ ]   (1)DASH [2]   (2)BRACE   (3)SPEC [----------]                  │
```

After egg pickup, Dash on cooldown (1 charge used, 1 remaining):
```
│HP [=========-] 90%   EGG [*]   (1)DASH [1](cd=32s)   (2)BRACE   (3)SPEC [------]                │
```

Dash fully on cooldown (0 charges), Special nearly ready:
```
│HP [====------] 40%   EGG [*]   (1)DASH [0](cd=18s)   (2)BRACE   (3)SPEC [========]              │
```

### Encounter Screen

```
+----------------------------------------------------------+
|  A guard stands before you, spear leveled.               |
|                                                          |
|  Your options:                                           |
|  [D] Dash through     DASH [1] ready                    |
|  [B] Brace                                              |
|  [S] Special          SPEC [--] not yet                 |
|                                                          |
|  > _                                                     |
+----------------------------------------------------------+
```

### Milestone Upgrade Prompt

```
+----------------------------------------------------------+
|  MILESTONE: Floor cleared.                               |
|                                                          |
|  Your body knows what it needs. Choose:                  |
|                                                          |
|  [1] Keen lunges     — Dash cooldown -5s                 |
|  [2] Iron scales     — Max HP +10                        |
|  [3] Deep breath     — Special charges 20% faster        |
|  [4] Second wind     — Gain 1 extra Dash charge cap      |
|                                                          |
|  > _                                                     |
+----------------------------------------------------------+
```

---

## Integration Checkpoints

| Step | Shared Artifact | Source of Truth | Risk |
|------|----------------|-----------------|------|
| Status bar | DASH charge count | GameState.dashCharges | Must update on use + replenish |
| Status bar | SPEC charge level | GameState.specialCharge | Must display 0 on game start |
| Status bar | EGG indicator | GameState.hasEgg | Must toggle on egg room entry |
| Encounter | Available actions | GameState.dashCharges, specialCharge | Action list must reflect live state |
| Egg discovery | Egg room trigger | FloorMap.eggRoomId | Must fire once per run |
| Special attack | Special trigger | GameState.specialCharge == full | Full-screen event must interrupt normal render |
| Exit patio | Win condition | GameState.hasEgg + PlayerPosition.atExit | Must check both conditions |
| Milestone | Upgrade pool | UpgradePool (6-8 entries) | Player choice must persist |
