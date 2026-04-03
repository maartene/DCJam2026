import Testing
@testable import DCJam2026
@testable import GameDomain

// Test Budget: 2 behaviors × 2 = 4 unit tests max
//   Behavior 1: \e[40m emitted before first dungeon frame line write
//   Behavior 2: \e[0m emitted after last dungeon frame line, before any row-17+ write

private let ansiBlackBg = "\u{1B}[40m"
private let ansiResetCode = "\u{1B}[0m"

@Suite struct `Renderer — Graphics Pass: dark background for dungeon view zone` {

    // ACCEPTANCE TEST: full render() call in dungeon mode
    // \e[40m must appear before the first dungeon frame line write (row 2, col 2)
    // \e[0m must appear after the last dungeon frame line write (row 16)
    // No write at row 17+ may contain \e[40m
    @Test func `renderDungeon emits black background before frame lines and reset after`() {
        let spy = TUIOutputSpy()
        let renderer = Renderer(output: spy)
        let state = GameState.initial(config: .default).withScreenMode(.dungeon)
        renderer.render(state)

        let allWrites = spy.entries

        // Find the index of the write containing \e[40m
        guard let bgIndex = allWrites.firstIndex(where: { $0.string.contains(ansiBlackBg) }) else {
            Issue.record("Expected \(ansiBlackBg) to be written, but it was never emitted")
            return
        }

        // Find index of the first dungeon frame line (row 2, col 2)
        guard let firstFrameIndex = allWrites.firstIndex(where: { $0.row == 2 && $0.col == 2 }) else {
            Issue.record("Expected a dungeon frame write at row 2 col 2, but none found")
            return
        }

        // \e[40m must come before the first frame line
        #expect(bgIndex < firstFrameIndex,
                "\(ansiBlackBg) must be emitted before first dungeon frame line (row 2), but bgIndex=\(bgIndex) firstFrameIndex=\(firstFrameIndex)")

        // Find index of the last dungeon frame line (row 16, col 2)
        let lastFrameIndex = allWrites.lastIndex(where: {
            (2...16).contains($0.row) && $0.col == 2 && !$0.string.contains(ansiBlackBg)
        }) ?? firstFrameIndex

        // Find the reset emitted by renderDungeon (after last frame line, before row 17+)
        let resetAfterDungeon = allWrites.enumerated().first(where: { idx, entry in
            idx > lastFrameIndex && entry.string.contains(ansiResetCode)
        })
        #expect(resetAfterDungeon != nil,
                "\(ansiResetCode) must be emitted after the last dungeon frame line (row 16)")

        // No write at row 17+ may contain \e[40m
        let illegalBgWrites = allWrites.filter { $0.row >= 17 && $0.string.contains(ansiBlackBg) }
        #expect(illegalBgWrites.isEmpty,
                "\(ansiBlackBg) must not appear in writes at row 17+, found: \(illegalBgWrites.map { "row \($0.row): \($0.string)" })")

        // Minimap writes (col 61-79) must not contain \e[40m
        let minimapBgWrites = allWrites.filter { $0.col >= 61 && $0.string.contains(ansiBlackBg) }
        #expect(minimapBgWrites.isEmpty,
                "\(ansiBlackBg) must not appear in minimap writes (cols 61+), found: \(minimapBgWrites.map { "col \($0.col): \($0.string)" })")
    }

    // UNIT TEST 1: \e[40m is emitted as the very first write in renderDungeon sequence
    @Test func `renderDungeon emits black background code before any frame content`() {
        let spy = TUIOutputSpy()
        let renderer = Renderer(output: spy)
        let state = GameState.initial(config: .default).withScreenMode(.dungeon)
        renderer.render(state)

        // All writes for the dungeon region start at row 2+ (after chrome at row 1)
        // The \e[40m must appear before any write at rows 2-16 col 2
        let dungeonFrameWrites = spy.entries.filter { (2...16).contains($0.row) && $0.col == 2 }
        let allWrites = spy.entries

        guard let bgIndex = allWrites.firstIndex(where: { $0.string.contains(ansiBlackBg) }) else {
            Issue.record("No \(ansiBlackBg) found in any write")
            return
        }
        guard let firstFrameIndex = allWrites.firstIndex(where: { entry in
            dungeonFrameWrites.contains(where: { frame in
                frame.row == entry.row && frame.col == entry.col && frame.string == entry.string
            })
        }) else {
            Issue.record("No dungeon frame writes found at rows 2-16 col 2")
            return
        }

        #expect(bgIndex < firstFrameIndex,
                "Background code index \(bgIndex) must precede first frame write index \(firstFrameIndex)")
    }

    // UNIT TEST 2: \e[0m reset is emitted after last dungeon frame write
    @Test func `renderDungeon emits reset after last frame line`() {
        let spy = TUIOutputSpy()
        let renderer = Renderer(output: spy)
        let state = GameState.initial(config: .default).withScreenMode(.dungeon)
        renderer.render(state)

        let allWrites = spy.entries

        // Last frame line is at row 16, col 2
        guard let lastRow16Index = allWrites.lastIndex(where: { $0.row == 16 && $0.col == 2 }) else {
            Issue.record("No write at row 16 col 2 found")
            return
        }

        // Find a reset write that comes after it (from renderDungeon, not colored() helpers)
        // We look for a write whose string IS \e[0m (standalone reset, not embedded in colored())
        let standaloneResetAfterLastFrame = allWrites.enumerated().first(where: { idx, entry in
            idx > lastRow16Index && entry.string == ansiResetCode
        })
        #expect(standaloneResetAfterLastFrame != nil,
                "A standalone \(ansiResetCode) write must follow the last dungeon frame line at row 16")
    }
}

// MARK: - Step 01-02: Depth-graded ANSI 16-color foreground on dungeon frames
// Test Budget: 3 behaviors × 2 = 6 unit tests max
//   Behavior 1: depth=0 dungeon lines contain \e[97m and end with \e[0m
//   Behavior 2: depth=1 dungeon lines contain \e[37m
//   Behavior 3: depth=2/3 dungeon lines contain \e[90m

private let ansiBrightWhiteFg = "\u{1B}[97m"
private let ansiStandardWhite  = "\u{1B}[37m"
private let ansiDarkGrayFg     = "\u{1B}[90m"
private let ansiBlackBgCode    = ansiBlackBg

/// Helpers to build a minimal GameState for a given depth key
/// Depth = 0: player is standing right in front of a wall (adjacentWall in dungeon key)
/// The DungeonFrameKey.depth is derived in dungeonFrameKey(). We test by directly
/// checking what renderDungeon() writes for the states that exercise each depth key.

@Suite("Renderer — Graphics Pass: depth-graded foreground color on dungeon frames")
struct DepthGradedColorTests {

    // ACCEPTANCE TEST (Behavior 1): depth=0 frame lines contain \e[97m and end with \e[0m
    @Test("depth=0 frame lines contain bright-white foreground code and reset")
    func depth0LinesContainBrightWhiteAndReset() {
        // Use a GameState whose position/facing yields depth=0 (player faces a wall directly)
        let spy = TUIOutputSpy()
        let renderer = Renderer(output: spy, supports256Color: false)
        let state = makeDepthState(depth: 0)
        renderer.render(state)

        let dungeonLineWrites = spy.entries.filter { (2...16).contains($0.row) && $0.col == 2 }
        #expect(!dungeonLineWrites.isEmpty, "Expected dungeon frame line writes at rows 2-16 col 2")
        for entry in dungeonLineWrites {
            #expect(entry.string.contains(ansiBrightWhiteFg),
                    "depth=0 line at row \(entry.row) should contain \(ansiBrightWhiteFg), got: \(entry.string)")
            #expect(entry.string.hasSuffix(ansiResetCode),
                    "depth=0 line at row \(entry.row) should end with \(ansiResetCode), got: \(entry.string)")
        }
    }

    // ACCEPTANCE TEST (Behavior 2): depth=1 frame lines contain \e[37m
    @Test("depth=1 frame lines contain standard-white foreground code")
    func depth1LinesContainStandardWhite() {
        let spy = TUIOutputSpy()
        let renderer = Renderer(output: spy, supports256Color: false)
        let state = makeDepthState(depth: 1)
        renderer.render(state)

        let dungeonLineWrites = spy.entries.filter { (2...16).contains($0.row) && $0.col == 2 }
        #expect(!dungeonLineWrites.isEmpty, "Expected dungeon frame line writes at rows 2-16 col 2")
        for entry in dungeonLineWrites {
            #expect(entry.string.contains(ansiStandardWhite),
                    "depth=1 line at row \(entry.row) should contain \(ansiStandardWhite), got: \(entry.string)")
        }
    }

    // ACCEPTANCE TEST (Behavior 3): depth=2 frame lines contain \e[90m
    @Test("depth=2 frame lines contain dark-gray foreground code")
    func depth2LinesContainDarkGray() {
        let spy = TUIOutputSpy()
        let renderer = Renderer(output: spy, supports256Color: false)
        let state = makeDepthState(depth: 2)
        renderer.render(state)

        let dungeonLineWrites = spy.entries.filter { (2...16).contains($0.row) && $0.col == 2 }
        #expect(!dungeonLineWrites.isEmpty, "Expected dungeon frame line writes at rows 2-16 col 2")
        for entry in dungeonLineWrites {
            #expect(entry.string.contains(ansiDarkGrayFg),
                    "depth=2 line at row \(entry.row) should contain \(ansiDarkGrayFg), got: \(entry.string)")
        }
    }

}

/// Returns a GameState whose dungeon frame depth equals the requested depth.
/// depth=0: player at y=1 (one step into corridor, wall directly in front)
/// depth=1: player at y=2
/// depth=2: player at y=3
private func makeDepthState(depth: Int) -> GameState {
    // The default floor has the staircase far away; player starts at (7,0) facing north.
    // Moving 'y' forward increases corridor depth in dungeonFrameKey.
    // depth is determined by how many open cells are ahead of the player.
    // depth=0: wall directly ahead (y close to staircase or wall)
    // We use initial GameState but override playerPosition to engineer the depth.
    var state = GameState.initial(config: .default).withScreenMode(.dungeon)
    // depth=0 → player at position that creates depth-0 key.
    // From FloorGenerator, staircase is at y=6; walls are beyond that.
    // Player at y=6 facing north = wall 1 step ahead = depth 0.
    // Player at y=5 facing north = 1 open cell ahead = depth 1.
    // Player at y=4 facing north = 2 open cells ahead = depth 2/3.
    switch depth {
    case 0: state = state.withPlayerPosition(Position(x: 7, y: 6))
    case 1: state = state.withPlayerPosition(Position(x: 7, y: 5))
    case 2: state = state.withPlayerPosition(Position(x: 7, y: 4))
    default: state = state.withPlayerPosition(Position(x: 7, y: 3))
    }
    return state
}

// MARK: - Step 01-03: Depth-0 wall face character density
// Test Budget: 2 behaviors × 2 = 4 unit tests
//   Behavior 1: depth-0 rows 4–8 contain the dense alternating wall pattern
//   Behavior 2: density ordering depth-0 >= depth-1 > depth-2

private func d0Frame() -> [String] {
    buildFrameTable()[DungeonFrameKey(depth: 0, nearLeft: false, nearRight: false, farLeft: false, farRight: false)]!
}

private func d1Frame() -> [String] {
    buildFrameTable()[DungeonFrameKey(depth: 1, nearLeft: false, nearRight: false, farLeft: false, farRight: false)]!
}

private func d2Frame() -> [String] {
    buildFrameTable()[DungeonFrameKey(depth: 2, nearLeft: false, nearRight: false, farLeft: false, farRight: false)]!
}

private func d3Frame() -> [String] {
    buildFrameTable()[DungeonFrameKey(depth: 3, nearLeft: false, nearRight: false, farLeft: false, farRight: false)]!
}

@Suite("Depth-0 frame wall face uses dense alternating chars denser than depth-1")
struct DepthZeroWallDensityTests {

    // ACCEPTANCE TEST (Behavior 1): rows 4–8 contain String(repeating: "▓▒", count: 25)
    @Test("rows 4-8 contain dense alternating wall string")
    func rowsFourToEightContainDenseAlternatingWall() {
        let frame = d0Frame()
        let expectedStone = String(repeating: "▓▒", count: 25)
        for index in 4...8 {
            #expect(frame[index].contains(expectedStone),
                    "Row \(index) should contain the dense wall pattern but was: \(frame[index])")
        }
    }

    // ACCEPTANCE TEST (Behavior 2): density ordering depth-0 >= depth-1 > depth-2
    @Test("depth-0 density >= depth-1 density > depth-2 density in rows 4-8")
    func densityOrderingAcrossDepths() {
        func shadeCount(_ frame: [String]) -> Int {
            frame[4...8].reduce(0) { total, row in
                total + row.unicodeScalars.filter { $0 == "\u{2593}" || $0 == "\u{2592}" || $0 == "\u{2591}" }.count
            }
        }

        let countD0 = shadeCount(d0Frame())
        let countD1 = shadeCount(d1Frame())
        let countD2 = shadeCount(d2Frame())

        #expect(countD0 >= countD1,
                "depth-0 shade count (\(countD0)) should be >= depth-1 (\(countD1))")
        #expect(countD1 > countD2,
                "depth-1 shade count (\(countD1)) should be > depth-2 (\(countD2))")
    }

    // UNIT TEST: frame structure preserved — 15 rows, each 58 chars
    @Test("frame_d0_none returns 15 rows each 58 chars wide")
    func frameStructurePreserved() {
        let frame = d0Frame()
        #expect(frame.count == 15, "Expected 15 rows, got \(frame.count)")
        for (index, row) in frame.enumerated() {
            #expect(row.count == 58,
                    "Row \(index) has \(row.count) chars, expected 58")
        }
    }

    // UNIT TEST: depth-1/2/3 frames are unchanged — verify ▓░ / ░▓ patterns in depth-1
    @Test("depth-1 brick patterns unchanged after depth-0 fix")
    func depth1BrickPatternsUnchanged() {
        let d1 = d1Frame()
        let brickA = String(repeating: "▓░", count: 25)
        let brickB = String(repeating: "░▓", count: 25)
        #expect(d1.count == 15, "depth-1 frame should have 15 rows")
        #expect(d1[4].contains(brickA), "depth-1 row 4 should contain brickA pattern ▓░ repeated")
        #expect(d1[5].contains(brickB), "depth-1 row 5 should contain brickB pattern ░▓ repeated")
        #expect(d1[7].contains(brickB), "depth-1 row 7 should contain brickB pattern ░▓ repeated")
        #expect(d1[8].contains(brickA), "depth-1 row 8 should contain brickA pattern ▓░ repeated")
    }
}

// MARK: - Step 01-04: 256-color grayscale depth ramp with 16-color fallback
// Test Budget: 3 behaviors × 2 = 6 unit tests max
//   Behavior 1: 256-color path emits correct grayscale codes per depth (4 depths, parametrized)
//   Behavior 2: 16-color fallback path emits correct 16-color codes
//   Behavior 3: ansi256Fg helper returns correct escape string

private let ansi256Depth0 = "\u{1B}[38;5;252m"  // near-white
private let ansi256Depth1 = "\u{1B}[38;5;249m"  // light gray
private let ansi256Depth2 = "\u{1B}[38;5;244m"  // medium gray
private let ansi256Depth3 = "\u{1B}[38;5;240m"  // dark-but-readable gray
private let ansi256Prefix  = "\u{1B}[38;5;"

@Suite("Renderer — Graphics Pass 01-04: 256-color grayscale depth ramp")
struct ColorDepth256Tests {

    // ACCEPTANCE TEST (Behavior 1): 256-color path emits correct grayscale code for each depth
    @Test("256-color terminal uses grayscale codes per depth",
          arguments: [
            (0, "\u{1B}[38;5;252m"),
            (1, "\u{1B}[38;5;249m"),
            (2, "\u{1B}[38;5;244m"),
            (3, "\u{1B}[38;5;240m"),
          ])
    func uses256ColorGrayscaleCodeForDepth(depth: Int, expectedCode: String) {
        let spy = TUIOutputSpy()
        let renderer = Renderer(output: spy, supports256Color: true)
        let state = makeDepthState(depth: depth)
        renderer.render(state)

        let dungeonLineWrites = spy.entries.filter { (2...16).contains($0.row) && $0.col == 2 }
        #expect(!dungeonLineWrites.isEmpty, "Expected dungeon frame line writes at rows 2-16 col 2")
        for entry in dungeonLineWrites {
            #expect(entry.string.contains(expectedCode),
                    "depth=\(depth) line at row \(entry.row) should contain \(expectedCode), got: \(entry.string)")
        }
    }

    // ACCEPTANCE TEST (Behavior 2): 16-color fallback path emits correct 16-color codes
    @Test("16-color fallback terminal uses 16-color codes and not 256-color codes",
          arguments: [
            (0, "\u{1B}[97m"),
            (1, "\u{1B}[37m"),
            (2, "\u{1B}[90m"),
          ])
    func uses16ColorFallbackForDepth(depth: Int, expectedCode: String) {
        let spy = TUIOutputSpy()
        let renderer = Renderer(output: spy, supports256Color: false)
        let state = makeDepthState(depth: depth)
        renderer.render(state)

        let dungeonLineWrites = spy.entries.filter { (2...16).contains($0.row) && $0.col == 2 }
        #expect(!dungeonLineWrites.isEmpty, "Expected dungeon frame line writes at rows 2-16 col 2")
        for entry in dungeonLineWrites {
            #expect(entry.string.contains(expectedCode),
                    "depth=\(depth) fallback line at row \(entry.row) should contain \(expectedCode), got: \(entry.string)")
            #expect(!entry.string.contains(ansi256Prefix),
                    "depth=\(depth) fallback line at row \(entry.row) must not contain 256-color code, got: \(entry.string)")
        }
    }

    // UNIT TEST (Behavior 3): ansi256Fg helper returns correct escape string
    @Test("ansi256Fg returns correct ANSI 256-color foreground escape string",
          arguments: [(252, "\u{1B}[38;5;252m"), (249, "\u{1B}[38;5;249m"),
                      (244, "\u{1B}[38;5;244m"), (240, "\u{1B}[38;5;240m")])
    func ansi256FgHelperReturnsCorrectEscapeString(index: Int, expected: String) {
        #expect(ansi256Fg(index) == expected,
                "ansi256Fg(\(index)) should return \(expected)")
    }

    // UNIT TEST: reset \e[0m still applied after each dungeon line in 256-color mode
    @Test("256-color mode still applies reset after each dungeon frame line")
    func reset256ColorModeStillAppliesResetAfterEachLine() {
        let spy = TUIOutputSpy()
        let renderer = Renderer(output: spy, supports256Color: true)
        let state = makeDepthState(depth: 0)
        renderer.render(state)

        let dungeonLineWrites = spy.entries.filter { (2...16).contains($0.row) && $0.col == 2 }
        #expect(!dungeonLineWrites.isEmpty)
        for entry in dungeonLineWrites {
            #expect(entry.string.hasSuffix("\u{1B}[0m"),
                    "256-color line at row \(entry.row) must end with \\e[0m, got: \(entry.string)")
        }
    }
}
