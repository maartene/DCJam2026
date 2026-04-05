# Component Boundaries — handcrafted-maps

**Feature**: handcrafted-maps
**Wave**: DESIGN
**Date**: 2026-04-04

---

## Module Map

All new types live in `GameDomain`. No new SwiftPM targets are added.

```
GameDomain (existing module — zero external imports)
├── FloorDefinition          NEW — pure data container
├── FloorDefinitionParser    NEW — character grid → FloorGrid + positions
├── FloorRegistry            NEW — floor number → FloorMap (replaces FloorGenerator call sites)
├── HandcraftedFloors.swift  NEW — five FloorDefinition constants (file, not a type)
├── FloorGenerator           UNCHANGED — retained for test compatibility
├── FloorMap / FloorGrid / FloorCell  UNCHANGED
├── GameState                UNCHANGED
└── RulesEngine              MODIFIED — 3 call sites replaced (FloorGenerator → FloorRegistry)

Renderer (existing module — imports GameDomain)
└── Renderer.swift           MODIFIED — 1 call site replaced; floor label moved to row 2 cols 61-79; minimap start row updated to 3
```

---

## Dependency Graph

```
FloorDefinition         ← no dependencies
FloorDefinitionParser   ← FloorDefinition, FloorGrid, FloorCell, Position
FloorRegistry           ← FloorDefinition, FloorDefinitionParser, FloorMap, GameConfig
RulesEngine             ← FloorRegistry (replaces FloorGenerator)
Renderer                ← FloorRegistry (replaces FloorGenerator)
FloorGenerator          ← FloorGrid, FloorMap, GameConfig (unchanged)
```

Dependency rule: all arrows point inward toward `FloorDefinition`. No cycles. `FloorDefinitionParser` never calls `FloorRegistry`; `FloorRegistry` never calls `FloorGenerator`.

---

## Type Responsibilities

### `FloorDefinition` — `GameDomain`

**Owns**: The character grid (`rows: [String]`) for one floor.

**Does not own**:
- Passability logic (that is `FloorDefinitionParser`'s job)
- Position extraction (that is `FloorDefinitionParser`'s job)
- Game rules (egg eligibility, boss, exit flags) — those live in `FloorRegistry`

**Invariants enforced at design time** (not runtime — jam scope):
- All strings in `rows` have equal length (enforced by the developer authoring the literal)
- All characters belong to the vocabulary (`#`, `.`, `^`, `>`, `v`, `<`, `G`, `B`, `*`, `S`, `X`, `E`)

**Access**: `public` (GameDomain is imported by Renderer and RulesEngine indirectly via GameLoop)

---

### `FloorDefinitionParser` — `GameDomain`

**Owns**: The mapping from character grid to `FloorGrid` and landmark positions.

**Single responsibility**: Given a `FloorDefinition`, return a `FloorGrid` and a set of named optional `Position` values for each vocabulary landmark.

**Does not own**:
- Which floor number is being parsed
- Whether a landmark is "expected" for this floor (that is `FloorRegistry`)
- Any state between parse calls

**Access**: `internal` to `GameDomain`. Only `FloorRegistry` calls it. Not exposed to `Renderer` or `RulesEngine`.

---

### `FloorRegistry` — `GameDomain`

**Owns**: The five `FloorDefinition` constants and the `floor(_ floorNumber: Int, config: GameConfig) -> FloorMap` interface.

**Single responsibility**: Map floor number to `FloorMap`. Apply game-rule flags (`hasEggRoom`, `hasBossEncounter`, `hasExitSquare`) derived from the parsed grid and floor number context.

**Game rule application**:
- `hasEggRoom = parsed.eggPosition != nil` — the grid is authoritative; no floor-number conditional needed (the floor 1 grid has no `*`, the floor 5 grid has no `*`)
- `hasBossEncounter = parsed.bossPosition != nil` — same principle
- `hasExitSquare = parsed.exitPosition != nil` — same principle
- `staircasePosition2D`: if `hasExitSquare`, the staircase sentinel `Position(x: Int.max, y: Int.max)` is used (consistent with existing `FloorMap.staircasePosition` accessor pattern); else the parsed `S` position
- `exitPosition2D`: parsed `X` position if present; else `staircasePosition2D` (matches existing `FloorGenerator` convention)

**Does not own**: Character parsing, passability, grid construction.

**Access**: `public` — called by `RulesEngine` and `Renderer`.

---

### `HandcraftedFloors.swift` — `GameDomain`

Not a type — a Swift source file containing five `FloorDefinition` constants as private or internal static properties accessible to `FloorRegistry`.

Suggested structure: private constants at file scope, or nested in a private extension on `FloorRegistry`. The crafter decides the exact organization.

---

### `Renderer` — `Renderer` module

**Modified methods**:

1. `renderDungeon(_ state:)` — replace `FloorGenerator.generate` with `FloorRegistry.floor`. Replace the existing floor label write at row 2 with a write at row 2, cols 61–79. Update minimap start row from 2 to 3.

2. `drawChrome()` — **unchanged**. Signature is not modified. No parameter threading required.

3. `drawMinimapLegend()` — called unconditionally. All authored floors are ≤6 rows tall (authoring constraint from ADR-019), so legend rows 9–15 are never obstructed.

**Call chain in dungeon mode** (after this feature):
```
render(state) → renderDungeon(state)
    → FloorRegistry.floor(state.currentFloor, config: state.config) → FloorMap
    → drawChrome()                             [row 1: plain ─ fill, unchanged]
    → write floor label at row 2, cols 61-79
    → renderDungeonView(frame, key)            [rows 2-16, cols 2-59]
    → renderMinimap(floor, state)              [rows 3+, cols 61-79]
    → drawMinimapLegend()                      [rows 9-15, unconditional]
```

---

## What Is NOT Changing

| Type | Location | Status |
|------|----------|--------|
| `FloorGenerator` | `GameDomain` | Unchanged — public API preserved |
| `FloorMap` | `GameDomain` | Unchanged — `FloorRegistry` returns the same type |
| `FloorGrid` | `GameDomain` | Unchanged |
| `FloorCell` | `GameDomain` | Unchanged |
| `GameState` | `GameDomain` | Unchanged |
| `GameRun` | `GameDomain` | Unchanged — `FloorGenerator.generateRun` still compiles |
| Test files calling `FloorGenerator.generate` | Test targets | Unchanged — `FloorGenerator` is not deleted |
| `TUILayer`, `InputHandler`, `GameLoop`, `DCJam2026` | respective modules | Unchanged |
