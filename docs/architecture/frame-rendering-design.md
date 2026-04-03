# Frame Rendering Design — Compositional Corridor Geometry

**Status**: Step 0 — reference mockups for implementation
**Date**: 2026-04-03

## Constraint

The dungeon viewport is **58 chars wide x 15 rows tall** (cols 2-59, rows 2-16 of the 80x25 terminal). This does not change.

---

## Corridor Geometry Constants

The frame uses nested rectangles converging to a vanishing point:

| Depth | Left wall col | Right wall col | Ceiling row | Floor row | Inner width |
|-------|---------------|----------------|-------------|-----------|-------------|
| D=0   | 0             | 57             | (edges)     | (edges)   | 56          |
| D=1   | 3             | 54             | 2           | 10        | 50          |
| D=2   | 6             | 51             | 4           | 8         | 44          |
| D=3   | (fog zone)    | (fog zone)     | (fog zone)  | (fog zone)| -           |

Perspective transition lines (connecting depth levels):

| Transition    | Left chars         | Right chars        | Rows      |
|---------------|--------------------|--------------------|-----------|
| D=0 to D=1 ceiling | col 1 `\`, col 2 `\`  | col 56 `/`, col 55 `/` | rows 1-2  |
| D=0 to D=1 floor   | col 1 `/`, col 2 `/`  | col 56 `\`, col 55 `\` | rows 11-10 |
| D=1 to D=2 ceiling | col 5 `\`            | col 52 `/`            | row 4     |
| D=1 to D=2 floor   | col 5 `/`            | col 52 `\`            | row 8     |

Wall characters: `|` vertical, `\` `/` perspective, `_` ceiling/floor surface.

---

## Floor Map Context (for reference positions)

Floor 1 grid (15x7, origin south-west):
```
y=6:  ####### S #######
y=5:  ####### . #######
y=4:  ####### . #######    <-- position 7,4
y=3:  ## . . . . . . #####  <-- position 7,3 (branch corridor y=3, x=2..7)
y=2:  ####### G #######
y=1:  ####### . #######
y=0:  ####### E #######
```

Main corridor: x=7, y=0..6 (vertical).
Branch corridor: y=3, x=2..7 (horizontal, going west).

---

## Reference: Base Corridor (depth=3, no openings)

This is the starting point. Both walls fully intact, fog at the far end.

```
|                                                        |  row  0: D=0 walls
|\                                                      /|  row  1: ceiling perspective D=0->D=1
| \____________________________________________________/ |  row  2: D=1 ceiling
|  |                                                  |  |  row  3: D=1 walls
|  | \______________________________________________/ |  |  row  4: D=2 ceiling
|  |  |  . . . . . . . . . . . . . . . . . . . .   |  |  |  row  5: fog
|  |  |      . . . . . . . . . . . . . . . .       |  |  |  row  6: fog (centre)
|  |  |  . . . . . . . . . . . . . . . . . . . .   |  |  |  row  7: fog
|  | /______________________________________________\ |  |  row  8: D=2 floor
|  |                                                  |  |  row  9: D=1 walls
| /____________________________________________________\ |  row 10: D=1 floor
|/                                                      \|  row 11: floor perspective D=1->D=0
|                                                        |  row 12: D=0 walls
                                                           row 13: (empty)
                                                           row 14: (empty)
```

---

## Mockup A: Position 7,3 facing South — near-right opening

**Frame key**: depth=3, nearRight=true (all others false)
**Meaning**: The right wall at D=0 (the wall directly beside the player) is absent — there is a corridor branching to the right.

**What changes from base**: The D=0 right wall boundary (col 57 `|`, plus ceiling/floor perspective at cols 55-56) is removed for the entire height. The D=1 right wall (col 54) remains visible, as does everything inside it.

```
|                                                           row  0: left D=0 wall only
|\                                                          row  1: left ceiling perspective only
| \____________________________________________________     row  2: D=1 ceiling, right edge open
|  |                                                  |     row  3: D=1 right wall visible, D=0 gone
|  | \______________________________________________/ |     row  4: D=2 ceiling, D=1 right wall visible
|  |  |  . . . . . . . . . . . . . . . . . . . .   |  |     row  5: fog, interior unchanged
|  |  |      . . . . . . . . . . . . . . . .       |  |     row  6: fog centre, interior unchanged
|  |  |  . . . . . . . . . . . . . . . . . . . .   |  |     row  7: fog, interior unchanged
|  | /______________________________________________\ |     row  8: D=2 floor, D=1 right wall visible
|  |                                                  |     row  9: D=1 right wall visible, D=0 gone
| /____________________________________________________     row 10: D=1 floor, right edge open
|/                                                          row 11: left floor perspective only
|                                                           row 12: left D=0 wall only
                                                            row 13
                                                            row 14
```

**Rule applied**: Remove all characters belonging to the D=0 right wall zone:
- Col 57 (`|`) for rows 0-12
- Col 56 (`/`) row 1 and col 56 (`\`) row 11 (perspective diagonals)
- Col 55 (`/`) row 2 and col 55 (`\`) row 10 (perspective diagonals)
- Replace all with spaces. Everything inside D=1 boundary is untouched.

**Mirror**: near-left opening applies the same rule to cols 0-2 on the left side.

---

## Mockup B: Position 7,4 facing South — far-right opening

**Frame key**: depth=3, farRight=true (all others false)
**Meaning**: One step ahead, there is a corridor branching to the right. The D=1 right wall has a visible gap.

**What changes from base**: The D=0 outer walls are fully intact. The D=1 right wall (col 54) and the D=1-to-D=2 perspective on the right (cols 52-53) are removed for the opening zone (rows 4-8). The D=1 wall at rows 3 and 9 remains intact (the "lintel" above and below the opening).

```
|                                                        |  row  0: both D=0 walls
|\                                                      /|  row  1: both ceiling perspectives
| \____________________________________________________/ |  row  2: D=1 ceiling complete
|  |                                                  |  |  row  3: D=1 walls intact (above opening)
|  | \______________________________________________     |  row  4: D=2 ceiling, gap cols 52-54
|  |  |  . . . . . . . . . . . . . . . . . . . .   |     |  row  5: fog, D=1 right wall gone
|  |  |      . . . . . . . . . . . . . . . .       |     |  row  6: fog, D=1 right wall gone
|  |  |  . . . . . . . . . . . . . . . . . . . .   |     |  row  7: fog, D=1 right wall gone
|  | /______________________________________________     |  row  8: D=2 floor, gap cols 52-54
|  |                                                  |  |  row  9: D=1 walls intact (below opening)
| /____________________________________________________\ |  row 10: D=1 floor complete
|/                                                      \|  row 11: both floor perspectives
|                                                        |  row 12: both D=0 walls
                                                            row 13
                                                            row 14
```

**Rule applied**: Remove the D=1-to-D=2 right-side connection for the opening zone:
- Col 52 (`/` row 4, `\` row 8 — D=2 perspective) -> space
- Col 53 (space) -> space (already space, no change)
- Col 54 (`|` rows 4-8 — D=1 right wall) -> space
- Rows 3 and 9 stay intact: the opening has visible top/bottom edges.

**Mirror**: far-left opening applies the same rule to cols 4-6 on the left side.

---

## Compositional Rendering Approach

Instead of authoring one monolithic frame per key combination, build frames by composition:

```
buildFrame(key: DungeonFrameKey) -> [String]:
    1. grid = baseCorridorGrid(depth: key.depth)       // both walls, no openings
    2. if key.nearLeft:  applyNearOpening(grid, side: .left)
    3. if key.nearRight: applyNearOpening(grid, side: .right)
    4. if key.farLeft:   applyFarOpening(grid, side: .left)
    5. if key.farRight:  applyFarOpening(grid, side: .right)
    6. return grid as [String]
```

Each opening modifier only touches characters in its own zone — they compose without conflict:
- Near-left: cols 0-2
- Near-right: cols 55-57
- Far-left: cols 4-6, rows 4-8
- Far-right: cols 52-54, rows 4-8

No zone overlaps, so any combination of openings can be applied independently.

---

## Slicing Plan

**Slice A (current)**: Gaps only — openings shown as removed wall segments. This document's mockups.

**Slice B (future)**: Visible side corridors — draw receding corridor geometry through each gap (ceiling/floor/back wall of the side passage visible through the opening).
