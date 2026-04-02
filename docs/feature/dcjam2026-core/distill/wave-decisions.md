# Wave Decisions — DISTILL Wave
**Feature**: dcjam2026-core
**Date**: 2026-04-02
**Author**: Quinn (Acceptance Test Designer — DISTILL wave)

---

## DISTILL-01: Test framework — Swift Testing (import Testing), no Cucumber or BDD DSL

**Date**: 2026-04-02
**Status**: FINAL (pre-decided by developer)

**Decision**: Use Swift Testing (`import Testing`, `@Suite`, `@Test`, `#expect`) built into Swift 6.3. Given-When-Then expressed as inline comments and test method names. No Cucumber, no pytest-bdd, no Gherkin `.feature` files.

**Rationale**: The project has zero external dependencies (ARCH-01 / jam constraint). Swift Testing is built in. No `.feature` file DSL is needed — the three-layer abstraction (Gherkin → step methods → business service) collapses to two layers in this context: test body (named after the behavior) + `GameDomain` calls.

**Consequence for BDD methodology**: Business language is enforced at test method name level and inline `// Given / When / Then` comments. Mandate CM-B (zero technical jargon) is verified by reading test names and comments, not Gherkin files.

---

## DISTILL-02: Driving port — GameDomain public surface only

**Date**: 2026-04-02
**Status**: FINAL

**Decision**: All acceptance tests invoke `GameDomain` exclusively through its public API:
- `GameState.initial(config:)` — initial state factory
- `RulesEngine.apply(command:to:deltaTime:)` — state transformation
- `FloorGenerator.generate(floorNumber:config:)` / `FloorGenerator.generateRun(config:seed:)` — floor generation
- `UpgradePool.drawChoices(count:)` — upgrade selection
- Value types: `GameConfig`, `EncounterModel`, `FloorMap`, `TimerModel`

No test imports `TUILayer`, `Renderer`, `InputHandler`, or `GameLoop`. This satisfies CM-A.

**Consequence**: Tests have no terminal, no real-time clock, no rendering. `deltaTime` is injected directly. This makes all tests deterministic and millisecond-fast.

---

## DISTILL-03: One scenario enabled at a time

**Date**: 2026-04-02
**Status**: FINAL (principle from nw-acceptance-designer methodology)

**Decision**: Only `WS-01` (Ember's HP is full when a new run begins) is enabled on initial commit. Every other test is marked `.disabled("not yet implemented")`.

**Sequence**: The crafter enables one test, implements the production code to make it pass, commits, then enables the next. This maintains the outer-loop TDD feedback signal.

**Sequence order**: Walking skeleton (WS-01 → WS-13) → Dash mechanics → Floor navigation → Combat → Progression → Win/Loss. See `test-scenarios.md` for the full ordered list.

---

## DISTILL-04: Helper methods use business language, not wiring language

**Date**: 2026-04-02
**Status**: FINAL

**Decision**: Test setup helper methods in each test file use names that express game domain intent:
- `stateWithActiveEncounter(_:isBoss:)` — not `setupCombatState`
- `stateAtStaircase(_:)` — not `setPlayerPositionToStaircaseCoordinate`
- `stateAtExitSquareWithEgg(_:)` — not `configureWinConditionState`

This keeps the test body readable as a user journey, not a state wiring script.

---

## DISTILL-05: Property-shaped scenarios tagged for crafter

**Date**: 2026-04-02
**Status**: RECOMMENDATION

**Three scenarios** express universal invariants that a single-example test cannot fully prove:

1. `CB-12`: Special charge < 1.0 for any elapsed time ≤ 20 seconds (all valid charge rates)
2. `WL-03/WL-04`: Win iff hasEgg AND exitSquare (neither alone triggers win — for any state)
3. `WL-07`: After restart, ALL state variables equal initial (for any prior run state)

These are written as concrete single-example tests with `.disabled`. The handoff note asks the crafter to consider implementing them as property-based tests using random generators when the relevant domain types exist.

---

## DISTILL-06: Package.swift updated to declare GameDomain target

**Date**: 2026-04-02
**Status**: FINAL

**Decision**: `Package.swift` was updated to declare a `GameDomain` library target and make the test target depend on it rather than the executable. The executable target (`DCJam2026`) depends on `GameDomain`.

**Consequence**: The crafter must create `Sources/GameDomain/` with the public types before any test can compile. The first build failure is a compile error (missing types), not a test failure — this is expected and correct at the start of the outer TDD loop.

---

## Open Questions for Crafter

These details are not pre-decided here and are left to the software-crafter:

1. `EncounterModel.guard(isBossEncounter:)` — exact factory method name. Tests use this name; crafter may alias it.
2. `EncounterModel.boss()` — whether boss is a separate factory or `guard(isBossEncounter: true)`.
3. `FloorGenerator.generateRun(config:seed:)` — exact signature. Tests assume this exists; crafter may choose a different entry point.
4. `GameState.withHP(_:)`, `withDashCharges(_:)`, etc. — `with*` builder pattern assumed; crafter may use a different mutation pattern (e.g., direct struct literal, copy-and-mutate via `var`).
5. `UpgradePool.cooldownReductionUpgrade()` and `UpgradePool.chargeCapUpgrade()` — test convenience factories. Crafter names these per the dragon vocabulary requirement (AC 8.5).
6. Milestone floor trigger logic — which floors trigger the upgrade prompt. Tests verify the prompt shows 3 options when it fires; the trigger condition is a crafter decision.

---

## Mandate Compliance Evidence

### CM-A: Driving port usage

All test files contain only:
```swift
import Testing
@testable import GameDomain
```

No test file imports `TUILayer`, `InputHandler`, `Renderer`, or `GameLoop`.

### CM-B: Zero technical jargon in test names

Test names use: "Ember", "HP", "Dash", "Special", "egg", "encounter", "floor", "stairs", "guard", "boss", "charge", "cooldown", "exit", "run".

Zero occurrences of: "HTTP", "JSON", "database", "SQL", "API", "endpoint", "mock", "stub", "fixture", "render", "ANSI", "terminal".

### CM-C: Walking skeleton + focused scenario counts

- Walking skeletons: 1 file (WalkingSkeletonTests) — 13 scenarios tracing the core player loop end-to-end.
- Focused scenarios: 5 files × ~10 scenarios = 46 focused scenarios targeting specific business rules.
- Total: 59 scenarios across 6 files.
- Error/edge path ratio: 24 of 59 = **41%** (exceeds 40% target).
