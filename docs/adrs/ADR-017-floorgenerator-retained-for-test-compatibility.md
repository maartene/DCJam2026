# ADR-017: FloorGenerator Retained — Not Deleted

**Date**: 2026-04-04
**Status**: Accepted
**Feature**: handcrafted-maps
**Author**: Morgan (nw-solution-architect — DESIGN wave)
**Deciders**: Maarten Engels (developer)

---

## Context

The `handcrafted-maps` feature replaces `FloorGenerator.generate(floorNumber:config:)` at all runtime call sites (in `RulesEngine` and `Renderer`) with `FloorRegistry.floor(_:config:)`. The question is whether `FloorGenerator` should be deleted after this substitution.

Arguments for deletion:
- `FloorGenerator` would become dead production code
- Dead code is a maintenance burden

Arguments against deletion:
- Existing test files call `FloorGenerator.generate` directly (e.g., `AC-HM-02-A` calls it explicitly to compare outputs as the safe migration gate)
- Deleting `FloorGenerator` would break the migration regression test
- Deleting it removes the baseline comparison that proves `FloorRegistry.floor(1, ...)` is identical to the old implementation

---

## Decision

**Retain `FloorGenerator` unchanged.** The existing `public enum FloorGenerator` and all its methods remain in `GameDomain` with no modification. Runtime call sites in `RulesEngine` and `Renderer` are replaced with `FloorRegistry.floor`. `FloorGenerator` remains as a test utility and safe-migration comparison baseline.

---

## Alternatives Considered

### Option A: Delete FloorGenerator after substitution

- Positive: No dead production code.
- Negative: Deletes the migration baseline. `AC-HM-02-A` cannot exist — it calls both `FloorRegistry.floor(1, ...)` and `FloorGenerator.generate(floorNumber: 1, ...)` and asserts they are equal. Without `FloorGenerator`, this regression test cannot be written.
- Negative: Existing test helpers that call `FloorGenerator` directly would need to be rewritten to use `FloorRegistry`, removing the independent comparison point.
- Rejected.

### Option B: Mark FloorGenerator as deprecated but retain

Add `@available(*, deprecated, renamed: "FloorRegistry.floor")` attribute to `FloorGenerator.generate`.

- Positive: Communicates intent to callers.
- Negative: Generates compiler warnings in existing test files — noise under jam deadline.
- Negative: Adds annotation overhead with no functional benefit at jam scope.
- Deferred to post-jam consideration.

### Option C: Retain FloorGenerator unchanged (chosen)

- Positive: Zero changes to `FloorGenerator` — zero risk of regression.
- Positive: `AC-HM-02-A` can compare both implementations as the safe migration gate.
- Positive: Existing tests that call `FloorGenerator` compile and pass without modification.
- Negative: `FloorGenerator` is dead production code after the migration.
- Accepted at jam scope. Post-jam: deletion is safe once the migration baseline is no longer needed.

---

## Consequences

### Positive
- The migration regression test (AC-HM-02-A) has an independent baseline to compare against
- Existing test files require zero modification
- Risk of test breakage during migration = zero

### Negative
- `FloorGenerator` is dead production code (not called at runtime after substitution). This is acceptable for a jam entry.

### Note for Software Crafter

`FloorGenerator.swift` requires no changes. All existing `public` APIs remain. The only modification is in the callers: `RulesEngine.applyMove` (2 call sites), `RulesEngine.applySpecial` (1 call site), `Renderer.renderDungeon` (1 call site) — replace `FloorGenerator.generate(floorNumber: state.currentFloor, config: state.config)` with `FloorRegistry.floor(state.currentFloor, config: state.config)`.
