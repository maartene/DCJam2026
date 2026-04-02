#!/usr/bin/env swift
// Spike 3 v3: Dungeon view — fixed 80x25, one-pass frame write
//
// Key change from v2: every row is built as a complete 80-char string
// (including both borders) and written top-to-bottom in a single pass.
// No separate "chrome" pass. No mixed cursor-positioning.
//
// Run with:  swift spikes/spike3-dungeon-render.swift
// Controls:  ← → arrows cycle depth | q quit

#if canImport(Darwin)
import Darwin
#else
import Glibc
#endif

// MARK: - Layout constants (fixed 80×25)

let COLS = 80                   // terminal width
let ROWS = 25                   // terminal height

// Row indices (1-based, terminal coordinates)
let VIEW_TOP     = 1            // ┌─ dungeon box top border
let VIEW_BOT     = 17           // └─ dungeon box bottom border
let VIEW_H       = VIEW_BOT - VIEW_TOP - 1   // 15 inner rows
let VIEW_W       = COLS - 2                  // 78 inner cols

let STATUS_ROW   = 18
let THOUGHTS_TOP = 19           // ┌─ thoughts box top border
let THOUGHTS_BOT = 23           // └─ thoughts box bottom border
let HINT_ROW     = 24
// row 25 left blank

// MARK: - Terminal

var originalTermios = termios()
// Open /dev/tty as a SEPARATE fd for non-blocking input.
// Critical: do NOT set O_NONBLOCK on STDIN_FILENO — stdin and stdout share
// the same underlying file description on a tty. Making stdin non-blocking
// also makes stdout non-blocking, causing write() to return EAGAIN mid-frame
// and corrupting multi-byte UTF-8 sequences.
var inputFD: Int32 = -1

func enableRawMode() {
    tcgetattr(STDIN_FILENO, &originalTermios)
    var raw = originalTermios
    raw.c_lflag &= ~tcflag_t(ICANON | ECHO)
    tcsetattr(STDIN_FILENO, TCSAFLUSH, &raw)
    // Non-blocking input on a SEPARATE fd — stdout is unaffected
    inputFD = open("/dev/tty", O_RDONLY | O_NONBLOCK)
}
func disableRawMode() {
    tcsetattr(STDIN_FILENO, TCSAFLUSH, &originalTermios)
    if inputFD >= 0 { close(inputFD) }
}

// MARK: - ANSI

let ESC = "\u{1B}"
func esc(_ s: String) -> String { "\(ESC)[\(s)" }
func at(_ r: Int, _ c: Int)    -> String { esc("\(r);\(c)H") }
func hideCursor()               -> String { esc("?25l") }
func showCursor()               -> String { esc("?25h") }
func noWrap()                   -> String { esc("?7l") }
func wrapOn()                   -> String { esc("?7h") }
func cls()                      -> String { esc("2J") + at(1,1) }

let DIM    = esc("2m")
let BOLD   = esc("1m")
let RESET  = esc("0m")
let YELLOW = esc("93m")
let CYAN   = esc("96m")
let WHITE  = esc("97m")

// MARK: - Write

func flush(_ s: String) {
    var bytes = Array(s.utf8)
    var offset = 0
    while offset < bytes.count {
        let n = bytes.withUnsafeBufferPointer { p in
            write(STDOUT_FILENO, p.baseAddress! + offset, bytes.count - offset)
        }
        if n > 0 { offset += n }
        else if n == -1 && errno == EINTR { continue }  // interrupted — retry
        else { break }                                   // real error — give up
    }
}

// MARK: - Timing

func nowNs() -> UInt64 {
    var ts = timespec()
    clock_gettime(CLOCK_MONOTONIC, &ts)
    return UInt64(ts.tv_sec) * 1_000_000_000 + UInt64(ts.tv_nsec)
}

// MARK: - Frame helpers

// Exact-width string: pad with spaces or truncate. Plain chars only.
func exact(_ s: String, _ w: Int) -> String {
    let n = s.count
    if n == w { return s }
    if n  > w { return String(s.prefix(w)) }
    return s + String(repeating: " ", count: w - n)
}

func rep(_ c: String, _ n: Int) -> String { String(repeating: c, count: max(0, n)) }
func hbar(_ n: Int)              -> String { rep("─", n) }

// A dungeon frame: VIEW_H rows, each VIEW_W plain characters wide.
typealias DungeonFrame = [String]

// Build a row that has left-wall-fill|lb| inner content |rb|right-wall-fill
// Total = lw + lb.count + innerW + rb.count + rw = VIEW_W
func wallRow(lw: Int, lb: String, innerW: Int, inner: String, rb: String, rw: Int) -> String {
    rep("▓", lw) + lb + exact(inner, innerW) + rb + rep("▓", rw)
}

// MARK: - Pre-authored dungeon frames

let CEIl0 = rep("▓", VIEW_W)   // ceiling closest
let CEIL1 = rep("▒", VIEW_W)
let CEIL2 = rep("░", VIEW_W)   // ceiling farthest
let FLOOR2 = CEIL2
let FLOOR1 = CEIL1
let FLOOR0 = CEIl0             // floor closest

// Depth-1 aperture: lw=9, rw=9, inner=VIEW_W-9-9-2=58
let D1L=9; let D1R=9; let D1W=VIEW_W-D1L-D1R-2   // 58

// Depth-2 aperture: lw=18, rw=18, inner=VIEW_W-18-18-2=40
let D2L=18; let D2R=18; let D2W=VIEW_W-D2L-D2R-2   // 40

// Depth-3 aperture: lw=27, rw=27, inner=VIEW_W-27-27-2=22
let D3L=27; let D3R=27; let D3W=VIEW_W-D3L-D3R-2   // 22 (must be > 0)

// Depth-2 inner string (what sits inside D1 frame)
func d2top()     -> String { rep(" ", D2L-D1L-1) + "┌" + hbar(D2W) + "┐" + rep(" ", D2R-D1R-1) }
func d2fill()    -> String { rep(" ", D2L-D1L-1) + "│" + rep(" ", D2W) + "│" + rep(" ", D2R-D1R-1) }
func d2bot()     -> String { rep(" ", D2L-D1L-1) + "└" + hbar(D2W) + "┘" + rep(" ", D2R-D1R-1) }

// Depth-3 inner string (what sits inside D2 frame)
func d3top()     -> String { rep(" ", D3L-D2L-1) + "┌" + hbar(D3W) + "┐" + rep(" ", D3R-D2R-1) }
func d3wall()    -> String { rep(" ", D3L-D2L-1) + "│" + rep("▒", D3W) + "│" + rep(" ", D3R-D2R-1) }
func d3bot()     -> String { rep(" ", D3L-D2L-1) + "└" + hbar(D3W) + "┘" + rep(" ", D3R-D2R-1) }

// Wrap depth-3 content inside depth-2 frame for use inside depth-1 frame
func wrapD3(inner: String) -> String {
    rep(" ", D2L-D1L-1) + "│" + inner + "│" + rep(" ", D2R-D1R-1)
}

// ── Frame: wall at depth 3 (long corridor) ───────────────────────────────────
let frameDepth3: DungeonFrame = {
    var f: [String] = []
    f.append(CEIl0)           // row  1
    f.append(CEIL1)           // row  2
    f.append(CEIL2)           // row  3
    // D1 frame top
    f.append(wallRow(lw:D1L, lb:"┌", innerW:D1W, inner:hbar(D1W),     rb:"┐", rw:D1R))
    // D2 frame top inside D1
    f.append(wallRow(lw:D1L, lb:"│", innerW:D1W, inner:d2top(),        rb:"│", rw:D1R))
    // D3 frame top inside D2 inside D1
    f.append(wallRow(lw:D1L, lb:"│", innerW:D1W, inner:wrapD3(inner:d3top()),  rb:"│", rw:D1R))
    // D3 wall fill
    f.append(wallRow(lw:D1L, lb:"│", innerW:D1W, inner:wrapD3(inner:d3wall()), rb:"│", rw:D1R))
    // D3 frame bottom
    f.append(wallRow(lw:D1L, lb:"│", innerW:D1W, inner:wrapD3(inner:d3bot()),  rb:"│", rw:D1R))
    // D2 frame bottom inside D1
    f.append(wallRow(lw:D1L, lb:"│", innerW:D1W, inner:d2bot(),        rb:"│", rw:D1R))
    // D1 frame bottom
    f.append(wallRow(lw:D1L, lb:"└", innerW:D1W, inner:hbar(D1W),     rb:"┘", rw:D1R))
    f.append(FLOOR2)          // row 11
    f.append(FLOOR1)          // row 12
    f.append(FLOOR0)          // row 13
    f.append(FLOOR0)          // row 14
    f.append(FLOOR0)          // row 15
    assert(f.count == VIEW_H, "frameDepth3: \(f.count) rows, expected \(VIEW_H)")
    return f
}()

// ── Frame: wall at depth 2 ────────────────────────────────────────────────────
let frameDepth2: DungeonFrame = {
    var f: [String] = []
    f.append(CEIl0)
    f.append(CEIL1)
    f.append(CEIL2)
    f.append(wallRow(lw:D1L, lb:"┌", innerW:D1W, inner:hbar(D1W),  rb:"┐", rw:D1R))
    f.append(wallRow(lw:D1L, lb:"│", innerW:D1W, inner:d2top(),     rb:"│", rw:D1R))
    f.append(wallRow(lw:D1L, lb:"│", innerW:D1W, inner:d2fill(),    rb:"│", rw:D1R))
    f.append(wallRow(lw:D1L, lb:"│", innerW:D1W, inner:d2fill(),    rb:"│", rw:D1R))
    f.append(wallRow(lw:D1L, lb:"│", innerW:D1W, inner:d2fill(),    rb:"│", rw:D1R))
    f.append(wallRow(lw:D1L, lb:"│", innerW:D1W, inner:d2bot(),     rb:"│", rw:D1R))
    f.append(wallRow(lw:D1L, lb:"└", innerW:D1W, inner:hbar(D1W),  rb:"┘", rw:D1R))
    f.append(FLOOR2)
    f.append(FLOOR1)
    f.append(FLOOR0)
    f.append(FLOOR0)
    f.append(FLOOR0)
    assert(f.count == VIEW_H, "frameDepth2: \(f.count) rows, expected \(VIEW_H)")
    return f
}()

// ── Frame: wall at depth 1 (right in front) ──────────────────────────────────
let frameDepth1: DungeonFrame = {
    let wallFill = rep("▒", D1W)
    var f: [String] = []
    f.append(CEIl0)
    f.append(CEIL1)
    f.append(CEIL2)
    f.append(wallRow(lw:D1L, lb:"┌", innerW:D1W, inner:hbar(D1W),   rb:"┐", rw:D1R))
    f.append(wallRow(lw:D1L, lb:"│", innerW:D1W, inner:wallFill,     rb:"│", rw:D1R))
    f.append(wallRow(lw:D1L, lb:"│", innerW:D1W, inner:wallFill,     rb:"│", rw:D1R))
    f.append(wallRow(lw:D1L, lb:"│", innerW:D1W, inner:wallFill,     rb:"│", rw:D1R))
    f.append(wallRow(lw:D1L, lb:"│", innerW:D1W, inner:wallFill,     rb:"│", rw:D1R))
    f.append(wallRow(lw:D1L, lb:"│", innerW:D1W, inner:wallFill,     rb:"│", rw:D1R))
    f.append(wallRow(lw:D1L, lb:"└", innerW:D1W, inner:hbar(D1W),   rb:"┘", rw:D1R))
    f.append(FLOOR2)
    f.append(FLOOR1)
    f.append(FLOOR0)
    f.append(FLOOR0)
    f.append(FLOOR0)
    assert(f.count == VIEW_H, "frameDepth1: \(f.count) rows, expected \(VIEW_H)")
    return f
}()

// ── Frame: solid wall (depth 0) ───────────────────────────────────────────────
let frameDepth0: DungeonFrame = {
    let solid = rep("▓", VIEW_W)
    let f = [String](repeating: solid, count: VIEW_H)
    assert(f.count == VIEW_H)
    return f
}()

let frames     = [frameDepth3, frameDepth2, frameDepth1, frameDepth0]
let frameNames = ["depth 3 — long corridor", "depth 2", "depth 1 — wall close", "depth 0 — face to stone"]

// MARK: - Full-frame renderer (one pass, top to bottom)

func buildFrame(idx: Int, tick: Int, thoughts: [String]) -> String {
    let f = frames[idx]
    var rows = [String]()
    rows.reserveCapacity(ROWS)

    // Row 1: dungeon box top border
    rows.append("┌" + hbar(COLS-2) + "┐")

    // Rows 2-16: dungeon view (with borders)
    for viewRow in f {
        rows.append("│" + viewRow + "│")
    }

    // Row 17: dungeon box bottom border
    rows.append("└" + hbar(COLS-2) + "┘")

    // Row 18: status (plain, no ANSI for now to isolate rendering)
    let status = "  HP [=========.] 100%  EGG [?]  (1)DASH [2](cd= 0s)  (2)BRACE  (3)SPEC[    ]"
    rows.append(exact(status, COLS))

    // Row 19: thoughts box top border
    rows.append("┌─Thoughts" + hbar(COLS-11) + "┐")

    // Rows 20-22: thoughts content
    for i in 0..<3 {
        let t = i < thoughts.count ? "  " + thoughts[i] : ""
        rows.append("│" + exact(t, COLS-2) + "│")
    }

    // Row 23: thoughts bottom border
    rows.append("└" + hbar(COLS-2) + "┘")

    // Row 24: hint (tick counter proves 30 Hz loop is running continuously)
    let hint = "  <- -> cycle depth  |  \(frameNames[idx])  |  tick:\(tick)  |  q: quit"
    rows.append(exact(hint, COLS))

    // Row 25: blank
    rows.append(exact("", COLS))

    assert(rows.count == ROWS, "Expected \(ROWS) rows, got \(rows.count)")

    // Build output: cursor to (1,1), write each row at its absolute position.
    var buf = at(1, 1)
    for (i, row) in rows.enumerated() {
        buf += at(i + 1, 1) + row
    }
    return buf
}

// MARK: - Main

enableRawMode()
flush(hideCursor() + noWrap() + cls())

let thoughts = [
    "Five floors between me and the sky.",
    "Find the egg. Then the exit.",
    "Move.",
]

var frameIdx = 0
var tick     = 0
let frameBudget: UInt64 = 1_000_000_000 / 30
var running = true

while running {
    let t0 = nowNs()

    // Input
    var b: UInt8 = 0
    if read(inputFD, &b, 1) == 1 {
        if b == 0x1B {
            var b1: UInt8 = 0, b2: UInt8 = 0
            _ = read(STDIN_FILENO, &b1, 1)
            _ = read(STDIN_FILENO, &b2, 1)
            if b1 == 0x5B {
                if b2 == 0x44 { frameIdx = max(0, frameIdx - 1) }               // ←
                if b2 == 0x43 { frameIdx = min(frames.count - 1, frameIdx + 1) } // →
            }
        } else if b == UInt8(ascii: "q") {
            running = false
        }
    }

    if running { flush(buildFrame(idx: frameIdx, tick: tick, thoughts: thoughts)) }
    tick += 1

    let elapsed = nowNs() - t0
    if elapsed < frameBudget { usleep(UInt32((frameBudget - elapsed) / 1000)) }
}

flush(showCursor() + wrapOn() + cls() + at(1,1))
disableRawMode()
print("Spike 3 done.")
