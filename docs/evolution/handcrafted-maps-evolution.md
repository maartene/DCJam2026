# Evolution: handcrafted-maps

**Date**: 2026-04-05
**Feature**: Replace procedural FloorGenerator with handcrafted floor definitions
**Status**: DELIVERED

---

## Summary

Introduced a `FloorDefinition` / `FloorRegistry` system that replaces the algorithmic `FloorGenerator` at all runtime call sites. Floor 1 is now expressed as a multi-line character-grid string literal embedded directly in Swift source. The generator is retained as an untouched test-utility baseline. The right-panel layout was updated to accommodate the new components: a floor label at row 2 (cols 61–79), minimap shifted to start at row 3, and legend shifted to rows 10–16.

---

## Steps Executed

| Step | Name | TDD Phases | Result |
|------|------|-----------|--------|
| 01-01 | FloorDefinition, FloorDefinitionParser, FloorRegistry — floor 1 character grid | PREPARE → RED_ACCEPTANCE → RED_UNIT → GREEN → COMMIT | PASS |
| 02-01 | Replace FloorGenerator with FloorRegistry at 3 RulesEngine + 1 Renderer call sites | PREPARE → RED_ACCEPTANCE → GREEN → COMMIT (RED_UNIT skipped — pre-existing RU-01 suite + acceptance tests sufficient) | PASS |
| 03-01 | Floor label row 2 cols 61-79; minimap row 3; legend rows 10-16; update existing row assertions | PREPARE → RED_ACCEPTANCE → GREEN → COMMIT (RED_UNIT skipped — acceptance tests FL-01/MM-01/ML-01 establish RED state) | PASS |

---

## Artifacts

### New production files
- `Sources/GameDomain/FloorDefinition.swift` — `public struct FloorDefinition` (single `grid: String` field, `Sendable`) and `FloorDefinitionParser` (internal, stateless scanner)
- `Sources/GameDomain/FloorRegistry.swift` — `public enum FloorRegistry` with `static func floor(_ number: Int, config: GameConfig) -> FloorMap`; floor 1 character grid; placeholder stubs for floors 2–5; fallback for unknown floor numbers

### Modified production files
- `Sources/GameDomain/RulesEngine.swift` — 3 call sites updated: `FloorGenerator.generate` → `FloorRegistry.floor` in `applyMove` (2 sites) and `applySpecial` (1 site)
- `Sources/App/Renderer.swift` — 1 call site updated (`FloorGenerator` → `FloorRegistry` in `renderDungeon`); floor label write added at row 2, col 61; minimap start row updated 2 → 3; legend rows updated 9–15 → 10–16

### New test files
- `Tests/DCJam2026Tests/HandcraftedMapsWalkingSkeletonTests.swift` — WS-01 through WS-07 (cell-for-cell passability parity between FloorRegistry and FloorGenerator; landmark positions; fallback behaviour)
- `Tests/DCJam2026Tests/HandcraftedMapsFloorDefinitionTests.swift` — RU-01 through RU-04 (movement through FloorRegistry-served floor 1)
- `Tests/DCJam2026Tests/HandcraftedMapsFloorLabelTests.swift` — FL-01 through FL-09 (label present in dungeon mode, absent in combat/death/win/start)
- `Tests/DCJam2026Tests/HandcraftedMapsMinimapTests.swift` — MM-01 through MM-05 (minimap first write at row 3; no write at row 2)

### Modified test files
- `Tests/DCJam2026Tests/MinimapTests.swift` — screenRow formula updated: `2 + (6-y)` → `3 + (6-y)`
- `Tests/DCJam2026Tests/MinimapLegendTests.swift` — row assertions updated: rows 9–15 → rows 10–16
- `Tests/DCJam2026Tests/GuardClearedAfterDefeatTests.swift` — minimap row formula updated (2 → 3)
- `Tests/DCJam2026Tests/HeadWardenBossTests.swift` — minimap row formula updated (2 → 3)
- `Tests/DCJam2026Tests/TransientOverlayRendererTests.swift` — thought text updated to reflect revised layout

### ADRs
- `docs/adrs/ADR-016-handcrafted-floor-character-grid-format.md` — Multi-line string `"""` chosen over `[String]`, `[[Bool]]`, JSON, and explicit position structs
- `docs/adrs/ADR-017-floorgenerator-retained-for-test-compatibility.md` — FloorGenerator retained unchanged as test utility; not deleted
- `docs/adrs/ADR-018-floor-label-in-top-border.md` — Floor label at row 2, cols 61–79, inside `renderDungeon`; `drawChrome` signature unchanged
- `docs/adrs/ADR-019-minimap-legend-conditional-suppression.md` — Floor height capped at 7 rows; legend rendered unconditionally at rows 10–16

---

## Key Design Decisions

**ADR-016**: The `"""` multi-line string character-grid format was chosen because it makes the entire floor topology visible as a spatial map block in Swift source — the developer literally sees the layout when reading the code. No external parsing library, no file I/O, no separate data structures to keep in sync.

**ADR-017**: `FloorGenerator` is retained unchanged to preserve the migration gate test (`WS-06`) that compares cell-for-cell passability between `FloorRegistry.floor(1, ...)` and `FloorGenerator.generate(floorNumber: 1, ...)`. Deleting it would destroy the independent comparison baseline.

**ADR-018**: The floor label is written directly inside `renderDungeon` at row 2, cols 61–79. `drawChrome()` signature is unchanged — no parameter threading, no refactor of existing call sites.

**ADR-019**: All handcrafted floor heights are capped at 7 rows. This makes `drawMinimapLegend()` an unconditional call with no layout arithmetic — the constraint is an authoring rule, not runtime logic.

---

## Test Results

All 337 tests pass (286 pre-existing + 51 new/modified).

---

## Timing

| Step | Phase | Start | End |
|------|-------|-------|-----|
| 01-01 | PREPARE → COMMIT | 10:07:32Z | 10:08:07Z |
| 02-01 | PREPARE → COMMIT | 10:15:48Z | 10:15:57Z |
| 03-01 | PREPARE → COMMIT | 10:17:50Z | 10:28:14Z |
