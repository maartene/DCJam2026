# Rules Coverage Analysis — Ember's Escape (DCJam 2026)
**Feature**: rules-coverage
**Date**: 2026-04-03
**Author**: Luna (Product Owner — DISCUSS wave)

---

## Summary

This document maps every DCJam 2026 mandatory rule to its implementation status in the
current codebase, then identifies gaps that must be closed before submission.

**Verdict**: 8 of 11 jam rules are fully or substantially covered.
**2 rules have confirmed implementation gaps** that must be fixed for a valid submission.
**1 rule has a partial gap** that needs verification before submission.

---

## Jam Rule Coverage Table

| # | Jam Rule | Status | Evidence |
|---|----------|--------|----------|
| R1 | First-person exploration at all times (exceptions: combat, cut scenes, overlays) | PASS | `renderDungeon` (lookup-table frames), `renderCombat`, `renderNarrativeOverlay` |
| R2 | Explorable locations (dungeon, viewed in first-person) | PASS | 5-floor L-shaped corridor dungeon; `FloorGenerator`; `DungeonFrames` lookup table |
| R3 | Step movement on a square grid, no half-steps | PASS | `applyMove` advances by exactly 1 `Position`; grid is 15×7; Dash always +3 (not partial) |
| R4 | 90-degree turns in four cardinal directions, keyboard-invoked | PASS | `applyTurn` + `CardinalDirection.turned(by:)`; WASD + arrow keys in `InputHandler` |
| R5 | Player-controlled character / persona | PASS | Ember the dragon; full keyboard control |
| R6 | At least one basic stat (minimum: a single health/power bar) | PASS | HP bar (`state.hp`, `drawStatusBar`), Special charge meter, Dash charges |
| R7 | Combat or mechanic for determining outcome of encounters | PASS | Real-time brace/parry system, Special attack, Dash exit; `RulesEngine` |
| R8 | Win condition | PASS | `hasEgg == true` AND `playerPosition == exitSquare` → `.winState` |
| R9 | Death/fail condition | PASS | `hp <= 0` → `.deathState`; restart available |
| R10 | At least one way to affect character stats | **GAP** | Upgrade pool and `UpgradePrompt` screen exist, but the upgrade prompt is **never triggered** by `RulesEngine` during normal play — no milestone trigger is wired. |
| R11 | Game includes an interpretation of the theme | PARTIAL | Theme "Dragons" is directly implemented (Ember is a dragon). "Cleaning up the hero's mess", "Retrofuturism", "Elemental Rock Paper Scissors" are not explicitly addressed. The jam announces one theme; the others are alternatives. Confirm which theme is active for DCJam 2026. |

---

## Gap 1 (CRITICAL): Upgrade Prompt Never Triggers — R10

### Problem

The jam requires "at least one way to affect character stats." The intended mechanism is
the milestone upgrade system: when Ember descends a staircase, she is offered 3 upgrades
from a pool of 8.

The `UpgradePool`, `Upgrade`, `UpgradeEffect`, `UpgradePrompt` screen mode, and
`applyUpgrade` function all exist and are tested. However, **`RulesEngine.applyMove`
never transitions to `.upgradePrompt`**. The staircase descent code in `applyMove` is:

```swift
return state.withCurrentFloor(nextFloor).withPlayerPosition(nextFloorMap.entryPosition)
```

There is no call to `UpgradePool.drawChoices` and no transition to `.upgradePrompt(choices:)`.
The upgrade system is implemented but disconnected from the game loop.

A player can complete a full 5-floor run without ever seeing an upgrade prompt.

### Impact

Without the upgrade system firing, the only stat-affecting mechanic is the initial
HP/Dash/Special configuration — which cannot be modified during play. This likely fails
R10 ("at least one way to affect character stat(s)"), which lists "potions, items with
bonuses" as examples. At minimum it is a very thin interpretation.

Additionally, the game's own design intends upgrades as a pacing tool — the combat
difficulty escalates floor to floor and upgrades compensate. Without them, the boss
encounter on Floor 5 may be unwinnable at default stats (HP=100, 2 Dash charges,
~125s to full Special).

### What Is Required

When Ember descends the staircase (floor transition fires), `RulesEngine` must:
1. Check whether a milestone upgrade should be offered on the new floor.
2. If yes: draw 3 unique choices from `UpgradePool` (excluding already-selected), transition
   to `.upgradePrompt(choices:)`.
3. If no: continue to dungeon as today.

**Milestone trigger rule** (to be confirmed with developer — two viable options):

- **Option A**: Offer an upgrade on every floor transition (floors 1→2, 2→3, 3→4, 4→5).
  Simple; predictable; 4 upgrades per 5-floor run.
- **Option B**: Offer an upgrade on even-numbered floors only (2 and 4).
  Two upgrades per run; less frequent; matches "milestone" framing.

The developer must confirm which option before implementation. Option A is recommended
given the current combat balance — the boss at Floor 5 deals 25 damage per 2-second hit,
making longer runs very punishing without stat growth.

---

## Gap 2 (MEDIUM): Theme Interpretation — R11

### Problem

DCJam rules state "the game must include an interpretation of the (to-be-announced)
theme." `docs/rules.md` lists four candidate themes. The final active theme for the jam
must be confirmed.

**Current theme coverage:**

| Theme | Coverage in game |
|-------|-----------------|
| Dragons | Full — Ember is a dragon; all vocabulary is dragon-voiced |
| Cleaning up the hero's mess | Partial — narrative states the dragon's parent was killed by a hero; Ember reclaims the egg stolen by guards left behind. The "hero's mess" framing is present in lore but not surfaced in gameplay text |
| Retrofuturism | None — no visual or narrative element references retrofuturism |
| Elemental Rock Paper Scissors | Explicitly out of scope (`docs/CLAUDE.md`); DEC-09 |

### Impact

If the active jam theme is "Dragons" or "Cleaning up the hero's mess", the game passes
with existing or minor text polish.

If the active theme is "Retrofuturism" or "Elemental RPS", the game fails R11.
Retrofuturism would require art/narrative changes. Elemental RPS is out of scope and
cannot be added in the remaining time without major rework.

### What Is Required

1. Confirm which theme DCJam 2026 announced (check jam page or Discord).
2. If "Cleaning up the hero's mess": surface the narrative in the start screen or
   in-game thoughts. The existing lore in `renderNarrativeOverlay` covers this partially.
3. If "Retrofuturism" or "Elemental RPS": immediate escalation needed — a new discovery
   session is required.

---

## Gap 3 (LOW / DESIGN DEBT): Staircase to Floor 5 Visually Indistinguishable

### Problem

The rules require that on Floor 5 the exit is the win condition square, not a staircase
to Floor 6. The current code handles this correctly in logic:
`floor.hasExitSquare = isFinalFloor`. However, the minimap shows "S" for both staircase
and exit on floor 5 because `buildMinimap` uses the staircase position for both.

The `renderMinimap` function correctly shows "X" for the exit on floor 5 because it
checks `floor.hasExitSquare`. But the older `buildMinimap` string function (still present
in the renderer) has inconsistent logic. This is not a jam-rules gap but a minor visual
inconsistency worth noting.

---

## Fully Covered Jam Rules — Detail Notes

### R3: Step Movement on Square Grid

The movement is grid-correct. Dash always advances exactly 3 squares forward (`dashAdvanceSquares = 3`). No half-steps, no diagonals. Wall collision prevents movement into non-passable cells. Grid is 15×7 (squares, not hexagons). PASS.

### R4: 90-Degree Turns

`CardinalDirection.turned(by:)` produces exact 90-degree rotations. Four directions: north, east, south, west. Turning is keyboard-invoked (A/D, arrow left/right). No mouse-look present. PASS.

### R7: Combat Mechanic

The brace/parry system is a genuine mechanical determination of encounter outcome:
- Brace opens a 0.5s invulnerability window
- Enemy attacks on a 2.0s fixed interval
- Successful parry: 0 damage, +15% Special charge
- Unbraced hit: 15 damage (guard) or 25 damage (boss)
- Dash exits the encounter (costs 1 charge, blocked for boss)
- Special attack deals 60 damage (defeats guard in one shot, takes ~2 hits on boss)

This is a real-time action mechanic with meaningful player agency. PASS.

### R8 + R9: Win and Death Conditions

Both are implemented and tested. Win requires BOTH `hasEgg == true` AND stepping onto
`exitSquare`. Death fires at `hp <= 0` with a death screen and restart option. PASS.

---

## Prioritized Action List

| Priority | Action | Jam Risk | Effort |
|----------|--------|----------|--------|
| P1 | Wire upgrade prompt to staircase transition in `RulesEngine.applyMove` | HIGH — R10 | ~2h |
| P2 | Confirm active DCJam 2026 theme on jam page | HIGH — R11 | 15 min |
| P3 | If theme is "Cleaning up hero's mess": polish start screen narrative hook | LOW | ~1h |
| P4 | Remove or reconcile the legacy `buildMinimap` string function | None | ~30 min |

---

## Out of Scope

The following DCJam rules are explicitly noted as not applicable to this game style,
or are covered by exception clauses in the rules:

- **Overworld map movement** — not implemented; not required (rules allow point-to-point
  overworld as an exception, but it is optional)
- **Smooth transitions** — rules allow smooth transitions between grid squares but do not
  require them; the instantaneous step-move is valid
- **Gamepad control** — rules say "keyboard (or gamepad)"; keyboard-only is valid

---

## Recommendation

**The game is submittable after closing Gap 1 (upgrade prompt trigger) and confirming
the active jam theme (Gap 2).** Both are low-effort fixes. Gap 1 is a wiring task
of approximately 2 hours. Gap 2 is a 15-minute information check.

Once Gap 1 is fixed, the upgrade system already has 8 upgrades, renders correctly, and
applies stat changes correctly — it simply needs to be called.
