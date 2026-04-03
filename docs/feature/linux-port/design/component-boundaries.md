# Component Boundaries — linux-port

**Feature**: linux-port
**Date**: 2026-04-03
**Author**: Morgan (Solution Architect — DESIGN wave)

---

## 1. Boundary Overview

The linux-port change does not alter any existing component boundaries. It introduces one new file (`PlatformCompat.swift`) that lives within the existing `DCJam2026` executable target and makes targeted edits to three existing files. No new SwiftPM targets, no new modules, no new protocols.

---

## 2. Component Inventory

### Unchanged Boundary: `GameDomain` Target

- Location: `Sources/GameDomain/`
- Responsibility: pure domain logic — state, rules, floor generation, command definitions
- OS imports: none
- Dependencies: none
- Change: none

This boundary is the most important in the system. It must remain hermetically sealed from OS-specific code. The linux-port feature does not touch it.

### Existing Boundary: `TUIOutputPort` (Protocol)

- Location: `Sources/App/TUIOutputPort.swift`
- Responsibility: output port interface between `Renderer` and `ANSITerminal`
- Change: none

The port boundary already exists and remains intact. The linux-port changes are behind this boundary (in `ANSITerminal`, the concrete adapter), not at the port itself.

### New File within `DCJam2026` Target: `PlatformCompat.swift`

- Location: `Sources/App/PlatformCompat.swift`
- Responsibility: the single designated location for all `#if canImport(Darwin) / #elseif canImport(Glibc)` conditional compilation in the `DCJam2026` target
- Exports: `monoTimeNanoseconds() -> UInt64`; `c_cc` index access pattern (see architecture-design.md)
- Consumed by: `GameLoop.swift` (clock), `ANSITerminal.swift` (c_cc indices)
- Dependencies: none beyond the platform module (Darwin/Glibc) itself

**Convention**: after this feature is merged, `PlatformCompat.swift` is the only permitted location for platform-conditional imports or platform-specific symbol abstractions. Files other than `PlatformCompat.swift` use unconditional `#if canImport(...)` guards only for the top-level module import line itself.

### Modified File: `ANSITerminal.swift`

- Location: `Sources/App/ANSITerminal.swift`
- Existing responsibility: concrete `TUIOutputPort` implementation; raw mode; buffered write to stdout
- Platform boundary change: replaces `import Darwin` with conditional import; fixes `c_cc` index access using `VMIN`/`VTIME` constants; removes `Darwin.`-qualified call prefix from `write`
- Protocol boundary: unchanged

### Modified File: `InputHandler.swift`

- Location: `Sources/App/InputHandler.swift`
- Existing responsibility: opens `/dev/tty` O_NONBLOCK; polls and maps keypresses to `GameCommand`
- Platform boundary change: replaces `import Darwin` with conditional import; removes `Darwin.`-qualified call prefixes from `open`, `close`, `read`
- Logic boundary: unchanged

### Modified File: `GameLoop.swift`

- Location: `Sources/App/GameLoop.swift`
- Existing responsibility: 30Hz blocking game loop; monotonic frame timing via `usleep`
- Platform boundary change: replaces `import Darwin` with conditional import; replaces two `clock_gettime_nsec_np(CLOCK_MONOTONIC)` call sites with `monoTimeNanoseconds()` from `PlatformCompat.swift`
- Logic boundary: unchanged

---

## 3. Platform Boundary Location

The platform boundary is concentrated entirely within the `DCJam2026` executable target (`Sources/App/`). Specifically:

```
Sources/App/
  PlatformCompat.swift     ← ALL platform-conditional code lives here
  ANSITerminal.swift       ← conditional import line only; c_cc index via PlatformCompat
  InputHandler.swift       ← conditional import line only
  GameLoop.swift           ← conditional import line only; clock via PlatformCompat
```

No platform-conditional code exists anywhere in `Sources/GameDomain/`.

---

## 4. Dependency Direction (post-change)

```
DCJam2026 (executable)
  ├── GameDomain              ← domain (no OS dep)
  ├── PlatformCompat.swift    ← new; platform shim (Darwin OR Glibc)
  ├── ANSITerminal.swift      ← uses PlatformCompat for c_cc; uses Darwin/Glibc directly for POSIX calls
  ├── InputHandler.swift      ← uses Darwin/Glibc directly for POSIX calls
  ├── GameLoop.swift          ← uses PlatformCompat for monoTimeNanoseconds()
  └── Renderer.swift          ← uses Foundation (unchanged)
```

All dependencies point in the correct direction. `GameDomain` has no upward dependencies. `PlatformCompat` is a leaf with no intra-app dependencies.

---

## 5. What Does Not Change

- `Package.swift` — no new targets, no new dependencies
- `TUIOutputPort` protocol signature — unchanged
- `GameCommand` type — unchanged
- All `GameDomain` types and their invariants — unchanged
- `Renderer.swift` — unchanged
- Test target structure — unchanged
- All 139 existing tests remain valid
