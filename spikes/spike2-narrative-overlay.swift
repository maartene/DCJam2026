#!/usr/bin/env swift
// Spike 2: Full-screen narrative overlay (v2)
//
// Fixes over v1:
//   - Atomic frame writes (single write() syscall = no flicker)
//   - Auto-wrap disabled (lines at terminal edge no longer corrupt layout)
//   - Centering uses plain/styled split (no broken ANSI regex)
//
// Run with:  swift spikes/spike2-narrative-overlay.swift
// Controls:  e = egg found overlay | x = exit overlay | q = quit
//            any key dismisses an overlay

#if canImport(Darwin)
import Darwin
#else
import Glibc
#endif
import Foundation

// MARK: - Terminal setup

var originalTermios = termios()

func enableRawMode() {
    tcgetattr(STDIN_FILENO, &originalTermios)
    var raw = originalTermios
    raw.c_lflag &= ~tcflag_t(ICANON | ECHO)
    tcsetattr(STDIN_FILENO, TCSAFLUSH, &raw)
    let flags = fcntl(STDIN_FILENO, F_GETFL, 0)
    _ = fcntl(STDIN_FILENO, F_SETFL, flags | O_NONBLOCK)
}

func disableRawMode() {
    tcsetattr(STDIN_FILENO, TCSAFLUSH, &originalTermios)
    let flags = fcntl(STDIN_FILENO, F_GETFL, 0)
    _ = fcntl(STDIN_FILENO, F_SETFL, flags & ~O_NONBLOCK)
}

// MARK: - ANSI constants

let ESC = "\u{1B}"
let reset          = "\(ESC)[0m"
let bold           = "\(ESC)[1m"
let dim            = "\(ESC)[2m"
let fgYellow       = "\(ESC)[33m"
let fgCyan         = "\(ESC)[36m"
let fgBrightYellow = "\(ESC)[93m"
let fgBrightCyan   = "\(ESC)[96m"
let fgBrightWhite  = "\(ESC)[97m"

// MARK: - ANSI helpers (write to buffer, not stdout)

func esc_cls()                      -> String { "\(ESC)[2J\(ESC)[H" }
func esc_at(_ r: Int, _ c: Int)     -> String { "\(ESC)[\(r);\(c)H" }
func esc_hideCursor()               -> String { "\(ESC)[?25l" }
func esc_showCursor()               -> String { "\(ESC)[?25h" }
func esc_noWrap()                   -> String { "\(ESC)[?7l" }   // disable auto-wrap
func esc_wrapOn()                   -> String { "\(ESC)[?7h" }   // restore auto-wrap

// MARK: - Atomic frame write

func flush(_ buf: String) {
    buf.withCString { ptr in
        _ = write(STDOUT_FILENO, ptr, strlen(ptr))
    }
}

// MARK: - Terminal size

func termSize() -> (rows: Int, cols: Int) {
    var ws = winsize()
    _ = ioctl(STDOUT_FILENO, TIOCGWINSZ, &ws)
    return (ws.ws_row > 0 ? Int(ws.ws_row) : 24,
            ws.ws_col > 0 ? Int(ws.ws_col) : 80)
}

// MARK: - Centering (plain text for width, styled for output)

func centered(plain: String, styled: String, width: Int) -> String {
    let pad = max(0, (width - plain.count) / 2)
    return String(repeating: " ", count: pad) + styled
}

// MARK: - Timing

func nowNs() -> UInt64 {
    var ts = timespec()
    clock_gettime(CLOCK_MONOTONIC, &ts)
    return UInt64(ts.tv_sec) * 1_000_000_000 + UInt64(ts.tv_nsec)
}

// MARK: - Fake dungeon layout

func hline(_ ch: String, count: Int) -> String { String(repeating: ch, count: max(0, count)) }

// Draw a box using explicit cursor positioning (no inline appending).
// This avoids right-wall placement bugs from inline string building.
func drawBox(into buf: inout String, top: Int, left: Int, bottom: Int, right: Int) {
    guard right > left + 1, bottom > top else { return }
    let inner = right - left - 1
    buf += esc_at(top,    left) + "┌" + hline("─", count: inner) + "┐"
    for row in (top + 1)..<bottom {
        buf += esc_at(row, left) + "│"
        buf += esc_at(row, right) + "│"
    }
    buf += esc_at(bottom, left) + "└" + hline("─", count: inner) + "┘"
}

func buildDungeonFrame(tick: Int, thoughts: [String]) -> String {
    let (rows, cols) = termSize()
    let viewRows    = max(6, rows - 8)   // viewport height
    let statusRow   = viewRows + 1
    let thoughtsTop = statusRow + 2

    var buf = esc_cls()

    // --- 3D view: nested corridor boxes ---
    // Each box is drawn with explicit cursor positioning — no inline wall math.
    drawBox(into: &buf, top: 1,  left: 1,  bottom: viewRows,     right: cols)
    drawBox(into: &buf, top: 2,  left: 4,  bottom: viewRows - 1, right: cols - 3)
    drawBox(into: &buf, top: 3,  left: 8,  bottom: viewRows - 2, right: cols - 7)
    drawBox(into: &buf, top: 4,  left: 13, bottom: viewRows - 3, right: cols - 12)

    // --- Status line ---
    buf += esc_at(statusRow, 1)
    buf += "\(fgBrightWhite)HP [\(fgBrightYellow)=========-\(fgBrightWhite)] 90%\(reset)"
    buf += "  EGG \(fgYellow)[?]\(reset)"
    buf += "  \(bold)(1)DASH\(reset) [\(fgBrightCyan)2\(reset)](cd=0s)"
    buf += "  \(bold)(2)BRACE\(reset)"
    buf += "  \(bold)(3)SPEC\(reset) \(fgBrightYellow)[    ]\(reset)"

    // --- Thoughts panel ---
    drawBox(into: &buf, top: thoughtsTop, left: 1, bottom: thoughtsTop + 4, right: cols)
    buf += esc_at(thoughtsTop, 3) + "\(bold)Thoughts\(reset)"
    for i in 0..<3 {
        let line = i < thoughts.count ? thoughts[i] : ""
        buf += esc_at(thoughtsTop + 1 + i, 3) + "\(dim)\(line)\(reset)"
    }
    buf += esc_at(thoughtsTop + 5, 1) + "\(dim)  (e) egg found · (x) exit · (q) quit\(reset)"

    return buf
}

// MARK: - Overlays

func waitForKey() {
    var byte: UInt8 = 0
    while read(STDIN_FILENO, &byte, 1) != 1 { usleep(16_000) }
}

func showEggOverlay() {
    let (rows, cols) = termSize()

    let lines: [(plain: String, styled: String)] = [
        ("", ""),
        ("~ My egg. ~",          "\(fgBrightYellow)\(bold)~ My egg. ~\(reset)"),
        ("",                      ""),
        ("     .-.     ",         "\(fgYellow)     .-.     \(reset)"),
        ("    /   \\    ",         "\(fgYellow)    /   \\    \(reset)"),
        ("   | o o |   ",         "\(fgYellow)   | o o |   \(reset)"),
        ("   |  ^  |   ",         "\(fgYellow)   |  ^  |   \(reset)"),
        ("    \\___/    ",         "\(fgYellow)    \\___/    \(reset)"),
        ("",                      ""),
        ("Warm. Alive. Still here.",    "\(fgBrightWhite)Warm. Alive. Still here.\(reset)"),
        ("",                      ""),
        ("\"They almost had you. Almost.\"", "\(dim)\"They almost had you. Almost.\"\(reset)"),
        ("",                      ""),
        ("[ press any key ]",     "\(dim)[ press any key ]\(reset)"),
    ]

    let startRow = max(1, (rows - lines.count) / 2)
    var buf = esc_cls()
    for (i, line) in lines.enumerated() {
        buf += esc_at(startRow + i, 1)
        buf += centered(plain: line.plain, styled: line.styled, width: cols)
    }
    flush(buf)
    waitForKey()
}

func showExitOverlay() {
    let (rows, cols) = termSize()

    let lines: [(plain: String, styled: String)] = [
        ("", ""),
        ("The sky.",              "\(fgBrightCyan)\(bold)The sky.\(reset)"),
        ("Open. Endless. Yours.", "\(fgCyan)Open. Endless. Yours.\(reset)"),
        ("", ""),
        ("       *    .  *       .        ",  "\(fgBrightWhite)       *    .  *       .        \(reset)"),
        ("  .         .              .    ",  "\(fgBrightWhite)  .         .              .    \(reset)"),
        ("      .    *       .            ",  "\(fgBrightWhite)      .    *       .            \(reset)"),
        ("  *        .    .       *       ",  "\(fgBrightWhite)  *        .    .       *       \(reset)"),
        ("", ""),
        ("\"Home is a long flight from here.", "\(fgBrightWhite)\"Home is a long flight from here.\(reset)"),
        (" But you are free.\"",              "\(fgBrightWhite) But you are free.\"\(reset)"),
        ("", ""),
        ("[ press any key ]",     "\(dim)[ press any key ]\(reset)"),
    ]

    let startRow = max(1, (rows - lines.count) / 2)
    var buf = esc_cls()
    for (i, line) in lines.enumerated() {
        buf += esc_at(startRow + i, 1)
        buf += centered(plain: line.plain, styled: line.styled, width: cols)
    }
    flush(buf)
    waitForKey()
}

// MARK: - Main

enableRawMode()
flush(esc_hideCursor() + esc_noWrap())

var tick     = 0
var thoughts = ["\"The stone is cold beneath my claws.\"",
                "\"Five floors. Then light.\""]

let frameBudgetNs: UInt64 = 1_000_000_000 / 30

var running = true
while running {
    let frameStart = nowNs()

    var byte: UInt8 = 0
    if read(STDIN_FILENO, &byte, 1) == 1 {
        switch Character(UnicodeScalar(byte)) {
        case "e":
            showEggOverlay()
            thoughts = ["\"Safe. You are safe now, little one.\"",
                        "\"Now — the exit.\""]
        case "x":
            showExitOverlay()
            running = false
        case "q":
            running = false
        default: break
        }
    }

    if running {
        flush(buildDungeonFrame(tick: tick, thoughts: thoughts))
    }

    tick += 1
    let elapsed = nowNs() - frameStart
    if elapsed < frameBudgetNs { usleep(UInt32((frameBudgetNs - elapsed) / 1000)) }
}

flush(esc_showCursor() + esc_wrapOn() + esc_cls() + esc_at(1, 1))
disableRawMode()
print("Spike 2 complete. \(tick) frames rendered.")
