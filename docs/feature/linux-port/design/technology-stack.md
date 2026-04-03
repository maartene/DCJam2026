# Technology Stack — linux-port

**Feature**: linux-port
**Date**: 2026-04-03
**Author**: Morgan (Solution Architect — DESIGN wave)

---

## 1. Overview

This feature introduces no new libraries, no new tools, and no new dependencies. It achieves Linux portability entirely within the existing Swift/SPM stack by using language-native conditional compilation.

---

## 2. Swift on Linux

### Swift Toolchain
- **Version**: Swift 6.3 (matches `swift-tools-version: 6.3` in `Package.swift`)
- **Distribution**: Swift.org open-source toolchain for Linux
  - License: Apache 2.0
  - URL: https://swift.org/download/
  - Available as: pre-built tarballs for Ubuntu 20.04, 22.04, 24.04; Amazon Linux 2; Red Hat Enterprise Linux 8/9
- **Language mode**: Swift 6 (strict concurrency) — preserved unchanged

### CI / Jam Build
- Judges building from source need only: Swift 6.3 toolchain + `swift build`
- No `apt-get`, no Homebrew, no Makefile — pure SPM

---

## 3. Swift Standard Library

Available identically on macOS and Linux. No action required.

---

## 4. Foundation (swift-corelibs-foundation)

- **Used by**: `Renderer.swift` (`import Foundation`)
- **Linux availability**: swift-corelibs-foundation ships as part of the Swift Linux toolchain distribution
  - License: Apache 2.0
  - URL: https://github.com/swiftlang/swift-corelibs-foundation
- **Subset note**: swift-corelibs-foundation implements the core Foundation subset. `Renderer.swift` uses only `String`, `Double.format`, and collection operations — all available in swift-corelibs-foundation on Linux.
- **Action required**: none

---

## 5. Platform System Modules

### Darwin (macOS only)
- **Used by**: `ANSITerminal.swift`, `InputHandler.swift`, `GameLoop.swift` (currently unconditional)
- **Post-change**: imported only under `#if canImport(Darwin)` guard

### Glibc (Linux only)
- **Used by**: same three files, post-change
- **License**: LGPL 2.1+ (GNU C Library)
- **Availability**: present on all Linux distributions that ship the Swift toolchain
- **Symbols used**:
  - `termios`, `tcgetattr`, `tcsetattr`, `STDIN_FILENO`, `STDOUT_FILENO`, `TCSAFLUSH`
  - `ICANON`, `ECHO`, `ISIG`, `IXON`, `ICRNL`
  - `VMIN`, `VTIME` (constants, correct values per platform)
  - `open`, `close`, `read`, `write`
  - `O_RDONLY`, `O_NONBLOCK`
  - `errno`, `EINTR`
  - `clock_gettime`, `CLOCK_MONOTONIC`, `timespec`
  - `usleep`

All symbols listed above exist in both Darwin and Glibc with identical names and semantics. The only exception is `clock_gettime_nsec_np` (Darwin-only), which is abstracted away in `PlatformCompat.swift`.

---

## 6. Conditional Compilation Mechanism

Swift's `#if canImport(ModuleName)` directive resolves at compile time and has zero runtime overhead. It is the official Swift mechanism for platform-conditional module imports.

```swift
#if canImport(Darwin)
import Darwin
#elseif canImport(Glibc)
import Glibc
#endif
```

This is preferable to `#if os(macOS)` / `#if os(Linux)` because `canImport` tests whether the module is actually available in the compiler context, which is more robust when cross-compiling or running on future Apple platforms.

---

## 7. No New Dependencies

The `Package.swift` `dependencies: []` array remains empty after this change. This is a hard constraint:
- Jam builds must compile from source with `swift build` and no network access after clone
- No SPM package registry access needed
- Binary size and build time unchanged

---

## 8. Build Verification Matrix

| Platform | Toolchain | Expected result |
|----------|-----------|----------------|
| macOS 14+ | Swift 6.3 | `swift build` succeeds; `swift test` passes 139 tests |
| Ubuntu 22.04 | Swift 6.3 | `swift build` succeeds; `swift test` passes 139 tests |
| Ubuntu 24.04 | Swift 6.3 | `swift build` succeeds; `swift test` passes 139 tests |

Note: The Linux build command for use inside Claude Code (sandbox): `TMPDIR=/tmp/claude-501 swift build --disable-sandbox`
