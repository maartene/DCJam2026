# Technology Stack — zero-download-deployment

---

## Bridge Server

| Technology | Version | Role | Rationale |
|---|---|---|---|
| Node.js | 20 LTS | Bridge server runtime | Runs on ARM Linux (RPi) with no compilation; LTS = stable for jam window |
| `ws` | ^8.x | WebSocket server | Minimal, zero-dependency WS library; battle-tested; no framework overhead |
| `node-pty` | ^1.x | PTY + process spawning | Required to give Swift game a controlling terminal (`/dev/tty` dependency in InputHandler.swift) |

**Why not a more featureful framework (Express, Fastify)?**  
The server does two things: serve one static HTML file and manage WebSocket sessions. That fits in ~80 lines of plain Node.js. No routing, no middleware, no templating required.

**Why not Deno or Bun?**  
`node-pty` is an npm package with native bindings. Deno and Bun have incomplete npm compatibility for native addons. Node.js 20 LTS is the safe choice for `node-pty` on ARM Linux.

---

## Browser Client

| Technology | Version | Role | Rationale |
|---|---|---|---|
| xterm.js | 5.x (CDN) | Terminal emulator in browser | De-facto standard; full ANSI/VT100/256-colour/box-drawing support; WebSocket attach addon available |
| `@xterm/addon-attach` | 0.x (CDN) | Wires WS stream to xterm.js | Reduces WS↔terminal wiring to 3 lines of JS |

**Why CDN instead of bundled?**  
No build step required. The `index.html` is a single self-contained file. Judges get the terminal immediately without waiting for a JS bundle download.

---

## Game Executable

| Technology | Version | Role |
|---|---|---|
| Swift | 6.3 | Game binary | Existing — unchanged |
| Swift Package Manager | built-in | Build tool | Existing — unchanged |

The Swift binary is compiled for `aarch64-unknown-linux-gnu` (Raspberry Pi ARM64). See ADR-012 for compilation strategy.

---

## Deployment

See `deployment/deployment-architecture.md` for full detail. Summary:

| Technology | Role |
|---|---|
| Docker (ARM64) | Packages Node.js + Swift binary into single deployable image |
| `arm64v8/node:20-alpine` | Base image for ARM Raspberry Pi |
| `cloudflared` | Cloudflare Tunnel daemon: exposes localhost:3000 as public HTTPS/WSS URL |

---

## What Is Explicitly Not Used

| Technology | Reason not used |
|---|---|
| SwiftNIO / Vapor | Would require modifying Swift package and adding dependencies — deferred to post-jam |
| `child_process.spawn` (plain stdio) | Cannot provide `/dev/tty` to Swift game — `node-pty` required |
| WASM compilation | 3–5 days + hard blockers in App layer — out of scope for jam |
| ngrok | Cloudflare Tunnel preferred: free tier, no session limits, HTTPS by default |
| WebRTC / SSE | WebSocket is the correct transport for full-duplex byte-stream terminal I/O |
