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

### Slice A (gaps only — implemented)

**Rule applied**: Remove all characters belonging to the D=0 right wall zone:
- Col 57 (`|`) for rows 0-12
- Col 56 (`/`) row 1 and col 56 (`\`) row 11 (perspective diagonals)
- Col 55 (`/`) row 2 and col 55 (`\`) row 10 (perspective diagonals)
- Replace all with spaces. Everything inside D=1 boundary is untouched.

**Mirror**: near-left applies the same rule to cols 0-2 on the left side.

### Slice B (visible side corridor — reference mockup)

**What changes from Slice A**: The ceiling line (row 2) and floor line (row 10) extend all the way to the right frame edge using `_`. This implies the ceiling and floor planes continuing into the open side corridor. No back wall — the corridor extends beyond draw distance.

```
|                                                           row  0: left wall only
|\                                                          row  1: left ceiling perspective only
| \_______________________________________________________  row  2: ceiling underscores extend to col 57
|  |                                                  |     row  3: D=1 right wall visible, D=0 gone
|  | \______________________________________________/ |     row  4: D=2 ceiling, D=1 right wall visible
|  |  |  . . . . . . . . . . . . . . . . . . . .   |  |     row  5: fog, interior unchanged
|  |  |      . . . . . . . . . . . . . . . .       |  |     row  6: fog centre, interior unchanged
|  |  |  . . . . . . . . . . . . . . . . . . . .   |  |     row  7: fog, interior unchanged
|  | /______________________________________________\ |     row  8: D=2 floor, D=1 right wall visible
|  |                                                  |     row  9: D=1 right wall visible, D=0 gone
| /_______________________________________________________  row 10: floor underscores extend to col 57
|/                                                          row 11: left floor perspective only
|                                                           row 12: left wall only
                                                            row 13
                                                            row 14
```

**Slice B rule** (additive on top of Slice A):
- Row 2: replace trailing 3 spaces (cols 55-57) with `___`
- Row 10: replace trailing 3 spaces (cols 55-57) with `___`

**Mirror**: near-left Slice B extends rows 2 and 10 underscores leftward to col 0 (replacing the leading spaces at cols 0-2).

---

## Mockup B: Position 7,4 facing South — far-right opening

**Frame key**: depth=3, farRight=true (all others false)
**Meaning**: One step ahead, there is a corridor branching to the right. The D=1 right wall has a visible gap.

### Slice A (gaps only — implemented)

The D=0 outer walls are fully intact. The D=1 right wall (col 54) and the D=1-to-D=2 perspective at col 52 are removed for the opening zone (rows 4-8). Rows 3 and 9 remain as lintels.

**Rule applied**:
- Col 52 (`/` row 4, `\` row 8) → space
- Col 54 (`|` rows 4-8) → space
- Rows 3 and 9 stay intact.

**Mirror**: far-left applies the same rule to cols 4-6 on the left side.

### Slice B (visible side corridor — locked reference mockup)

**What changes from Slice A**: A back wall `|` is drawn inside the gap (at col 55), with a ceiling stub `__` on row 3 and a floor stub `_` on row 8, showing the entrance of the side corridor.

```
|                                                        |  row  0: both D=0 walls
|\                                                      /|  row  1: both ceiling perspectives
| \____________________________________________________/ |  row  2: D=1 ceiling complete
|  |                                                 __| |  row  3: ceiling stub of side corridor
|  | \______________________________________________/| | |  row  4: D=2 ceiling + back wall visible
|  |  |  . . . . . . . . . . . . . . . . . . . .   | | | |  row  5: fog + back wall + D=0 outer wall
|  |  |      . . . . . . . . . . . . . . . .       | | | |  row  6: fog + back wall + D=0 outer wall
|  |  |  . . . . . . . . . . . . . . . . . . . .   | | | |  row  7: fog + back wall + D=0 outer wall
|  | /______________________________________________\|_| |  row  8: D=2 floor + floor stub
|  |                                                   | |  row  9: D=1 walls intact (below opening)
| /____________________________________________________\ |  row 10: D=1 floor complete
|/                                                      \|  row 11: both floor perspectives
|                                                        |  row 12: both D=0 walls
```

**Slice B rule** (additive on top of Slice A):
- Row 3: col 53=`_`, col 54=`_` (ceiling stub — overwrites the lintel spaces, keeps `|` at 54 from Slice A intact as the right edge of stub)
- Rows 4-8: col 55=`|` (back wall of side corridor)
- Row 8: col 53=`_` (floor stub)

**Mirror**: far-left Slice B places back wall at col 2, ceiling/floor stubs at col 4.

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

**Slice A (complete)**: Gaps only — implemented. Near and far openings shown as removed wall segments. All 16 combinations for depths 1-3 generated compositionally.

**Slice B (next)**: Visible side corridors — mockups locked above. Near openings: extend ceiling/floor underscores to frame edge. Far openings: add back wall `|` at col 55 (right) / col 2 (left) with ceiling/floor stubs.
