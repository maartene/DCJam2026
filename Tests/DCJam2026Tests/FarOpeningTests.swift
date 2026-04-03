import Testing
@testable import DCJam2026

// Test Budget: 4 distinct behaviors x 2 = 8 max unit tests
// Behaviors:
//   1. Far-right removes D=1 wall in gap zone (rows 4-8, col 54)
//   2. Far-right leaves lintel rows 3 and 9 intact
//   3. Far-right leaves D=0 outer wall (col 57) intact
//   4. Far-left mirrors far-right (col 3 row 5 cleared)

// MARK: - Acceptance Test

@Suite("FarOpening — acceptance: far-right depth=3 frame has correct opening")
struct FarOpeningAcceptanceTests {

    @Test("depth=3 farRight frame: D=1 wall removed in gap zone, lintels and D=0 wall intact")
    func farRightDepth3_frameTableLookup() {
        let table = buildFrameTable()
        let key = DungeonFrameKey(depth: 3, nearLeft: false, nearRight: false, farLeft: false, farRight: true)
        guard let frame = table[key] else {
            Issue.record("Frame not found in table for key \(key)")
            return
        }
        let rows = frame.map { Array($0) }

        // Gap zone: D=1 right wall removed at col 54 row 5
        #expect(rows[5][54] == " ", "col 54 row 5 should be space (D=1 right wall in gap zone)")

        // Lintel above opening intact: row 3 col 54 is |
        #expect(rows[3][54] == "|", "col 54 row 3 should be | (lintel above opening)")

        // Lintel below opening intact: row 9 col 54 is |
        #expect(rows[9][54] == "|", "col 54 row 9 should be | (lintel below opening)")

        // D=0 outer wall untouched: col 57 row 5 is |
        #expect(rows[5][57] == "|", "col 57 row 5 should be | (D=0 outer wall intact)")
    }
}

// MARK: - Unit Tests: applyFarOpening

@Suite("FarOpening — unit: applyFarOpening modifies correct cells")
struct FarOpeningUnitTests {

    // Behavior 1: far-right removes D=1 wall in gap zone
    @Test("applyFarOpening(.right) clears col 54 in rows 4-8")
    func farRight_clearsGapZone() {
        var grid = baseCorridorGrid(depth: 3)
        applyFarOpening(&grid, side: .right)

        #expect(grid[4][54] == " ", "row 4 col 54 cleared")
        #expect(grid[5][54] == " ", "row 5 col 54 cleared")
        #expect(grid[6][54] == " ", "row 6 col 54 cleared")
        #expect(grid[7][54] == " ", "row 7 col 54 cleared")
        #expect(grid[8][54] == " ", "row 8 col 54 cleared")
    }

    // Behavior 2: lintel rows intact
    @Test("applyFarOpening(.right) does not touch row 3 or row 9")
    func farRight_leavesLintelsIntact() {
        var grid = baseCorridorGrid(depth: 3)
        let row3Before = grid[3][54]
        let row9Before = grid[9][54]
        applyFarOpening(&grid, side: .right)

        #expect(grid[3][54] == row3Before, "row 3 col 54 unchanged")
        #expect(grid[9][54] == row9Before, "row 9 col 54 unchanged")
    }

    // Behavior 3: D=0 outer wall intact
    @Test("applyFarOpening(.right) does not touch col 57")
    func farRight_leavesOuterWallIntact() {
        var grid = baseCorridorGrid(depth: 3)
        let col57Before = (0..<15).map { grid[$0][57] }
        applyFarOpening(&grid, side: .right)

        for row in 0..<15 {
            #expect(grid[row][57] == col57Before[row], "col 57 row \(row) unchanged")
        }
    }

    // Behavior 4: far-left mirrors far-right
    @Test("applyFarOpening(.left) clears col 3 in rows 4-8")
    func farLeft_clearsGapZone() {
        var grid = baseCorridorGrid(depth: 3)
        applyFarOpening(&grid, side: .left)

        #expect(grid[4][3] == " ", "row 4 col 3 cleared")
        #expect(grid[5][3] == " ", "row 5 col 3 cleared")
        #expect(grid[6][3] == " ", "row 6 col 3 cleared")
        #expect(grid[7][3] == " ", "row 7 col 3 cleared")
        #expect(grid[8][3] == " ", "row 8 col 3 cleared")
    }
}

// MARK: - Unit Tests: buildFrameTable completeness

@Suite("FarOpening — buildFrameTable contains far-opening keys for depths 1-3")
struct FarOpeningTableTests {

    @Test("buildFrameTable has all 16 combinations for depths 1-3")
    func tableContainsFarOpeningKeysForDepths1to3() {
        let table = buildFrameTable()

        for depth in 1...3 {
            for nearLeft in [false, true] {
                for nearRight in [false, true] {
                    for farLeft in [false, true] {
                        for farRight in [false, true] {
                            let key = DungeonFrameKey(depth: depth, nearLeft: nearLeft, nearRight: nearRight, farLeft: farLeft, farRight: farRight)
                            #expect(table[key] != nil, "Missing key: depth=\(depth) nL=\(nearLeft) nR=\(nearRight) fL=\(farLeft) fR=\(farRight)")
                        }
                    }
                }
            }
        }
    }

    @Test("buildFrameTable far-left depth=3: col 3 row 5 is space")
    func farLeftDepth3_col3Row5isSpace() {
        let table = buildFrameTable()
        let key = DungeonFrameKey(depth: 3, nearLeft: false, nearRight: false, farLeft: true, farRight: false)
        guard let frame = table[key] else {
            Issue.record("Frame not found for far-left depth=3")
            return
        }
        let rows = frame.map { Array($0) }
        #expect(rows[5][3] == " ", "col 3 row 5 should be space (far-left opening)")
    }

    @Test("fallbackFrame no longer strips farLeft/farRight: exact match returned first")
    func fallbackFrame_usesExactKeyFirst() {
        let key = DungeonFrameKey(depth: 2, nearLeft: false, nearRight: false, farLeft: false, farRight: true)
        let frame = fallbackFrame(for: key)
        let table = buildFrameTable()
        let exactFrame = table[key]
        #expect(exactFrame != nil, "Exact key must exist in table")
        #expect(frame == exactFrame!, "fallbackFrame should return exact match when it exists")
    }
}
