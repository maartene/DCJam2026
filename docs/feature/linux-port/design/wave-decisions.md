# Wave Decisions — linux-port

**Feature**: linux-port
**Date**: 2026-04-03
**Author**: Morgan (Solution Architect — DESIGN wave)

---

## Decision Summary

### D1 — Approach: Per-file conditional imports + `PlatformCompat.swift` shim (Option A)

**Decision**: Adopt Option A. Replace `import Darwin` in the three affected files with `#if canImport(Darwin) / #elseif canImport(Glibc) / #endif` guards. Add `Sources/App/PlatformCompat.swift` to encapsulate the two symbols that require active abstraction (`monoTimeNanoseconds()` and `c_cc` index access).

**Alternatives rejected**:
- Option B (dedicated `PlatformIO` protocol): Adds protocol, two concrete implementations, and constructor injection for a 3-file, 5-symbol divergence. Provides no additional testability (the symbols are exercised indirectly already). Disproportionate complexity for the scope. Rejected.
- Separate SPM target for platform shims: Adds a new SwiftPM target (`PlatformShims` or similar), requiring `Package.swift` changes and a new directory. The divergence is too small to justify a module boundary. A single file within the existing target is sufficient. Rejected.

**See**: ADR-007

---

### D2 — `PlatformCompat.swift` as the single platform boundary file

**Decision**: Designate `Sources/App/PlatformCompat.swift` as the only file in the `DCJam2026` target permitted to contain platform-conditional code beyond the bare top-level import guard. Other files may have `#if canImport(Darwin)` / `#elseif canImport(Glibc)` for their own import line, but all logic differences route through `PlatformCompat.swift`.

**Rationale**: Concentrating platform divergence in one file makes future platform work (e.g., Windows, WebAssembly) easier to find and reason about. It also reduces the diff surface when Linux-specific bugs emerge during jam judging.

---

### D3 — Use `#if canImport(Darwin)` over `#if os(macOS)`

**Decision**: Use `canImport` guards rather than `os()` guards for module imports.

**Rationale**: `#if canImport(Darwin)` tests module availability in the compiler's view of the world. `#if os(macOS)` hardcodes the OS name, which does not extend to visionOS, tvOS, watchOS, or hypothetical future Apple platforms. For a jam project the difference is minor, but `canImport` is the Swift community's documented best practice for this pattern (SE-0075).

---

### D4 — No change to `Package.swift`

**Decision**: `Package.swift` is not modified. No new targets, no new dependencies, no new source path mappings.

**Rationale**: The jam constraint requires zero-dependency builds. The platform work fits entirely within the existing `DCJam2026` target's source path (`Sources/App/`). A new target would require declaration in `Package.swift` and would add build graph complexity for no benefit.

---

### D5 — `GameDomain` target remains untouched

**Decision**: Zero changes to `Sources/GameDomain/`.

**Rationale**: `GameDomain` has no OS imports. It is pure Swift. Making it cross-platform requires no action. Touching it risks introducing regressions in the domain tests.

---

## Quality Gates Passed

- [x] Requirements traced to components (3 files, 5 symbols, 1 new file)
- [x] Component boundaries with clear responsibilities (`PlatformCompat.swift` boundary documented)
- [x] Technology choices with ADR (ADR-007)
- [x] Quality attributes addressed (portability primary; maintainability via single boundary file)
- [x] Dependency-inversion compliance (`GameDomain` unchanged; `TUIOutputPort` boundary intact)
- [x] C4 diagrams L1 + L2 in Mermaid (architecture-design.md)
- [x] OSS preference validated (no new proprietary dependency)
- [x] AC behavioral, not implementation-coupled
- [x] No external integrations (no contract test annotation needed)
- [x] Architecture enforcement tooling noted (SwiftPM structural + code review convention)
