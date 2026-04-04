// server.js — Node.js HTTP + WebSocket server for zero-download-deployment bridge
// Step 01-02: WebSocket listener added; spawns DCJam2026 via node-pty per connection.
// Usage: node server.js
// Environment: PORT (default 3000), GAME_BINARY (default 'DCJam2026')

import http from 'node:http'
import fs from 'node:fs'
import path from 'node:path'
import { fileURLToPath } from 'node:url'
import { createRequire } from 'node:module'
const require = createRequire(import.meta.url)
const { WebSocketServer } = require('ws')
const { spawn } = require('node-pty')

const __dirname = path.dirname(fileURLToPath(import.meta.url))
const PORT = parseInt(process.env.PORT ?? '3000', 10)
const GAME_BINARY = process.env.GAME_BINARY ?? 'DCJam2026'
const INDEX_HTML = path.join(__dirname, 'index.html')

const server = http.createServer((req, res) => {
  if (req.method === 'GET' && req.url === '/') {
    fs.readFile(INDEX_HTML, (err, data) => {
      if (err) {
        res.writeHead(500, { 'Content-Type': 'text/plain' })
        res.end('Internal Server Error')
        return
      }
      res.writeHead(200, { 'Content-Type': 'text/html; charset=utf-8' })
      res.end(data)
    })
    return
  }

  res.writeHead(404, { 'Content-Type': 'text/plain' })
  res.end('Not Found')
})

/** @type {Map<import('ws').WebSocket, import('node-pty').IPty>} */
const sessions = new Map()

const wss = new WebSocketServer({ server, path: '/game' })

wss.on('connection', (ws, req) => {
  const { searchParams } = new URL(req.url, 'http://localhost')
  const cols = parseInt(searchParams.get('cols') ?? '80', 10)
  const rows = parseInt(searchParams.get('rows') ?? '25', 10)

  if (cols < 80 || rows < 25) {
    ws.send('Terminal too small. Please resize to at least 80x25.')
    ws.close()
    return
  }

  let pty
  try {
    pty = spawn(GAME_BINARY, [], {
      name: 'xterm-256color',
      cols,
      rows,
      cwd: process.cwd(),
      env: process.env,
    })
  } catch (err) {
    console.error('Failed to spawn game process:', err.message)
    ws.close()
    return
  }

  sessions.set(ws, pty)

  pty.onData((data) => {
    if (ws.readyState === ws.OPEN) {
      ws.send(data)
    }
  })

  ws.on('message', (data) => {
    pty.write(data)
  })

  ws.on('close', () => {
    const session = sessions.get(ws)
    if (session) {
      session.kill()
      sessions.delete(ws)
    }
  })

  ws.on('error', (err) => {
    console.error('WebSocket error:', err.message)
    const session = sessions.get(ws)
    if (session) {
      session.kill()
      sessions.delete(ws)
    }
  })

  pty.onExit(() => {
    sessions.delete(ws)
    if (ws.readyState === ws.OPEN || ws.readyState === ws.CONNECTING) {
      ws.close()
    }
  })
})

server.listen(PORT, () => {
  console.log(`Bridge server listening on http://localhost:${PORT}`)
})
