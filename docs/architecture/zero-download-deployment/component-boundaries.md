# Component Boundaries — zero-download-deployment

---

## Existing Swift Package (Unchanged)

```
Sources/
  GameDomain/     ← pure domain logic — NO changes
  App/            ← TUI App layer — NO changes
    main.swift
    TUIOutputPort.swift
    InputHandler.swift    ← opens /dev/tty (requires PTY)
    ANSITerminal.swift    ← calls tcsetattr (requires PTY)
    GameLoop.swift
    Renderer.swift
    ...
```

**Contract**: The Swift binary reads bytes from `/dev/tty` and writes ANSI bytes to stdout. It requires a controlling terminal (PTY slave). It has no knowledge of WebSockets, browsers, or Node.js.

---

## New: `infrastructure/` Directory

Outside the Swift package tree. Contains all zero-download-deployment sources: bridge code, deployment config, and acceptance tests.

```
infrastructure/
  web/
    server.js        ← Bridge Server component
    index.html       ← Browser Client component
    package.json
    package-lock.json
```

### Bridge Server (`web/server.js`)

**Responsibility**: Accept WebSocket connections; spawn one Swift game process per connection inside a PTY; pipe bytes bidirectionally.

**Interfaces**:
- Inbound: WebSocket connections on `ws://localhost:3000/game`
- Inbound: HTTP GET `/` → serves `index.html`
- Outbound: `node-pty.spawn("DCJam2026", [], { cols: 80, rows: 25 })` per session

**Dependencies**: `ws`, `node-pty`, Node.js `http` module, Node.js `fs` module (serve index.html)

**State**: A `Map<WebSocket, IPty>` of active sessions. No persistent state.

**Session lifecycle**:
```
ws 'connection' → pty = spawn(game) → wire pty.onData → ws.send; wire ws 'message' → pty.write
ws 'close'      → pty.kill('SIGTERM'); sessions.delete(ws)
pty 'exit'      → ws.close(); sessions.delete(ws)
```

**Size estimate**: ~80 lines of JavaScript.

---

### Browser Client (`web/index.html`)

**Responsibility**: Render an 80×25 xterm.js terminal; connect to the bridge via WebSocket; send keydown events; render received ANSI bytes.

**Interfaces**:
- Outbound: WebSocket to `ws(s)://{host}/game`
- Renders: xterm.js `Terminal` with `AttachAddon`

**No server-side logic.** Fully static — can be served from Node.js or any static host.

**Size estimate**: ~40 lines of HTML/JS.

---

## `infrastructure/deploy/` Subfolder

Deployment configuration. Separate from `web/` because deployment concerns (Docker, tunnel config) are operationally distinct from bridge code.

```
infrastructure/
  deploy/
    Dockerfile           ← multi-stage: build Swift binary + package Node.js server
    docker-compose.yml   ← service definition for RPi
    cloudflared.yml      ← Cloudflare Tunnel configuration
  tests/
    acceptance/          ← Gherkin feature files
      steps/
        bridge.test.js   ← Node.js node:test implementation
```

See `deployment/deployment-architecture.md` for the design of the deploy files.

---

## Dependency Rule

```
Browser Client ──(WSS)──→ Bridge Server ──(PTY)──→ Swift Game Process
(infrastructure/web/       (infrastructure/web/         ↑
 index.html)                server.js)         (existing Swift package,
                                                unchanged, no new deps)
```

The Swift game process has no outbound dependency on the bridge. It is unaware it is being proxied. This is the key invariant: the bridge is a transparent I/O adapter, not an integration point.

---

## What Is Not a Component Boundary

The Node.js bridge does **not** expose any API to `GameDomain` or parse game state. It is a raw byte pipe. ANSI rendering intelligence lives entirely in xterm.js (browser side). No game-specific logic belongs in the bridge.
