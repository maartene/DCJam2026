# ADR-002: Programming Paradigm

**Date**: 2026-04-02
**Status**: Confirmed — 2026-04-02
**Author**: Morgan (Solution Architect — DESIGN wave)
**Deciders**: Maarten Engels (developer)

---

## Context

Swift 6.3 is a multi-paradigm language. It supports:
- Object-Oriented Programming (OOP): classes, inheritance, polymorphism
- Functional Programming (FP): closures, higher-order functions, value types, immutability
- Value-oriented programming: structs, enums, protocol composition

For a real-time game with a 30 Hz loop, clear state transitions, and a solo developer over 4 days, the paradigm choice has immediate practical consequences for testability, debuggability, and development speed.

---

## Decision

**Value-Oriented OOP using Swift's natural idioms: structs + protocols + plain class game loop.**

Specifically:
- All domain types are `struct` (value types): `GameState`, `FloorMap`, `EncounterModel`, `TimerModel`, `UpgradePool`, `ThoughtsLog`, `GameConfig`
- All domain transformations are pure functions: `RulesEngine.apply(command:to:deltaTime:)`, `FloorGenerator.generate(floorNumber:seed:)`, `TimerModel.advance(delta:)`
- Port boundaries are `protocol`: `TUIOutputPort`, `InputPort`
- The game loop coordinator is a plain `class GameLoop` (or `struct` with `mutating` run loop) — the single location of mutable state. No `@MainActor` annotation required (see developer rationale below).
- `FloorGenerator` and `RulesEngine` are stateless namespaces (enums with static methods or structs with no stored properties)

---

## Alternatives Considered

### Option A: Classical OOP (mutable objects, inheritance)
Pattern: `class Enemy`, `class Player`, `class Floor` with mutable properties. Objects call methods on each other. Inheritance hierarchies for enemy types.

Trade-offs:
- **Negative**: Mutable objects in a real-time loop create hidden state dependencies. The render call sees `enemy.hp` but another code path may have modified it in the same tick. Race conditions (even single-threaded logical races) become hard to debug under time pressure.
- **Negative**: Inheritance for enemy types adds indirection with minimal benefit for a jam with ~3 enemy variants.
- **Negative**: Testing requires object setup, mock collaborators, and teardown. Harder than testing pure functions.
- **Positive**: Familiar OOP idiom; no unfamiliar concepts.
- Rejected: mutable shared state is the wrong model for a game loop that benefits from immutable state snapshots.

### Option B: Pure Functional (all closures and function composition, no structs-with-methods)
Pattern: `GameState` as a plain data type. All logic as free functions. Effect types or `Result`/monad-style chaining for state transitions.

Trade-offs:
- **Negative**: Swift's I/O boundaries (terminal APIs, `tcsetattr`, `fcntl`) are imperative. Wrapping them in a functional effect system adds significant boilerplate for a 4-day jam.
- **Negative**: Swift's standard library and tooling are OOP-oriented. Fighting the language idioms for a jam is expensive.
- **Positive**: Maximum purity, maximum testability for domain logic.
- Rejected: the I/O boundary cost outweighs the benefit for a solo jam. Value-oriented OOP achieves 90% of the testability benefit without fighting the language.

### Option C: Value-Oriented OOP (chosen)
Structs for domain, pure functions for transformations, protocols for ports, plain `class` for the mutable loop coordinator.

Trade-offs:
- **Positive**: `GameState` is an immutable snapshot — the renderer always sees a consistent state. No partial-update bugs.
- **Positive**: `RulesEngine` pure functions are trivially unit testable: input state + command + deltaTime → output state. No mock setup.
- **Positive**: The synchronous blocking game loop requires no concurrency guards. A synchronous 30 Hz `while` loop occupies the calling thread exclusively — there is no concurrent access to race on. `@MainActor` is an isolation mechanism for code that shares the main actor queue with async work; it is unnecessary (and misleading) on a plain synchronous loop.
- **Positive**: Familiar to Swift developers; aligns with Swift's own stdlib design (`String`, `Array`, `Dictionary` are all value types).
- **Negative**: Copy-on-write semantics of large structs — `FloorMap` copying on every tick could be expensive if the grid is large. Mitigation: keep grid sizes modest (jam scope); use `UnsafePointer`-backed storage only if profiling shows it necessary (extremely unlikely for a 5-floor jam game).
- Accepted.

---

## Consequences

### Positive
- All domain logic is pure-function testable (no mocks needed for `RulesEngine`, `FloorGenerator`, `TimerModel`)
- `GameState` immutability makes the debugger useful — the state at tick N is inspectable independently
- Swift 6 strict concurrency compliance is natural: value types are implicitly `Sendable`; the synchronous loop requires no isolation annotation
- Protocol ports (`TUIOutputPort`, `InputPort`) enable test doubles without a mocking framework

### Negative
- Developers accustomed to mutable OOP need to think in transformations (input → output) rather than mutations
- `FloorMap` copies on every `apply()` call — acceptable for jam scope, worth monitoring if grids grow large

### Neutral
- The paradigm choice does not affect the external-facing behavior. It is a crafter-level concern for internal structure. This ADR communicates the intent so the crafter can enforce it.

---

## Developer Rationale (recorded verbatim)

> "If the game loop is truly synchronous, you might not need any actors or async/await functions. Meaning you don't need to guard things with `@MainActor`."

This correction is incorporated. The `GameLoop` is a plain `class` (or `struct` with a `mutating` run loop). The `@MainActor` annotation has been removed from all architecture artifacts. If future work introduces async I/O (audio, network), the concurrency story can be revisited at that point with a targeted ADR amendment.
