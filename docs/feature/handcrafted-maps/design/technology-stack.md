# Technology Stack — handcrafted-maps

**Feature**: handcrafted-maps
**Wave**: DESIGN
**Date**: 2026-04-04

---

## Overview

This feature introduces no new technology dependencies. All implementation is within the existing project stack.

---

## Existing Stack (unchanged)

| Component | Technology | Version | License | Notes |
|-----------|-----------|---------|---------|-------|
| Language | Swift | 6.3 | Apache 2.0 | Strict concurrency mode active |
| Build system | Swift Package Manager (SwiftPM) | bundled with Swift 6.3 | Apache 2.0 | Module boundary enforcement via target dependencies |
| Testing framework | Swift Testing | bundled with Swift 6.3 | Apache 2.0 | `import Testing`, `#expect`, `@Suite`, `@Test` |
| Terminal I/O | Raw ANSI (custom `TUILayer`) | N/A | N/A | No external TUI library — see ADR-001 |
| Platform | macOS / Linux | macOS 14+, Ubuntu 22.04+ | N/A | Cross-platform via `#if canImport(Darwin)` guards — see ADR-007 |

---

## New Dependencies

**None.** This feature adds zero entries to `Package.swift`.

The character grid format (`[String]`) uses only Swift standard library types. No serialization libraries (JSON, YAML, Property Lists) are needed — floor definitions are pure Swift literal arrays compiled into the binary.

---

## Rationale for No New Dependencies

| Option | Evaluation | Decision |
|--------|-----------|----------|
| JSON / Property List file I/O | Adds `Foundation` dependency; requires file-system access at runtime; breaks `GameDomain` zero-I/O invariant | Rejected |
| Custom binary format | Higher complexity than `[String]` literals; no benefit at 5-floor jam scope | Rejected |
| Third-party map editor format (e.g., Tiled TMX) | Heavy dependency; XML parsing; overkill for 5 fixed floors | Rejected |
| `[String]` Swift literals (chosen) | Zero new dependencies; human-readable in source; diff-friendly; compiles to static data | Accepted |

---

## Architectural Enforcement

No mutation testing is configured for this project at present (see docs/CLAUDE.md). Module boundary enforcement is provided by SwiftPM's target dependency graph — any import violation is a build error.

Post-jam, if the project grows beyond jam scope, `swift-dependency-analyser` (open source, MIT) or `import-linter` could be added to CI to enforce the `GameDomain` no-import rule programmatically.
