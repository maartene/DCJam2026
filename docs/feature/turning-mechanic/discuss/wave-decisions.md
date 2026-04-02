# Wave Decisions: Turning Mechanic

## Context

DISCOVER wave was not run. This feature is being added to a brownfield project (Dragon Escape, DCJam 2026).
All design constraints below were provided directly by the developer and are treated as settled decisions.

---

## Settled Decisions (Treat as Requirements)

| ID | Decision | Rationale |
|----|----------|-----------|
| WD-01 | Minimap is the primary UX concern | Getting lost is not fun; player must be able to orient at all times |
| WD-02 | Facing direction does NOT affect combat | Turning is navigation-only |
| WD-03 | Forward/backward movement is facing-relative | Turning opens a bigger explorable space |
| WD-04 | 90-degree turns in four cardinal directions, keyboard-invoked | Hard jam rule; non-negotiable |
| WD-05 | Movement model: `turnLeft`, `turnRight` replaces absolute NSEW | Classic dungeon crawler model confirmed |
| WD-06 | W/S = move forward/back; A/D = turn left/right | Extends existing W/S bindings naturally |
| WD-07 | Arrow Left/Right = turn left/right (mirrors A/D) | Extends existing arrow up/down bindings |
| WD-08 | Turning is BLOCKED during combat encounters | No visual feedback other than minimap; disorientation risk is high; turning has no mechanical combat impact, so blocking it is the correct trade-off |
| WD-09 | Minimap: dedicated 2D top-down view (NOT inline text in Thoughts panel) | 2D floor layout requires a 2D minimap; a single text string cannot represent a grid; screen layout WILL change to accommodate this |
| WD-10 | Facing indicator: `^`/`>`/`v`/`<` character on player marker in 2D minimap | Readable at terminal scale; replaces the circular `○` marker with a directional one |
| WD-11 | `GameState.facingDirection` new field; type `CardinalDirection` (.north, .east, .south, .west) | Single source of truth for facing |
| WD-12 | `GameCommand.turn(TurnDirection)` added; `TurnDirection` has `.left` and `.right` | Minimal command protocol change |
| WD-13 | Floor layout changes from 1D (linear sequence) to 2D (x,y grid) | Turning only has meaning and value if the player can navigate in two spatial dimensions; 1D corridor makes left/right facing semantically equivalent — a 2D grid is required for the mechanic to work correctly |

---

## Open Questions Resolved During This Wave

| Question | Resolution |
|----------|------------|
| Minimap placement | Dedicated 2D top-down region; screen layout must change to fit — exact placement is a DESIGN decision |
| Facing indicator style | Directional caret (^ > v <) replaces `○` in 2D minimap grid |
| Movement after turning | Relative forward/back with 2D (dx,dy) deltas from facing direction |
| Keyboard layout | A/D + Arrow Left/Right for turning; W/S + Arrow Up/Down stay for movement |
| Turn in combat | BLOCKED — no turning during combat encounters |
| Floor model | 2D grid (x,y) required — 1D is insufficient for turning to have meaning |

---

## Architecture Alignment

- `GameDomain` is the single source of truth for `CardinalDirection` enum and `GameState.facingDirection`
- `InputHandler` maps A/D and Arrow Left/Right to `.turn(.left)` / `.turn(.right)`
- `RulesEngine` resolves `turn` command into new `facingDirection` (pure function; no side effects); turn is rejected/ignored during `.combat` screen mode
- `RulesEngine` resolves `move(.forward)` / `move(.backward)` using `facingDirection` to derive 2D `(dx, dy)` delta applied to `playerPosition: (x: Int, y: Int)`
- `FloorMap` changes from 1D array to 2D grid; `FloorGenerator` must generate 2D layouts
- `GameState.playerPosition` changes from `Int` to a 2D coordinate type (e.g., `Position` struct with `x` and `y`)
- `Renderer` requires a dedicated 2D minimap region using `^`/`>`/`v`/`<` for player facing; screen layout change required
- `DungeonFrameKey` depth calculation must derive from the 2D position and facing direction
