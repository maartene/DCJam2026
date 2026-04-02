# ADR-005: Position Type for 2D Player and Landmark Coordinates

**Date**: 2026-04-02
**Status**: Accepted
**Author**: Morgan (Solution Architect — DESIGN wave)
**Deciders**: Maarten Engels (developer)

---

## Context

`GameState.playerPosition` currently stores a single `Int` (1D floor offset). The 2D floor model requires a 2D coordinate. All landmark positions in `FloorMap` must also change from `Int` to a 2D type.

The new type must:
- Be usable as a stored property in `GameState` and `FloorMap`, both of which conform to `Sendable`
- Work in `GameDomain` which has zero imports (no Foundation, no Darwin, no SIMD)
- Support `Equatable` and `Hashable` for use as dictionary key in the future (minimap rendering)
- Be a value type (struct/enum per CLAUDE.md)

---

## Decision

**Named `struct Position` with `x: Int` and `y: Int` fields, defined in `GameDomain`.**

```
struct Position: Sendable, Equatable, Hashable {
    let x: Int
    let y: Int
}
```

No computed properties. No arithmetic operators. No geometry methods. The struct is a data holder. Arithmetic on Position values (applying movement deltas) is the RulesEngine's responsibility.

---

## Alternatives Considered

### Option A: Swift Tuple `(x: Int, y: Int)`

A tuple with labeled elements.

Trade-offs:
- Positive: No type declaration needed. Lightweight.
- Negative: In Swift 6 strict concurrency, tuples do not synthesise `Sendable` conformance automatically when crossing isolation boundaries. `GameState` is `Sendable`; storing a tuple in a `Sendable` struct requires the tuple itself to be `Sendable`. Swift 6 has no way to declare `extension (Int, Int): Sendable`. This would be a compile error.
- Negative: Cannot conform to `Hashable` — tuples do not support protocol conformance in Swift.
- Rejected: Swift 6 `Sendable` conformance is not achievable for tuples.

### Option B: Typealias to `(Int, Int)`

Same as Option A with a name. Same limitations. Rejected for the same reasons.

### Option C: `SIMD2<Int32>`

Apple's SIMD vector type.

Trade-offs:
- Positive: `Equatable`, `Hashable`, and conforms to `Sendable`. Supports arithmetic operators.
- Negative: `SIMD2` requires importing the Swift standard library's SIMD module. In GameDomain, "zero imports" means no explicit `import` statements beyond the implicit Swift stdlib. SIMD2 is part of the Swift stdlib and available without an import statement — technically compliant.
- Negative: Using a SIMD type for a simple 2-integer coordinate signals numeric processing intent. The semantic noise is not justified for a coordinate that never does vectorised arithmetic.
- Negative: `Int32` is the smallest integer SIMD type; the floor grid uses plain `Int`. Mixing `Int` and `Int32` in the codebase adds unnecessary conversion sites.
- Rejected: Semantic mismatch. A named struct is clearer.

### Option D: Named `struct Position` (chosen)

- Positive: Self-documenting. Compiler synthesises `Sendable`, `Equatable`, `Hashable` for a struct of `Sendable` fields.
- Positive: No imports required. Pure Swift.
- Positive: Follows the established pattern in GameDomain (all types are named structs or enums).
- Positive: Future additions (e.g., a `static let zero` convenience, a `func clamped(to:)`) can be added if needed without changing call sites.
- Accepted.

---

## Consequences

### Positive
- Compiler synthesises all required protocol conformances
- Zero imports — fully compliant with GameDomain constraints
- Call sites are readable: `Position(x: 4, y: 3)` is unambiguous

### Negative
- Every existing call site using `playerPosition` as an `Int` must be updated to `Position`. This is a compiler-driven migration — all missed sites are build errors. High blast radius but low risk.
- `FloorMap` landmark positions (`Int?` optionals) become `Position?`. Same migration pattern.

### Note for Software Crafter

Define `Position` in a new file `Sources/GameDomain/Position.swift`. The struct has two stored `let` properties (`x: Int`, `y: Int`). Swift synthesises `Sendable`, `Equatable`, `Hashable` automatically for a struct of `Sendable`, `Equatable`, `Hashable` components. No explicit conformance bodies needed.

When migrating `GameState.playerPosition` from `Int` to `Position`, the compiler will enumerate every call site. The crafter should migrate all at once rather than incrementally to avoid a red-state build.
