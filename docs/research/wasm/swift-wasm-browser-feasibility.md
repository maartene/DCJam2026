# Swift WASM Browser Feasibility for DCJam2026

**Research question**: Is a WASM-based build that runs in a web browser a viable option for a Swift TUI game?

**Date**: 2026-04-03
**Status**: COMPLETE
**Depth**: Detailed
**Context**: DCJam2026 — Swift 6.x dungeon crawler, ANSI TUI, pure SPM, no external dependencies

---

## Table of Contents

1. [Executive Summary](#executive-summary)
2. [Swift WASM Support and Maturity](#swift-wasm-support-and-maturity)
3. [Browser Execution Model](#browser-execution-model)
4. [TUI in Browser: ANSI Rendering Options](#tui-in-browser-ansi-rendering-options)
5. [Non-blocking Input in WASM/Browser](#non-blocking-input-in-wasmbrowser)
6. [Practical Implementation Path](#practical-implementation-path)
7. [Known Limitations and Blockers — Project-Specific Analysis](#known-limitations-and-blockers--project-specific-analysis)
8. [Alternative Approaches](#alternative-approaches)
9. [Recommendation](#recommendation)
10. [Knowledge Gaps](#knowledge-gaps)
11. [Sources](#sources)

---

## Executive Summary

Swift WASM has matured significantly. As of Swift 6.1/6.2, WASM is an officially supported compilation target in the mainline Swift toolchain — no custom forks required. Compiling `GameDomain` (pure domain logic) to WASM is straightforwardly feasible.

**However, the `App` layer (TUI, input, game loop) is not WASM-compatible as written.** Three hard blockers exist in the current codebase:

1. **`/dev/tty` does not exist in WASI** — `InputHandler.swift` opens `/dev/tty` via POSIX `open()`. This syscall will fail silently or abort in a WASI sandbox.
2. **`tcsetattr`/`tcgetattr` are not available in WASI** — `ANSITerminal.swift` calls `tcsetattr` for raw mode. WASI has no `termios.h` implementation. The issue tracking this in the WASI spec was filed in 2019 and remains open with no standardized resolution.
3. **`usleep` blocking loop is incompatible with the browser's single-threaded JavaScript event model** — `GameLoop.swift` uses a tight `while true` loop with `usleep`. WASM cannot block the browser's main thread; doing so freezes the entire page.

**Verdict**: Compiling the existing `App` layer to WASM and running it in a browser is **not feasible without significant rework** of the input, terminal, and game loop layers. The architectural gap is substantial.

**Best alternative for a game jam**: A **server-side WebSocket bridge** using the existing Swift executable (running natively on Linux) as the game process, with xterm.js in the browser as the terminal front-end. This requires zero changes to `GameDomain` and minimal changes to `App`, preserves all ANSI rendering, and can be deployed as a containerized service. Estimated effort: 1–2 days.

---

## Swift WASM Support and Maturity

### Official Support Status

**Confidence: High** (3 independent authoritative sources)

Swift's WebAssembly support has transitioned from a community fork to a first-class compilation target in the official toolchain:

- **Swift 6.1** is the first official Swift release to support WebAssembly (WASM) as a compilation target without requiring a custom `swiftwasm` fork. All components — compiler, stdlib, Foundation, XCTest, swift-testing — have been fully upstreamed to `swiftlang/swift`. [swift.org WASM getting started, SwiftWasm 6.1 blog]
- **Swift 6.2** further formalised WASM support, announced at WWDC. The Swift SDK for WASM is now distributed on swift.org for Linux and macOS hosts. [swift.org, Swift Forums Q3 2025 updates]
- **Swift 6.3** is referenced in the official swift.org getting-started guide as the demonstrated version for WASM builds. The guide shows `swift build --swift-sdk swift-6.3-RELEASE_wasm` as the build command. [swift.org getting started guide]

The SwiftWasm project has shifted from distributing its own compiler toolchain forks to distributing **Swift SDKs** only, letting users pair them with official Swift toolchains from swift.org. This is a significant maturity milestone. [SwiftWasm 6.1 release blog]

### Build Toolchain

The standard build command for a pure Swift package is:

```
swift build --swift-sdk swift-6.3-RELEASE_wasm
```

The output is a `.wasm` binary targeting `wasm32-unknown-wasi`. Running locally is supported via `WasmKit`, a Swift-written WASM runtime bundled with compatible toolchains. [swift.org getting started]

### WASM Target Triple

Two target triples are supported:
- `wasm32-unknown-wasi` — for WASI-compatible runtimes (server, CLI, browser with polyfill)
- `wasm32-unknown-unknown` — bare metal WASM, no system interface

DCJam2026 would target `wasm32-unknown-wasi`.

---

## Browser Execution Model

### Running WASM in a Browser

**Confidence: High** (3 sources)

All modern browsers (Chrome 91+, Firefox 88+, Safari 15+) support the WebAssembly JavaScript API natively. A WASM binary can be loaded, instantiated, and executed via `WebAssembly.instantiateStreaming()`. [MDN WebAssembly docs]

WASM binaries targeting WASI require a **WASI polyfill** in the browser — a JavaScript layer that maps WASI system calls (file I/O, environment variables, clocks) to browser APIs. Several production-ready polyfills exist:

- **@wasmer/wasi** — Wasmer's JavaScript WASI implementation [wasmer.io]
- **wasm-webterm** — xterm.js addon that bundles a WASI polyfill for running WASI binaries in a browser terminal [github.com/cryptool-org/wasm-webterm]
- Browser-native WASI support is also being standardised as WASI Preview 2 / Component Model [WebAssembly.org]

### Key Browser Constraints

WASM in a browser runs in the **main thread** (or a Web Worker) but is bound by JavaScript's event loop model:

- WASM cannot call `sleep()` / `usleep()` and block the main thread without freezing the browser tab.
- WASM cannot make synchronous system calls that block (e.g., blocking `read()` for stdin) unless using `SharedArrayBuffer` + `Atomics` (requires cross-origin isolation headers: `Cross-Origin-Opener-Policy: same-origin` and `Cross-Origin-Embedder-Policy: require-corp`). [MDN SharedArrayBuffer docs]
- `SharedArrayBuffer` enables a pattern where a Web Worker running WASM is paused by an `Atomics.wait()` call while the main thread fills an input buffer, then signals the worker. This is how `wasm-webterm` implements blocking stdin. [github.com/cryptool-org/wasm-webterm]

---

## TUI in Browser: ANSI Rendering Options

### xterm.js — The Standard Solution

**Confidence: High** (3 sources)

[xterm.js](https://xtermjs.org/) is the de-facto standard JavaScript library for browser-based terminal emulation. It supports:
- Full ANSI/VT100 escape code rendering (cursor movement, colors, 256-color, true color)
- Custom key event handlers
- Attachment addons for WebSocket or other I/O streams via `@xterm/addon-attach`

DCJam2026's ANSI rendering (cursor positioning, 256-color, screen clearing) is fully within xterm.js's capability. The existing `ANSITerminal.swift` outputs standard VT100/ANSI sequences that xterm.js renders natively.

### Connecting WASM stdout to xterm.js

**wasm-webterm** ([github.com/cryptool-org/wasm-webterm](https://github.com/cryptool-org/wasm-webterm)) is an xterm.js addon specifically designed to run WASI binaries in the browser. It:
- Loads a WASI polyfill
- Maps stdout/stderr writes from the WASM binary to the xterm.js display
- Handles stdin via `SharedArrayBuffer + Atomics` (blocking-safe) or `window.prompt()` fallback
- Supports both WASI and Emscripten binaries

This is the technically closest existing tooling to the DCJam2026 use case. However, it was designed for CLI-style programs, not interactive TUI games with a tight game loop.

### ANSI Rendering Without Terminal Emulator

An alternative is to render game output directly to an HTML `<canvas>` element, parsing ANSI codes in JavaScript. This is used by projects like [antirez's kilo editor ported to WASM](https://github.com/antirez/kilo). However, this requires building or integrating a custom ANSI-to-canvas renderer, which is non-trivial and outside scope for a game jam.

---

## Non-blocking Input in WASM/Browser

### The Core Problem

**Confidence: High** (4 sources)

This is the most fundamental constraint for DCJam2026's architecture.

The game loop in `GameLoop.swift` uses:
1. `inputHandler.poll()` — opens `/dev/tty` with `O_NONBLOCK` and calls `read()`
2. `usleep()` to cap the loop at 30 Hz

**Neither pattern translates to WASM/browser:**

**`/dev/tty` does not exist in WASI.** WASI's filesystem namespace is a virtual sandbox. There is no `/dev/tty` device node. The `open("/dev/tty", O_RDONLY | O_NONBLOCK)` call in `InputHandler.swift` will return `-1` (ENOENT or ENOSYS) in a WASI environment. [WASI spec, WebAssembly/WASI GitHub issues]

**`usleep()` blocks the browser's main thread.** Browsers do not permit synchronous spin-waiting on the main thread. A `while true { usleep(...) }` loop will freeze the browser tab. The WASM spec has no mechanism for yielding to the JavaScript event loop from within a tight loop. [Rust WASM book, dealing-with-blocking-input in WASM Rust forum]

**What the browser provides instead:** Keyboard events are asynchronous JavaScript events (`keydown`/`keypress`). The correct browser game loop pattern uses `requestAnimationFrame` callbacks. These require restructuring the game loop from a synchronous blocking loop to an event-driven or cooperative coroutine model. [MDN requestAnimationFrame, Rust WASM game loop examples]

### Non-blocking stdin in WASM: The SharedArrayBuffer Pattern

For WASI programs that call blocking `read()` on stdin, `wasm-webterm` implements a workaround: the WASM binary runs in a **Web Worker** thread. When it calls `read(stdin)`, the polyfill executes `Atomics.wait()`, suspending the worker. The main thread handles the `keydown` event, writes the byte to a SharedArrayBuffer, then wakes the worker with `Atomics.notify()`. This makes stdin appear synchronous to the WASM program.

**This approach requires:**
- The WASM binary runs in a Web Worker (not the main thread)
- The host server sets `Cross-Origin-Opener-Policy: same-origin` and `Cross-Origin-Embedder-Policy: require-corp` headers (required for `SharedArrayBuffer` availability)
- The blocking game loop (`usleep`) must still be replaced with a cooperative yield to allow the Worker's event loop to process messages

**The `usleep` problem remains:** Even with stdin solved via SharedArrayBuffer, `GameLoop.swift`'s `while true { usleep(33ms) }` will busy-block the Web Worker thread, preventing it from processing the `Atomics.notify()` wake signal. The game loop must be restructured.

---

## Practical Implementation Path

### Path A: Full WASM Port (High Effort)

Compile the entire Swift package to WASM and run it in xterm.js via wasm-webterm.

**Required changes:**

1. **`InputHandler.swift`**: Remove `/dev/tty` dependency. Replace with WASI-compatible stdin polling via `WASILibc.read(STDIN_FILENO, ...)`. The input bytes would arrive via the browser's xterm.js → SharedArrayBuffer → stdin pipe.

2. **`ANSITerminal.swift`**: Remove `tcsetattr`/`tcgetattr` calls (raw mode configuration). In a browser xterm.js context, raw mode is configured on the JavaScript side — the Swift program never needs to call `tcsetattr`. The ANSI escape sequence output remains unchanged.

3. **`PlatformCompat.swift`**: Add `#elseif canImport(WASILibc)` guards for all `#if canImport(Darwin) / #elseif canImport(Glibc)` branches. The WASM target uses `WASILibc`.

4. **`GameLoop.swift`**: Replace `while true { usleep(...) }` with a cooperative game loop. In WASM/WASI compiled for browser, the standard solution is to export a `tick()` function from WASM and call it from JavaScript's `requestAnimationFrame`. This requires restructuring the game loop from a blocking model to a step-function model.

5. **Build configuration**: Add a `Package.swift` conditional for the WASM target, excluding Darwin/Glibc-specific imports.

6. **JavaScript glue**: Write a small HTML/JS page that loads the WASM binary, sets up xterm.js, wires keyboard events to stdin, and calls `tick()` each animation frame.

**Estimated effort**: 3–5 days of focused Swift/WASM/JS work. Requires familiarity with WASM/WASI toolchain, JavaScript interop, and SharedArrayBuffer security headers.

**Risk**: `usleep` + blocking game loop restructuring is non-trivial. The step-function refactor changes the fundamental architecture of `GameLoop.swift`.

### Path B: GameDomain to WASM, Port App Layer to JavaScript (Medium Effort)

Compile only `GameDomain` (pure logic, zero I/O, zero POSIX dependencies) to WASM. Write a new JavaScript/TypeScript `App` layer that calls into WASM for game state transitions while handling rendering and input natively in the browser.

**Required changes:**

1. Export Swift functions from `GameDomain` using `@_expose(wasm)` or JavaScript interop attributes
2. Write a JS/TS app layer that:
   - Creates `GameState` and calls `RulesEngine.apply()` via WASM exports
   - Renders to xterm.js using the same ANSI sequences as the existing `Renderer.swift`
   - Handles `keydown` events natively
   - Runs its own `requestAnimationFrame` game loop

**Estimated effort**: 2–4 days. The JS app layer is essentially a port of `Renderer.swift` and `GameLoop.swift` to TypeScript. `GameDomain` compiles to WASM without modification (it has no POSIX dependencies).

**Risk**: Swift ↔ JavaScript interop for complex types (`GameState`, `RulesEngine`) requires careful FFI design. `GameState` is a value type — passing it across the WASM boundary requires serialization or shared memory.

### Path C: Server-Side WebSocket Bridge (Low Effort — Recommended)

Run the existing Swift executable natively on a Linux server. The browser connects via WebSocket. A thin JavaScript page with xterm.js renders the terminal output received over the WebSocket and sends keystrokes back.

**Required changes to DCJam2026**: None to game logic. The `App` layer may optionally be wrapped in a thin server adapter, but the game process can also be spawned as a child process with its stdio piped through the WebSocket.

**Architecture:**

```
Browser (xterm.js)
    ↕  WebSocket (raw bytes)
Server (Node.js or Swift HTTP server)
    ↕  PTY / stdio pipe
DCJam2026 Swift executable (unchanged)
```

The server component is a standard "browser terminal" pattern with many existing reference implementations:
- `webssh2` pattern (Node.js: spawn process, pipe to WebSocket, attach xterm.js)
- `pyxtermjs` pattern (Python: Flask + pty)
- Swift-native: Vapor 4 or Hummingbird 2 with WebSocket support, spawning the game process via `Foundation.Process`

**Estimated effort**: 1–2 days. A Node.js proof-of-concept using `node-pty` + `ws` + xterm.js is well-documented and can be wired up in hours. A Swift-native server using Vapor/Hummingbird + Foundation.Process adds 0.5–1 day.

**Deployment**: Docker container with the Swift executable + Node.js WebSocket server. Matches the project's existing Docker/Podman build infrastructure documented in project memory.

---

## Known Limitations and Blockers — Project-Specific Analysis

This section analyzes each file in the `App` target against WASM/WASI constraints.

### `InputHandler.swift` — HARD BLOCKER

```swift
fd = open("/dev/tty", O_RDONLY | O_NONBLOCK)
```

- `/dev/tty` does not exist in WASI's virtual filesystem sandbox
- `O_NONBLOCK` flag on WASI stdin is implementation-defined and may not work
- **Resolution**: Replace with `WASILibc.read(STDIN_FILENO, ...)` and rely on the browser's SharedArrayBuffer stdin bridge to provide input bytes

### `ANSITerminal.swift` — HARD BLOCKER

```swift
func enableRawMode() {
    guard tcgetattr(STDIN_FILENO, &savedTermios) == 0 else { return }
    tcsetattr(STDIN_FILENO, TCSAFLUSH, &raw)
```

- `tcgetattr` and `tcsetattr` are **not available in WASI**. The `termios.h` functionality was requested in WASI Issue #161 (filed 2019, still unresolved as of 2025).
- In a browser context, "raw mode" is configured on the JavaScript/xterm.js side. The Swift program does not need to configure terminal mode.
- **Resolution**: Guard the `enableRawMode`/`restoreTerminal` calls with `#if !os(WASI)` — they become no-ops for the WASM target.

### `GameLoop.swift` — HARD BLOCKER

```swift
while true {
    // ...
    usleep(UInt32((targetFrameNs - elapsed) / 1000))
}
```

- `usleep` is available in WASI (it maps to `__wasi_sched_yield` or a time-based wait), but a blocking `while true` loop prevents the browser's JavaScript event loop from processing messages, including stdin bytes from the SharedArrayBuffer bridge.
- **Resolution**: Export a `gameTick()` function from Swift and drive it from JavaScript's `requestAnimationFrame`. This requires converting the game loop from imperative/blocking to cooperative/step-function architecture.

### `PlatformCompat.swift` — MODERATE EFFORT

```swift
#if canImport(Darwin)
    import Darwin
#elseif canImport(Glibc)
    import Glibc
#elseif canImport(Musl)
    import Musl
```

- WASM/WASI uses `WASILibc`, not Darwin, Glibc, or Musl.
- All platform-conditional code needs a `#elseif canImport(WASILibc)` branch.
- `clock_gettime(CLOCK_MONOTONIC, ...)` is available in WASI, so `monoTimeNanoseconds()` is portable.
- `termios`-related code must be excluded for WASM.

### `GameDomain` Target — NO BLOCKERS

The `GameDomain` target (pure value-type domain logic: `GameState`, `RulesEngine`, `FloorMap`, etc.) has **no POSIX dependencies, no I/O, no threading**. It compiles to WASM without modification.

### Standard Library Features Used

| Feature | WASM/WASI Status |
|---|---|
| Swift stdlib (Array, String, Int, etc.) | Fully available |
| Foundation (basic types) | Available with limitations |
| Dispatch / DispatchQueue | NOT AVAILABLE in WASM |
| POSIX I/O (read, write, open) | Limited — WASI-mapped only |
| termios.h | NOT AVAILABLE |
| /dev/tty | NOT AVAILABLE |
| usleep | Available but blocks worker thread |
| clock_gettime | Available via WASI |

DCJam2026 does not use Foundation or Dispatch in the domain layer, which is advantageous.

---

## Alternative Approaches

### Alternative 1: Server-Side WebSocket Bridge (Recommended for Game Jam)

**Architecture**: Native Swift executable (unchanged) on a Linux server, xterm.js in browser, WebSocket bridge in between.

**Pros**:
- Zero changes to game logic or rendering
- All ANSI features work exactly as in native terminal
- Proven pattern (pyxtermjs, webssh2, wasm-webterm all use variants of this)
- Reuses existing Docker/Linux build infrastructure
- Judges play in browser with no install required

**Cons**:
- Requires a server to be running (not self-contained in browser)
- Network latency affects responsiveness (acceptable for a turn-based/30Hz game)
- Requires hosting/deployment infrastructure

**Effort**: 1–2 days including deployment.

### Alternative 2: Full WASM Port

**Architecture**: Compile entire Swift package to WASM, run in browser via wasm-webterm + xterm.js.

**Pros**:
- Self-contained — runs entirely in browser, no server required
- Demonstrates Swift WASM capability

**Cons**:
- 3 hard blockers in current codebase (see above)
- Requires game loop architectural refactor
- `termios` removal is straightforward but `usleep` loop restructure is significant
- No existing reference implementation for Swift TUI + WASM game found
- Toolchain complexity (WASM SDK, cross-origin headers, SharedArrayBuffer setup)

**Effort**: 3–5 days. Not recommended for game jam timescale.

### Alternative 3: Hybrid — GameDomain to WASM, JS App Layer

**Architecture**: `GameDomain` compiled to WASM as a library, new TypeScript app layer handles rendering and input in browser.

**Pros**:
- `GameDomain` is already clean/portable — compiles with zero changes
- JavaScript game loop and input are straightforward
- Avoids all WASI I/O issues

**Cons**:
- Requires writing a parallel rendering/input layer in TypeScript
- Swift ↔ JS type marshalling for `GameState` is non-trivial
- Partial rewrite of the `App` layer

**Effort**: 2–4 days. More effort than the WebSocket bridge with similar risk.

### Alternative 4: Recompile for WASM with Emscripten (via C interop)

Swift does not have native Emscripten support. This path is not viable.

---

## Recommendation

**Verdict: WASM port is feasible-with-effort (3–5 days) but not recommended for a game jam.**

### For DCJam2026 Specifically

**Recommended approach: Alternative 1 (Server-Side WebSocket Bridge)**

Rationale:
1. **Zero game-logic changes** — `GameDomain` and `RulesEngine` remain untouched.
2. **Perfect fidelity** — judges see the exact same ANSI rendering as a native terminal.
3. **Lowest effort** — the xterm.js + WebSocket + PTY pattern is well-documented with multiple reference implementations.
4. **Works with existing infrastructure** — the project already uses Docker/Linux builds. Adding a Node.js WebSocket proxy layer to the Docker image is a small addition.
5. **No toolchain risk** — no WASM SDK setup, no cross-origin header configuration, no JavaScript interop debugging.

**If browser-only (no server) is a hard requirement:**
Go with Alternative 3 (GameDomain to WASM + JS App Layer). Compile `GameDomain` to WASM, write a TypeScript shim for the `App` layer. The GameDomain target requires zero modifications and compiles to WASM cleanly. The TypeScript rendering layer is a straightforward port of `Renderer.swift`.

**If full WASM (entire Swift package in browser) is desired post-jam:**
Path A is viable but requires dedicated WASM engineering time. The three hard blockers are all solvable — they require `#if os(WASI)` guards around termios calls, replacing `/dev/tty` with WASI stdin, and restructuring the game loop to a step-function driven by JavaScript's `requestAnimationFrame`. Estimated 3–5 days from an engineer familiar with both Swift and WASM/JS interop.

### Summary Table

| Approach | Effort | Game-logic changes | Server required | WASM in browser | Risk |
|---|---|---|---|---|---|
| WebSocket bridge | 1–2 days | None | Yes | No | Low |
| Full WASM port | 3–5 days | Significant App layer refactor | No | Yes | High |
| GameDomain to WASM + JS App | 2–4 days | None to GameDomain; new JS layer | No | Yes | Medium |
| Keep native only | 0 days | None | No | No | None |

---

## Knowledge Gaps

1. **Swift `@_expose(wasm)` / JavaScript interop API**: The exact mechanism for exporting Swift functions to JavaScript in SwiftWasm (the FFI API) was not verified in detail. The official docs reference `JavaScriptKit` for DOM access, but the raw export syntax for non-DOM WASM FFI is underspecified in sources found. *Searched: "SwiftWasm JavaScript interop export function FFI" — sources found describe JavaScriptKit for DOM, not raw WASM exports.*

2. **wasm-webterm compatibility with Swift WASM output**: The project (`cryptool-org/wasm-webterm`) was verified to support WASI binaries but no Swift-specific test or example was found. Compatibility with Swift's WASI output format (particularly its memory layout and startup behavior) was not confirmed. *Searched: "wasm-webterm Swift WASM" — no results found.*

3. **`usleep` behavior in WASI Web Worker context**: Whether `usleep` in a WASI Web Worker blocks the worker's internal event loop (preventing `Atomics.notify()` processing) vs. yielding properly was not definitively confirmed from authoritative sources. The evidence strongly suggests it blocks but was inferred from general WASM threading docs, not a Swift-specific test.

4. **`requestAnimationFrame` game loop with Swift WASM**: No existing example of a Swift TUI or game using `requestAnimationFrame`-driven tick exports was found. Rust WASM examples exist (e.g., `wasm-bindgen` guide) but the Swift equivalent was not located. *Searched: "SwiftWasm requestAnimationFrame game loop tick export" — no direct results.*

5. **WASM binary size for DCJam2026**: Estimated binary size for the full Swift package compiled to WASM was not found. Swift WASM binaries can be large (tens of MB) without tree-shaking. Embedded Swift can produce much smaller binaries but has significant stdlib restrictions. *Not researched due to turn budget.*

---

## Sources

### Authoritative (swift.org, github.com/webassembly, xtermjs.org)

1. **Swift.org — Getting Started with Swift SDKs for WebAssembly**
   [https://www.swift.org/documentation/articles/wasm-getting-started.html](https://www.swift.org/documentation/articles/wasm-getting-started.html)
   *Swift 6.3 build commands, toolchain setup, official documentation.*

2. **SwiftWasm 6.1 Release Blog**
   [https://blog.swiftwasm.org/posts/6-1-released/](https://blog.swiftwasm.org/posts/6-1-released/)
   *First no-custom-patches release, SDK-only distribution model, maturity milestone.*

3. **Swift and WebAssembly Book — Porting Guide**
   [https://book.swiftwasm.org/getting-started/porting.html](https://book.swiftwasm.org/getting-started/porting.html)
   *Foundation limitations, Dispatch unavailability, 32-bit constraints, WASILibc.*

4. **WASI Issue #161 — missing termios.h functionality**
   [https://github.com/WebAssembly/WASI/issues/161](https://github.com/WebAssembly/WASI/issues/161)
   *Confirms tcsetattr/tcgetattr not available in WASI; open since 2019.*

5. **wasm-webterm (cryptool-org)**
   [https://github.com/cryptool-org/wasm-webterm](https://github.com/cryptool-org/wasm-webterm)
   *xterm.js addon for WASI binaries; SharedArrayBuffer stdin bridge; limitations documented.*

6. **xterm.js**
   [https://xtermjs.org/](https://xtermjs.org/)
   *ANSI/VT100 support, WebSocket attach addon, browser terminal standard.*

7. **Swift Forums — Swift for Wasm Q3 2025 Updates**
   [https://forums.swift.org/t/swift-for-wasm-q3-2025-updates/81956](https://forums.swift.org/t/swift-for-wasm-q3-2025-updates/81956)
   *Ongoing upstream development, Swift 6.2 WASM features.*

### High Trust (github.com, infoq.com)

8. **swiftwasm/awesome-swiftwasm**
   [https://github.com/swiftwasm/awesome-swiftwasm](https://github.com/swiftwasm/awesome-swiftwasm)
   *No CLI/TUI game examples found; confirms gap in existing Swift WASM TUI examples.*

9. **Hummingbird WebSocket Tutorial (swiftonserver.com)**
   [https://swiftonserver.com/websockets-tutorial-using-swift-and-hummingbird/](https://swiftonserver.com/websockets-tutorial-using-swift-and-hummingbird/)
   *Swift-native WebSocket server option for the bridge approach.*

10. **Dealing with blocking input in WASM (Rust Forum)**
    [https://users.rust-lang.org/t/dealing-with-blocking-input-in-wasm/42695](https://users.rust-lang.org/t/dealing-with-blocking-input-in-wasm/42695)
    *Confirms WASM cannot block JS thread; cooperative scheduling requirement.*

### Medium Trust (medium.com, dev.to, fatbobman.com)

11. **SwiftWasm in 2025: From Niche to First-Class (Medium)**
    [https://medium.com/wasm-radar/swiftwasm-in-2025-from-niche-to-first-class-75a30bbba41e](https://medium.com/wasm-radar/swiftwasm-in-2025-from-niche-to-first-class-75a30bbba41e)
    *Overview of Swift 6.1 WASM milestone; corroborates official sources.*

12. **Building WASM Applications with Swift (fatbobman.com)**
    [https://fatbobman.com/en/posts/building-wasm-applications-with-swift/](https://fatbobman.com/en/posts/building-wasm-applications-with-swift/)
    *Practical build guide; Foundation/Dispatch limitations; corroborates official sources.*
