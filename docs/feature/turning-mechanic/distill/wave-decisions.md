# Wave Decisions: Turning Mechanic — DISTILL Wave

**Feature**: turning-mechanic
**Date**: 2026-04-02
**Author**: Quinn (Acceptance Test Designer — DISTILL wave)

---

## Decisions Inherited from DESIGN (settled, not re-opened)

| ID | Decision | Impact on Tests |
|----|----------|-----------------|
| WD-08 | Turning blocked during combat | TurningEdgeCaseTests: `.turn` in `.combat` asserts facingDirection unchanged |
| WD-09 | Minimap: dedicated 2D region | MinimapTests: assertions scoped to rows 2-16 (minimap panel) |
| WD-13 | 2D floor layout | TwoDFloorTests: all positions use `Position(x:y:)` |
| DSGN-01 | Vertical split; Thoughts stays 4 rows; controls hint removed | AC-05-8 has no test (out of scope) |
| DSGN-02 | 15×7 L-shaped corridor (updated post-DISTILL; see upstream-issues.md) | TwoDFloorTests: grid dimensions, corridor/wall assertions, landmark positions |
| DSGN-03 | Position = named struct `(x: Int, y: Int)` | All positional tests use `Position(x:y:)` — no tuple or integer comparison |

---

## Decisions Made in DISTILL Wave

### DIST-01: Walking Skeleton Scope

**Decision**: The walking skeleton covers only turn-left and turn-right from the initial state. It does not include minimap rendering or floor movement.

**Rationale**: The minimum observable outcome that proves the outer loop is closed is `facingDirection` changing after a `RulesEngine.apply(command: .turn(...))` call. Adding minimap or movement to the skeleton would couple it to three additional unimplemented components and delay the first GREEN signal. The narrower skeleton allows the crafter to implement `CardinalDirection`, `TurnDirection`, `GameState.facingDirection`, and the `RulesEngine.turn` handler as a single focused unit before expanding.

---

### DIST-02: Minimap Tests Use TUIOutputSpy Scoped to Rows 2-16

**Decision**: MinimapTests assertions filter `spy.entries` to rows 2-16 (the minimap panel) rather than the full terminal.

**Rationale**: The minimap panel occupies cols 61-79, rows 2-16 per DSGN-01. Filtering to those rows isolates the minimap assertions from Thoughts and status bar writes. This prevents false passes if the facing symbol happens to appear elsewhere on screen.

**Risk**: If the Renderer writes minimap content at different row numbers than 2-16, these tests will fail. The row range is derived from DSGN-01 and is a design contract, not a test assumption.

---

### DIST-03: InputHandler API Assumed as `mapKey(bytes: [UInt8]) -> GameCommand?`

**Decision**: TurnKeyBindingTests call `handler.mapKey(bytes: [UInt8])` returning an optional `GameCommand`.

**Rationale**: The existing codebase does not expose `InputHandler.mapKey` as a public testable API in the current sources. The crafter must make `mapKey` (or an equivalent) testable. The optional return type (`GameCommand?`) accommodates the case where a byte sequence is not mapped to any command. The rapid-turn test uses `?? .none` to handle nil safely.

**Alternative considered**: Testing InputHandler indirectly via a full game loop integration. Rejected — this would couple key binding tests to the game loop timing and non-blocking fd behavior, making them fragile.

---

### DIST-04: Property-Tagged Scenarios

**Decision**: No `@property` tag applied to any scenario in this feature.

**Rationale**: The rotation table test (`fullRotationTableIsCorrect`) checks all 8 combinations exhaustively — it is already complete enumeration, not a property. The four-consecutive-turns test (`fourConsecutiveLeftTurnsReturnToStart`) could be framed as a property ("for any starting direction, four same-direction turns return to start"), but the finite enum of 4 directions makes exhaustive testing more appropriate than a generator. No scenario in this feature meets the property-signal criteria (universal invariant over an unbounded input space).

---

### DIST-05: AC-06-2 Interpretation — "Ignored" vs "Blocked"

**Decision**: Tests assert `facingDirection` is unchanged (not that an error is returned).

**Rationale**: DISCUSS user-stories.md said "turn accepted" (stale); DESIGN wave-decisions.md says WD-08 "turning BLOCKED"; DISCUSS acceptance-criteria.md AC-06-2 says "ignores (discards) .turn commands when screenMode == .combat". "Ignore/discard" is the observable behavior: the command is received, no state changes. No error is returned — this is consistent with the pure function design of `RulesEngine` which always returns a `GameState`.

---

## Deferred

| Item | Disposition |
|------|-------------|
| DungeonFrameKey depth calculation in 2D | Renderer concern; no acceptance test required at this level. The crafter's unit tests for DungeonFrameKey derivation are inner-loop tests. |
| Frame art re-authoring at 58 columns | Content task; no automated test. Verified by developer playtesting. |
| Egg room minimap symbol on floors 2-4 | Covered by player-marker-overrides-landmark tests; specific egg symbol not tested separately (low value). |

---

## Mandate Compliance Evidence

### CM-A: Driving Port Usage

All GameDomain tests:
```swift
import Testing
@testable import GameDomain
// Invokes: RulesEngine.apply(command:to:deltaTime:)
//          GameState.initial(config:)
//          FloorGenerator.generate(floorNumber:config:)
```

MinimapTests and TurnKeyBindingTests:
```swift
import Testing
@testable import DCJam2026
@testable import GameDomain
// Invokes: Renderer.render(_:) via TUIOutputSpy
//          InputHandler.mapKey(bytes:)
```

No internal component (validator, parser, Cell directly) is invoked in any test.

### CM-B: Zero Technical Terms in Test Names

Verified: no HTTP, SQL, JSON, database, API, endpoint, or framework terms appear in any `@Test` title or `@Suite` title. All names use: Ember, facing, turn, floor, combat, minimap, corridor, encounter, position, staircase, egg, entry.

### CM-C: Walking Skeleton + Focused Scenario Counts

- Walking skeletons: 1 (`emberTurnsLeftAndRight` — covers observable user outcome E2E through domain)
- Focused scenarios: 45 (disabled, one enabled per DELIVER iteration)
- Total: 46 scenarios across 5 test files and 6 user stories
