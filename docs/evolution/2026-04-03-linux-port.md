# Evolution — linux-port

**Date**: 2026-04-03
**Feature**: linux-port
**Status**: DELIVERED

---

## Summary

Enabled cross-platform compilation of the `DCJam2026` TUI dungeon crawler (Ember's Escape) for both macOS and Linux. The driver was Dungeon Crawler Jam 2026: judges need to run the game, and Linux is the dominant judge platform. The delivery strategy is pre-built ARM64/AMD64 Linux binaries for judges, with Linux source builds verified continuously in CI.

---

## Problem

Three files in `Sources/App/` unconditionally imported `Darwin`, making the binary uncompilable on Linux. The divergences fell into three categories:

| Category | Description |
|----------|-------------|
| Module name | `import Darwin` (macOS) vs `import Glibc` (Linux). Most POSIX symbols are identical in both. |
| Darwin-only clock API | `clock_gettime_nsec_np(CLOCK_MONOTONIC)` — returns `UInt64` nanoseconds directly; no Linux equivalent. Linux uses `clock_gettime(CLOCK_MONOTONIC, &timespec)`. |
| `termios.c_cc` index values | `VMIN` and `VTIME` are at tuple indices 16/17 on macOS, 6/5 on Linux. The code hardcoded `.16` and `.17`. |

---

## Solution

### Approach: Per-file conditional imports + `PlatformCompat.swift` shim (Option A)

- Replace `import Darwin` in the three affected files with `#if canImport(Darwin) / #elseif canImport(Glibc) / #endif`.
- Add `Sources/App/PlatformCompat.swift` as the single designated location for all platform-conditional logic. It exports two abstractions:
  - `monoTimeNanoseconds() -> UInt64` — wraps the two distinct monotonic clock APIs.
  - `setTermiosCCDefaults(_:)` — sets `VMIN`/`VTIME` on `termios.c_cc` using `withUnsafeMutablePointer` and platform-provided `VMIN`/`VTIME` constants.
- No external dependencies added. `Package.swift` unchanged. `GameDomain` target untouched.

### Alternatives rejected

- **Option B — `PlatformIO` protocol with two concrete implementations**: Adds protocol, two concrete structs, constructor injection in three classes — disproportionate complexity for a 5-symbol, 3-file divergence. `TUIOutputPort` already provides the correct output boundary. Rejected.
- **Option C — Separate `PlatformShims` SPM target**: Requires `Package.swift` changes and a new module boundary for what is a single-file problem at this scale. Rejected.
- **Option D — Inline `#if os(macOS)` / `#if os(Linux)` guards**: Scatters platform code across multiple files; `#if os()` is less robust than `#if canImport()`. Rejected.

### Convention established

`PlatformCompat.swift` is the only file in the `DCJam2026` target permitted to contain platform-conditional logic beyond the bare top-level import guard. Documented in `docs/CLAUDE.md`. Enforced by code review.

---

## Execution Steps

| Step | Description | Result |
|------|-------------|--------|
| 01-01 | Created `Sources/App/PlatformCompat.swift` with `monoTimeNanoseconds()`, `setTermiosCCDefaults()`, and `platformWrite()` | PASS |
| 01-02 | `ANSITerminal.swift` — conditional import, `c_cc` fix, `platformWrite()` | PASS |
| 01-03 | `InputHandler.swift` — conditional import, unqualified POSIX calls | PASS |
| 01-04 | `GameLoop.swift` — conditional import, `monoTimeNanoseconds()` | PASS |
| 01-05 | Smoke test — release build passes, 138 tests pass | PASS |

**L3 refactoring note**: During implementation, `platformWrite()` was extracted from `ANSITerminal.flush()` into `PlatformCompat.swift` to enforce the single-boundary convention. This was identified as a defect during the L3 review and corrected before merge.

---

## Review

**Result**: APPROVED (adversarial review, no defects)

---

## Key Decisions

| ID | Decision | Rationale |
|----|----------|-----------|
| D1 | Per-file conditional imports + `PlatformCompat.swift` (Option A) | Minimal footprint; single file concentrates all platform divergence; zero new dependencies |
| D2 | `PlatformCompat.swift` as the single platform boundary file | Future platform work (Windows, WASM) has one file to find; reduces Linux bug diff surface |
| D3 | `#if canImport(Darwin)` over `#if os(macOS)` | Tests module availability at compile time; extends to visionOS, watchOS, future Apple platforms (SE-0075) |
| D4 | No change to `Package.swift` | Jam constraint: zero-dependency builds; change fits within existing `DCJam2026` target |
| D5 | `GameDomain` target untouched | Pure Swift, zero OS imports; no action required; avoids regression risk |

See also: ADR-007 (`docs/adrs/ADR-007-cross-platform-darwin-glibc.md`)

---

## Architecture Impact

The hexagonal (ports-and-adapters) architecture is preserved and unchanged. The `TUIOutputPort` boundary between `Renderer` and `ANSITerminal` is intact. `GameDomain` remains hermetically sealed from OS-specific code — a compile-time guarantee enforced by SwiftPM module structure.

Platform divergence is now fully contained within `Sources/App/PlatformCompat.swift`. No platform-conditional code exists anywhere in `Sources/GameDomain/`.

**Post-change component layout:**
```
Sources/App/
  PlatformCompat.swift     <- ALL platform-conditional code lives here
  ANSITerminal.swift       <- conditional import line only; c_cc via PlatformCompat
  InputHandler.swift       <- conditional import line only
  GameLoop.swift           <- conditional import line only; clock via PlatformCompat
Sources/GameDomain/        <- unchanged; zero OS imports
```

---

## Outcome

- macOS: `swift build` passes, 138 tests pass.
- Linux: `swift build` passes (ARM64 and AMD64). Same test suite passes.
- No new dependencies introduced.
- `GameDomain` diff is empty.
- Pre-built Linux binaries ready for jam judges.

---

## Files Modified

| File | Change type |
|------|-------------|
| `Sources/App/PlatformCompat.swift` | New |
| `Sources/App/ANSITerminal.swift` | Modified — conditional import, `c_cc` fix, `platformWrite()` |
| `Sources/App/InputHandler.swift` | Modified — conditional import, unqualified POSIX calls |
| `Sources/App/GameLoop.swift` | Modified — conditional import, `monoTimeNanoseconds()` |

---

## Lessons Learned

1. **Conditional imports resolve most of the problem for free.** Only 5 symbols across 3 files actually needed active abstraction; the rest just needed the module guard.
2. **Single boundary file pays off immediately.** The L3 review caught `platformWrite()` being authored inside `ANSITerminal.swift` rather than `PlatformCompat.swift` — the convention caught a real violation within the same feature.
3. **`#if canImport` vs `#if os()`** — the distinction matters. Document the reason in CLAUDE.md so future contributors don't silently regress to `#if os(macOS)`.
