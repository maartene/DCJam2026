# Wave Decisions — DESIGN Wave
**Feature**: dcjam2026-core
**Date**: 2026-04-02
**Author**: Morgan (Solution Architect — DESIGN wave)

This document records all significant architectural decisions made during the DESIGN wave.

---

## ARCH-01: TUI library — raw ANSI with custom adapter (no external library)

**Date**: 2026-04-02
**Status**: FINAL

**Decision**: No external TUI library. A custom `TUILayer` module (~150-200 lines) uses raw ANSI escape codes and POSIX terminal APIs.

**Evidence**: SwiftTerm is a terminal emulator widget (wrong abstraction). SwiftTUI's reactive model conflicts with a synchronous game loop. ncurses via C bridging adds complexity exceeding the benefit. Raw ANSI provides all required capabilities with zero dependencies.

**See**: ADR-001

**What this rules out**:
- SwiftTerm, SwiftTUI, or any external TUI library dependency in `Package.swift`
- C bridging to ncurses

---

## ARCH-02: Programming paradigm — value-oriented OOP (structs + protocols + plain class game loop)

**Date**: 2026-04-02
**Status**: CONFIRMED — developer confirmed 2026-04-02

**Decision**: Domain types as `struct` (value types). Domain transformations as pure functions. Port boundaries as `protocol`. Game loop coordinator as a plain `class` (no `@MainActor`).

**Evidence**: Immutable state snapshots eliminate partial-update bugs in the real-time loop. Pure functions are trivially testable without mocks. Swift 6 strict concurrency is naturally satisfied by value types. The game loop is fully synchronous and blocking — no concurrent access exists to guard against, so `@MainActor` is unnecessary. Classical OOP with mutable objects creates hidden state dependencies; pure FP fights Swift's I/O boundary idioms.

**See**: ADR-002

---

## ARCH-03: First-person rendering — pre-computed depth-zone lookup table

**Date**: 2026-04-02
**Status**: FINAL

**Decision**: ~20-25 pre-authored ASCII art frames indexed by `(depth, leftOpen, rightOpen)` view state tuple. Zero per-frame floating-point computation.

**Evidence**: Ray-casting maps to pixel columns, not character cells. Procedural ASCII line drawing produces poor visual quality. Lookup table is the model used by classic dungeon crawlers (Wizardry, Bard's Tale) and maps directly to terminal character art. Testable as a pure function.

**See**: ADR-003

---

## ARCH-04: Architecture style — ports and adapters within a modular single process

**Date**: 2026-04-02
**Status**: FINAL

**Decision**: Six SwiftPM modules (`GameDomain`, `TUILayer`, `InputHandler`, `Renderer`, `GameLoop`, `DCJam2026` entry point). `GameDomain` has zero imports — it is the pure domain. All other modules depend on it. `TUIOutputPort` and `InputPort` protocols are the adapter boundaries.

**Evidence**: Solo developer + 4 days rules out microservices. Modular monolith with dependency inversion gives testable domain logic and infrastructure isolation at minimal overhead. The port-and-adapter pattern is enforced at build time by SwiftPM module dependencies.

**What this rules out**:
- Microservices (wrong scale)
- Single-file monolith (no testability)
- Any architecture where domain logic imports TUI or I/O code

---

## ARCH-05: Game loop — synchronous 30 Hz tick, no async/await in hot path

**Date**: 2026-04-02
**Status**: FINAL

**Decision**: The main game loop is a synchronous blocking `while` loop. No `@MainActor`, no `async/await` in the hot path. Timer advancement (Dash cooldowns, Special charge) uses delta-time injection, not `DispatchQueue.asyncAfter` or `Task.sleep`.

**Evidence**: Delta-time timers are deterministic and testable. Async timers require coroutine scheduling overhead and complicate test injection. A 30 Hz terminal render loop is well within single-threaded Swift throughput.

**What this rules out**:
- `DispatchQueue.asyncAfter` for cooldown management
- `Timer` for charge accumulation
- Any non-deterministic time source in the domain

---

## ARCH-06: Screen mode — explicit state enum owned by domain

**Date**: 2026-04-02
**Status**: FINAL

**Decision**: `ScreenMode` is a domain enum with cases: `.dungeon`, `.combat(EncounterModel)`, `.narrativeOverlay(NarrativeEvent)`, `.upgradePrompt([Upgrade])`, `.deathState`, `.winState`. The Renderer switches on this enum.

**Evidence**: Narrative overlays (egg discovery, special attack, exit patio) are domain events — their triggering conditions are business rules, not rendering decisions. Keeping them in the domain ensures they are testable and their trigger conditions are encapsulated.

---

## Open Questions for Crafter

The following design details are intentionally left to the software-crafter:

1. **Exact ASCII art frames** for the first-person view — the crafter authors these during the GREEN phase
2. **FloorGenerator algorithm** — the constraints are specified (`component-boundaries.md`); the procedural generation algorithm (BSP, room+corridor, cellular automata) is the crafter's choice
3. **`GameLoop` clock implementation** — the interface is `clock.tick() -> Double` (returns deltaTime in seconds); the concrete implementation (using `ContinuousClock`, `Date`, or `clock_gettime`) is the crafter's choice
4. **Brace damage reduction value** — `GameConfig.braceDefenseMultiplier = 0.4` is the starting point; the crafter tunes this during the polish slice
5. **Boss HP and attack rate** — design details for the crafter; the architecture provides the `EncounterModel` fields

---

## Handoff Status

| Gate | Status | Notes |
|------|--------|-------|
| Requirements traced to components | PASS | All REQ-01 through REQ-13 mapped |
| Component boundaries defined | PASS | Six modules with clear responsibilities |
| Technology choices in ADRs | PASS | ADR-001 (TUI), ADR-002 (paradigm, confirmed), ADR-003 (rendering) |
| Quality attributes addressed | PASS | Testability, maintainability, performance, portability |
| Dependency inversion compliance | PASS | GameDomain has zero outgoing dependencies |
| C4 diagrams (L1+L2+L3) | PASS | All in architecture-design.md |
| Integration patterns specified | PASS | Component boundaries + integration points documented |
| OSS preference validated | PASS | No external dependencies (jam constraint); Swift toolchain is Apache 2.0 |
| AC behavioral, not implementation-coupled | PASS | All AC from DISCUSS wave are behavioral |
| External integrations annotated | N/A | No external APIs |
| Architecture enforcement tooling | PASS | SwiftPM module boundaries as enforcement mechanism |
| Peer review | PENDING |  |
