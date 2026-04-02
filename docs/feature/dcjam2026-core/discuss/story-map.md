# User Story Map — Dragon Escape
**Feature**: dcjam2026-core
**Date**: 2026-04-02
**Author**: Luna (Product Owner — DISCUSS wave)

---

## Scope Assessment: PASS — 11 stories, 3 bounded contexts, estimated 4 days

Bounded contexts: Game Loop, Encounter System, Floor Generation.
Story count: 11 (US-01 through US-11).
Estimated effort: 4 days (jam duration). Within jam scope — each slice is independently playable.

---

## Story Map Backbone

The backbone lists the user activities in the sequence the player experiences them, left to right. Each column is one activity. Stories hang below their activity.

```
ACTIVITY:  [Start Game]  [Navigate]    [Encounter]   [Progress]   [Win/Lose]
           |             |             |             |            |
           v             v             v             v            v
BACKBONE:  Orientation   Movement      Combat        Milestone    End State
           + UI state    through       actions       + Emotional  (win / death)
                         dungeon       (Dash/        beats
                                       Brace/        (egg/exit/
                                       Special)      special)
```

---

## Activities and Stories

### Activity 1: Start Game

| Story | Title | Release |
|-------|-------|---------|
| US-01 | Game Start — UI State Legibility | Slice 0 |

### Activity 2: Navigate the Dungeon

| Story | Title | Release |
|-------|-------|---------|
| US-04 | Floor Structure and Descent | Slice 0 |

### Activity 3: Encounter (Combat and Evasion)

| Story | Title | Release |
|-------|-------|---------|
| US-02 | Dash — Pass Through Enemy Square | Slice 0 |
| US-05 | Brace — Option-Starved Window | Slice 1 |
| US-03 | Special Attack — Power Beat | Slice 2 |
| US-09 | Boss Encounter — Dash Blocked | Slice 2 |

### Activity 4: Progress and Emotional Beats

| Story | Title | Release |
|-------|-------|---------|
| US-06 | Special Charge Meter — Visual Readiness | Slice 1 |
| US-07 | Egg Discovery — Relief Beat | Slice 1 |
| US-08 | Milestone Upgrade Choice | Slice 2 |

### Activity 5: Win / Lose State

| Story | Title | Release |
|-------|-------|---------|
| US-10 | Exit Patio — Final Relief Beat | Slice 1 |
| US-11 | Death Condition | Slice 0 |

---

## Walking Skeleton

The thinnest end-to-end slice that proves the core loop:

**Slice 0: Walking Skeleton**

> Player spawns on Floor 1 → encounters one enemy → uses Dash to pass through → reaches stairs → descends → (floors 2+ are empty corridors) → reaches exit → game ends.

Stories required:
- US-01: UI state is legible at game start (Dash=2, Spec=empty)
- US-02: Dash — pass through enemy square, advance, charge decrements
- US-04: Floor structure exists; stairs work; descent increments floor counter
- US-11: Death condition fires when HP reaches 0

The walking skeleton deliberately omits: egg, special, upgrades, boss, emotional beat events. It proves the locomotion + one encounter + floor traversal + win/death conditions work end-to-end.

---

## Release Slices

### Slice 0: Walking Skeleton (Day 1)

**Outcome**: The core loop is playable. Dash works. Movement works. You can die.

| Story | Why it's in Slice 0 |
|-------|---------------------|
| US-01 | UI legibility is the entire "tutorial" — must exist from first play |
| US-02 | Dash is the reason the game exists — must prove this first |
| US-04 | Floor traversal is the structural scaffold everything else hangs on |
| US-11 | Death condition is a hard jam requirement |

Demonstrable: Player can launch the game, encounter a guard, Dash through, reach stairs, descend, reach "exit" placeholder, and die if HP hits 0.

---

### Slice 1: Core Loop Complete (Day 2)

**Outcome**: All floors playable, egg discoverable, exit achievable. The full run is completable from start to win state.

| Story | Why it's in Slice 1 |
|-------|---------------------|
| US-05 | Brace completes the action set for Slice 0's encounter system |
| US-06 | Special charge meter must be visible before Special is enabled |
| US-07 | Egg discovery is the first emotional beat — required for a complete run |
| US-10 | Exit patio is the win state — required for a complete run |

Demonstrable: Player can complete a full run from Floor 1 to Floor 5, find the egg, reach the exit, and see the win state.

---

### Slice 2: Full Feature Set (Day 3)

**Outcome**: Special attack fires, boss encounter exists, upgrades are choosable. All jam requirements met.

| Story | Why it's in Slice 2 |
|-------|---------------------|
| US-03 | Special attack delivers the power beat — jam showpiece |
| US-08 | Milestone upgrades satisfy the jam stat-modification rule |
| US-09 | Boss encounter gives Floor 5 its climactic encounter |

Demonstrable: Player can complete a full run with all three emotional beats firing (Dash delight, Special badass, egg/exit relief), choose an upgrade, and fight the boss.

---

### Slice 3: Polish (Day 4 — if time permits)

**Outcome**: Dragon vocabulary is comprehensive, edge cases handled, difficulty tuned, TUI visual polish.

| Story | Why it's in Slice 3 |
|-------|---------------------|
| Dragon vocabulary pass | All strings use dragon-appropriate language throughout |
| Cooldown tuning | ~45s cooldown is calibrated for feel |
| Special charge rate tuning | Rate calibrated so first-encounter use is impossible |
| Upgrade pool population | All 6-8 upgrades defined and tested |
| Egg placement distribution | Confirmed not biased toward Floor 2 |

Demonstrable: Polished, tuned full run. Ready for jam submission.

---

## Story Map Visual

```
BACKBONE  [Start Game]  ------  [Navigate]  ------  [Encounter]  ------  [Progress]  ------  [Win/Lose]

SLICE 0   US-01                 US-04                US-02                                     US-11
          (UI state)            (floors+stairs)      (Dash)

SLICE 1                                              US-05                US-06       US-07     US-10
                                                     (Brace)              (spec meter)(egg)     (exit)

SLICE 2                                              US-03       US-09    US-08
                                                     (Special)   (Boss)   (Upgrades)

SLICE 3   [Polish pass — vocabulary, tuning, distribution checks]
```
