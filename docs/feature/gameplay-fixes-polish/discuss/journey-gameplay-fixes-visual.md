# Journey: Gameplay Fixes and Polish — Player Experience

## Overview

Three discrete player experience problems, each documented as a current-state vs. desired-state journey.

---

## Item 1: Guard Persists After Defeat (BUG — Major)

### What happens now

```
[Player approaches guard cell]
        |
        v
[Combat screen opens]
  Guard HP = 40, Ember fights
        |
        v
[Ember defeats guard — HP reaches 0]
        |
        v
[Screen returns to .dungeon mode]
        |
        v
[Minimap still shows "G" on guard's cell]  <-- BUG
        |
        v
[Player walks toward that cell again]
        |
        v
[Combat triggers AGAIN — new guard with full 40 HP]  <-- BUG
```

**Root cause (observed in code):**
`FloorMap.encounterPosition2D` is a static property — it is never set to `nil` after defeat.
`minimapChar(at:floor:state:)` checks `floor.encounterPosition2D` unconditionally, so the
guard symbol always reappears. `applyMove` re-triggers combat on the same cell because
`FloorMap` has no record of whether the encounter was completed.

**Player experience now:** Confusing. The guard the player just defeated is standing
there again, healthy. The minimap lies about the dungeon state.

### What should happen

```
[Player approaches guard cell]
        |
        v
[Combat screen opens]
        |
        v
[Ember defeats guard]
        |
        v
[Screen returns to .dungeon mode]
        |
        v
[Guard cell is cleared — "G" removed from minimap]
        |
        v
[Player can walk through the cell freely — no re-trigger]
        |
        v
[Minimap shows passable corridor "." at that cell]
```

**Design note:** `GameState` needs a way to record which encounter positions have been
cleared on the current floor. A simple `Set<Position>` of defeated encounter positions
on the active floor is sufficient. `FloorMap` itself stays immutable.

---

## Item 2: Boss Redesign — Warden, Not Cat

### What happens now

The boss encounter is labelled "DRAGON WARDEN" in the combat HUD (`enemyName`) and
in `combatThoughts`, but the ASCII art renders a **cat face** (symmetric ears, whiskers).
This directly contradicts the game's narrative: Ember is a dragon reclaiming her egg
from humans who stole it. The antagonists should be human wardens, not animals.

```
BOSS COMBAT SCREEN — current state:
┌────────────────────────────────────────────┐
│            DRAGON WARDEN                   │
│                                            │
│              /\___/\                       │
│             /  o o  \      <-- cat ears    │
│            / ==^==  \      <-- cat whiskers│
│           /  \_V_/  \                      │
│   /\     /___/ \___\                       │
│  /  \   /   WARDEN  \                      │
│ /    \_/             \                     │
│/______________________\                    │
└────────────────────────────────────────────┘
```

**Player experience now:** Jarring. Ember's narration says "The Dragon Warden" but
the art shows a cat. Story coherence breaks. The human-antagonist premise is undermined.

### What should happen

The boss is the **Head Warden**: a large, armoured human — a formidable jailer who
holds authority over the entire dungeon. The art must read as human: upright posture,
heavy frame, helmet or hood, no animal features.

```
BOSS COMBAT SCREEN — desired state:
┌────────────────────────────────────────────┐
│           HEAD WARDEN                      │
│                                            │
│           .-""""-.                         │
│          /  _  _  \    <-- human face      │
│         |  (_)(_)  |   <-- eyes, not cat   │
│         |    __    |   <-- stern expression │
│          \  ----  /                        │
│      ____[========]____                    │
│     /    |  WARDEN |   \  <-- armour       │
│    /_____|_________|_____\                 │
└────────────────────────────────────────────┘
```

**Design note — name change:**
- Combat HUD label: `"HEAD WARDEN"` (replaces `"DRAGON WARDEN"`)
- Thought text: should reflect the human-antagonist narrative (e.g. "The Head Warden.
  The one who ordered my egg stolen. This ends here.")
- Minimap symbol "B" stays; colour stays bold red. Only art and text change.

---

## Item 3: Minimap Legend

### What happens now

The minimap (cols 61-75, rows 2-8) renders 10 distinct characters with distinct colours:

```
 Current minimap — no legend:
 ┌───────────────────┐
 │ ##.....##.....##. │  row 2
 │ #....>....G...##. │  row 3  (">" = player, "G" = guard — but player doesn't know)
 │ #.............##. │  row 4
 │ #...*..G......##. │  row 5  ("*" = egg room — but player doesn't know)
 │ #.............##. │  row 6
 │ #......S......##. │  row 7  ("S" = staircase — unclear without legend)
 │ #......E......##. │  row 8  ("E" = entry)
 └───────────────────┘
```

**Player experience now:** The minimap is visually appealing but opaque. Players must
guess what symbols mean. Egg rooms ("*") or guards ("G") may go unnoticed.

### What should happen

A legend appears below the minimap, within the right-panel column space (cols 61-79).
It uses the same characters and colours as the minimap itself, keeping the legend
self-consistent.

```
MINIMAP WITH LEGEND — desired state:
 ┌───────────────────┐  (cols 61-79, rows 2-8)
 │ ##.....##.....##. │  row 2
 │ #....>....G...##. │  row 3
 │ #.............##. │  row 4
 │ #...*..G......##. │  row 5
 │ #.............##. │  row 6
 │ #......S......##. │  row 7
 │ #......E......##. │  row 8
 └───────────────────┘
                        row 9  (blank spacer)
 ^/>/<  You             row 10
 G      Guard           row 11
 B      Boss            row 12
 *      Egg             row 13
 S      Stairs          row 14
 E      Entry           row 15
 X      Exit            row 16
```

**Design note:** The legend lives in rows 9-16 of the right panel (cols 61-79).
It must not overflow into the status-bar separator at row 17. Each legend line is:
`[coloured symbol]  [plain-text label]`. Seven entries, seven rows — fits exactly.
