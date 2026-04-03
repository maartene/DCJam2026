# Technology Stack — Ember's Escape (dcjam2026-core)
**Feature**: dcjam2026-core
**Date**: 2026-04-02
**Author**: Morgan (Solution Architect — DESIGN wave)

---

## Stack Summary

| Layer | Choice | License | Rationale |
|-------|--------|---------|-----------|
| Language | Swift 6.3 | Apache 2.0 | Developer preference; not a jam requirement |
| Build system | Swift Package Manager (built-in) | Apache 2.0 | Included with Swift toolchain; zero setup |
| TUI output | Raw ANSI escape codes (custom `TUILayer`) | N/A — no library | See ADR-001 |
| Testing | Swift Testing (built-in, Swift 6+) | Apache 2.0 | Included with Swift 6; modern, macro-based |
| OS I/O | Darwin/Glibc POSIX APIs | System | `tcsetattr`, `fcntl`, `read` for raw terminal input |
| No external dependencies | — | — | See rationale below |

---

## Language: Swift 6.3

**License**: Apache 2.0 (open source)
**Repository**: https://github.com/apple/swift
**Choice rationale**: Developer preference. Swift 6.3 is not mandated by jam rules; it is selected deliberately for its strict concurrency model, value-type semantics, and first-class protocol support — all of which align well with the value-oriented OOP paradigm used in this project.

Swift 6.3 introduces strict concurrency checking by default. Because the game loop is fully synchronous and blocking, no `@MainActor` annotation or Swift concurrency primitives are required in the hot path. Strict concurrency remains relevant for any future async I/O additions.

---

## TUI Layer: Raw ANSI Escape Codes (No Library)

**Decision**: Custom `TUILayer` adapter using ANSI escape sequences directly.
**See**: ADR-001 for full rationale and alternatives evaluated.

### Why No Library

The three evaluated options were:

| Option | Status | Reason Not Chosen |
|--------|--------|-------------------|
| SwiftTerm | Rejected | Terminal emulator widget (renders terminals inside a terminal). Wrong abstraction level — it is the host, not the renderer. |
| SwiftTUI | Rejected | SwiftUI-like declarative TUI. The reactive/diffing model adds significant complexity for a game that needs a 30 Hz synchronous render loop. State management conflicts with game loop architecture. |
| Raw ANSI (custom) | **Chosen** | Full control, zero dependencies, 150-200 lines of code, directly expressible as a thin adapter. Well-documented escape codes. Portable across macOS/Linux. |

There is no mature Swift-native ncurses binding with Swift 6 concurrency compatibility that is also well-maintained (last checked: April 2026). `ncurses` via a C interop bridge is possible but adds C header bridging complexity for minimal benefit over raw ANSI.

### ANSI Capabilities Used

- Cursor positioning: `ESC[row;colH`
- Clear screen: `ESC[2J` + `ESC[H`
- Color (3-bit and 8-bit): `ESC[{code}m`
- Bold/dim: `ESC[1m` / `ESC[2m`
- Reset: `ESC[0m`
- Hide/show cursor: `ESC[?25l` / `ESC[?25h`
- Box-drawing characters: U+2500 block (─ │ ┌ ┐ └ ┘ ├ ┤ ┬ ┴ ┼)

All of these are supported by any ANSI-compatible terminal (macOS Terminal.app, iTerm2, Linux VTE-based terminals).

---

## Testing: Swift Testing Framework

**License**: Apache 2.0 (part of Swift open-source toolchain)
**Documentation**: https://github.com/swiftlang/swift-testing

Swift 6 ships with the `swift-testing` framework (distinct from XCTest). It provides:
- Macro-based `#expect` and `#require` assertions
- `@Test` and `@Suite` annotations
- Parameterized tests (important for testing multiple floor generation scenarios)
- Better error messages than XCTest

All test targets use Swift Testing. XCTest is not used (it is the older API).

---

## No External Dependencies — Rationale

The `Package.swift` currently has no dependencies. This is deliberate for a jam entry:

1. **Dependency resolution adds friction** during rapid iteration (network, build time)
2. **Jam constraint**: the game must be compilable by judges from source with `swift build`; external dependencies require `swift package resolve` and internet access at build time
3. **Scope is bounded**: a solo 4-day jam game does not need a framework; the TUI layer is ~150 lines, the game loop is ~50 lines
4. **Swift 6 std library** provides everything needed: `Clock`, `Duration`, `String`, `Array`, `Dictionary`, value types, protocols

If a future post-jam version needs argument parsing, `swift-argument-parser` (Apache 2.0, first-party Apple) is the natural addition.

---

## Platform Targets

| Platform | Support | Notes |
|----------|---------|-------|
| macOS 13+ | Primary | Developer's target for jam submission |
| Linux (Ubuntu 22.04+) | Secondary | Swift toolchain available; POSIX I/O is portable; `#if os(Linux)` guards for `Glibc` vs `Darwin` differences |

The only platform-specific code is in `TUILayer`:
- `tcsetattr` / `tcgetattr` — in `Darwin.POSIX.termios` (macOS) and `Glibc` (Linux)
- `fcntl` / `O_NONBLOCK` — POSIX, available on both

All domain logic and rendering logic is platform-agnostic.
