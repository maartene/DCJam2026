# Walking Skeleton — zero-download-deployment

## Definition

> A judge opens the URL, the start screen renders in their browser, they press a key, the game responds — all in browser.

## Stories (WS-1 to WS-5)

| # | Story | Acceptance test | Order |
|---|---|---|---|
| WS-1 | Static HTML page with xterm.js served | `walking-skeleton.feature` Scenario 1 | 1st |
| WS-2 | WebSocket connects, game process spawns | `walking-skeleton.feature` Scenario 2 | 2nd |
| WS-3 | ANSI output pipes to client | `walking-skeleton.feature` Scenario 3 | 3rd |
| WS-4 | Keypress reaches game and game responds | `walking-skeleton.feature` Scenario 4 | 4th |
| WS-5 | Tab close terminates game process | `walking-skeleton.feature` Scenario 5 | 5th |

## Implementation Order for DELIVER

Implement WS-1 through WS-5 in order. Each story has a passing test before moving to the next.

1. **WS-1**: Create `web/index.html` + serve it from `web/server.js` (`http` module)
2. **WS-2**: Add WebSocket server (`ws`) to `server.js`; spawn `DCJam2026` via `node-pty` on connection
3. **WS-3**: Pipe PTY stdout → `ws.send()` 
4. **WS-4**: Pipe `ws.message` → PTY stdin write
5. **WS-5**: On `ws.close` → `pty.kill('SIGTERM')`

After WS-5 passes: the walking skeleton is complete. All other milestone features build on top.
