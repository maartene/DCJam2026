# Evolution: turning-mechanic

**Date**: 2026-04-02
**Status**: Complete
**Jam**: DCJam 2026

---

## Feature Summary

The turning-mechanic feature adds 90-degree first-person turns to Ember's Escape. Turning is a mandatory DCJam 2026 jam rule — all entries must support step movement on a square grid with cardinal direction turns.

### What Was Delivered

- `CardinalDirection` enum (`.north`, `.east`, `.south`, `.west`) — single source of truth for facing
- `TurnDirection` enum (`.left`, `.right`) — minimal turn input type
- `GameCommand.turn(TurnDirection)` — command case connecting input to domain
- `RulesEngine` turn handler with a complete 8-combination rotation table
- Combat turn blocking (WD-08): `.turn` commands ignored when `screenMode == .combat`
- `Position(x:y:)` struct replacing the previous `Int` player position
- `FloorMap` redesigned as a 15x7 2D grid with row-major `[[Cell]]` storage
- `FloorGenerator` producing an L-shaped corridor: main corridor at x=7, east-west branch at y=3 (x=2..7)
- Facing-relative movement deltas with wall collision and bounds clamping
- 2D minimap panel in the right screen region (cols 61-79, rows 2-16)
- Facing indicator `^>v<` on the player marker in the minimap
- Vertical split screen layout: dungeon view left (cols 2-59), minimap right (cols 61-79)
- Dungeon frame art resized from 78 to 58 columns
- `DungeonFrameKey` depth derived from 2D grid lookahead and `facingDirection` (Renderer responsibility)
- A/D and Arrow Left/Right key bindings for turning
- Facing persistence through floor transitions (copy-on-write `withCurrentFloor`)
- 132 tests passing across 17 test suites

### Business Context

DCJam 2026 mandates step movement on a 2D square grid as an entry requirement. Without this feature the game cannot be submitted. Beyond compliance, turning meaningfully expands navigation: the L-shaped corridor topology makes facing direction matter — the egg room is only reachable by entering the branch corridor at the correct heading.

---

## All 19 Delivery Steps

Steps are organised by phase. Each step ran the PREPARE → RED_ACCEPTANCE → RED_UNIT → GREEN → COMMIT sequence, with some phases skipped where noted.

### Phase 01: Domain Foundation (steps 01-01 to 01-04)

| Step | Name | RED_UNIT | Notes |
|------|------|----------|-------|
| 01-01 | Walking skeleton: CardinalDirection + facingDirection + turn handler | SKIPPED | Rotation table unit tests deferred to 01-02; walking skeleton covers observable outcome |
| 01-02 | Complete rotation table: all 8 combos, no side effects, 4-turn cycle | EXECUTED | RED_UNIT + GREEN both executed; rotation table fully tested |
| 01-03 | Initial state properties: 4 directions, north init, withFacingDirection copy | SKIPPED | Production code complete from 01-01; tests passed on activation |
| 01-04 | 2D floor grid: Position type, 15x7 FloorMap, FloorGenerator, landmark positions | SKIPPED | Acceptance test compile failures sufficient to drive implementation |

### Phase 02: Movement (steps 02-01 to 02-04)

| Step | Name | RED_UNIT | Notes |
|------|------|----------|-------|
| 02-01 | Forward/backward deltas for all 4 facings | SKIPPED | Acceptance tests through driving port cover all 5 behaviors within budget |
| 02-02 | Wall collision blocking and bounds clamping | SKIPPED | FloorGrid.cell passability API already tested via grid structure tests |
| 02-03 | Game rule preservation: encounter check and win condition after 2D move | SKIPPED | Tests passed immediately from RED_ACCEPTANCE |
| 02-04 | Turn key bindings: A/D and Arrow Left/Right with W/S regression guard | SKIPPED | 10 acceptance-level tests cover all distinct behaviors |

### Phase 03: Minimap Rendering (steps 03-01 to 03-04)

| Step | Name | RED_UNIT | Notes |
|------|------|----------|-------|
| 03-01 | 2D minimap panel in right region rows 2-16 cols 61-79 | SKIPPED | 2 acceptance tests cover both behaviors within budget |
| 03-02 | Facing indicator: ^>v< player marker for all four directions | SKIPPED | Acceptance tests are the unit tests here — 4 behavioral tests through Renderer.render |
| 03-03 | Player marker overrides landmarks and updates same frame as turn | SKIPPED | renderMinimap already drew player last; all 3 tests passed without code changes (GREEN also skipped) |
| 03-04 | Screen layout: vertical split with divider at col 60 | EXECUTED | No disabled acceptance tests existed; layout verification needed unit tests written directly |

### Phase 04: Combat Turn Blocking (steps 04-01 to 04-03)

| Step | Name | RED_UNIT | Notes |
|------|------|----------|-------|
| 04-01 | Turn ignored in .combat: facing unchanged, mode unchanged, HP unchanged | SKIPPED | Acceptance tests serve as unit tests |
| 04-02 | All 8 turn combinations blocked in combat for all starting facings | SKIPPED | No production code needed; guard in 04-01 fires regardless of facing or TurnDirection |
| 04-03 | Movement locked in combat regardless of facing, HP unchanged on locked move | SKIPPED | Tests passed immediately on activation; movement lock already present (GREEN also skipped) |

### Phase 05: Persistence and Edge Cases (steps 05-01 to 05-04)

| Step | Name | RED_UNIT | Notes |
|------|------|----------|-------|
| 05-01 | Facing persists through single and multiple floor transitions | SKIPPED | withCurrentFloor already correct via copy-on-write; no production code change (GREEN also skipped) |
| 05-02 | DungeonFrameKey depth from 2D grid and facing direction | EXECUTED | DISTILL scoped this as inner-loop crafter test; no acceptance scenario existed; RED_ACCEPTANCE skipped |
| 05-03 | Dungeon frame art re-authored at 58-column width | EXECUTED | DISTILL scoped as content task; RED_ACCEPTANCE skipped; unit tests written for frame widths |
| 05-04 | Rapid turn round-trip and integration smoke: all 46 scenarios pass | SKIPPED | No remaining disabled tests; all behaviors covered by prior steps |

---

## Key Wave Decisions

### DISCUSS Wave (WD-01 to WD-13)

These decisions were provided directly by the developer as settled requirements for a brownfield feature addition.

| ID | Decision |
|----|----------|
| WD-01 | Minimap is the primary UX concern — getting lost is not fun |
| WD-02 | Facing direction does NOT affect combat — turning is navigation-only |
| WD-03 | Forward/backward movement is facing-relative |
| WD-04 | 90-degree turns in four cardinal directions, keyboard-invoked (hard jam rule) |
| WD-05 | Movement model: `turnLeft`/`turnRight` (classic dungeon crawler model) |
| WD-06 | W/S = move forward/back; A/D = turn left/right |
| WD-07 | Arrow Left/Right = turn left/right (mirrors A/D) |
| WD-08 | Turning BLOCKED during combat encounters — no mechanical combat impact, high disorientation risk |
| WD-09 | Minimap: dedicated 2D top-down view (not inline text) |
| WD-10 | Facing indicator: `^`/`>`/`v`/`<` on player marker in minimap |
| WD-11 | `GameState.facingDirection: CardinalDirection` — single source of truth |
| WD-12 | `GameCommand.turn(TurnDirection)` — minimal command protocol extension |
| WD-13 | Floor layout changes from 1D (linear sequence) to 2D (x,y grid) — required for turning to have meaning |

### DESIGN Wave (DSGN-01 to DSGN-06)

| ID | Decision |
|----|----------|
| DSGN-01 | Vertical split: dungeon left (cols 2-59), minimap right (cols 61-79), divider at col 60. Thoughts stays 4 rows. Controls hint removed (deferred to future start screen). See ADR-006. |
| DSGN-02 | 15x7 L-shaped corridor grid: main corridor x=7, branch at y=3 (x=2..7). Visual aspect ratio 15:14 ≈ square at 2:1 terminal font. See ADR-004. |
| DSGN-03 | `Position` is a named `struct` with `x: Int` and `y: Int`. Swift tuples are not `Sendable` (Swift 6). Struct is self-documenting and compiler-enforced. See ADR-005. |
| DSGN-04 | Minimap panel at cols 61-79 provides 19 interior characters. Grid (15 chars wide) plus margin fits within this budget. |
| DSGN-05 | `DungeonFrameKey` derivation is entirely a Renderer responsibility. Domain does not know about depth zones or camera-facing. Maintains ports-and-adapters separation. |
| DSGN-06 | Dungeon frame art re-authored from 78-column to 58-column width to fit narrower dungeon view after split. Content task, not architecture change. |

### DISTILL Wave (DIST-01 to DIST-05)

| ID | Decision |
|----|----------|
| DIST-01 | Walking skeleton scoped to turn-left and turn-right only — no minimap or movement. Narrowest slice that proves the outer loop is closed. |
| DIST-02 | Minimap tests use TUIOutputSpy scoped to rows 2-16. Prevents false passes if the facing symbol appears elsewhere on screen. |
| DIST-03 | InputHandler API assumed as `mapKey(bytes: [UInt8]) -> GameCommand?`. The crafter must expose this for testing. |
| DIST-04 | No `@property` tag: the rotation table is exhaustive enumeration (8 combinations) not a property over an unbounded space. |
| DIST-05 | AC-06-2 interpretation: "ignored" means `facingDirection` is unchanged. No error returned — consistent with `RulesEngine` always returning `GameState`. |

---

## Issues Encountered

### Issue 1: 11x7 to 15x7 Grid Migration

**Wave**: Post-DISTILL (before DELIVER)
**Source**: DESIGN ADR-004 was revised after DISTILL ran.

DISTILL had written test scenarios and comments referencing an 11x7 grid with main corridor at x=4. The DESIGN wave updated to 15x7 with main corridor at x=7 after recognising that 11x7 left 8 empty rows in the 15-row minimap panel (poor aspect ratio). 15x7 gives a visual ratio of 15:14 ≈ square at 2:1 terminal font.

Resolution: DISTILL test files and `wave-decisions.md` were updated before DELIVER started. All test bodies were `{}` (disabled, empty) at that point, so only comments and test names changed. Zero test logic was affected.

### Issue 2: 1D to 2D Position Migration

**Wave**: DELIVER (step 01-04)
**Scope**: High-impact compiler-driven migration across RulesEngine, Renderer, and tests.

`GameState.playerPosition` changed from `Int` to `Position`. `FloorMap` landmark positions changed from `Int` to `Position`. The Swift 6 type system caught all call sites at compile time. No runtime failures — all mismatches were compile errors. The migration proceeded as one coordinated pass in step 01-04.

This was the largest single change in the feature (estimated 3.0 hours). The ports-and-adapters architecture contained the blast radius: only `RulesEngine`, `Renderer`, and test helpers needed updating, with `GameDomain`'s zero-import constraint enforced by SwiftPM.

### Issue 3: DES Hook Requiring RED_ACCEPTANCE in All Prompts

**Wave**: DELIVER (throughout)
**Source**: The DES (DELIVER Execution Standard) hook enforcing `RED_ACCEPTANCE` in every step prompt.

Several steps had no disabled acceptance tests to activate (e.g., 03-04 where all minimap tests were already enabled), or were scoped by DISTILL as inner-loop crafter tests with no acceptance scenario (05-02 DungeonFrameKey depth, 05-03 frame art re-authoring). In these cases the step required a `NOT_APPLICABLE` justification in the execution log and either (a) wrote unit tests directly or (b) noted that the RED_ACCEPTANCE gate was structurally inapplicable.

This did not block delivery but required explicit documentation of the skip rationale in `execution-log.json` for each affected step.

---

## Migrated Artifacts

| Original Location | Permanent Location |
|-------------------|--------------------|
| `docs/feature/turning-mechanic/design/architecture-design.md` | `docs/architecture/turning-mechanic/architecture-design.md` |
| `docs/feature/turning-mechanic/design/component-boundaries.md` | `docs/architecture/turning-mechanic/component-boundaries.md` |
| `docs/feature/turning-mechanic/design/data-models.md` | `docs/architecture/turning-mechanic/data-models.md` |
| `docs/feature/turning-mechanic/design/technology-stack.md` | `docs/architecture/turning-mechanic/technology-stack.md` |
| `docs/feature/turning-mechanic/distill/test-scenarios.md` | `docs/scenarios/turning-mechanic/test-scenarios.md` |
| `docs/feature/turning-mechanic/distill/walking-skeleton.md` | `docs/scenarios/turning-mechanic/walking-skeleton.md` |
| ADR-004 (2D floor grid topology) | `docs/adrs/ADR-004-2d-floor-grid-topology.md` (already in permanent location) |
| ADR-006 (screen layout — minimap) | `docs/adrs/ADR-006-screen-layout-minimap.md` (already in permanent location) |

`wave-decisions.md` files (DISCUSS, DESIGN, DISTILL) are not migrated — key decisions are extracted into this evolution document above.
