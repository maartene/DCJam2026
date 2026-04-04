# Test Scenarios — zero-download-deployment

## Summary

| Feature file | Scenarios | Automated | Manual | AC covered |
|---|---|---|---|---|
| `walking-skeleton.feature` | 5 | 5 | 0 | WS-1 to WS-5 |
| `milestone-1-session-lifecycle.feature` | 3 | 3 | 0 | AC-6, AC-7 |
| `milestone-2-terminal-guard.feature` | 4 | 4 | 0 | AC-5 |
| `milestone-3-ansi-and-input.feature` | 5 | 3 | 2 | AC-2, AC-3, AC-4 |
| `integration-checkpoints.feature` | 4 | 3 | 1 | AC-8 + Docker |
| **Total** | **21** | **18** | **3** | AC-1 to AC-8 |

---

## Driving Port

All automated tests drive through the WebSocket endpoint (`ws://localhost:3000/game`) and HTTP endpoint (`http://localhost:3000`). No internal components are tested directly. The Swift game binary is exercised as a black box via the PTY.

---

## Manual Scenarios (3)

These require a browser and human visual inspection:

| Scenario | Reason not automatable |
|---|---|
| xterm.js renders box-drawing characters without corruption | Requires visual inspection of rendered terminal |
| Start screen loads within timing targets (3s page / 2s game) | Browser-specific timing; DevTools measurement |
| Cloudflare Tunnel exposes service over WSS | Requires live tunnel to CF edge; not reproducible in CI |

**When to run manual tests**: Before submitting to DCJam 2026, on Chrome, Firefox, and Safari.

---

## Test Execution

### Prerequisites
```bash
# Terminal 1: build Swift binary
swift build -c release

# Terminal 2: start the bridge server
cd infrastructure/web
npm install
GAME_BINARY=../../.build/release/DCJam2026 node server.js

# Terminal 3: run acceptance tests (from project root)
node --test infrastructure/tests/acceptance/steps/bridge.test.js
```

### Against Docker
```bash
docker build --platform linux/arm64 -t embers-escape -f infrastructure/deploy/Dockerfile .
docker run -d --name bridge -p 3000:3000 embers-escape
node --test infrastructure/tests/acceptance/steps/bridge.test.js
docker stop bridge && docker rm bridge
```

---

## Implementation Notes for Terminal Size Guard (AC-5)

The test for AC-5 assumes the server reads terminal dimensions from WebSocket query parameters (`?cols=N&rows=N`). This is the simplest approach. The alternative is a first-message JSON protocol. Either is fine — the test code has a comment marking this as TBD. Align with whatever `server.js` implements.

---

## AC Coverage Matrix

| AC | Scenario(s) | Automated |
|---|---|---|
| AC-1 Start screen loads in browser | `milestone-3` @manual | Manual |
| AC-2 Keyboard input reaches game | `milestone-3` "W key byte" | Yes |
| AC-3 All game keys work | `milestone-3` "primary game keys" | Yes |
| AC-4 ANSI fidelity | `milestone-3` CSI sequences + @manual | Partial |
| AC-5 Terminal size warning | `milestone-2` all 4 scenarios | Yes |
| AC-6 Session isolation | `milestone-1` concurrent sessions | Yes |
| AC-7 Clean teardown | `walking-skeleton` WS-5 + `milestone-1` | Yes |
| AC-8 Game logic unchanged | `integration-checkpoints` + existing ci.yml | Yes (CI) |
