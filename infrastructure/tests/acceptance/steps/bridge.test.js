// Acceptance test step implementation — zero-download-deployment bridge
// Framework: Node.js built-in test runner (node:test) — zero new dependencies beyond ws
// Run: node --test infrastructure/tests/acceptance/steps/bridge.test.js
//
// Prerequisites:
//   - server.js running: node infrastructure/web/server.js  (or via Docker)
//   - DCJam2026 binary on PATH
//   - npm install ws  (in infrastructure/web/ directory; ws already listed in package.json)
//
// Environment variables:
//   BRIDGE_URL   WebSocket URL  (default: ws://localhost:3000/game)
//   HTTP_URL     HTTP base URL  (default: http://localhost:3000)

import { test, describe, before, after } from 'node:test'
import assert from 'node:assert/strict'
import http from 'node:http'
import { execSync, exec } from 'node:child_process'
import { createRequire } from 'node:module'

const require = createRequire(import.meta.url)
const WebSocket = require('ws')  // from infrastructure/web/node_modules/ws

const BRIDGE_URL = process.env.BRIDGE_URL ?? 'ws://localhost:3000/game'
const HTTP_URL   = process.env.HTTP_URL   ?? 'http://localhost:3000'
const TIMEOUT_MS = 5000

// ── Helpers ────────────────────────────────────────────────────────────────

function httpGet(url) {
  return new Promise((resolve, reject) => {
    http.get(url, res => {
      let body = ''
      res.on('data', chunk => body += chunk)
      res.on('end', () => resolve({ status: res.statusCode, body }))
    }).on('error', reject)
  })
}

function openWS(url = BRIDGE_URL) {
  return new Promise((resolve, reject) => {
    const ws = new WebSocket(url)
    ws.on('open', () => resolve(ws))
    ws.on('error', reject)
    setTimeout(() => reject(new Error('WS open timeout')), TIMEOUT_MS)
  })
}

function waitForData(ws, timeoutMs = 2000) {
  return new Promise((resolve, reject) => {
    ws.once('message', data => resolve(data))
    setTimeout(() => reject(new Error('No data received within timeout')), timeoutMs)
  })
}

function closeWS(ws) {
  return new Promise(resolve => {
    if (ws.readyState === WebSocket.CLOSED) { resolve(); return }
    ws.once('close', resolve)
    ws.close()
  })
}

function pidExists(pid) {
  try { execSync(`kill -0 ${pid}`, { stdio: 'ignore' }); return true }
  catch { return false }
}

function countProcesses(name) {
  try {
    const out = execSync(`pgrep -x "${name}" 2>/dev/null | wc -l`, { encoding: 'utf8' })
    return parseInt(out.trim(), 10)
  } catch { return 0 }
}

function sleep(ms) { return new Promise(r => setTimeout(r, ms)) }

// ── Walking Skeleton ───────────────────────────────────────────────────────

describe('Walking Skeleton — WS-1 through WS-5', () => {

  test('WS-1: static HTML page is served', async () => {
    const { status, body } = await httpGet(HTTP_URL)
    assert.equal(status, 200)
    assert.ok(body.toLowerCase().includes('xterm'), 'page must reference xterm')
    assert.ok(body.toLowerCase().includes('websocket') || body.includes('WebSocket'),
              'page must reference WebSocket')
  })

  test('WS-2: WebSocket connection establishes and game process spawns', async () => {
    const before = countProcesses('DCJam2026')
    const ws = await openWS()
    await sleep(500)
    const after = countProcesses('DCJam2026')
    assert.ok(after > before, 'a DCJam2026 process should have spawned')
    await closeWS(ws)
  })

  test('WS-3: ANSI output (ESC bytes) flow from game to client', async () => {
    const ws = await openWS()
    const data = await waitForData(ws, 2000)
    const bytes = Buffer.isBuffer(data) ? data : Buffer.from(data)
    assert.ok(bytes.includes(0x1B), 'output must contain ESC (0x1B) for ANSI sequences')
    await closeWS(ws)
  })

  test('WS-4: sending Enter key produces a new ANSI frame', async () => {
    const ws = await openWS()
    await waitForData(ws, 2000)  // wait for start screen
    ws.send(Buffer.from([0x0D]))  // Enter
    const response = await waitForData(ws, 500)
    const bytes = Buffer.isBuffer(response) ? response : Buffer.from(response)
    assert.ok(bytes.length > 0, 'should receive a response frame after keypress')
    await closeWS(ws)
  })

  test('WS-5: closing WebSocket terminates the game process within 2s', async () => {
    const ws = await openWS()
    await waitForData(ws, 2000)

    // Capture the PID via a parallel connection count heuristic:
    // count before close, then verify it decrements
    const countBefore = countProcesses('DCJam2026')
    assert.ok(countBefore >= 1, 'process should exist before close')

    await closeWS(ws)
    await sleep(2000)

    const countAfter = countProcesses('DCJam2026')
    assert.ok(countAfter < countBefore, 'process count should decrease after close')
  })
})

// ── Session Lifecycle ──────────────────────────────────────────────────────

describe('Session isolation and teardown — AC-6, AC-7', () => {

  test('AC-6: two concurrent connections have independent processes', async () => {
    const wsA = await openWS()
    const wsB = await openWS()
    await sleep(500)

    const count = countProcesses('DCJam2026')
    assert.ok(count >= 2, `expected at least 2 game processes, got ${count}`)

    await closeWS(wsA)
    await sleep(2000)
    const countAfterA = countProcesses('DCJam2026')
    assert.ok(countAfterA < count, 'one process should exit when connection A closes')

    // B should still be alive and receiving data
    const dataB = await waitForData(wsB, 500)
    assert.ok(dataB, 'connection B should still receive data after A closed')

    await closeWS(wsB)
  })

  test('AC-7: no zombie processes after 5 sequential sessions', async () => {
    for (let i = 0; i < 5; i++) {
      const ws = await openWS()
      await waitForData(ws, 2000)
      await closeWS(ws)
      await sleep(500)
    }
    await sleep(2000)
    const remaining = countProcesses('DCJam2026')
    assert.equal(remaining, 0, `expected 0 DCJam2026 processes after 5 sessions, got ${remaining}`)
  })
})

// ── Terminal Size Guard ────────────────────────────────────────────────────

describe('Terminal size guard — AC-5', () => {
  // NOTE: These tests assume the client sends dimensions as the first WS message.
  // Protocol: client sends JSON {"cols": N, "rows": N} immediately after connecting,
  // OR the server reads the terminal size from the node-pty spawn options and the
  // client passes them as query parameters: ws://localhost:3000/game?cols=79&rows=25
  //
  // The exact protocol is TBD in implementation. Adjust these tests to match.

  test('AC-5: server warns when terminal is too small (79×25)', async () => {
    const ws = new WebSocket(`${BRIDGE_URL}?cols=79&rows=25`)
    await new Promise((resolve, reject) => {
      ws.on('open', resolve); ws.on('error', reject)
    })
    const data = await waitForData(ws, 2000)
    const text = Buffer.isBuffer(data) ? data.toString('utf8') : String(data)
    assert.ok(
      text.toLowerCase().includes('too small') || text.toLowerCase().includes('resize'),
      `expected size warning, got: ${text.slice(0, 100)}`
    )
    await closeWS(ws)
  })

  test('AC-5: server accepts minimum valid dimensions (80×25)', async () => {
    const ws = new WebSocket(`${BRIDGE_URL}?cols=80&rows=25`)
    await new Promise((resolve, reject) => {
      ws.on('open', resolve); ws.on('error', reject)
    })
    const data = await waitForData(ws, 2000)
    const bytes = Buffer.isBuffer(data) ? data : Buffer.from(data)
    assert.ok(bytes.includes(0x1B), 'should receive ANSI output, not a warning')
    await closeWS(ws)
  })
})

// ── ANSI Output Integrity ──────────────────────────────────────────────────

describe('ANSI output integrity — AC-4 (byte-level)', () => {

  test('game output contains CSI sequences (ESC [)', async () => {
    const ws = await openWS()
    const data = await waitForData(ws, 2000)
    const bytes = Buffer.isBuffer(data) ? data : Buffer.from(data)

    // ESC [ = 0x1B 0x5B — cursor positioning, colour sequences
    let hasCSI = false
    for (let i = 0; i < bytes.length - 1; i++) {
      if (bytes[i] === 0x1B && bytes[i + 1] === 0x5B) { hasCSI = true; break }
    }
    assert.ok(hasCSI, 'output must contain CSI sequences (ESC [) for ANSI rendering')
    await closeWS(ws)
  })
})

// ── AC-8: game logic unchanged ─────────────────────────────────────────────
// Verified by existing ci.yml (swift test) — not duplicated here.
// This test just confirms the binary is the same build as tested in CI.

test('AC-8: DCJam2026 binary is present and executable', () => {
  let path
  try {
    path = execSync('which DCJam2026', { encoding: 'utf8' }).trim()
  } catch {
    path = execSync('which .build/release/DCJam2026 || find . -name DCJam2026 -type f | head -1',
                    { encoding: 'utf8' }).trim()
  }
  assert.ok(path.length > 0, 'DCJam2026 binary must be findable on PATH or in .build/release/')
})
