# Data Models — zero-download-deployment

The bridge is a transparent byte pipe. It has no domain data model.

---

## Bridge Server Runtime State

```javascript
// In-memory only; no persistence; discarded on process restart
const sessions = new Map()  // Map<WebSocket, IPty>
```

Each entry:

| Field | Type | Description |
|---|---|---|
| key | `WebSocket` | The active WS connection for a judge session |
| value | `IPty` (node-pty) | The PTY handle wrapping the Swift game process |

No serialisation. No database. No file I/O. State lives only for the duration of a session.

---

## WebSocket Message Format

**Browser → Server** (keypress):
- Binary frame
- Content: raw key bytes as produced by xterm.js `terminal.onData` callback
- Encoding: UTF-8 (xterm.js default)
- Examples: `w` → `0x77`; arrow up → `0x1B 0x5B 0x41`

**Server → Browser** (game output):
- Binary frame
- Content: raw PTY stdout bytes from Swift game
- Encoding: UTF-8 ANSI escape sequences
- No framing, no envelope — raw bytes passed through unchanged

This is intentional: xterm.js consumes raw VT100/ANSI byte streams natively. Any framing would require a corresponding parser in the browser — unnecessary complexity.

---

## No Domain Data Model Changes

`GameDomain` data models (`GameState`, `FloorMap`, `EncounterModel`, etc.) are completely unaffected by this feature. The bridge has no visibility into game state.
