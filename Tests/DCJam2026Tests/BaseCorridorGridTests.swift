import Testing
@testable import DCJam2026

// BaseCorridorGridTests — Step 01-01
//
// Driving port: buildFrameTable() for acceptance; baseCorridorGrid(depth:) for unit tests.
// Behavior: the new baseCorridorGrid(depth:) function produces structurally correct
// [[Character]] grids that match the corridor geometry constants.
//
// Test Budget: 3 distinct behaviors × 2 = 6 max unit tests
//   B1: depth=0 base grid has | at [row0][col0] and | at [row0][col57]
//   B2: depth=3 base grid row 5 contains fog dot character ·
//   B3: all grids (depth 0-3) are exactly 15 rows × 58 chars
// Total unit tests: 3 (within budget)

// MARK: - Acceptance Test (via buildFrameTable driving port)

@Suite("BaseCorridorGrid — structural characters are correct in no-opening frames")
struct BaseCorridorGridAcceptanceTests {

    // ACCEPTANCE: buildFrameTable() depth=3 no-opening frame has | at col 0 and col 57 of row 0,
    // and row 5 contains fog dot characters. This verifies the structural skeleton is intact.
    @Test("depth=3 no-opening frame has outer wall pipes at row 0 and fog dots in row 5")
    func depth3NoOpeningFrameHasCorrectStructure() {
        let table = buildFrameTable()
        let key = DungeonFrameKey(depth: 3, nearLeft: false, nearRight: false, farLeft: false, farRight: false)
        guard let frame = table[key] else {
            Issue.record("buildFrameTable() missing key for depth=3 no-opening")
            return
        }

        #expect(frame.count == 15, "depth=3 no-opening frame must have 15 rows, got \(frame.count)")

        let row0 = Array(frame[0])
        #expect(row0.count == 58, "row 0 must be 58 chars wide, got \(row0.count)")
        #expect(row0[0] == "|", "row 0 col 0 must be | (outer left wall), got \(row0[0])")
        #expect(row0[57] == "|", "row 0 col 57 must be | (outer right wall), got \(row0[57])")

        #expect(frame[5].contains("·"),
                "row 5 must contain fog dot character ·, got: \(frame[5])")
    }

    // ACCEPTANCE: buildFrameTable() still returns all four depth=N no-opening keys
    @Test("buildFrameTable returns no-opening keys for all depths 0-3",
          arguments: [0, 1, 2, 3])
    func allNoOpeningKeysPresent(depth: Int) {
        let table = buildFrameTable()
        let key = DungeonFrameKey(depth: depth, nearLeft: false, nearRight: false, farLeft: false, farRight: false)
        #expect(table[key] != nil, "buildFrameTable() must contain key for depth=\(depth) no-opening")
    }
}

// MARK: - Unit Tests for baseCorridorGrid(depth:)

@Suite("baseCorridorGrid — returns correct [[Character]] grid for each depth")
struct BaseCorridorGridUnitTests {

    // B1: depth=0 grid has outer left wall | at row 0 col 0 and outer right wall | at row 0 col 57
    @Test("depth=0 base grid has pipe characters at outer wall positions in row 0")
    func depth0GridHasPipesAtOuterWallPositions() {
        let grid = baseCorridorGrid(depth: 0)
        let row0 = grid[0]
        #expect(row0[0] == "|", "depth=0 row 0 col 0 must be | (outer left wall), got \(row0[0])")
        #expect(row0[57] == "|", "depth=0 row 0 col 57 must be | (outer right wall), got \(row0[57])")
    }

    // B2: depth=3 grid row 5 contains fog dot character ·
    @Test("depth=3 base grid row 5 contains fog dot character")
    func depth3GridRow5ContainsFogDot() {
        let grid = baseCorridorGrid(depth: 3)
        let row5 = grid[5]
        #expect(row5.contains("·"), "depth=3 row 5 must contain fog dot ·, got: \(String(row5))")
    }

    // B3: all grids are exactly 15 rows × 58 chars
    @Test("all base corridor grids are exactly 15 rows × 58 characters",
          arguments: [0, 1, 2, 3])
    func allGridsAre15Rows58Chars(depth: Int) {
        let grid = baseCorridorGrid(depth: depth)
        #expect(grid.count == 15, "depth=\(depth) grid must have 15 rows, got \(grid.count)")
        for (rowIndex, row) in grid.enumerated() {
            #expect(row.count == 58,
                    "depth=\(depth) row \(rowIndex) must be 58 chars, got \(row.count)")
        }
    }
}
