# Requirements: Turning Mechanic

## Business Capability

**DCJam 2026 compliance + navigation UX** — The game must feature 90-degree turns in four cardinal directions, invoked by keyboard control. Navigation must feel spatial and oriented; the player must never feel lost.

---

## Functional Requirements

### FR-01: CardinalDirection Domain Type

The `GameDomain` module must define a `CardinalDirection` value type with exactly four cases: `.north`, `.east`, `.south`, `.west`.

`GameState` must include a `facingDirection: CardinalDirection` field, initialised to `.north` in `GameState.initial(config:)`.

A `withFacingDirection(_:) -> GameState` functional updater must exist on `GameState`.

### FR-02: Turn Command

`GameCommand` must have a `case turn(TurnDirection)`. `TurnDirection` must have `.left` and `.right` cases.

`RulesEngine` must handle `.turn(direction)` by returning a new `GameState` with `facingDirection` updated according to the rotation table:

| Current facing | Turn left | Turn right |
|----------------|-----------|------------|
| `.north` | `.west` | `.east` |
| `.east` | `.north` | `.south` |
| `.south` | `.east` | `.west` |
| `.west` | `.south` | `.north` |

Turn must have zero side effects: no HP change, no dash change, no special change, no position change, no encounter change.

### FR-03: 2D Floor Model and Facing-Relative Movement

`FloorMap` must change from a 1D linear sequence to a 2D grid. `GameState.playerPosition` must change from a single `Int` to a 2D coordinate — a `Position` value type with `x: Int` and `y: Int` fields.

`RulesEngine` must resolve `move(.forward)` and `move(.backward)` using `state.facingDirection` to derive a 2D `(dx, dy)` delta:

| Facing | Forward (dx, dy) | Backward (dx, dy) |
|--------|-----------------|-------------------|
| `.north` | (0, +1) | (0, -1) |
| `.east` | (+1, 0) | (-1, 0) |
| `.south` | (0, -1) | (0, +1) |
| `.west` | (-1, 0) | (+1, 0) |

`playerPosition` must be clamped to the valid bounds of the 2D floor grid after delta application.

All existing movement rules (DISC-03 encounter lock, win condition check, staircase transition) are evaluated after the new delta is applied.

### FR-04: 2D Minimap with Facing Indicator

The minimap must display a 2D top-down view of the current floor grid. It must be rendered in a dedicated screen region (not inline in the Thoughts panel text). The screen layout will require updating to accommodate this region — exact placement is a DESIGN decision.

The player's position in the 2D minimap must be rendered using a directional character that reflects `state.facingDirection`:

| `facingDirection` | Player marker |
|-------------------|---------------|
| `.north` | `^` |
| `.east` | `>` |
| `.south` | `v` |
| `.west` | `<` |

Room/cell markers for non-player positions (walls, corridors, landmarks such as egg room, guard, staircase) are a DESIGN decision.

The player marker must override any landmark at the same position.

The minimap must update on the same render frame as any turn or movement command.

### FR-05: Input Key Bindings

`InputHandler` must map:

| Key | Byte(s) | Command |
|-----|---------|---------|
| `a` / `A` | `0x61` / `0x41` | `.turn(.left)` |
| `d` / `D` | `0x64` / `0x44` | `.turn(.right)` |
| Arrow Left | `[0x1B, 0x5B, 0x44]` | `.turn(.left)` |
| Arrow Right | `[0x1B, 0x5B, 0x43]` | `.turn(.right)` |

Existing bindings (W/S, Arrow Up/Down, 1/2/3, Space/Enter, R, Q/Esc) must remain unchanged.

The dungeon controls hint (row 19) must be updated to include turn instructions: `A/D: turn left/right`.

---

## Non-Functional Requirements

### NFR-01: Rendering latency

The minimap caret must update on the same render frame as the turn command is processed. No perceptible lag between key press and facing update.

### NFR-02: Screen layout change required

The 80×25 terminal layout WILL change to accommodate the 2D minimap region. The minimap cannot be an inline text string — it needs a grid-shaped area of the screen. Exact placement and size are a DESIGN decision. The dungeon view, status bar, and Thoughts panel may be resized or repositioned.

### NFR-03: Pure domain functions

All turn and movement logic must be pure functions (same inputs → same output, no side effects). Deterministic and testable via injected state.

### NFR-04: No performance regression

The turn command must not introduce any new heap allocations in the hot render path. `CardinalDirection` is a value type; no reference semantics.

---

## Business Rules

| Rule ID | Rule | Source |
|---------|------|--------|
| BR-01 | 90-degree turns only; no free-look, no diagonal facing | DCJam 2026 rules |
| BR-02 | Turning must be keyboard-invoked | DCJam 2026 rules |
| BR-03 | Facing direction does not affect combat damage or combat outcomes | WD-02 |
| BR-04 | Movement is always relative to current facing | WD-03 |
| BR-05 | Turning is blocked during combat encounters; permitted in all other screen modes | WD-08 |
| BR-06 | `GameState.facingDirection` is the single source of truth for all facing-dependent logic | WD-11 |
| BR-07 | On restart (`GameState.initial`), `facingDirection` resets to `.north` | INT-04 alignment |

---

## Integration Points

| Integration | From | To | Risk |
|-------------|------|----|------|
| `facingDirection` read by Renderer | `GameState` | `Renderer.buildMinimap` | HIGH — must not be cached |
| `facingDirection` read by RulesEngine | `GameState` | `RulesEngine.apply(move:)` | HIGH — delta must derive from this |
| `.turn` command produced by InputHandler | `InputHandler` | `GameLoop` → `RulesEngine` | LOW — simple enum case |
| Controls hint updated | `Renderer` | Row 19 string literal | LOW |

---

## Out of Scope

- Branching corridors / non-linear 2D floor layouts — the 2D grid must be implemented, but complex branching layouts with arbitrary room connectivity are post-jam scope
- Mouse-look or smooth rotation animation — not applicable to ASCII TUI
- Combat movement (Dash direction, escape direction) — Dash is not directional; it exits regardless of facing (existing rule REQ-09)
- Facing affecting combat outcomes — explicitly out of scope (WD-02)
