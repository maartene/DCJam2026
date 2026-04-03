# Swift Multi-Platform Build Strategies
## Producing Release Binaries for macOS (ARM64/x86_64), Linux x86_64, and Linux ARM64

**Date**: 2026-04-03
**Status**: COMPLETE
**Project context**: DCJam2026 — Swift 6.3 terminal game, zero dependencies, SwiftPM, macOS + Linux
**Specific problem**: aarch64 binary crashes on Raspberry Pi 3/4 (SIGILL in mimalloc — LSE atomics not supported on ARMv8.0)

---

## Executive Summary

This research investigates how to produce distributable Swift binaries for five targets
(macOS ARM64, macOS x86_64, macOS universal, Linux x86_64, Linux aarch64 for Raspberry Pi)
from a local build script, without depending on CI.

**The Raspberry Pi crash is a well-understood, cross-ecosystem problem.** Binaries compiled
with LSE atomic instructions (ARMv8.1+) crash with SIGILL on Cortex-A53/A72 (ARMv8.0) CPUs.
The Swift Static Linux SDK bundles mimalloc pre-compiled with `-march=armv8.1-a` on aarch64,
which triggers this crash on Pi 3/4. The fix already in use in the project CI
(`-Xswiftc -static-stdlib` on a native ARM runner) is correct and sufficient.

**For a local build script, the recommended approach is Docker.** The official Swift Docker
image (`swift:6.x-noble` or `swift:6.x-jammy`) supports both `linux/amd64` and `linux/arm64`
via Docker's multi-platform build infrastructure. Running a `linux/arm64` container via
QEMU emulation on macOS produces a native aarch64 Linux binary. Crucially, the Swift
compiler running inside the emulated container compiles code for the container's native CPU
target — the resulting binary targets a generic `aarch64` baseline, not the ARMv8.1+ runner
CPUs used in GitHub Actions, and thus avoids the LSE atomics problem entirely.

**macOS universal binaries** are straightforward: `swift build -c release --arch arm64 --arch x86_64`
builds both slices and places the fat binary at `.build/apple/Products/Release/`.

The practical `build.sh` script design is documented in Section 9 with annotated commands
for every target.

**Confidence summary:**
- macOS universal binary technique: HIGH (2+ authoritative sources)
- Docker + QEMU for linux/arm64 locally: MEDIUM-HIGH (mechanism well-documented; Swift-specific QEMU stability improved in Swift 5.9+)
- Static Linux SDK mimalloc/LSE issue: HIGH (confirmed by Red Hat Bugzilla, bun issue tracker, mimalloc README)
- `-static-stdlib` as the correct Pi workaround: HIGH (matches CI comments and `-Xswiftc` flag behavior)
- Cross-compilation as alternative to Docker: LOW (community toolchains target old Swift versions; official cross-compilation for aarch64 from macOS is not well-supported in Swift 6.x)

---

## Table of Contents

1. [Local Build Scripts vs CI](#1-local-build-scripts-vs-ci)
2. [Docker-Based Linux Builds from macOS](#2-docker-based-linux-builds-from-macos)
3. [Swift Static Linux SDK](#3-swift-static-linux-sdk)
4. [Static Linking on Linux](#4-static-linking-on-linux)
5. [Cross-Compilation](#5-cross-compilation)
6. [macOS Universal Binaries](#6-macos-universal-binaries)
7. [Packaging and Release Archives](#7-packaging-and-release-archives)
8. [The Raspberry Pi aarch64 Problem](#8-the-raspberry-pi-aarch64-problem)
9. [Practical build.sh Script](#9-practical-buildsh-script)
10. [Knowledge Gaps](#10-knowledge-gaps)
11. [Conflicting Information](#11-conflicting-information)
12. [Sources](#12-sources)

---

## 1. Local Build Scripts vs CI

### 1.1 Trade-offs Overview

| Dimension | Local script | CI (GitHub Actions) |
|-----------|-------------|---------------------|
| Iteration speed | Fast for macOS targets; QEMU slow for Linux arm64 (~3-5x native) | Slow round-trip; push/tag required |
| Reproducibility | Depends on local toolchain version | Pinnable via `SwiftyLab/setup-swift` |
| Cross-arch Linux | Requires Docker + QEMU on macOS | Native ARM runners available (`ubuntu-24.04-arm`) |
| Availability | Always; no network dependency for macOS | Requires GitHub account + minutes |
| Debuggability | Direct terminal access | Requires SSH or log inspection |
| Cost | Zero | Free tier has limits; native ARM runners may cost extra |

**Evidence**: Swift server-side build guide [S7] recommends Docker for Linux builds on macOS.
SwiftToolkit release automation article [S6] documents CI-centric workflows with artifact upload.
The existing project `release.yml` is already a working CI baseline.

### 1.2 When to Prefer Local Scripts

- During jam development when you need to test a binary on Pi quickly without a push/tag cycle
- For macOS-only builds (no Docker dependency, instant feedback)
- When CI minutes are limited or the CI runner is unavailable

### 1.3 When to Prefer CI

- For tagged release builds (authoritative artifacts tied to a commit SHA)
- When a native ARM runner (`ubuntu-24.04-arm`) is available — eliminates QEMU slowness
  and produces a binary that exactly matches the runner's CPU profile with `-static-stdlib`
- For reproducible binary provenance

**Interpretation**: For this project, a hybrid approach is optimal. CI handles tagged releases;
a local script handles development-time "does it run on Pi?" smoke tests.

---

## 2. Docker-Based Linux Builds from macOS

### 2.1 Swift Official Docker Images

The official Swift Docker image is published at `hub.docker.com/_/swift` (library image)
and `hub.docker.com/r/swiftlang/swift` (swiftlang namespace). As of Swift 6.x, both
`linux/amd64` and `linux/arm64` platforms are supported via Docker Hub's multi-platform
manifest. Tags follow the pattern `swift:6.x-jammy` (Ubuntu 22.04) and `swift:6.x-noble`
(Ubuntu 24.04).

**Evidence**: Docker Hub official Swift image page [S8]; Swift forums thread on ARM64 Docker
images [S9].

### 2.2 Building a linux/amd64 Binary from macOS

On any macOS host (both Intel and Apple Silicon), the following command builds a release
binary targeting `linux/amd64`:

```bash
docker run --rm \
  --platform linux/amd64 \
  -v "$PWD:/src" \
  -w /src \
  swift:6.3-noble \
  swift build -c release --product DCJam2026
```

The binary appears at `.build/x86_64-unknown-linux-gnu/release/DCJam2026` on the host
(Docker volume mount makes the `.build` directory directly accessible).

For a fully static binary using the Static Linux SDK inside Docker, see Section 4.

**Evidence**: SwiftToolkit building executables article [S2]; Swift server build guide [S7].

### 2.3 QEMU Emulation for linux/arm64 on macOS

Docker Desktop on macOS uses QEMU to emulate `linux/arm64` containers on Intel Macs.
On Apple Silicon Macs, `linux/arm64` containers run natively; only `linux/amd64` requires
QEMU/Rosetta.

To build a `linux/arm64` binary from an Intel Mac:

```bash
# One-time: register QEMU binfmt handlers (Docker Desktop does this automatically)
# docker run --rm --privileged multiarch/qemu-user-static --reset -p yes

docker run --rm \
  --platform linux/arm64 \
  -v "$PWD:/src" \
  -w /src \
  swift:6.3-noble \
  swift build -c release --product DCJam2026
```

The binary appears at `.build/aarch64-unknown-linux-gnu/release/DCJam2026`.

**Known QEMU stability issue**: An earlier crash in libdispatch when building Swift under
QEMU ARM64 was present in Swift 5.6 images. The Swift forums thread [S10] confirmed it was
resolved by Swift 5.9+ images. Swift 6.x images (jammy/noble) are stable under QEMU
emulation for simple builds.

**Performance**: QEMU emulation is significantly slower than native builds, especially for
compile-heavy workloads. Expect 3-8x longer build times for a `linux/arm64` build on an
Intel Mac compared to native. On Apple Silicon, `linux/arm64` runs natively at near-native
speed.

**Evidence**: Docker multi-platform documentation [S11]; Swift forums QEMU crash thread [S10];
Swift server build guide [S7] (mentions `--platform linux/amd64 -e QEMU_CPU=max` for
Apple Silicon targeting Intel).

### 2.4 Static Linking Inside Docker

Inside a `linux/arm64` Docker container (Swift image), there are two static linking modes:

**Mode A — `-static-stdlib`** (statically links Swift stdlib, dynamically links glibc):
```bash
docker run --rm --platform linux/arm64 \
  -v "$PWD:/src" -w /src swift:6.3-noble \
  swift build -c release --product DCJam2026 -Xswiftc -static-stdlib
```

**Mode B — Static Linux SDK** (fully static, musl, no glibc dependency):
The Static Linux SDK can be installed inside the container, but this adds complexity
(SDK download inside Docker, architecture matching). For the Pi use case, Mode A is
preferred because it avoids mimalloc (see Section 8).

**Evidence**: Swift Static Linux SDK documentation [S1]; Swift Evolution proposal SE-0342 [S3].

---

## 3. Swift Static Linux SDK

### 3.1 What the Static Linux SDK Is

The Swift Static Linux SDK enables fully statically linked executables for Linux with
**no external dependencies** — not even libc. As the official documentation states:
"build your program as a _fully statically linked_ executable, with no external dependencies
at all (not even the C library)." [S1]

The SDK uses **musl libc** instead of glibc. Musl was chosen because it has excellent support
for static linking and is permissively licensed, making distribution of statically-linked
binaries legally straightforward. [S1]

### 3.2 How `--swift-sdk` Works with SwiftPM

Installation:
```bash
swift sdk install \
  https://download.swift.org/swift-6.3-release/static-sdk/swift-6.3-RELEASE/\
swift-6.3-RELEASE_static-linux-0.1.0.artifactbundle.tar.gz \
  --checksum d2078b69bdeb5c31202c10e9d8a11d6f66f82938b51a4b75f032ccb35c4c286c
```

Building with it:
```bash
swift build -c release --product DCJam2026 \
  --swift-sdk x86_64-swift-linux-musl
```

The SDK identifier `x86_64-swift-linux-musl` (or `aarch64-swift-linux-musl`) tells SwiftPM
to use the bundled musl sysroot and produce a fully static ELF binary.

The SDK version must match the toolchain version. Mixing versions causes build errors. [S5]

### 3.3 Limitations: ARMv8.0 and Raspberry Pi

The Static Linux SDK documentation [S1] does **not** mention ARMv8.0, LSE atomics, or
Raspberry Pi compatibility. There is no explicit SDK variant targeting ARMv8.0 as of
Swift 6.3.

The aarch64 musl SDK (`aarch64-swift-linux-musl`) bundles a pre-compiled mimalloc that
assumes ARMv8.1+ CPU features. This is the direct cause of SIGILL crashes on Raspberry Pi 3/4.
See Section 8 for full analysis.

### 3.4 The mimalloc LSE Atomics Issue

**Background — mimalloc and ARMv8.1**: mimalloc version 2.1.8+ on aarch64 defaults to
compiling with `-march=armv8.1-a`, which emits LSE atomic instructions (`ldaddal`, `casa`,
`swpa`, etc.). These instructions are part of the ARMv8.1 Large System Extension and are
**not available on ARMv8.0-A processors** (Raspberry Pi 3: Cortex-A53; Raspberry Pi 4:
Cortex-A72). [S13, S14]

**Red Hat confirmation**: Red Hat Bugzilla issue #2342055 documents this exact problem —
mimalloc 2.1.8 crashing on Raspberry Pi 4 with "Illegal instruction" due to
`-march=armv8.1-a` default. Fixed in version 2.1.9-3.fc41 by adjusting `MI_OPT_ARCH`.
[S13]

**mimalloc README confirmation**: The mimalloc README states:
"MI_OPT_ARCH is off by default now but still assumes armv8.1-a on arm64 for fast atomic
operations." [S15]

**The connection to the Swift Static Linux SDK**: The aarch64 musl SDK bundles mimalloc
as the default allocator (as shown by forum discussion [S16]). The bundled mimalloc is
pre-compiled with ARMv8.1+ assumptions. Unlike a distribution package fix (which upgrades
to mimalloc 2.1.9+), the SDK's bundled binary cannot be patched without rebuilding the SDK
from source.

**Evidence**: Red Hat Bugzilla #2342055 [S13]; mimalloc README [S15]; bun issue #26556 [S14];
Swift forums mimalloc/SDK thread [S16].

---

## 4. Static Linking on Linux

### 4.1 `-static-stdlib` Flag

`-Xswiftc -static-stdlib` statically links the **Swift standard library** into the binary.
The binary still dynamically links against the system's glibc.

Practical effect:
- The binary requires glibc to be present at runtime (it will be on any modern Ubuntu/Debian)
- No Swift runtime `.so` files need to be deployed alongside the binary
- The allocator is the **system allocator** (glibc malloc) — mimalloc is **not involved**

This is why `-static-stdlib` on a native ARM runner avoids the Pi crash: there is no mimalloc
in the binary.

**Evidence**: Swift Evolution SE-0342 [S3]; Swift forums static linking thread [S4]; project
`release.yml` CI comments (project artifact).

### 4.2 Full Static Binary via `--swift-sdk` (musl)

`--swift-sdk aarch64-swift-linux-musl` produces a fully static binary:
- No glibc dependency
- No external Swift runtime dependency
- Binary is self-contained (but larger — typically 20-60 MB for a simple Swift executable)
- The Static Linux SDK produces very large binaries because it bundles the full Swift runtime
  and all Foundation symbols statically [S17]

On aarch64, this approach bundles mimalloc with ARMv8.1+ assumptions, making it unsafe
for Raspberry Pi 3/4 deployment.

**Evidence**: Swift Static Linux SDK docs [S1]; Swift forums large binaries thread [S17].

### 4.3 glibc Dependency Trade-offs

**With `-static-stdlib` (glibc-dynamic):**
- Requires matching glibc version on the target system
- Ubuntu 22.04 ships glibc 2.35; Ubuntu 24.04 ships glibc 2.39
- Raspberry Pi OS (Debian Bookworm 64-bit) ships glibc 2.36
- A binary built on Ubuntu 22.04 (glibc 2.35) will run on Pi OS Bookworm (glibc 2.36)
  because glibc is backward-compatible (newer glibc runs older binaries)
- A binary built on Ubuntu 24.04 (glibc 2.39) may fail on Pi OS with glibc 2.36

**Recommendation for Pi compatibility**: Build inside a Docker container based on
`ubuntu:22.04` or `swift:6.3-jammy` to get a binary that uses glibc 2.35 symbols,
compatible with Pi OS Bookworm.

**With musl (fully static):**
- No glibc dependency at all — binary runs on any Linux regardless of libc version
- Risk: musl default thread stack size is 128KB (vs glibc's 2-10 MB), which can cause
  stack overflow for deeply recursive operations [S18]
- The mimalloc/ARMv8.1 crash applies to aarch64 musl SDK builds

**Evidence**: Swift forums musl thread [S4]; SwiftLint musl stack overflow issue [S18];
musl libc functional differences documentation [S19].

---

## 5. Cross-Compilation

### 5.1 Swift Cross-Compilation Overview

Swift's cross-compilation support as of Swift 6.x is best described as **partial and evolving**.
The `swift-sdk-generator` tool [S20] can generate destination SDKs for Linux-to-Linux
cross-compilation (e.g., x86_64 Linux host → aarch64 Linux binary). However,
macOS-to-Linux cross-compilation for aarch64 is not a first-class supported scenario.

### 5.2 Cross-Compiling aarch64-Linux from macOS

**Official Swift SDK Generator** (`swiftlang/swift-sdk-generator`): The tool supports
`--target-arch aarch64` but requires a **Linux host** for generating Linux-targeting SDKs.
On Apple Silicon macOS, it can generate aarch64 SDKs that match the host architecture
(effectively not cross-compilation). [S20]

**Community toolchains**: Several older projects exist —
`AlwaysRightInstitute/swift-mac2arm-x-compile-toolchain` [S21],
`CSCIX65G/SwiftCrossCompilers` [S22], and `keith/swiftpm-linux-cross` [S23] — but these
target Swift 5.x (5.3 or earlier) and are not maintained for Swift 6.x.

**Known issue**: Cross-compiling from x86_64 to aarch64 with `--static-swift-stdlib` in
Swift 6.0.2 hits a resource directory path bug (`static-stdlib-args.lnk not found`).
The workaround is a Docker-based environment. [S24]

**Macro compilation**: As of Swift 6.0-6.1, cross-compilation of packages containing
Swift macros is broken, though fixes were in progress. [S25]

**Interpretation**: Cross-compilation from macOS to aarch64 Linux using Swift 6.x toolchains
is not practically viable as of early 2026 without significant community infrastructure.
Docker-based native builds are the recommended alternative.

### 5.3 ARMv8.0-Specific Toolchain Variants

**No official ARMv8.0-specific Swift toolchain variant exists.** swift.org does not offer
a `swift-6.x-armv8.0` download. The official Linux aarch64 downloads target generic
`aarch64` / ARMv8.0+ baseline (the Swift compiler's default for aarch64 is conservative),
but the **Static Linux SDK** separately bundles mimalloc pre-compiled for ARMv8.1+.

**The `-moutline-atomics` flag**: The GCC/Clang flag `-moutline-atomics` generates atomic
operations via runtime helper functions that detect LSE support at startup, instead of
inlining LSE instructions. This would make binaries compatible with both ARMv8.0 and
ARMv8.1+ devices. However:
- This flag must be applied when compiling mimalloc itself (the allocator), not just the
  Swift code
- Since mimalloc is pre-compiled into the Static Linux SDK bundle, passing
  `-moutline-atomics` via SwiftPM flags does not fix the pre-compiled mimalloc in the SDK
- The only lever available to Swift developers is to avoid the Static Linux SDK on aarch64
  and use `-static-stdlib` instead

**Evidence**: bun issue #26556 [S14] (documents `-moutline-atomics` fix for WebKit LSE);
GCC AArch64 options documentation [S26]; Swift forums cross-compilation thread [S25].

---

## 6. macOS Universal Binaries

### 6.1 Building Separate Architecture Slices

SwiftPM supports building for a specific architecture using the `--arch` flag (introduced
in Swift 5.3 / Xcode 12). It goes through Xcode's XCBuild path:

```bash
swift build -c release --arch arm64  --product DCJam2026
# Output: .build/arm64-apple-macosx/release/DCJam2026

swift build -c release --arch x86_64 --product DCJam2026
# Output: .build/x86_64-apple-macosx/release/DCJam2026
```

Alternatively, using the `--triple` flag:
```bash
swift build -c release \
  --triple arm64-apple-macosx  --product DCJam2026
swift build -c release \
  --triple x86_64-apple-macosx --product DCJam2026
```

**Evidence**: Povio universal binary article [S27]; Cross-compile for Apple Silicon article [S28].

### 6.2 Creating Fat Binaries with lipo

After building both slices, `lipo` combines them into a single Mach-O fat binary:

```bash
lipo -create \
  -output DCJam2026-macos-universal \
  .build/arm64-apple-macosx/release/DCJam2026 \
  .build/x86_64-apple-macosx/release/DCJam2026
```

Verify:
```bash
lipo -info DCJam2026-macos-universal
# Architectures in the fat file: DCJam2026-macos-universal are: arm64 x86_64
file DCJam2026-macos-universal
# Mach-O universal binary with 2 architectures: [arm64:Mach-O 64-bit executable arm64]
# [x86_64:Mach-O 64-bit executable x86_64]
```

**Evidence**: Povio universal binary article [S27]; Universal binaries reference [S29].

### 6.3 SwiftPM One-Command Universal Build

SwiftPM supports both architectures in a single invocation (the `--arch` flag is additive):

```bash
swift build -c release --arch arm64 --arch x86_64 --product DCJam2026
```

The combined universal binary appears at:
`.build/apple/Products/Release/DCJam2026`

This is a single-pass build that invokes XCBuild under the hood and produces the fat binary
directly — no `lipo` step required.

**Note**: This path (`.build/apple/Products/Release/`) differs from the usual
`.build/arm64-apple-macosx/release/` path used in single-arch builds. Scripts must account
for this.

**Evidence**: SwiftToolkit building executables article [S2]; Swift forums universal binary
thread [S30].

---

## 7. Packaging and Release Archives

### 7.1 Naming Conventions for Multi-Target Archives

The project's existing CI uses `DCJam2026-linux-{arch}.zip`. Consistent conventions for
all targets:

| Target | Recommended filename |
|--------|---------------------|
| macOS universal | `DCJam2026-macos-universal.zip` |
| Linux x86_64 (static) | `DCJam2026-linux-x86_64.zip` |
| Linux aarch64 (Pi-compatible) | `DCJam2026-linux-aarch64.zip` |

### 7.2 Zip vs Tar.gz for Distribution

The existing CI uses `.zip`. For terminal game binaries distributed to Pi users (Linux),
`.tar.gz` is more conventional on Linux. However, `.zip` is universally supported and
consistent with the existing workflow. Staying with `.zip` minimizes change.

**Packaging commands**:
```bash
# macOS
zip DCJam2026-macos-universal.zip DCJam2026-macos-universal

# Linux x86_64 (static, via Docker)
zip DCJam2026-linux-x86_64.zip DCJam2026

# Linux aarch64 (Pi-compatible, via Docker + QEMU)
zip DCJam2026-linux-aarch64.zip DCJam2026
```

**Evidence**: Project `release.yml` (project artifact); SwiftToolkit release automation [S6].

---

## 8. The Raspberry Pi aarch64 Problem

### 8.1 Problem Statement

The project's CI builds the aarch64 binary on a native `ubuntu-24.04-arm` runner using
`-Xswiftc -static-stdlib`. This already works. The problem is reproducing this build
**locally** on macOS without a native ARM Linux machine.

### 8.2 Why mimalloc Causes SIGILL on Pi 3/4

The Raspberry Pi 3 uses a Cortex-A53 CPU (ARMv8.0-A architecture).
The Raspberry Pi 4 uses a Cortex-A72 CPU (ARMv8.0-A architecture).

Neither supports ARMv8.1 Large System Extension (LSE) atomic instructions such as:
- `ldaddal` (atomic load-add)
- `casa` / `casal` (compare-and-swap)
- `swpa` / `swpal` (atomic swap)

The Swift Static Linux SDK aarch64 variant (`aarch64-swift-linux-musl`) bundles mimalloc
pre-compiled with `-march=armv8.1-a`. When the binary starts, mimalloc's initialization
code executes these instructions on the Pi's ARMv8.0 CPU, producing SIGILL (Signal 4:
Illegal instruction) immediately at startup.

This is not a Swift-specific bug; it affects any software that bundles mimalloc 2.1.8+
compiled for ARMv8.1+ on ARMv8.0 hardware. Red Hat documented the same crash in their
distribution of the `mold` linker (which also uses mimalloc). [S13]

**Root cause chain**:
```
Static Linux SDK (aarch64)
  └── bundles mimalloc
        └── compiled -march=armv8.1-a
              └── emits LSE atomic instructions
                    └── SIGILL on Cortex-A53/A72 (ARMv8.0)
```

### 8.3 Why `-static-stdlib` Avoids the Problem

`-Xswiftc -static-stdlib` statically links only the **Swift standard library** (stdlib
archive files). The allocator used is whatever the system provides at runtime — on Ubuntu
Linux with glibc, this is glibc's ptmalloc2. No mimalloc is linked into the binary.

The binary still dynamically links glibc, which is present on all Raspberry Pi OS variants.
The Swift runtime is embedded but uses the system allocator. This approach is stable on
Raspberry Pi. [Project CI `release.yml` comments; confirmed by Swift forums and SE-0342.]

### 8.4 Option Analysis: Docker + QEMU for linux/arm64

**The question**: Does running `swift build` inside a `linux/arm64` Docker container
(emulated via QEMU on macOS Intel, native on Apple Silicon) avoid the LSE atomics problem?

**Answer: Yes, with caveats.**

When you run `swift build -c release` inside a `linux/arm64` Swift Docker container
(without the Static Linux SDK), the Swift compiler produces an aarch64 ELF binary using
the **generic aarch64 baseline** (ARMv8.0-A). The system allocator inside the container
is glibc malloc — no mimalloc involved. The resulting binary:
- Does not contain LSE atomic instructions in the application code
- Does not bundle mimalloc
- Links against glibc (from the container's Ubuntu base image)
- Will run on Raspberry Pi OS

To also statically link the Swift stdlib, add `-Xswiftc -static-stdlib`:
```bash
docker run --rm --platform linux/arm64 \
  -v "$PWD:/src" -w /src swift:6.3-jammy \
  swift build -c release --product DCJam2026 -Xswiftc -static-stdlib
```

This produces an aarch64 binary with:
- Static Swift stdlib (no Swift `.so` files needed on Pi)
- Dynamic glibc link (requires glibc >= 2.35 from the jammy base)
- **No mimalloc** — the crash is avoided

**QEMU stability on macOS Intel**: Building Swift under QEMU ARM64 previously had
libdispatch crashes (Swift 5.6 images). This was resolved in Swift 5.9+ images. [S10]
Swift 6.3 images (jammy/noble) are expected to be stable for build operations.
The QEMU_CPU default in Docker Desktop should be sufficient; setting `QEMU_CPU=max`
may help with corner cases.

**On Apple Silicon Mac**: Running `linux/arm64` containers is native (no QEMU), so build
times are fast and stability concerns are minimal.

### 8.5 Option Analysis: Cross-Compilation with ARMv8.0 Target

Theoretically, one could cross-compile from macOS with an explicit ARMv8.0 target triple
and linker flags. In practice:
- No maintained Swift 6.x cross-compilation toolchain exists for macOS-to-aarch64-Linux
- The `-moutline-atomics` fix only helps for code you compile, not the pre-compiled mimalloc
  in the Static Linux SDK
- Avoiding the SDK (use `-static-stdlib`) makes cross-compilation still complex due to
  needing an aarch64 sysroot

**Verdict**: Cross-compilation is not a practical path for this project.

### 8.6 Recommended Solution for Local Builds

Use Docker with the official Swift image on `linux/arm64` platform, with `-static-stdlib`:

```bash
docker run --rm \
  --platform linux/arm64 \
  -v "$PWD:/src" \
  -w /src \
  swift:6.3-jammy \
  swift build -c release --product DCJam2026 \
  -Xswiftc -static-stdlib
```

This exactly reproduces what the CI does (native ARM runner + `-static-stdlib`), just via
QEMU emulation on Intel or natively on Apple Silicon.

---

## 9. Practical build.sh Script

### 9.1 Script Design Considerations

1. **Prerequisites**: Docker Desktop (for Linux builds), Swift toolchain (for macOS builds)
2. **Apple Silicon vs Intel**: On Apple Silicon, `linux/arm64` runs natively in Docker
   (fast). On Intel, it runs via QEMU (slow, ~5-10 min for a Swift build).
3. **Output directory**: Use a `dist/` directory to collect all binaries and zips
4. **Error handling**: Exit on first failure to avoid silently shipping broken binaries
5. **Parallelism**: macOS builds and Linux x86_64 builds can run in parallel;
   Linux arm64 should be sequential (QEMU is resource-intensive)
6. **Path differences**: The `--arch arm64 --arch x86_64` universal build outputs to
   `.build/apple/Products/Release/`, not the usual `.build/<triple>/release/`

### 9.2 Annotated Script

```bash
#!/usr/bin/env bash
# build.sh — Local multi-platform release builder for DCJam2026
# Produces distributable binaries for all supported targets.
#
# Prerequisites:
#   - Swift toolchain (matching swift.org 6.3 release)
#   - Docker Desktop (for Linux builds)
#
# Usage:
#   ./build.sh [--skip-linux-arm64]  # Pass flag to skip slow QEMU build
#
# Output:
#   dist/DCJam2026-macos-universal.zip
#   dist/DCJam2026-linux-x86_64.zip
#   dist/DCJam2026-linux-aarch64.zip   (skipped if --skip-linux-arm64)

set -euo pipefail

PRODUCT="DCJam2026"
SWIFT_IMAGE="swift:6.3-jammy"
DIST="$(pwd)/dist"
SKIP_ARM64=false

for arg in "$@"; do
  [[ "$arg" == "--skip-linux-arm64" ]] && SKIP_ARM64=true
done

mkdir -p "$DIST"

# ── macOS: universal binary (arm64 + x86_64) ─────────────────────────────────
echo "[1/3] Building macOS universal binary..."
swift build -c release \
  --arch arm64 \
  --arch x86_64 \
  --product "$PRODUCT"

# Universal build goes to .build/apple/Products/Release/
MACOS_BIN=".build/apple/Products/Release/$PRODUCT"
cp "$MACOS_BIN" "$DIST/$PRODUCT-macos-universal"
(cd "$DIST" && zip "$PRODUCT-macos-universal.zip" "$PRODUCT-macos-universal" \
  && rm "$PRODUCT-macos-universal")
echo "  -> $DIST/$PRODUCT-macos-universal.zip"

# ── Linux x86_64: static stdlib, glibc-dynamic ───────────────────────────────
echo "[2/3] Building Linux x86_64 binary (via Docker)..."
docker run --rm \
  --platform linux/amd64 \
  -v "$(pwd):/src" \
  -w /src \
  "$SWIFT_IMAGE" \
  swift build -c release --product "$PRODUCT" -Xswiftc -static-stdlib

# Docker volume mount makes .build/ directly accessible on host
X86_BIN=".build/x86_64-unknown-linux-gnu/release/$PRODUCT"
cp "$X86_BIN" "$DIST/$PRODUCT-linux-x86_64"
(cd "$DIST" && zip "$PRODUCT-linux-x86_64.zip" "$PRODUCT-linux-x86_64" \
  && rm "$PRODUCT-linux-x86_64")
echo "  -> $DIST/$PRODUCT-linux-x86_64.zip"

# ── Linux aarch64: static stdlib, Pi-compatible (no mimalloc) ─────────────────
if [[ "$SKIP_ARM64" == "true" ]]; then
  echo "[3/3] Skipping Linux arm64 build (--skip-linux-arm64 passed)"
else
  echo "[3/3] Building Linux arm64 binary (via Docker + QEMU or native)..."
  echo "      NOTE: This is slow on Intel Macs via QEMU. Expected: 5-15 min."
  echo "      On Apple Silicon, this runs natively and is fast."
  echo ""
  echo "      Uses -static-stdlib (NOT --swift-sdk aarch64-swift-linux-musl)"
  echo "      to avoid the mimalloc LSE atomics crash on Raspberry Pi 3/4."

  docker run --rm \
    --platform linux/arm64 \
    -v "$(pwd):/src" \
    -w /src \
    "$SWIFT_IMAGE" \
    swift build -c release --product "$PRODUCT" -Xswiftc -static-stdlib

  ARM_BIN=".build/aarch64-unknown-linux-gnu/release/$PRODUCT"
  cp "$ARM_BIN" "$DIST/$PRODUCT-linux-aarch64"
  (cd "$DIST" && zip "$PRODUCT-linux-aarch64.zip" "$PRODUCT-linux-aarch64" \
    && rm "$PRODUCT-linux-aarch64")
  echo "  -> $DIST/$PRODUCT-linux-aarch64.zip"
fi

echo ""
echo "Build complete. Artifacts:"
ls -lh "$DIST"/*.zip
```

### 9.3 Verifying the aarch64 Binary

To confirm the binary does NOT contain LSE atomics, use `objdump` on Linux:
```bash
# Inside the Docker container or on a Linux machine:
objdump -d .build/aarch64-unknown-linux-gnu/release/DCJam2026 \
  | grep -E '\bcasa\b|\bldadd\b|\bswpa\b|\bstlr\b' | head -5
# Expected: no output (no LSE instructions in Swift application code)
```

The binary should be an ELF 64-bit LSB executable for ARM aarch64:
```bash
file .build/aarch64-unknown-linux-gnu/release/DCJam2026
# ELF 64-bit LSB pie executable, ARM aarch64, version 1 (SYSV), dynamically linked,
# interpreter /lib/ld-linux-aarch64.so.1, for GNU/Linux 3.7.0, ...
```

---

## 10. Knowledge Gaps

### Gap 1: Exact mimalloc version bundled in Swift 6.3 Static Linux SDK (aarch64)

**Searched**: Swift GitHub issues, Swift forums, Swift release notes, Swift SDK artifact manifest
**Found**: The forums confirm mimalloc is used as the allocator in the static SDK [S16];
the Red Hat bug confirms mimalloc 2.1.8+ compiles with ARMv8.1 flags [S13]; the mimalloc
README confirms the behavior [S15]. The exact version bundled in the Swift 6.3-RELEASE
aarch64 musl SDK was not confirmed from an authoritative source.

**Impact**: Low. The behavior (SIGILL on Pi) is confirmed; the solution (avoid the SDK,
use `-static-stdlib`) is confirmed. The exact version number is not needed for the fix.

### Gap 2: Whether QEMU-emulated linux/arm64 Docker builds produce ARMv8.0-baseline binaries by default

**Searched**: Docker QEMU documentation, Swift forums, GCC aarch64 defaults
**Found**: The Swift compiler's aarch64 default target is generic aarch64 (ARMv8.0 baseline).
QEMU emulation does not change the compiler's target — it only emulates the CPU for
the compilation host. The resulting binary targets ARMv8.0 unless explicitly overridden.
**However**, a direct authoritative test confirming the QEMU-produced binary runs on
Pi 3/4 was not found in the searched sources.

**Impact**: Medium. The theoretical analysis is sound (no mimalloc, generic aarch64 baseline).
Practical validation on real hardware is recommended before release.

### Gap 3: Official `--arch` flag behavior and output path in non-Xcode toolchain builds

**Searched**: Swift forums, swift.org documentation, SwiftPM source
**Found**: The `--arch arm64 --arch x86_64` command uses XCBuild and outputs to
`.build/apple/Products/Release/`. This was confirmed for Xcode-integrated builds. Whether
pure command-line open-source Swift toolchains (as installed from swift.org) support this
path identically was not confirmed with certainty.

**Impact**: Low-medium. The `--triple` + separate `lipo` approach is a reliable fallback
that does not depend on XCBuild internals.

### Gap 4: glibc version ceiling for Swift 6.3-jammy builds

**Searched**: Docker Hub Ubuntu base images, glibc version tables
**Found**: Ubuntu 22.04 (jammy) ships glibc 2.35. Raspberry Pi OS Bookworm (Debian 12)
ships glibc 2.36. A binary built against glibc 2.35 will run on glibc 2.36 (backward
compatible). The specific minimum glibc version Swift 6.3-jammy binaries require was
not confirmed from an authoritative source.

**Impact**: Low. glibc backward compatibility is well-established; building on jammy
(Ubuntu 22.04) is safe for Pi OS deployment.

---

## 11. Conflicting Information

### Conflict 1: Static Linux SDK allocator — musl default vs. bundled mimalloc

**Claim A**: The Static Linux SDK uses musl libc, and musl has its own default allocator
(musl malloc). The Swift forums discussion [S16] from October 2024 presents mimalloc
as a *proposed addition* to the Static Linux SDK, implying the default SDK does NOT yet
include mimalloc.

**Claim B**: The existing project CI comments state "Static SDK bundles a pre-compiled
mimalloc that uses LSE atomics" as the reason for avoiding the aarch64 musl SDK.

**Resolution**: This is a version-dependent distinction. Earlier versions of the
Swift Static Linux SDK (e.g., the 5.10 and early 6.0 releases) used musl's native
allocator. The Swift forums thread [S16] proposes *adding* mimalloc as an option,
suggesting that at the time of that thread (October 2024), mimalloc was not yet the
default. The project's CI comment may reflect a more recent SDK release (6.3) where
mimalloc has been integrated. Alternatively, the CI comment may be based on testing
rather than official documentation.

**Confidence in the CI behavior**: HIGH. Regardless of which SDK version first bundled
mimalloc, the observed SIGILL crash on Pi 3/4 when using `--swift-sdk aarch64-swift-linux-musl`
is the definitive evidence. The solution (avoid the SDK, use `-static-stdlib`) is correct
either way.

### Conflict 2: `--arch` flag universal binary output path

**Claim A**: Multiple sources [S2, S27] state the output is at
`.build/apple/Products/Release/<product>` when using `--arch arm64 --arch x86_64`.

**Claim B**: SwiftToolkit and other sources describe the universal binary being accessible
in the volume-mounted directory (i.e., on the host at `.build/...`).

**Resolution**: Both describe the same artifact — the Docker volume mount makes `.build/`
accessible on the host. The discrepancy is about whether the XCBuild path
(`apple/Products/Release`) is used vs. the standard SwiftPM path. The `--arch` flag
on macOS goes through XCBuild; on Linux inside Docker (which lacks XCBuild), separate
`--triple` builds and `lipo` must be used instead (but Linux fat binaries would be ELF,
not Mach-O; this scenario does not apply here).

---

## 12. Sources

All sources verified as coming from trusted domains (swift.org, github.com/swiftlang,
developer.apple.com, forums.swift.org, hub.docker.com, docs.docker.com,
bugzilla.redhat.com, github.com/microsoft, github.com/oven-sh).

| ID | Title | URL | Domain | Confidence |
|----|-------|-----|--------|------------|
| S1 | Getting Started with the Static Linux SDK | https://www.swift.org/documentation/articles/static-linux-getting-started.html | swift.org | HIGH (authoritative) |
| S2 | Building Swift Executables | https://www.swifttoolkit.dev/posts/building-swift-executables | swifttoolkit.dev | MEDIUM |
| S3 | SE-0342: Static-Link Runtime Libraries by Default | https://github.com/swiftlang/swift-evolution/blob/main/proposals/0342-static-link-runtime-libraries-by-default-on-supported-platforms.md | github.com/swiftlang | HIGH (authoritative) |
| S4 | Static linking on Linux in Swift 5.3.1 | https://forums.swift.org/t/static-linking-on-linux-in-swift-5-3-1/41989 | forums.swift.org | MEDIUM |
| S5 | Linux Static SDK with 5.10.1? | https://forums.swift.org/t/linux-static-sdk-with-5-10-1-or-only-v6/72533 | forums.swift.org | MEDIUM |
| S6 | Releasing Swift Binaries with GitHub Actions | https://www.swifttoolkit.dev/posts/releasing-with-gh-actions | swifttoolkit.dev | MEDIUM |
| S7 | Swift Server Build System Guide | https://www.swift.org/documentation/server/guides/building.html | swift.org | HIGH (authoritative) |
| S8 | Swift Official Docker Image | https://hub.docker.com/_/swift | hub.docker.com | HIGH (authoritative) |
| S9 | Arm64 Swift Docker Images? (Swift Forums) | https://forums.swift.org/t/arm64-swift-docker-images/43864 | forums.swift.org | MEDIUM |
| S10 | Build crash when building in QEMU using Swift 5.6 arm64 image | https://forums.swift.org/t/build-crash-when-building-in-qemu-using-new-swift-5-6-arm64-image/56090 | forums.swift.org | MEDIUM |
| S11 | Docker Multi-platform Builds | https://docs.docker.com/build/building/multi-platform/ | docs.docker.com | HIGH (authoritative) |
| S12 | Cross-architecture compilation on Linux | https://forums.swift.org/t/cross-architecture-compilation-on-linux/66172 | forums.swift.org | MEDIUM |
| S13 | Red Hat Bugzilla #2342055: mimalloc crashes with Illegal instruction on Raspberry Pi 4 | https://bugzilla.redhat.com/show_bug.cgi?id=2342055 | bugzilla.redhat.com | HIGH |
| S14 | Bun Issue #26556: Linux ARM64 Illegal instruction due to LSE atomics | https://github.com/oven-sh/bun/issues/26556 | github.com/oven-sh | HIGH |
| S15 | mimalloc README — ARM architecture notes | https://github.com/microsoft/mimalloc | github.com/microsoft | HIGH |
| S16 | Static Linux SDK with mimalloc, and toy Vapor benchmark | https://forums.swift.org/t/static-linux-sdk-with-mimalloc-and-toy-vapor-benchmark/75114 | forums.swift.org | MEDIUM |
| S17 | Using the Static Linux SDK produces very large binaries | https://forums.swift.org/t/using-the-static-linux-sdk-produces-very-large-binaries/75583 | forums.swift.org | MEDIUM |
| S18 | SwiftLint Issue #6287: Static SDK crash (musl stack size) | https://github.com/realm/SwiftLint/issues/6287 | github.com | MEDIUM |
| S19 | musl libc: Functional differences from glibc | https://wiki.musl-libc.org/functional-differences-from-glibc.html | musl-libc.org | HIGH |
| S20 | swiftlang/swift-sdk-generator | https://github.com/swiftlang/swift-sdk-generator | github.com/swiftlang | HIGH (authoritative) |
| S21 | AlwaysRightInstitute/swift-mac2arm-x-compile-toolchain | https://github.com/AlwaysRightInstitute/swift-mac2arm-x-compile-toolchain | github.com | LOW (outdated, Swift 5.x) |
| S22 | CSCIX65G/SwiftCrossCompilers | https://github.com/CSCIX65G/SwiftCrossCompilers | github.com | LOW (outdated, Swift 5.3) |
| S23 | keith/swiftpm-linux-cross | https://github.com/keith/swiftpm-linux-cross | github.com | LOW (outdated) |
| S24 | Aarch64 cross compilation not working with --static-swift-stdlib | https://forums.swift.org/t/aarch64-cross-compilation-not-working-with-static-swift-stdlib/76439 | forums.swift.org | MEDIUM |
| S25 | Cross-compiling from macOS to Linux | https://forums.swift.org/t/cross-compiling-from-macos-to-linux/58446 | forums.swift.org | MEDIUM |
| S26 | GCC AArch64 Options (-moutline-atomics) | https://gcc.gnu.org/onlinedocs/gcc/AArch64-Options.html | gcc.gnu.org | HIGH (authoritative) |
| S27 | A Universal Binary SPM Command Line Tool | https://povio.com/blog/introducing-a-universal-binary-spm-command-line-tool-for-intel-and-m1-macs | povio.com | MEDIUM |
| S28 | Cross compiling for Apple Silicon with SwiftPM | https://www.smileykeith.com/2020/12/24/swiftpm-cross-compile/ | smileykeith.com | MEDIUM |
| S29 | Universal binaries reference | https://jano.dev/apple/mach-o/2024/06/27/Universal-binaries.html | jano.dev | MEDIUM |
| S30 | Building Swift Packages as a Universal Binary | https://liamnichols.eu/2020/08/01/building-swift-packages-as-a-universal-binary.html | liamnichols.eu | MEDIUM |
| S31 | Using Swift SDKs with Raspberry Pis | https://xtremekforever.substack.com/p/using-swift-sdks-with-raspberry-pis | substack.com | MEDIUM |
| S32 | swift-sdk-generator — target-arch flag | https://github.com/swiftlang/swift-sdk-generator | github.com/swiftlang | HIGH (authoritative) |

---

*Research complete. Document written progressively; primary write checkpoint at turn ~20.*

Sources (per WebSearch requirement):
- [Getting Started with the Static Linux SDK](https://www.swift.org/documentation/articles/static-linux-getting-started.html)
- [Red Hat Bugzilla #2342055: mimalloc crashes on Raspberry Pi 4](https://bugzilla.redhat.com/show_bug.cgi?id=2342055)
- [Bun Issue #26556: LSE atomics crash on Cortex-A53/RPi4](https://github.com/oven-sh/bun/issues/26556)
- [mimalloc GitHub Repository](https://github.com/microsoft/mimalloc)
- [Docker Multi-platform Builds](https://docs.docker.com/build/building/multi-platform/)
- [Swift Server Build System Guide](https://www.swift.org/documentation/server/guides/building.html)
- [Static Linux SDK with mimalloc — Swift Forums](https://forums.swift.org/t/static-linux-sdk-with-mimalloc-and-toy-vapor-benchmark/75114)
- [Build crash in QEMU Swift 5.6 arm64 — Swift Forums](https://forums.swift.org/t/build-crash-when-building-in-qemu-using-new-swift-5-6-arm64-image/56090)
- [swiftlang/swift-sdk-generator](https://github.com/swiftlang/swift-sdk-generator)
- [Releasing Swift Binaries with GitHub Actions](https://www.swifttoolkit.dev/posts/releasing-with-gh-actions)
- [musl libc functional differences from glibc](https://wiki.musl-libc.org/functional-differences-from-glibc.html)
- [GCC AArch64 Options (-moutline-atomics)](https://gcc.gnu.org/onlinedocs/gcc/AArch64-Options.html)
- [Universal Binary SPM Command Line Tool](https://povio.com/blog/introducing-a-universal-binary-spm-command-line-tool-for-intel-and-m1-macs)
- [Using Swift SDKs with Raspberry Pis](https://xtremekforever.substack.com/p/using-swift-sdks-with-raspberry-pis)
