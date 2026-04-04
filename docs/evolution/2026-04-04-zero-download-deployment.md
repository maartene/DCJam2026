# Evolution: zero-download-deployment

**Date**: 2026-04-04  
**Feature ID**: zero-download-deployment  
**Status**: COMPLETE

---

## Feature Summary

Implemented a WebSocket/xterm.js/node-pty browser bridge allowing DCJam 2026 judges to play Ember's Escape in a browser with zero install steps. A judge opens a public URL, a full 80x25 terminal renders in their browser, and they play the unmodified Swift game in real time.

The bridge is a ~80-line Node.js script (`infrastructure/web/server.js`) that:
1. Serves a static `index.html` with an xterm.js terminal and WebSocket client
2. Accepts WebSocket connections at `ws://localhost:3000/game`
3. Spawns one Swift game process per connection inside a PTY (via `node-pty`)
4. Pipes bytes bidirectionally between the WebSocket and the PTY

The existing Swift game binary is completely unchanged. No new Swift dependencies were added.

---

## Business Context

**Jam**: DCJam 2026  
**Problem**: Judges evaluate games submitted to the jam. A terminal roguelike requires macOS/Linux + Swift to run natively, creating friction that could cost votes or cause skipped evaluations.  
**Solution**: Zero-download browser access. Judge clicks a URL, plays the game in Chrome/Firefox/Safari.

**Minimum viable success**: A judge opens the URL, plays a full run, closes the tab — zero install steps, zero rendering errors.

---

## Delivery Execution — Completed Steps

All 7 steps across 3 phases completed on 2026-04-04. Every step followed the TDD RED-GREEN-COMMIT cycle.

### Phase 01 — Walking Skeleton

| Step | Name | Outcome | Notes |
|---|---|---|---|
| 01-01 | Serve static HTML page | PASS | HTTP server created; GET / returns xterm.js client page |
| 01-02 | WebSocket server and node-pty game spawn per connection | PASS | `ws` server added; `node-pty` spawns DCJam2026 binary per WS connection |
| 01-03 | Pipe PTY stdout to WebSocket | PASS | `pty.onData` → `ws.send`; ANSI bytes flow to browser |
| 01-04 | Pipe WebSocket messages to PTY stdin | PASS | `ws message` → `pty.write`; keypress bytes reach game |
| 01-05 | Clean teardown and session tracking | PASS | `ws close/error` → `pty.kill('SIGTERM')`; sessions Map cleanup; zombie test |

Unit tests: SKIPPED for all walking skeleton steps. Rationale: HTTP server creation, WebSocket+PTY wiring, and byte forwarding are transparent infrastructure with no domain logic. Acceptance tests (WS-1 to WS-5) are the appropriate test level.

### Phase 02 — Polish

| Step | Name | Outcome | Notes |
|---|---|---|---|
| 02-01 | Terminal size guard via query params | PASS | `?cols=N&rows=N` protocol; rejects cols<80 or rows<25 with warning over WS |

Protocol confirmed: query parameters (`ws://localhost:3000/game?cols=80&rows=25`). Recorded in CLAUDE.md.

### Phase 03 — Deployment

| Step | Name | Outcome | Notes |
|---|---|---|---|
| 03-01 | Docker image and deployment configuration | PASS | Multi-stage ARM64 Dockerfile; docker-compose.yml; cloudflared.yml |

Docker base image: `arm64v8/node:20-alpine`. Build tools (`python3 make g++`) required for `node-pty` native compilation.

---

## Key Wave Decisions

### DISCUSS Wave

- **D5 — WebSocket bridge, NOT WASM**: True WASM compilation would take 3-5 days with hard blockers in the App layer. The WebSocket/xterm.js bridge delivers the same judge experience in 1-2 days with zero game-code changes.
- **D6 — Node.js over SwiftNIO**: `node-pty` + `ws` + xterm.js has more reference implementations, lower setup risk, and keeps the Swift package dependency-free. SwiftNIO deferred to post-jam.
- **Deployment target**: Raspberry Pi (ARM Linux / aarch64) with Cloudflare Tunnel — not a cloud VPS. Uses developer's existing hardware at zero cost.

### DESIGN Wave

- **D1 — Thin bridge / process-per-session**: No framework, ~80 lines. One OS process per judge session. Session isolation guaranteed by OS process boundaries.
- **D2 — `node-pty` is a hard requirement**: `InputHandler.swift` opens `/dev/tty`, which requires a controlling terminal. Plain `child_process.spawn()` with stdio pipes provides no PTY slave — the game would fail to read input silently. `node-pty` is the only viable solution.
- **D3 — Raw byte pass-through**: Bridge does not parse ANSI or inspect game state. xterm.js consumes raw VT100 byte streams natively.
- **D5 — Raspberry Pi + Cloudflare Tunnel**: Developer's existing RPi + `cloudflared` for public HTTPS/WSS without router port forwarding.

### DEVOPS Wave

- **D3 — Extend existing `ci.yml`**: Added a `docker-bridge` job on `ubuntu-24.04-arm` runner (same architecture as RPi) to validate Docker image build.
- **D5 — Manual deployment**: `git pull` + `docker build` + `docker compose up` on the RPi. SSH deployment automation is out of scope for jam.
- **D6 — Console logs only**: Structured one-liners covering session lifecycle (`CONNECT`, `SPAWN`, `EXIT`, `CLOSE`, `WARN`, `ERROR`). Viewable via `docker compose logs -f`. No metrics stack.

### DISTILL Wave

- **D1 — Node.js `node:test` + `ws`**: No new test dependencies beyond `ws` which is already in `package.json`.
- **D3 — Real binary, no mocks**: Tests run against the real `DCJam2026` binary via the real `server.js`. PTY spawning is not mocked.
- **D4 — Terminal size protocol resolved**: DISTILL noted TBD; DELIVER confirmed query parameters (`?cols=N&rows=N`).

---

## Lessons Learned

### 1. `pgrep` macOS vs Linux compatibility

**Issue**: Acceptance tests for zombie process detection used `pgrep -c DCJam2026`. On macOS, `pgrep` counts processes differently than on Linux, producing false positives in local development.  
**Resolution**: Tests were written to run against the real server on the target platform (Linux/ARM via Docker or CI). macOS local runs of the process-count tests require awareness of this difference.  
**Lesson**: When writing process-lifecycle tests that will run on multiple OS families, prefer `/proc`-based checks on Linux or abstract behind a platform-aware helper.

### 2. Query params protocol — resolve TBDs before implementation begins

**Issue**: DISTILL wave documented terminal size protocol as TBD (query params vs. first-message JSON). This was resolved by DELIVER implementation, but the ambiguity caused a test-alignment step.  
**Resolution**: Query parameters confirmed and recorded in CLAUDE.md: `ws://localhost:3000/game?cols=80&rows=25`.  
**Lesson**: Wire-protocol TBDs should be resolved in DISTILL, not deferred to DELIVER. The test and implementation should agree on the protocol before either is written.

### 3. `node-pty` PTY requirement — non-obvious hard dependency

**Issue**: The dependency on `node-pty` is non-obvious from reading `server.js`. A future maintainer might attempt to simplify by replacing it with `child_process.spawn()` — which would silently break input.  
**Resolution**: The PTY requirement is documented in the architecture design, ADR-011, DESIGN wave decisions, and the CLAUDE.md bridge notes. Multiple documentation points reinforce this constraint.  
**Lesson**: Hard requirements that are invisible at the call site (the game code has no knowledge of the bridge) must be documented at every layer that a maintainer might read first.

### 4. Alpine + node-pty native build tools

**Issue**: `node-pty` requires `python3 make g++` to compile native bindings. Alpine Linux omits these by default. Without an `apk add` step before `npm ci`, the Docker build fails.  
**Resolution**: `apk add --no-cache python3 make g++` is a required step in the Dockerfile before `npm ci`.  
**Lesson**: Native npm packages in Alpine containers require explicit build tool installation. Always verify in CI before assuming `npm ci` will succeed in a minimal base image.

---

## Test Results

| Category | Count | Status |
|---|---|---|
| Automated acceptance tests | 18 | All PASS |
| Manual scenarios | 3 | Verified before submission |
| Walking skeleton | 5 | PASS |
| Unit tests | 0 (N/A) | Transparent infrastructure; no domain logic |

---

## Migrated Permanent Artifacts

| Artifact | Permanent location |
|---|---|
| Architecture design | `docs/architecture/zero-download-deployment/architecture-design.md` |
| Component boundaries | `docs/architecture/zero-download-deployment/component-boundaries.md` |
| Technology stack | `docs/architecture/zero-download-deployment/technology-stack.md` |
| Data models | `docs/architecture/zero-download-deployment/data-models.md` |
| Deployment architecture | `docs/architecture/zero-download-deployment/deployment/deployment-architecture.md` |
| Test scenarios | `docs/scenarios/zero-download-deployment/test-scenarios.md` |
| Walking skeleton | `docs/scenarios/zero-download-deployment/walking-skeleton.md` |
| Judge journey (YAML) | `docs/ux/zero-download-deployment/journey-judge-play.yaml` |
| Judge journey (visual) | `docs/ux/zero-download-deployment/journey-judge-play-visual.md` |
| ADR-011 WS/PTY bridge | `docs/adrs/ADR-011-websocket-pty-bridge.md` (already in place) |
| ADR-012 RPi + Cloudflare | `docs/adrs/ADR-012-raspberry-pi-cloudflare-tunnel.md` (already in place) |

---

## Implementation Artifacts (Permanent — in repo)

| Artifact | Location |
|---|---|
| Bridge server | `infrastructure/web/server.js` |
| Browser client | `infrastructure/web/index.html` |
| Package manifest | `infrastructure/web/package.json` |
| Acceptance tests | `infrastructure/tests/acceptance/steps/bridge.test.js` |
| Dockerfile (ARM64) | `infrastructure/deploy/Dockerfile` |
| Docker Compose | `infrastructure/deploy/docker-compose.yml` |
| Cloudflare Tunnel config | `infrastructure/deploy/cloudflared.yml` |
