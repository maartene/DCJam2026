# ADR-001: TUI Library Selection

**Date**: 2026-04-02
**Status**: Accepted
**Author**: Morgan (Solution Architect — DESIGN wave)
**Deciders**: Maarten Engels (developer)

---

## Context

Ember's Escape requires a TUI (Terminal User Interface) layer capable of:
1. Full-screen control (clear, cursor positioning)
2. Color output and Unicode box-drawing characters (U+2500 block)
3. Non-blocking keyboard input (required for real-time combat)
4. macOS and Linux compatibility
5. Swift 6.3 compatibility (strict concurrency — no data races at compile time)

The current `Package.swift` has no dependencies. Three candidates were evaluated. A fourth (ncurses via C bridging) was also considered.

The JAM CONSTRAINT is significant: the binary must compile cleanly from source with `swift build`. External dependencies require network access at `swift package resolve` time.

---

## Decision

**Use raw ANSI escape codes via a custom `TUILayer` adapter module. No external library.**

The `TUILayer` module (~150-200 lines) implements all required TUI capabilities directly using ANSI escape sequences and POSIX terminal APIs (`tcsetattr`, `fcntl`).

---

## Alternatives Considered

### Option A: SwiftTerm
- **GitHub**: https://github.com/migueldeicaza/SwiftTerm
- **License**: MIT
- **Stars**: ~600 (as of early 2026)
- **Assessment**: SwiftTerm is a **terminal emulator widget** — it renders a terminal window inside another environment (e.g., a SwiftUI app embeds a terminal pane). It is the wrong abstraction level for this use case. Using SwiftTerm to write a terminal game would be analogous to embedding a VNC client to render game output. Rejected: wrong tool for the problem.

### Option B: SwiftTUI
- **GitHub**: https://github.com/nicklockwood/SwiftTUI (and forks)
- **License**: MIT
- **Assessment**: SwiftTUI provides a SwiftUI-like declarative API for TUI apps. It uses a reactive diffing model similar to SwiftUI's view reconciler. Problems:
  1. The reactive/diffing architecture conflicts with a synchronous 30 Hz game loop — the game already knows what changed (it computed a new `GameState`); diffing adds overhead and complexity without benefit.
  2. SwiftTUI's layout model (flex-like containers) does not map to the fixed-region layout required (first-person view height is ASCII-art-determined, not flexbox-determined).
  3. Swift 6 strict concurrency compatibility is unclear for available forks (not confirmed active maintenance as of April 2026).
  - Rejected: wrong rendering model for a real-time game loop; potential Swift 6 compatibility issues.

### Option C: ncurses via C bridging
- **License**: MIT/ISC (system library)
- **Assessment**: ncurses is the canonical terminal control library. It provides window management, color, non-blocking input, and box-drawing. However:
  1. Swift C interop with ncurses requires a module map and bridging header. This adds setup friction.
  2. ncurses is a mutable-state C library (global window state). Wrapping it safely under Swift 6 strict concurrency requires `@unchecked Sendable` annotations or an actor wrapper — non-trivial.
  3. The capabilities needed (cursor positioning, color, non-blocking read) are directly expressible in ANSI/POSIX in ~150 lines of Swift with zero C interop complexity.
  - Rejected: C bridging complexity exceeds benefit for the capabilities needed. Raw ANSI provides the same output with simpler code.

### Option D: Raw ANSI (chosen)
- **License**: N/A — no library
- **Assessment**: All required TUI capabilities map directly to well-documented ANSI escape sequences and POSIX `tcsetattr`/`fcntl`. The TUI Abstraction Layer exposes a `TUIOutputPort` protocol, making the concrete implementation swappable. Full Swift 6 compatibility (pure Swift, no C interop). Zero external dependencies.
  - Chosen.

---

## Consequences

### Positive
- Zero external dependencies — `swift build` works without network access
- Full Swift 6 strict concurrency compatibility
- `TUIOutputPort` protocol enables mock renderer for testing
- ~150-200 lines of code — maintainable by solo developer
- macOS/Linux portability via `#if os(macOS)` / `#if os(Linux)` guards in one file
- No dependency on external project maintenance or versioning

### Negative
- No free text layout primitives (must implement status bar layout manually)
- Box-drawing characters require UTF-8 awareness (terminal must be in UTF-8 mode — true for all modern terminals)
- ANSI escape code knowledge required — well-documented but not zero learning curve
- If a bug in the TUI layer exists, the developer owns the fix (no community to report to)

### Neutral
- The `TUIOutputPort` protocol means adopting a library later (if desired) only requires replacing the concrete `ANSITerminal` implementation — Renderer code is unaffected.
