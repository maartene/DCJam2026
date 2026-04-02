# ADR-004: 2D Floor Grid Topology for Turning Mechanic

**Date**: 2026-04-02
**Status**: Accepted
**Author**: Morgan (Solution Architect — DESIGN wave)
**Deciders**: Maarten Engels (developer)

---

## Context

The turning mechanic (WD-13) requires the floor model to change from a 1D linear sequence to a 2D grid. The jam rule mandates step movement on a square grid with 90-degree turns. A 1D corridor makes left/right facing semantically equivalent — turning left and turning right both face the same wall. A 2D grid is required for the mechanic to be meaningful.

The question is: what topology does the 2D grid use? Options range from a trivially extended 1D corridor (straight north-south with no branches) to a fully generated maze.

Jam constraints:
- Step movement on a square grid (jam rule, non-negotiable)
- Solo developer, 4-day jam window remaining
- Existing landmarks must be preserved: entry, egg room, guard encounter, staircase, exit

Requirements:
- Turning must be mechanically meaningful — there must be somewhere to go when the player faces perpendicular to their current path
- All existing landmarks must have valid 2D positions
- FloorGenerator must remain a stateless function (no class, no mutable state)

---

## Decision

**L-shaped corridor on a 15×7 grid.**

Coordinate convention: origin `(0, 0)` at south-west corner. X increases eastward. Y increases northward.

Main corridor: `x = 7`, `y = 0...6` (north-south).
Branch corridor: `y = 3`, `x = 2...7` (east-west, connecting to the main corridor at the junction `(7, 3)`).

All other cells are `.wall`.

Grid visualisation (15 columns × 7 rows, landmark chars replace corridor `#`):

```
Y
6  . . . . . . . S . . . . . . .     S = staircase/exit
5  . . . . . . . . . . . . . . .
4  . . . . . . . . . . . . . . .
3  . . * . . . . G . . . . . . .     * = egg room, G = guard encounter
2  . . . . . . . . . . . . . . .
1  . . . . . . . . . . . . . . .
0  . . . . . . . E . . . . . . .     E = entry
   0 1 2 3 4 5 6 7 8 9 . . . 14    X
```

Standard landmark positions:

| Landmark | Position | Notes |
|----------|----------|-------|
| Entry | (7, 0) | South end of main corridor |
| Staircase | (7, 6) | North end of main corridor (non-final floors) |
| Exit | (7, 6) | Same position (final floor only) |
| Egg room | (2, 3) | West dead-end of branch |
| Encounter (standard) | (7, 3) | Junction of main corridor and branch |
| Boss encounter | (7, 3) | Same junction (final floor) |

The branch runs from `x=2` (west dead-end, egg room) to `x=7` (junction with main corridor). Reaching the egg room requires the player to navigate to the junction at `(7, 3)`, turn west, and walk forward five cells.

**Floor size constraint and aspect ratio rationale:**

The minimap panel is 19 chars wide × 15 rows tall (rows 2-16 of the screen). Terminal fonts are approximately 2:1 height-to-width — a character cell is roughly twice as tall as it is wide. To appear visually square in the minimap, the floor grid must satisfy:

```
grid_width (chars) ≈ 2 × grid_height (rows)
```

At 15 chars wide and 7 rows tall: visual ratio = 15 : (7 × 2) = 15:14 ≈ 1:1. This is the target — a floor that looks square in a typical terminal font.

The grid uses 15 of the 19 available minimap columns (2-char margins left and right) and 7 of the 13 usable minimap rows (1-row header + 1-row facing label overhead, 6 rows clear below the grid). This is intentionally "snug but not full" — using all 13 rows would make the grid appear extremely tall due to the font aspect ratio.

---

## Alternatives Considered

### Option A: Straight North-South Corridor (1D mapped to 2D)

Represent the existing 1D corridor as a single-column 2D grid: `x = 4`, `y = 0...10`. No east-west branch.

Trade-offs:
- Positive: Minimal change from 1D. All existing position values map trivially to `Position(x: 4, y: oldInt)`.
- Negative: Turning exists but is decorative — there is nowhere to go in the perpendicular direction. The player can turn left (face west) and press forward, and hit a wall immediately. This satisfies the jam rule letter but not its spirit. KPI-3 (navigation efficiency) would be unachievable.
- Rejected: Fails the "meaningful turning" requirement. WD-13 explicitly states that "a 2D grid is required for the mechanic to work correctly."

### Option B: L-Shaped Corridor (chosen)

One branch at the midpoint of the main corridor. The branch dead-ends at the egg room on one side.

- Positive: Simplest topology that makes turning mechanically meaningful. The player must navigate a perpendicular segment to reach the egg.
- Positive: All landmarks fit naturally: junction = encounter, branch end = egg room.
- Positive: Generatable by a stateless function with constants. No randomness required.
- Positive: Minimap is unambiguously readable at 11×7: player can orient by seeing the L.
- Negative: Only one branch — the dungeon feels simple. Acceptable for jam scope.
- Accepted.

### Option C: T-Junction or Cross Layout

Branch in both directions from the main corridor (east and west dead-ends).

- Positive: Slightly more exploration space.
- Negative: Adds a dead-end corridor with no landmark. At jam scope, an empty dead-end is padding. Post-jam: the east branch could hold an upgrade room or encounter.
- Deferred to post-jam: the L-shaped topology can extend to a T or cross by uncommenting two extra branch segments in FloorGenerator. The Cell grid API already supports it.

### Option D: Procedurally Generated Maze

BSP, recursive backtracker, or Prim's algorithm to generate a fresh layout each run.

- Positive: Replayability.
- Negative: Adds significant implementation complexity. The minimap must handle arbitrary layouts. Frame art must handle all possible neighbor configurations (left, right, ahead passable in any combination). The existing 52-frame DungeonFrameKey table was designed with corridor-style views; a maze with many open sides would require dozens more frames or a fallback rendering mode.
- Negative: Debugging a generated layout under time pressure is high risk.
- Deferred to post-jam: the Cell grid is maze-ready. Swapping FloorGenerator is the only required change.

---

## Consequences

### Positive
- FloorGenerator remains a simple stateless function with hardcoded positions — same pattern, extended
- The minimap is unambiguous at 11×7: the L-shape is immediately readable
- All existing landmarks have natural positions on the L
- The crafter can implement the full feature without maze generation complexity

### Negative
- The dungeon has the same layout on every floor (same topology, different landmark assignments based on floor number). Post-jam: topology variation via Option C or D.
- Re-authoring dungeon frame art for perpendicular views (facing east or west along the branch) is additional content work. The branch looks like a standard corridor, so the existing frame art applies — no new frames are strictly required for the walking skeleton.

### Note for Software Crafter

`FloorGenerator.generate(floorNumber:config:)` must produce a 15×7 `FloorMap` with the topology above. The grid is hardcoded for jam scope. No spatial algorithm is needed — set cells by position constants. The main corridor is at x=7; the branch at y=3 (x=2..7) determines where the egg room and encounter landmarks live.

When reading `cells[y][x]`, index y is the row (0 = south) and x is the column (0 = west). Accessing `cells[playerPosition.y][playerPosition.x]` returns the cell at the player's current position.

`GameState.initial(config:)` sets `playerPosition = Position(x: 7, y: 0)` (entry cell). `facingDirection` initialises to `.north`.
