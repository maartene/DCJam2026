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
