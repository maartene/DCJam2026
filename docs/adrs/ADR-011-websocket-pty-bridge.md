# ADR-011: WebSocket + node-pty as Browser Bridge Mechanism

**Date**: 2026-04-04  
**Status**: Accepted  
**Author**: Morgan (Solution Architect — DESIGN wave)  
**Deciders**: Maarten Engels (developer)

---

## Context

To allow DCJam 2026 judges to play Ember's Escape without installing anything, the game must be accessible via a browser. Three technical approaches were researched:

- **Path A**: Compile the entire Swift package to WASM and run in browser (no server)
- **Path B**: Compile `GameDomain` to WASM; write JS app layer
- **Path C**: Run Swift game natively on a server; bridge to browser via WebSocket + terminal emulator

The DISCUSS wave confirmed Path C (WebSocket bridge) as the implementation approach. This ADR records the specific mechanism within Path C: why `node-pty` is required over a plain `child_process.spawn()`.

---

## Decision

**Use Node.js with `ws` (WebSocket server) and `node-pty` (PTY-based process spawning).**

One game process is spawned per WebSocket connection. Bytes flow bidirectionally between the WebSocket and the PTY without modification. The browser client uses xterm.js to render ANSI output.

---

## Rationale: Why `node-pty` Over Plain `child_process.spawn()`

`InputHandler.swift` contains:

```swift
fd = open("/dev/tty", O_RDONLY | O_NONBLOCK)
```

`ANSITerminal.swift` contains:

```swift
tcgetattr(STDIN_FILENO, &savedTermios)
tcsetattr(STDIN_FILENO, TCSAFLUSH, &raw)
```

Both of these require a **controlling terminal** — a real or pseudo tty device. When a process is spawned with `child_process.spawn()` using stdio pipes:
- The child process has no controlling terminal
- `open("/dev/tty", ...)` returns `-1` (ENXIO)
- `tcsetattr()` fails on a non-tty fd

`node-pty` creates a PTY pair (master/slave). The spawned process's stdin/stdout are connected to the PTY slave, which is a real tty device. `/dev/tty` resolves to the PTY slave for that process. `tcsetattr` works correctly.

This is a hard technical constraint, not a preference.

---

## Alternatives Considered

### Plain `child_process.spawn()` with stdio pipes
**Rejected**: InputHandler.swift opens `/dev/tty` — not stdin. Without a PTY, the game cannot receive input. The Swift source must not be modified (AC-8).

### Modify `InputHandler.swift` to read from stdin instead of `/dev/tty`
**Rejected**: AC-8 explicitly requires zero modifications to `Sources/App/`. The bridge must adapt to the existing game, not the other way around.

### SwiftNIO telnet server (all-Swift approach)
**Considered**: Documented in `docs/research/telnet/swiftnio-telnet-feasibility.md`. Estimated 2–3 days; requires modifying the App layer to replace the blocking game loop with `scheduleRepeatedTask` and add a `TelnetOutputPort`. Valid post-jam option, but:
- Requires modifying existing Swift files
- Adds SwiftNIO as a Swift package dependency
- Higher implementation risk for jam timescale
**Deferred to post-jam.**

### True WASM compilation (Path A)
**Rejected**: Three hard blockers in current App layer (`/dev/tty`, `tcsetattr`, `usleep` game loop). Estimated 3–5 days. Documented in `docs/research/wasm/swift-wasm-browser-feasibility.md`. Out of scope for DCJam 2026.

---

## Consequences

### Positive
- Zero modifications to any Swift source file
- xterm.js renders the exact same ANSI output judges would see in a native terminal
- `node-pty` is a mature npm package (used by VS Code's terminal, Hyper, etc.)
- Per-connection process isolation is guaranteed by OS process boundaries
- Node.js runs on ARM Linux (Raspberry Pi) without compilation

### Negative
- `node-pty` has native Node.js addon bindings (compiled via `node-gyp`). Docker build requires build tools (`python3`, `make`, `g++`) in the build stage
- Node.js process must be kept alive during the entire judging window
- If the Node.js server crashes, all active sessions are dropped (acceptable for jam)

### Neutral
- The bridge adds ~80 lines of new JavaScript. No new Swift code required.
