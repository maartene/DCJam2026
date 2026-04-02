# Wave Decisions: Turning Mechanic — DESIGN Wave

**Feature**: turning-mechanic
**Date**: 2026-04-02
**Author**: Morgan (Solution Architect — DESIGN wave)

This document records the decisions made during the DESIGN wave. Decisions inherited from the DISCUSS wave are listed for traceability but marked as settled — they are not re-opened here.

---

## Decisions Inherited from DISCUSS (settled, not re-opened)

| ID | Decision |
|----|----------|
| WD-01 | Minimap is the primary UX concern |
| WD-02 | Facing direction does not affect combat |
| WD-03 | Forward/backward movement is facing-relative |
| WD-04 | 90-degree turns, keyboard-invoked (jam rule) |
| WD-05 | `turnLeft` / `turnRight` movement model |
| WD-06 | W/S = move; A/D = turn |
| WD-07 | Arrow Left/Right = turn (mirrors A/D) |
| WD-08 | Turning blocked during combat |
| WD-09 | Minimap: dedicated 2D top-down region |
| WD-10 | Player marker: `^`/`>`/`v`/`<` |
| WD-11 | `GameState.facingDirection: CardinalDirection` |
| WD-12 | `GameCommand.turn(TurnDirection)` |
| WD-13 | Floor layout changes from 1D to 2D |

---

## Decisions Made in DESIGN Wave

### DSGN-01: Screen Layout — Vertical Split

**Decision**: Split the main view region (rows 2-16) vertically. Dungeon view occupies cols 2-59 (58 interior columns). Minimap panel occupies cols 61-79 (19 interior columns). A vertical divider at col 60 (ASCII `│`). Thoughts retains 4 display rows (rows 20-23). Controls hint is removed from the dungeon screen entirely — key bindings move to a future start screen (polish feature).

**Rationale**: The minimap must be a 2D grid, not a single line. A vertical split accommodates the 15×7 grid without losing dungeon view height. Thoughts flavor text has more replay value than an inline controls hint — the developer prefers 4 Thoughts rows and a clean screen. Key bindings are better served by a dedicated start screen.

**Alternatives rejected**:
- Placing minimap below the dungeon view: would require reducing dungeon view to 8 rows (rows 2-9), which is too small for the existing frame art style. Rejected.
- Replacing Thoughts panel with minimap: Thoughts provides narrative flavor that supports the dragon theme. Losing it entirely harms the game's character without saving a meaningful amount of layout space.

**See**: ADR-006

---

### DSGN-02: 2D Floor Grid Topology — L-Shaped Corridor

**Decision**: The standard floor is a 15×7 grid with an L-shaped corridor: a main north-south corridor at x=7 plus an east-west branch at y=3 (x=2...7). Origin at south-west corner; y increases northward.

**Rationale**: 15×7 was chosen to fit snugly in the minimap panel (19 chars wide) while respecting terminal font aspect ratio (~2:1 height:width). At 15 chars wide × 7 rows tall, the visual ratio is 15:14 ≈ square. Using all 13 available minimap rows would make the grid appear excessively tall. The L-shaped topology makes turning mechanically meaningful — reaching the egg room requires navigating the perpendicular branch.

**Alternatives rejected**:
- Straight corridor (1D mapped to 2D): turning would exist but be decorative only, since there is nowhere to go in the perpendicular direction. Rejected — fails the minimum meaningful-turning test.
- Randomly generated maze: adds complexity and debug surface in a 4-day jam. Post-jam scope.

**See**: ADR-004

---

### DSGN-03: Position Type — Named Struct

**Decision**: `Position` is a `struct` with named fields `x: Int` and `y: Int`. Not a tuple, not a typealias.

**Rationale**: A named struct is self-documenting at call sites and conforms to `Sendable`, `Equatable`, `Hashable` without additional work. Swift tuples are not `Sendable` (Swift 6 restriction). A typealias to `(Int, Int)` would fail Swift 6 strict concurrency if stored in `GameState` which is `Sendable`. Named struct is the correct choice.

**Alternatives rejected**:
- Swift tuple `(x: Int, y: Int)`: not `Sendable` in Swift 6. Rejected.
- SIMD2<Int>: overkill, introduces knowledge of SIMD in a domain with no numeric processing need. Rejected.

---

### DSGN-04: Minimap Panel Width — 19 Interior Columns

**Decision**: The minimap panel at cols 61-79 provides 19 interior characters. The 11-wide grid fits in 11 chars; remaining 8 chars accommodate a floor label and facing indicator label.

**Rationale**: Grid is 11 chars wide, needs 1 char left-margin = 12 chars minimum. 19 chars provides space for labels. Col 60 is the divider. This is tight but workable — the minimap panel content is structured (grid rows, then labels below the grid).

---

### DSGN-05: DungeonFrameKey Depth — Renderer Responsibility

**Decision**: The derivation of `DungeonFrameKey` from the 2D grid and `facingDirection` is entirely a `Renderer` responsibility. No domain type encapsulates this. The Renderer reads `FloorMap.cells` and `GameState.facingDirection` directly.

**Rationale**: DungeonFrameKey is a rendering concept, not a domain concept. The domain does not know about frame art, depth zones, or camera-facing. Keeping this in Renderer maintains the ports-and-adapters separation. The domain only needs to expose the 2D grid and the facing direction as facts.

---

### DSGN-06: Dungeon Frame Art Re-Authoring at 58 Columns

**Decision**: Existing dungeon frame art (78-char wide) must be re-authored at 58-char wide to fit the narrower dungeon view region after the vertical split. The frame table structure (`DungeonFrameKey` → `[String]`) is unchanged.

**Rationale**: Frame art is authored content, not generated. The 20-character reduction is significant but manageable — the perspective lines and wall art can be rescaled. This is a content task, not an architecture change. The `DungeonFrameKey` struct is unchanged; only the string values in the lookup table change.

---

## Open Questions — Resolved

| Question | Resolution |
|----------|------------|
| Where does the minimap go? | Vertical split: right panel, cols 61-79, rows 2-16 (DSGN-01) |
| What is the 2D floor topology? | L-shaped corridor, 11×7 grid (DSGN-02) |
| What type is `Position`? | Named struct with `x: Int, y: Int` (DSGN-03) |
| How is DungeonFrameKey derived in 2D? | Renderer reads 2D grid + facing, computes lookahead — Renderer responsibility, not domain (DSGN-05) |
| Do dungeon frames need re-authoring? | Yes — 78→58 chars wide (DSGN-06) |
| Does the Thoughts panel shrink? | Yes — 4 rows → 3 rows. Controls hint gets its own row. (DSGN-01) |

---

## Deferred to Post-Jam

| Question | Disposition |
|----------|-------------|
| Complex branching floor layouts (multiple corridors, rooms) | Post-jam — generator supports extension; consumer API (Cell grid) is stable |
| Random/procedural 2D floor generation | Post-jam — L-shaped corridor is hardcoded for jam |
| Dungeon frame art for perpendicular views (facing east along the branch) | Post-jam or stretch goal — branch corridor uses the same frame art as the main corridor |
