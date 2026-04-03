# ADR-007: Cross-Platform OS Module Abstraction (Darwin / Glibc)

**Date**: 2026-04-03
**Status**: Accepted
**Author**: Morgan (Solution Architect — DESIGN wave)
**Deciders**: Maarten Engels (developer)

---

## Context

The `DCJam2026` executable target (`Sources/App/`) currently imports `Darwin` unconditionally in three files:

| File | Darwin symbols used |
|------|-------------------|
| `ANSITerminal.swift` | `termios`, `tcgetattr`, `tcsetattr`, raw mode flags, `VMIN`/`VTIME` via hardcoded tuple indices (`.16`, `.17`), `Darwin.write`, `errno`, `EINTR` |
| `InputHandler.swift` | `Darwin.open`, `Darwin.close`, `Darwin.read`, `O_RDONLY`, `O_NONBLOCK` |
| `GameLoop.swift` | `clock_gettime_nsec_np(CLOCK_MONOTONIC)` (Darwin-only), `usleep` |

This prevents compilation on Linux. To submit to Dungeon Crawler Jam 2026, the binary must compile and run correctly on Linux (Ubuntu 22.04/24.04) with Swift 6.3 in addition to macOS.

### Platform Divergence Analysis

Three categories of divergence exist:

**Category 1 — Module name only**
All standard POSIX symbols (`termios`, `tcgetattr`, `tcsetattr`, `open`, `close`, `read`, `write`, `usleep`, `errno`, `EINTR`, `O_RDONLY`, `O_NONBLOCK`, `STDIN_FILENO`, `STDOUT_FILENO`, `TCSAFLUSH`, `ICANON`, `ECHO`, `ISIG`, `IXON`, `ICRNL`) exist in both Darwin and Glibc with identical names and semantics. Resolves by conditional import alone.

**Category 2 — Darwin-only clock API**
`clock_gettime_nsec_np(CLOCK_MONOTONIC)` returns `UInt64` nanoseconds directly and is available only on Darwin. Linux provides `clock_gettime(CLOCK_MONOTONIC, &timespec)` which returns a `timespec` struct (`tv_sec: Int`, `tv_nsec: Int`). Requires a thin abstraction function.

**Category 3 — `termios.c_cc` tuple index values**
The `c_cc` control character array in `termios` is represented as a fixed-size tuple in both Darwin and Glibc. The indices for `VMIN` and `VTIME` differ by platform: macOS VMIN=16, VTIME=17; Linux VMIN=6, VTIME=5. The current code hardcodes `.16` and `.17`, which produces incorrect raw mode on Linux (sets wrong control characters). The fix is to use `withUnsafeMutablePointer(to: &raw.c_cc)` and access by offset using the platform-provided `VMIN` and `VTIME` integer constants, which are correctly defined in both Darwin and Glibc.

### Constraints

- No external dependencies (SPM `dependencies: []` must remain empty)
- Swift 6 language mode must be preserved
- All 139 existing tests must remain green
- `GameDomain` target must remain unchanged
- Time-to-market pressure (jam deadline)

---

## Decision

**Adopt Option A: per-file conditional imports plus a single `PlatformCompat.swift` shim file.**

1. In `ANSITerminal.swift`, `InputHandler.swift`, and `GameLoop.swift`, replace `import Darwin` with:
   ```swift
   #if canImport(Darwin)
   import Darwin
   #elseif canImport(Glibc)
   import Glibc
   #endif
   ```

2. Add `Sources/App/PlatformCompat.swift` containing:
   - `monoTimeNanoseconds() -> UInt64` — wraps `clock_gettime_nsec_np` on Darwin and `clock_gettime` on Linux
   - The documented `withUnsafeMutablePointer` pattern for setting `c_cc[VMIN]` and `c_cc[VTIME]` using platform-provided constants

3. Update `ANSITerminal.swift`:
   - Replace `raw.c_cc.16 = 1` and `raw.c_cc.17 = 0` with the `withUnsafeMutablePointer` pattern
   - Replace `Darwin.write(...)` with unqualified `write(...)`

4. Update `GameLoop.swift`:
   - Replace both `clock_gettime_nsec_np(CLOCK_MONOTONIC)` call sites with `monoTimeNanoseconds()`

5. Establish the convention: `PlatformCompat.swift` is the only permitted location for platform-conditional logic beyond the top-level import guard. Document this in `docs/CLAUDE.md`.

---

## Alternatives Considered

### Option B — Dedicated `PlatformIO` protocol with two concrete implementations

Introduce a new `PlatformIO` protocol with a Darwin adapter and a Glibc adapter, injected into `ANSITerminal`, `InputHandler`, and `GameLoop` at construction time.

**Evaluation**:
- Pro: cleaner conceptual separation; formally testable
- Con: requires protocol definition, two concrete structs, constructor injection changes in three classes, and wiring in `GameLoop.init()` — all to isolate 5 symbols across 3 files
- Con: provides no additional testability benefit; the affected symbols are exercised indirectly through `ANSITerminal`, `InputHandler`, and `GameLoop` in integration
- Con: the `TUIOutputPort` port already provides the correct abstraction boundary for renderer output; adding a `PlatformIO` port for 5 POSIX calls is over-engineering for this scope
- **Rejected**: disproportionate complexity relative to the change scope

### Option C — Separate SwiftPM target for platform shims (`PlatformShims`)

Add a new `PlatformShims` SPM target under `Sources/PlatformShims/` with `ANSITerminal` and the other platform-dependent types moved there, and declare it as a dependency of `DCJam2026`.

**Evaluation**:
- Pro: enforces the platform boundary at the module level (compile-time)
- Con: requires `Package.swift` modification; adds a new directory; creates a new module boundary for what is fundamentally a 5-symbol problem
- Con: for a single developer jam project, module-boundary isolation of platform code is addressable by convention and code review at this scale
- **Rejected**: unnecessary structural complexity; file-level convention in `PlatformCompat.swift` is sufficient

### Option D — `#if os(macOS)` / `#if os(Linux)` guards inline in each affected file

Scatter `#if os(macOS)` / `#if os(Linux)` blocks at every divergent line in each affected file.

**Evaluation**:
- Pro: no new file needed
- Con: platform code scattered across multiple files; future platform additions require touching multiple files; `#if os()` is less robust than `#if canImport()` (does not extend to visionOS, watchOS, or cross-compile scenarios)
- Con: the `c_cc` index problem and the clock API problem both require multi-line guarded blocks — an abstraction function is cleaner than inline guards at two call sites
- **Rejected**: maintainability inferior to a single shim file; `canImport` is the documented Swift best practice

---

## Consequences

### Positive
- The game compiles and runs correctly on macOS and Linux with a single SPM target and no new dependencies
- `GameDomain` is entirely unaffected — the domain/infrastructure boundary is preserved
- Platform divergence is concentrated in one new file (`PlatformCompat.swift`) — easy to find, easy to reason about, easy to extend
- `#if canImport(Darwin)` / `#elseif canImport(Glibc)` is idiomatic Swift; well understood by Swift developers
- All 139 existing tests remain valid without modification
- `Package.swift` is unchanged — zero-dependency jam build requirement satisfied

### Negative
- `PlatformCompat.swift` convention ("only file for platform-conditional code") requires documentation and code review to enforce — there is no compile-time tool in Swift as of April 2026 that can verify this rule automatically
- The `withUnsafeMutablePointer` pattern for `c_cc` access introduces a `withUnsafeMutablePointer` call, which is slightly more ceremonious than direct tuple index access — but is correct and safe

### Neutral
- Two `#if canImport` import blocks in `ANSITerminal.swift`, `InputHandler.swift`, `GameLoop.swift` add 3 lines each (4 lines per file) to the file headers — minor cosmetic change
- `usleep` requires no platform guard (present in both Darwin and Glibc)
