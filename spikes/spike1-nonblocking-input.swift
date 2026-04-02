#!/usr/bin/env swift
// Spike 1: Non-blocking input + synchronous ~60 Hz game loop
//
// Proves:
//   1. Terminal can be set to raw mode (no echo, no canonical buffering)
//   2. stdin can be made non-blocking via O_NONBLOCK
//   3. A ~60 Hz tick loop runs while reading keypresses without blocking
//
// Run with:  swift spikes/spike1-nonblocking-input.swift
// Quit with: q

#if canImport(Darwin)
import Darwin
#else
import Glibc
#endif
import Foundation

// MARK: - Terminal raw mode

var originalTermios = termios()

func enableRawMode() {
    tcgetattr(STDIN_FILENO, &originalTermios)
    var raw = originalTermios
    // Disable canonical mode (line buffering) and echo
    raw.c_lflag &= ~tcflag_t(ICANON | ECHO)
    tcsetattr(STDIN_FILENO, TCSAFLUSH, &raw)
    // Make stdin non-blocking: read() returns immediately with -1/EAGAIN if no data
    let flags = fcntl(STDIN_FILENO, F_GETFL, 0)
    _ = fcntl(STDIN_FILENO, F_SETFL, flags | O_NONBLOCK)
}

func disableRawMode() {
    tcsetattr(STDIN_FILENO, TCSAFLUSH, &originalTermios)
    let flags = fcntl(STDIN_FILENO, F_GETFL, 0)
    _ = fcntl(STDIN_FILENO, F_SETFL, flags & ~O_NONBLOCK)
}

// MARK: - ANSI helpers

func cls()                       { print("\u{1B}[2J\u{1B}[H", terminator: "") }
func at(_ row: Int, _ col: Int)  { print("\u{1B}[\(row);\(col)H", terminator: "") }
func hideCursor()                { print("\u{1B}[?25l", terminator: "") }
func showCursor()                { print("\u{1B}[?25h", terminator: "") }

// MARK: - Monotonic clock

func nowNs() -> UInt64 {
    var ts = timespec()
    clock_gettime(CLOCK_MONOTONIC, &ts)
    return UInt64(ts.tv_sec) * 1_000_000_000 + UInt64(ts.tv_nsec)
}

// MARK: - Main loop

enableRawMode()
hideCursor()
cls()

var tick       = 0
var lastKey    = "-"
var keyCount   = 0
var dashCount  = 0
var braceCount = 0
var specCount  = 0

let targetFPS: UInt64     = 30
let frameBudgetNs: UInt64 = 1_000_000_000 / targetFPS

// FPS measurement
var fpsWindowStart = nowNs()
var fpsFrameCount  = 0
var measuredFPS    = 0.0

var running = true
while running {
    let frameStart = nowNs()

    // --- Input (non-blocking) ---
    var byte: UInt8 = 0
    if read(STDIN_FILENO, &byte, 1) == 1 {
        let ch = Character(UnicodeScalar(byte))
        lastKey = String(ch)
        keyCount += 1
        switch ch {
        case "1": dashCount  += 1
        case "2": braceCount += 1
        case "3": specCount  += 1
        case "q": running = false
        default:  break
        }
    }

    // --- FPS measurement (update every 30 frames) ---
    fpsFrameCount += 1
    if fpsFrameCount == 30 {
        let windowNs = nowNs() - fpsWindowStart
        measuredFPS = Double(fpsFrameCount) / (Double(windowNs) / 1_000_000_000.0)
        fpsWindowStart = nowNs()
        fpsFrameCount = 0
    }

    // --- Render (cursor-positioned, no full clear = no flicker) ---
    at(1, 1); print("╔══ Spike 1: Non-blocking input + 60 Hz loop ══╗", terminator: "")
    at(2, 1); print("║                                               ║", terminator: "")
    at(3, 1); print("  Tick       : \(tick)          ", terminator: "")
    at(4, 1); print("  FPS        : \(String(format: "%.1f", measuredFPS))    ", terminator: "")
    at(5, 1); print("  Last key   : \(lastKey)        ", terminator: "")
    at(6, 1); print("  Keys total : \(keyCount)       ", terminator: "")
    at(7, 1); print("                                 ", terminator: "")
    at(8, 1); print("  (1) DASH   : \(dashCount)       ", terminator: "")
    at(9, 1); print("  (2) BRACE  : \(braceCount)      ", terminator: "")
    at(10, 1); print("  (3) SPECIAL: \(specCount)       ", terminator: "")
    at(12, 1); print("  Press 1 / 2 / 3 to fire abilities. 'q' to quit.", terminator: "")
    fflush(stdout)

    tick += 1

    // --- Frame rate cap ---
    let elapsed = nowNs() - frameStart
    if elapsed < frameBudgetNs {
        usleep(UInt32((frameBudgetNs - elapsed) / 1000))
    }
}

// --- Teardown ---
showCursor()
disableRawMode()
cls()
at(1, 1)
print("Spike 1 result:")
print("  Ticks run : \(tick)")
print("  Keys total: \(keyCount)  (1=\(dashCount) 2=\(braceCount) 3=\(specCount))")
print("")
if tick > 100 && keyCount > 0 {
    print("PASS — non-blocking input works, loop is viable at ~60 Hz.")
} else if tick > 0 {
    print("PARTIAL — loop ran but confirm key detection worked.")
} else {
    print("FAIL — loop did not run.")
}
print("")
