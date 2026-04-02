# Technology Stack: Turning Mechanic

**Feature**: turning-mechanic
**Date**: 2026-04-02

The stack is unchanged. This document confirms no new dependencies are introduced and no existing choices are altered by the turning mechanic.

---

## Confirmed Stack

| Layer | Technology | License | Notes |
|-------|-----------|---------|-------|
| Language | Swift 6.3 | Apache 2.0 | Developer preference; strict concurrency mode enabled |
| Build system | SwiftPM | Apache 2.0 | Part of Swift toolchain |
| Runtime | macOS / Linux (ANSI terminal) | — | No new platform requirements |
| Terminal I/O | Raw ANSI via `Darwin.write` / `tcsetattr` | Part of OS | Per ADR-001: no TUI library |
| Input | `/dev/tty` non-blocking fd | Part of OS | Per CLAUDE.md non-blocking input rule |
| Testing | Swift Testing (XCTest compatible) | Apache 2.0 | Built into Swift toolchain |
| External libraries | None | — | No new dependencies added |

---

## New Dependencies: None

The turning mechanic requires no new SwiftPM package dependencies. All new types (`CardinalDirection`, `TurnDirection`, `Position`, `Cell`) are plain Swift value types with no external library requirements.

The 2D grid (`[[Cell]]`) uses Swift's built-in Array. No matrix library or spatial indexing library is needed at jam scope.

---

## Architecture Enforcement: Built-in

No additional linting tool is added. Swift 6 strict concurrency + SwiftPM target isolation enforce the architecture rules at build and compile time. See architecture-design.md Section 4.
