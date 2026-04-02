# Shared Artifacts Registry: Turning Mechanic

## Purpose

Every `${variable}` appearing in journey TUI mockups, Gherkin scenarios, or user stories has a documented single source of truth here. Integration failures at wire-up time come from undocumented shared data.

---

## Registry

### facingDirection

| Field | Value |
|-------|-------|
| **Source of truth** | `GameState.facingDirection` (new field, `CardinalDirection` enum) |
| **Owner** | `GameDomain` module |
| **Type** | `CardinalDirection` enum: `.north`, `.east`, `.south`, `.west` |
| **Initial value** | `.north` (set in `GameState.initial(config:)`) |
| **Integration risk** | HIGH — if any consumer reads facing from a source other than `GameState.facingDirection`, the minimap caret, Facing label, and grid delta will desync |

**Consumers:**

| Consumer | Usage | How it reads |
|----------|-------|--------------|
| `Renderer.buildMinimap` | Appends caret to player `○` marker on minimap | `state.facingDirection` |
| `Renderer.buildMinimap` | Appends `Facing: N/S/E/W` label | `state.facingDirection` |
| `RulesEngine.apply(move:to:)` | Resolves grid delta for `move(.forward)` and `move(.backward)` | `state.facingDirection` |
| `RulesEngine.apply(turn:to:)` | Produces new `facingDirection` | Input state |

**Validation:** Every rendered frame, caret on minimap must match `GameState.facingDirection`. Add assertion in debug builds: `assert(minimapCaret == caretFor(state.facingDirection))`.

---

### playerPosition

| Field | Value |
|-------|-------|
| **Source of truth** | `GameState.playerPosition` (existing field) |
| **Owner** | `GameDomain` module |
| **Type** | `Int` (1D position along floor corridor) |
| **Integration risk** | MEDIUM — now mutable by `move(.forward/.backward)` through facing-relative delta; delta must use `facingDirection` not be hardcoded |

**Consumers (turning-mechanic additions):**

| Consumer | Usage | How it reads |
|----------|-------|--------------|
| `Renderer.buildMinimap` | Places `○` at position in minimap cell array | `state.playerPosition` |
| `RulesEngine` encounter check | Checks if movement lands on `encounterPosition` | `state.playerPosition + delta` |
| `RulesEngine` win check | Checks if `playerPosition == exitPosition && hasEgg` | `state.playerPosition` |

**Validation:** After `move(.forward)` while facing North, `playerPosition` must equal prior value + 1. After facing South, must equal prior value - 1. This is the key integration test for the facing-relative movement logic.

---

### CardinalDirection (new enum)

| Field | Value |
|-------|-------|
| **Source of truth** | `GameDomain.CardinalDirection` enum definition |
| **Owner** | `GameDomain` module |
| **Values** | `.north`, `.east`, `.south`, `.west` |
| **Integration risk** | LOW — pure value type; all consumers read from `GameState.facingDirection` |

**Rotation table (single source — define once in RulesEngine, reference nowhere else):**

| Current | Turn Left | Turn Right |
|---------|-----------|------------|
| `.north` | `.west` | `.east` |
| `.east` | `.north` | `.south` |
| `.south` | `.east` | `.west` |
| `.west` | `.south` | `.north` |

---

### TurnDirection (new enum in GameCommand)

| Field | Value |
|-------|-------|
| **Source of truth** | `GameCommand.turn(TurnDirection)` case |
| **Owner** | `GameDomain` module |
| **Values** | `.left`, `.right` |
| **Integration risk** | LOW — only consumed by `RulesEngine` turn handler and produced by `InputHandler` |

**Producers:**

| Producer | Trigger | Output |
|----------|---------|--------|
| `InputHandler.mapKey` | A key or Arrow Left | `.turn(.left)` |
| `InputHandler.mapKey` | D key or Arrow Right | `.turn(.right)` |

---

### minimap string (Thoughts panel row 21)

| Field | Value |
|-------|-------|
| **Source of truth** | `Renderer.buildMinimap(_ state:)` — computed each render tick |
| **Owner** | `Renderer` module |
| **Format** | `"Floor {N}:  [{cells}]  Facing: {N/S/E/W}"` |
| **Integration risk** | MEDIUM — player caret character (`^/>/ v/<`) must match `facingDirection`; if `buildMinimap` is called with stale state this will show wrong facing |

**Inputs to buildMinimap:**

| Input | Source |
|-------|--------|
| `state.playerPosition` | `GameState.playerPosition` |
| `state.facingDirection` | `GameState.facingDirection` |
| `state.currentFloor` | `GameState.currentFloor` |
| `state.hasEgg` | `GameState.hasEgg` |
| Floor landmarks | `FloorGenerator.generate(floorNumber:config:)` |

---

## Integration Checkpoint Summary

| Check | Description | Risk |
|-------|-------------|------|
| IC-01 | `GameState.initial` sets `facingDirection = .north` | LOW |
| IC-02 | `RulesEngine.apply(turn:)` uses rotation table once, defined in one place | LOW |
| IC-03 | `RulesEngine.apply(move(.forward))` uses `facingDirection` to compute delta | HIGH |
| IC-04 | `Renderer.buildMinimap` reads `state.facingDirection` — no cached copy | HIGH |
| IC-05 | `InputHandler` produces `.turn(.left)` for both A key and Arrow Left | LOW |
| IC-06 | `InputHandler` produces `.turn(.right)` for both D key and Arrow Right | LOW |
| IC-07 | Turn command processed in `.combat` screen mode without breaking encounter | MEDIUM |
