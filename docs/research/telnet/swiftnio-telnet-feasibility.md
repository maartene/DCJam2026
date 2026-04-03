# SwiftNIO Telnet Feasibility Research
## Wrapping a Swift TUI Game (DCJam2026 / Ember's Escape) in a Telnet / SSH Server

**Date**: 2026-04-03
**Research depth**: Detailed
**Context**: DCJam2026 — Ember's Escape. Swift 6.3, pure SPM, synchronous 30 Hz game loop, ANSI TUI.

---

## Executive Summary

Wrapping the existing TUI game in a SwiftNIO-based **telnet** server is **feasible with moderate effort** — roughly 2–4 focused days of work for a single developer familiar with SwiftNIO basics. The game's existing `TUIOutputPort` abstraction boundary makes the I/O substitution cleaner than it would otherwise be. The main work items are: (1) a custom ~100-line `TelnetNegotiationHandler` ChannelHandler, (2) converting the blocking `GameLoop` to use `EventLoop.scheduleRepeatedTask`, and (3) wrapping ANSI output to write into NIO `ByteBuffer` instead of stdout.

An **SSH** approach via `swift-nio-ssh` gives better security and richer terminal negotiation, but adds ~1–2 days of extra complexity (key management, authentication delegate, channel multiplexing) — probably not worth it for a jam submission. Telnet is the pragmatic jam choice.

**Verdict**: Telnet via SwiftNIO — **Feasible with effort**. SSH — **Feasible, but over-engineered for a game jam**.

---

## 1. Telnet Protocol Basics for a TUI Game

### 1.1 What telnet must negotiate for raw character mode

Telnet defaults to **line-buffered mode** where the client sends a whole line on Enter. A TUI game needs **character-at-a-time** mode with the server handling echo. The negotiation sequence is:

**Server sends on connection:**
```
IAC WILL ECHO          FF FB 01   — server will echo characters
IAC WILL SGA           FF FB 03   — suppress go-ahead (disables half-duplex)
IAC DO NAWS            FF FD 1F   — request client to send window size
```

**Expected client responses (if client supports these options):**
```
IAC DO ECHO            FF FD 01   — client accepts server echo
IAC DO SGA             FF FD 03   — client accepts SGA
IAC WILL NAWS          FF FB 1F   — client will report window size
IAC SB NAWS <W_hi> <W_lo> <H_hi> <H_lo> IAC SE   — actual dimensions
```

The combined ECHO + SGA negotiation is the standard MUD/game server pattern. RFC 854 defines the base protocol; RFC 858 defines SGA; RFC 857 defines ECHO; RFC 1073 defines NAWS.

**Key detail**: The server must also handle any unexpected `WILL`/`DO` from the client by responding `DONT`/`WONT` respectively. Modern clients (`telnet(1)`, PuTTY) actively negotiate options on connection — a server that silently ignores these will behave unpredictably.

**Confidence**: High. Sources: [RFC 854](https://www.rfc-editor.org/rfc/rfc854.html), [RFC 1073](https://www.rfc-editor.org/rfc/rfc1073), [Last Outpost MUD ECHO/SGA guide](https://www.last-outpost.com/LO/protocols/echosga.html), [codegenes.net character-mode guide](https://www.codegenes.net/blog/force-telnet-client-into-character-mode/).

### 1.2 NAWS — window size subnegotiation

The NAWS subnegotiation payload (RFC 1073) is 4 bytes packed as two big-endian 16-bit values:
```
IAC SB NAWS  <cols_hi> <cols_lo>  <rows_hi> <rows_lo>  IAC SE
 FF  FA  1F     00        50          00       18         FF F0
```
For an 80×24 terminal: `0x00 0x50 0x00 0x18`. The server parses this to know the client's terminal dimensions.

DCJam2026 currently targets a fixed **80×25** layout. If the client reports a smaller terminal, the server can warn the player rather than crashing. If the client is larger, the game continues normally. NAWS makes it straightforward to detect mismatches gracefully.

**Confidence**: High. Source: [RFC 1073](https://datatracker.ietf.org/doc/html/rfc1073).

### 1.3 How much must be hand-rolled?

No telnet handler exists in `apple/swift-nio` or `apple/swift-nio-extras`. The `swift-nio-extras` package provides frame decoders, HTTP codecs, and utility handlers — but no telnet negotiation support. Telnet negotiation **must be hand-rolled** as a custom `ChannelInboundHandler`.

A minimal implementation is roughly 80–120 lines of Swift:
- A state machine that strips IAC sequences from the inbound byte stream
- On connection: sends the WILL ECHO / WILL SGA / DO NAWS negotiation
- Parses NAWS subnegotiations and emits a terminal-size event
- Responds `DONT`/`WONT` to any unsolicited client options

This is modest complexity — similar in effort to writing a small binary framing codec.

**Confidence**: High. Sources: [swift-nio-extras README](https://github.com/apple/swift-nio-extras), [SwiftNIO README](https://github.com/apple/swift-nio), [MUD-Dev telnet wiki](http://mud-dev.wikidot.com/protocol:telnet).

---

## 2. SwiftNIO for TCP / Telnet Servers

### 2.1 Maturity

SwiftNIO is Apple's production-grade, actively maintained event-driven networking framework. It underpins Vapor, Hummingbird, and Apple's own server-side Swift ecosystem. The framework is mature: version 2.x has been stable since 2019, and the team commits to supporting the last three Swift minor releases with CI on nightly Swift. It is unambiguously the right choice for a Swift TCP server.

**Confidence**: High. Sources: [apple/swift-nio GitHub](https://github.com/apple/swift-nio), [Swift Package Index](https://swiftpackageindex.com/apple/swift-nio).

### 2.2 Building a TCP server

SwiftNIO provides `ServerBootstrap` with a `ServerSocketChannel` for accepting connections and a per-connection `SocketChannel`. The standard pattern:

```swift
let bootstrap = ServerBootstrap(group: eventLoopGroup)
    .serverChannelOption(.backlog, value: 256)
    .serverChannelOption(.socketOption(.so_reuseaddr), value: 1)
    .childChannelInitializer { channel in
        channel.pipeline.addHandlers([
            TelnetNegotiationHandler(),
            GameConnectionHandler(gameConfig: config)
        ])
    }

let channel = try await bootstrap.bind(host: "0.0.0.0", port: 23).get()
```

Each accepted connection becomes its own `Channel` with its own pipeline — providing natural per-connection isolation with no synchronization required within a single handler.

**Confidence**: High. Sources: [SwiftNIO README](https://github.com/apple/swift-nio), [process-one.net SwiftNIO echo server tutorial](https://www.process-one.net/blog/developing-a-basic-swift-echo-server-using-swift-nio/), [theswiftdev.com echo server tutorial](https://theswiftdev.com/swiftnio-tutorial-the-echo-server/).

### 2.3 No built-in telnet handler

Confirmed: `swift-nio-extras` contains no telnet-specific handler. The handler inventory is: `LineBasedFrameDecoder`, `FixedLengthFrameDecoder`, `LengthFieldBasedFrameDecoder`, `LengthFieldPrepender`, HTTP codec utilities, `RequestResponseHandler`, `QuiescingHelper`, debug handlers, and PCAP writer. No telnet, no terminal negotiation.

**Confidence**: High. Source: [swift-nio-extras GitHub](https://github.com/apple/swift-nio-extras).

---

## 3. Adapting the Game Loop

### 3.1 The current loop

`GameLoop` runs a blocking `while true { usleep(33_333) }` — approximately 30 Hz. It reads input, updates state, and renders to stdout. This must change for NIO because NIO's EventLoop threads must never block.

### 3.2 The NIO pattern: scheduleRepeatedTask

`EventLoop.scheduleRepeatedTask(initialDelay:delay:task:)` is the correct NIO primitive for a per-connection game tick. It schedules a closure to run on the EventLoop at fixed intervals, without blocking the thread:

```swift
let gameTask = channel.eventLoop.scheduleRepeatedTask(
    initialDelay: .milliseconds(0),
    delay: .milliseconds(33)  // ~30 Hz
) { [weak self] task in
    guard let self = self else { task.cancel(); return }
    let now = Date()
    let delta = now.timeIntervalSince(self.lastTick)
    self.lastTick = now
    self.gameState = RulesEngine.tick(self.gameState, delta: delta)
    let frame = Renderer.render(self.gameState)
    self.writeToChannel(frame)
}
```

The `RepeatedTask` can be cancelled on connection close. This replaces the `usleep`-based loop with no semantic change to the game's deterministic delta-time logic.

**Confidence**: High. Sources: [SwiftNIO EventLoop docs](https://github.com/apple/swift-nio/blob/main/Sources/NIOCore/EventLoop.swift), [swiftinit.org EventLoop docs](https://swiftinit.org/docs/swift-nio/niocore/eventloop).

### 3.3 Thread safety

Each NIO channel is permanently associated with exactly one EventLoop thread. All handler callbacks are guaranteed to run on that thread. This means a `GameConnectionHandler` can hold mutable `GameState` as a plain stored property — no `@MainActor`, no locks, no actors required. Swift 6's strict concurrency is satisfied because the `ChannelHandler` is confined to its EventLoop.

**Confidence**: High. Sources: [process-one.net ChannelHandlers and Pipelines](https://www.process-one.net/blog/swiftnio-introduction-to-channels-channelhandlers-and-pipelines/), [Swift Forums thread safety discussion](https://forums.swift.org/t/is-channelhandlers-property-thread-safe/30988).

---

## 4. Multi-Player vs. Single-Player Telnet

### 4.1 Per-connection isolation

SwiftNIO's channel architecture naturally enforces per-connection state isolation. Each accepted TCP connection gets:
- Its own `Channel` object
- Its own `ChannelPipeline` with fresh handler instances
- Its own EventLoop thread (or a thread from the group, with all events serialized)

This means each connecting player gets a completely independent `GameState`. There is no shared state to protect unless the game design calls for it (which DCJam2026 does not — it is single-player per session).

**Confidence**: High. Sources: [SwiftNIO README](https://github.com/apple/swift-nio), [process-one.net channels tutorial](https://www.process-one.net/blog/swiftnio-introduction-to-channels-channelhandlers-and-pipelines/).

### 4.2 Existing MUD precedent

The `NIOSwiftMUD` project (by the same developer as DCJam2026, interestingly) demonstrates exactly this pattern: a `Session` protocol abstraction over NIO channels, per-connection state via `MudSession`, and a command-dispatch architecture. Episode 13 of that series even transitions from telnet to SSH. This is a directly relevant reference.

**Confidence**: High. Source: [maartene/NIOSwiftMUD](https://github.com/maartene/NIOSwiftMUD).

---

## 5. Replacing the I/O Layer

### 5.1 What must change

The current I/O layer has two sides:

| Current (local TUI) | Telnet equivalent |
|---|---|
| `open("/dev/tty", O_RDONLY | O_NONBLOCK)` → read bytes | `channelRead(_:data:)` callback → bytes arrive in `ByteBuffer` |
| `write(STDOUT_FILENO, ...)` loop | `channel.writeAndFlush(ByteBuffer)` |
| `tcsetattr` raw mode | Telnet ECHO+SGA negotiation (handled by `TelnetNegotiationHandler`) |
| `ioctl(TIOCGWINSZ)` for terminal size | NAWS subnegotiation (parsed by `TelnetNegotiationHandler`) |

### 5.2 What stays the same

- `GameDomain` — zero changes needed. It is pure logic with no I/O.
- `Renderer.swift` — produces ANSI strings. Zero changes needed; those strings are sent over the socket instead of stdout.
- `TUIOutputPort` protocol — already an abstraction boundary. Create a `TelnetOutputPort` conformance that writes to a NIO `Channel` instead of stdout.

### 5.3 What must be replaced or bypassed

- `ANSITerminal.swift`: the `tcsetattr` raw-mode setup and the `/dev/tty` fd management are not needed for network connections. This file can be left for the local executable target and simply not linked into the telnet server target.
- `InputHandler.swift`: the `/dev/tty` non-blocking read is replaced by `channelRead`. The key-byte-to-`GameCommand` parsing logic can be reused as a pure function.
- `GameLoop.swift`: the blocking `while true` loop is replaced by `scheduleRepeatedTask`. The tick logic (read input, update state, render, write) remains identical in structure.

### 5.4 Write pattern for NIO

The CLAUDE.md write rule (looping write for short writes and EINTR) applies to `write(2)` syscalls on a tty. NIO's `channel.writeAndFlush` handles backpressure and fragmentation internally — the NIO equivalent of that loop is already built in. No manual looping write needed.

**Confidence**: High. Sources: project CLAUDE.md, [apple/swift-nio docs](https://github.com/apple/swift-nio), [swiftonserver.com NIO fundamentals](https://swiftonserver.com/using-swiftnio-fundamentals/).

---

## 6. Terminal Size Negotiation (NAWS)

DCJam2026 targets a fixed 80×25 layout (confirmed in CLAUDE.md). Via NAWS:

1. Server sends `IAC DO NAWS` during connection handshake.
2. Client responds `IAC WILL NAWS` + subnegotiation with actual dimensions.
3. Server parses the 4-byte dimensions and stores them per-connection.
4. If `cols < 80` or `rows < 25`: write a warning message to the client ("Terminal too small — please resize to at least 80×25 columns") and either wait or close.

The NAWS parsing is roughly 20 lines of Swift. The client can also send updated NAWS subnegotiations on terminal resize, allowing the server to re-check.

**Confidence**: High. Source: [RFC 1073](https://datatracker.ietf.org/doc/html/rfc1073).

---

## 7. ANSI Compatibility with Common Telnet Clients

The game uses standard ANSI/VT100 escape codes for cursor positioning, color, and box-drawing characters. Compatibility across common clients:

| Client | ANSI/VT100 support | Box-drawing (U+2500) | Notes |
|---|---|---|---|
| macOS `telnet` (via `brew install telnet`) | Full VT100/ANSI | Yes, if terminal font supports it | macOS Terminal.app is xterm-256color |
| PuTTY (Windows/Linux) | Full VT100/ANSI | Yes (configurable) | PuTTY has explicit box-drawing character support |
| GateOne (browser) | Full xterm | Yes | xterm-compatible browser terminal |
| ttyd (browser) | Full xterm | Yes | Uses xterm.js |
| netcat / raw socket | None — raw bytes only | N/A | Not a telnet client |

The existing `Renderer.swift` ANSI output will display correctly on any terminal that supports xterm/VT100. The only risk is **Unicode box-drawing characters** (U+2500 block): these require a UTF-8 terminal with a font that includes these glyphs. PuTTY and modern browser clients handle this well. Ancient pure-ASCII telnet clients would show garbage for box-drawing chars but are not a realistic concern.

**Confidence**: High (ANSI support); Medium (box-drawing universality — depends on client font configuration). Sources: [ANSI escape code Wikipedia](https://en.wikipedia.org/wiki/ANSI_escape_code), [PuTTY configuration docs](https://the.earth.li/~sgtatham/putty/0.64/htmldoc/Chapter4.html), [VT100 User Guide](https://vt100.net/docs/vt100-ug/chapter3.html).

---

## 8. Existing Swift / SwiftNIO Telnet / Game Server Examples

### 8.1 NIOSwiftMUD (maartene/NIOSwiftMUD)

A MUD game built with Swift + SwiftNIO by the same developer as DCJam2026. Demonstrates:
- TCP server bootstrap for text-based game connections
- Per-connection `Session` protocol abstraction decoupled from NIO
- Room-based navigation and multi-player notifications
- Episode 13 adds SSH support, suggesting the telnet→SSH migration is tractable

This is the single most relevant reference for this project. The architecture maps almost directly onto DCJam2026's `TUIOutputPort` pattern.

Source: [maartene/NIOSwiftMUD](https://github.com/maartene/NIOSwiftMUD).

### 8.2 apple/swift-nio-examples

The official examples repository (`apple/swift-nio-examples`) contains HTTP/1.1, HTTP/2, and echo server examples. The echo server (testable with `telnet`) demonstrates the `ServerBootstrap` + `ChannelHandler` pattern but does not include telnet protocol negotiation.

Source: [apple/swift-nio-examples](https://github.com/apple/swift-nio-examples).

### 8.3 swiftonserver.com NIO tutorial series

A current (2024–2025) tutorial series covering SwiftNIO fundamentals, client/server bootstrap patterns, and HTTP clients. Provides practical reference for the `ChannelHandler` API.

Source: [swiftonserver.com](https://swiftonserver.com/using-swiftnio-fundamentals/).

### 8.4 No telnet-specific SwiftNIO library found

No `swift-nio-telnet` package was found on GitHub, Swift Package Index, or in the `slashmo/awesome-swift-nio` curated list. Telnet negotiation must be hand-rolled. Given the simplicity of the protocol, this is not a significant obstacle.

**Confidence**: High (for absence of existing library). Sources: [swift-nio-extras](https://github.com/apple/swift-nio-extras), [awesome-swift-nio](https://github.com/slashmo/awesome-swift-nio).

---

## 9. SSH as an Alternative

### 9.1 What swift-nio-ssh provides

`apple/swift-nio-ssh` is Apple's programmatic SSH implementation built on SwiftNIO. It provides:
- `NIOSSHHandler` — a ChannelHandler implementing the SSH protocol
- Password and public-key authentication via delegate protocols
- Multiplexed child channels for session, direct-tcpip, and forwarded-tcpip
- `SSHChannelRequestEvent.PseudoTerminalRequest` for PTY allocation
- `WindowChangeRequest` for terminal resize events

Source: [apple/swift-nio-ssh README](https://github.com/apple/swift-nio-ssh/blob/main/README.md), [Introducing SwiftNIO SSH (swift.org)](https://www.swift.org/blog/swiftnio-ssh/).

### 9.2 PTY complexity

The `SSHChannelRequestEvent.PseudoTerminalRequest` event signals that the SSH client has requested a PTY. For the DCJam2026 use case, **a real PTY is not needed** — the game manages its own ANSI rendering directly. The server simply needs to:
1. Handle the PTY request event (acknowledge it).
2. Read `WindowChangeRequest` for terminal dimensions (replaces NAWS).
3. Send ANSI bytes directly into the SSH channel's data stream.

This avoids the hard PTY problem (described in Swift Forums thread) entirely. No `openpty()` or `forkpty()` is needed because the game is not wrapping a subprocess — it is the application itself.

**Confidence**: High for the no-PTY-process approach. Source: [Swift Forums PTY discussion](https://forums.swift.org/t/process-shell-with-pty-for-swift-nio-based-ssh-server/65457), [swift-nio-ssh README](https://github.com/apple/swift-nio-ssh/blob/main/README.md).

### 9.3 Additional SSH overhead vs. telnet

| Aspect | Telnet | SSH |
|---|---|---|
| Dependencies | None (pure NIO) | `swift-nio-ssh` package |
| Authentication | None (or trivial password check) | Requires `NIOSSHServerUserAuthenticationDelegate` |
| Key management | None | Server host key (generate once, persist) |
| Encryption | None | Automatic (Ed25519 / AES-GCM) |
| Client tools | `telnet`, browser terminals | `ssh`, all modern terminals |
| Terminal negotiation | NAWS via IAC subnegotiation | `PseudoTerminalRequest` + `WindowChangeRequest` events |
| Complexity delta | Baseline | +1–2 days |

For a game jam, the authentication and key management overhead of SSH is real but manageable. The compelling case for SSH is that `telnet` is disabled by default on many modern systems (macOS removed it in Mojave; it must be installed via `brew`). SSH clients are universally available.

**Confidence**: Medium. Sources: [swift-nio-ssh README](https://github.com/apple/swift-nio-ssh), [Swift.org SSH blog post](https://www.swift.org/blog/swiftnio-ssh/).

---

## 10. Effort Estimate

### 10.1 Telnet approach — component breakdown

| Component | Estimated effort | Notes |
|---|---|---|
| `TelnetNegotiationHandler` (IAC state machine, WILL/DO, NAWS parsing) | 4–6 hours | ~100 lines Swift; no external deps |
| `GameConnectionHandler` (holds `GameState`, tick via `scheduleRepeatedTask`) | 3–5 hours | Replaces `GameLoop`'s blocking loop |
| `TelnetOutputPort` conforming to `TUIOutputPort` | 1–2 hours | Write ANSI strings to `channel.writeAndFlush` |
| Input byte → `GameCommand` adapter | 1–2 hours | Reuse existing key mapping logic |
| `ServerBootstrap` wiring, SPM target, entry point | 2–3 hours | New executable target `DCJam2026-Telnet` |
| Terminal size check (NAWS → 80×25 validation) | 1 hour | Log or warn if too small |
| Testing (local telnet, PuTTY, browser client) | 2–4 hours | Manual smoke tests |
| **Total** | **~14–22 hours** | **2–3 focused days** |

### 10.2 SSH approach — additional overhead

| Additional SSH component | Estimated effort | Notes |
|---|---|---|
| Add `swift-nio-ssh` dependency, update Package.swift | 0.5 hours | |
| `NIOSSHServerUserAuthenticationDelegate` (password or accept-all) | 1–2 hours | For a jam: "no password" accept-all is trivial |
| SSH server bootstrap (replace TCP bootstrap) | 2–3 hours | Different bootstrap pattern from telnet |
| Handle `PseudoTerminalRequest`, `ShellRequest` channel events | 2–3 hours | Acknowledge requests, handle child channel |
| Host key generation and persistence | 1 hour | Generate `Ed25519` keypair, store to file |
| **Total delta over telnet** | **+6–9 hours** (~1.5 days) | |
| **SSH total** | **~20–31 hours** | **3–4 focused days** |

### 10.3 Risk factors

- **Swift 6 strict concurrency**: NIO 2.x is Swift 6 compatible, but care is needed when crossing actor boundaries. `ChannelHandler` stored properties are safe (EventLoop-confined), but any shared config passed in must be `Sendable`. Low risk given DCJam2026's value-oriented architecture.
- **Package.swift dependency addition**: DCJam2026 currently has zero external dependencies. Adding SwiftNIO introduces a build dependency that may increase compile times. On a modern machine with SPM caching this is a one-time cost of ~1–2 minutes.
- **Linux compatibility**: SwiftNIO is explicitly cross-platform (macOS + Linux). No issues expected. The existing POSIX I/O (`tcsetattr`, `/dev/tty`) in `ANSITerminal.swift` can remain in the local TUI target without affecting the telnet server target.

---

## 11. Recommendation

### Primary recommendation: Telnet via SwiftNIO

For a **game jam context**, telnet is the recommended approach:

- **Feasible**: The protocol is simple; no external dependencies beyond SwiftNIO core.
- **Architecturally clean**: DCJam2026's `TUIOutputPort` boundary and pure `GameDomain` make the I/O substitution surgical.
- **Precedent exists**: The `NIOSwiftMUD` project (same developer) demonstrates exactly this pattern.
- **Effort**: 14–22 hours (~2–3 days) — achievable within a jam schedule if time is allocated.

The telnet handshake (ECHO + SGA + NAWS) is a one-time implementation that can be encapsulated entirely in a single `TelnetNegotiationHandler` class. Once that handler is written, the rest of the work is plumbing — connecting the existing renderer output to the channel and replacing the blocking loop.

### Secondary recommendation: SSH if post-jam polish is planned

If the project continues past the jam and "telnet is disabled on my machine" becomes a real user friction point, migrating from telnet to SSH adds ~1.5 days of effort. The PTY complexity commonly cited as a Swift/SSH obstacle is **not relevant here** because the game directly manages its own ANSI rendering — no subprocess PTY is needed.

### Implementation order

1. Create new SPM target `TelnetServer` (or `DCJam2026-Telnet`) that imports `GameDomain`, `Renderer`, `InputHandler`.
2. Implement `TelnetNegotiationHandler` — IAC state machine, WILL ECHO + WILL SGA + DO NAWS on connect, NAWS parsing.
3. Implement `TelnetOutputPort: TUIOutputPort` — writes `ByteBuffer` to channel.
4. Implement `GameConnectionHandler: ChannelInboundHandler` — holds `GameState`, schedules tick at 30 Hz, feeds input bytes to command parser, calls renderer, writes output.
5. Wire `ServerBootstrap` in entry point (port 2323 to avoid requiring root for port 23).
6. Test with `telnet localhost 2323` and PuTTY.

---

## Knowledge Gaps

1. **No real benchmark of Swift 6 strict concurrency friction with NIO 2.x in 2025**: The exact `Sendable` error surface when integrating DCJam2026's `GameState` structs into a NIO handler under Swift 6's complete concurrency checking was not confirmed by any source. Likely low friction (all `GameState` types are `struct`s, which are `Sendable` if their stored properties are), but this needs a compile-time validation pass.

2. **NIOSwiftMUD telnet negotiation specifics**: The NIOSwiftMUD README does not document whether the telnet implementation includes ECHO/SGA negotiation or only raw TCP. The "Episode 13: SSH migration" note suggests early episodes may have used raw TCP (line-mode telnet) rather than character-mode negotiation.

3. **Browser-based telnet client testing**: GateOne and ttyd were identified as candidates for browser-based access, but no hands-on testing of ANSI rendering with the specific box-drawing characters used by DCJam2026 was performed. The U+2500 block characters used for the dungeon view (e.g., `┌`, `─`, `│`) require UTF-8 transport — standard telnet in its original RFC specification is 7-bit ASCII. In practice, modern telnet clients operate in 8-bit mode and pass UTF-8 bytes transparently, but this should be verified.

4. **Effort estimate confidence**: The 14–22 hour estimate is based on protocol complexity analysis and comparison to analogous projects, not on a reference implementation that has been built. Actual effort could vary by ±50% depending on Swift 6 concurrency friction encountered.

---

## Sources

- [apple/swift-nio — GitHub](https://github.com/apple/swift-nio)
- [apple/swift-nio-examples — GitHub](https://github.com/apple/swift-nio-examples)
- [apple/swift-nio-extras — GitHub](https://github.com/apple/swift-nio-extras)
- [apple/swift-nio-ssh — GitHub](https://github.com/apple/swift-nio-ssh)
- [Introducing SwiftNIO SSH — Swift.org](https://www.swift.org/blog/swiftnio-ssh/)
- [maartene/NIOSwiftMUD — GitHub](https://github.com/maartene/NIOSwiftMUD)
- [RFC 854 — Telnet Protocol Specification](https://www.rfc-editor.org/rfc/rfc854.html)
- [RFC 1073 — Telnet Window Size Option (NAWS)](https://datatracker.ietf.org/doc/html/rfc1073)
- [ECHO and SGA Telnet Options for MUDs — The Last Outpost](https://www.last-outpost.com/LO/protocols/echosga.html)
- [Force Telnet Client into Character Mode — codegenes.net](https://www.codegenes.net/blog/force-telnet-client-into-character-mode/)
- [Telnet Protocol — MUD-Dev Wiki](http://mud-dev.wikidot.com/protocol:telnet)
- [ANSI Escape Code — Wikipedia](https://en.wikipedia.org/wiki/ANSI_escape_code)
- [PuTTY Configuration Docs](https://the.earth.li/~sgtatham/putty/0.64/htmldoc/Chapter4.html)
- [SwiftNIO ChannelHandlers and Pipelines — process-one.net](https://www.process-one.net/blog/swiftnio-introduction-to-channels-channelhandlers-and-pipelines/)
- [Swift NIO thread-safety — Swift Forums](https://forums.swift.org/t/is-channelhandlers-property-thread-safe/30988)
- [PTY for swift-nio SSH server — Swift Forums](https://forums.swift.org/t/process-shell-with-pty-for-swift-nio-based-ssh-server/65457)
- [swiftonserver.com — Using SwiftNIO Fundamentals](https://swiftonserver.com/using-swiftnio-fundamentals/)
- [theswiftdev.com — SwiftNIO Echo Server Tutorial](https://theswiftdev.com/swiftnio-tutorial-the-echo-server/)
- [swift-nio-ssh — Swift Package Index](https://swiftpackageindex.com/apple/swift-nio-ssh)
- [awesome-swift-nio — slashmo/GitHub](https://github.com/slashmo/awesome-swift-nio)
