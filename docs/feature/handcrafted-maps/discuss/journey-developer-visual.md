# Developer Journey — Author a Handcrafted Floor

**Persona**: Maartene, solo developer, Swift 6.3, jam deadline pressure.
**Goal**: Define floor 3's layout in code and see it rendered correctly in-game within one edit-compile-run cycle.
**Emotional arc**: Constrained (grid limits unknown) → Clear (constraints understood) → Creative (layout authored) → Confident (tests pass, minimap renders)

---

## Journey Flow

```
TRIGGER: "All 5 floors look the same. Jam judges will notice."
        |
        v
[1. UNDERSTAND CONSTRAINTS]
  - Max grid: 19 wide × 15 tall (rows 2-16 of right panel)
  - Floor label moved to top border (row 1) — frees row 2 for map
  - Entry always present; egg room on floors 2-4 only; exit on floor 5 only
  - Landmark positions are explicit fields, not derived from grid scan
        |
        v  FEEL: "OK, I know the box I'm working in."
        |
[2. DEFINE THE FLOOR LAYOUT]
  - Open a new Swift file: Sources/GameDomain/HandcraftedFloors.swift
  - Define grid as a [String] literal using the minimap character language:
      # = wall, . = floor, ^ = entry (facing north), G = guard, * = egg room, S = stairs, B = boss, X = exit
  - Landmark positions are encoded in the grid — no separate Position fields needed
  - Pick a topology distinct from L-shape (e.g. T-junction, room-and-corridor, zigzag)
  - First: express the existing L-shape in this format (migration step) — then add new floors
        |
        v  FEEL: "I'm designing this — it has a shape I intended."
        |
[3. REGISTER THE FLOOR]
  - Add the floor definition to FloorRegistry.floor(_:config:)
  - Replace FloorGenerator call-sites: RulesEngine + Renderer
        |
        v  FEEL: "One place to register — no hunting for call sites."
        |
[4. COMPILE AND TEST]
  - swift test — existing tests must pass (backwards-compat)
  - New floor-shape tests confirm grid dimensions and landmark positions
        |
        v  FEEL: "Green. I trust the shape is what I drew."
        |
[5. RUN AND SEE IN-GAME]
  - swift run
  - Minimap shows the new shape; floor label "Floor 3/5" in top border
  - Navigate to confirm topology matches ASCII layout literal
        |
        v  FEEL: "That's my floor. It looks like what I drew."
```

---

## Emotional Annotations

| Step | Dominant Feeling | Risk if missing |
|------|-----------------|-----------------|
| 1 — constraints | Grounded, not guessing | Developer wastes time on a 20-wide layout that gets clipped |
| 2 — define layout | Creative ownership | No distinction between floors; jam feels lazy |
| 3 — register | Efficient, no friction | Hunt for all `FloorGenerator` call sites creates bugs |
| 4 — test | Confident | Silent regression: old tests pass but new floor has wrong topology |
| 5 — see in-game | Satisfying closure | Floor looks correct in tests but wrong on screen (minimap offset bug) |

---

## TUI Mockup — Floor Definition Authoring

The developer writes a literal grid as a 2D Bool array. No DSL, no external file.

```
Sources/GameDomain/HandcraftedFloors.swift

┌─────────────────────────────────────────────────────────────┐
│  // Floor 3 — T-junction corridor                           │
│  static let floor3 = FloorDefinition(                       │
│      width: 19, height: 10,                                 │
│      grid: [                                                 │
│          //  0  1  2  3  4  5  6  7  8  9  10 11 12 13 ...  │
│          [F, F, F, F, F, F, F, T, F, F, F, F, F, F, ...],  │
│          [F, F, F, F, F, F, F, T, F, F, F, F, F, F, ...],  │
│          [F, T, T, T, T, T, T, T, T, T, T, T, T, F, ...],  │
│          [F, F, F, F, F, F, F, T, F, F, F, F, F, F, ...],  │
│          ...                                                 │
│      ],                                                      │
│      entry:     Position(x: 7, y: 0),                       │
│      staircase: Position(x: 7, y: 9),                       │
│      encounter: Position(x: 7, y: 5),                       │
│      eggRoom:   nil                   // floor 3 has no egg │
│  )                                                           │
└─────────────────────────────────────────────────────────────┘

Legend: T = true (passable), F = false (wall)
```

---

## TUI Mockup — In-Game Result (80×25 Terminal)

```
┌──────────────────────────────────────────────────────┬── Floor 3/5 ──────┐  row 1
│                                                      │ # # # # # # # ^ # │  row 2
│                  [dungeon first-person view]         │ # # # # # # # . # │  row 3
│                                                      │ # . . . . . . . . │  row 4 (T-arm)
│                                                      │ # # # # # # # G # │  row 5
│                                                      │ # # # # # # # . # │  row 6
│                                                      │ # # # # # # # S # │  row 7
│                                                      │ # # # # # # # # # │  ...
├──────────────────────────────────────────────────────┴───────────────────┤  row 17
│ HP [====] EGG [ ]  (1)DASH[2]  (2)BRACE  (3)SPEC[====]                  │  row 18
│ W/S: move  A/D: turn  1: Dash  2: Brace  3: Special  ESC: quit           │  row 19
├─Thoughts─────────────────────────────────────────────────────────────────┤  row 20
│ Deeper now. The air is thicker, heavier. My claws find the floor         │  rows 21-24
│ and I press on.                                                           │
│                                                                           │
│                                                                           │
└───────────────────────────────────────────────────────────────────────────┘  row 25
```

Key changes from current layout:
- Row 1 right panel: "── Floor 3/5 ──────" instead of empty border characters
- Row 2 minimap starts at col 61 (same as before) — no row lost to label
- Map is 19 cols wide (cols 61-79), up from 15
- T-junction shape clearly distinct from current L-shape
