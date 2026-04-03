import Testing
@testable import DCJam2026

// NearOpeningTests — Step 01-02
//
// Driving port: buildFrameTable() for acceptance test; applyNearOpening(_:side:) for unit tests.
// Behavior: near-opening modifier removes the D=0 outer wall on the specified side, leaving
// the D=1 inner wall visible through the gap.
//
// Test Budget: 3 distinct behaviors × 2 = 6 max unit tests
//   B1: near-right clears col 57 (outer right wall removed for all rows 0-12)
//   B2: near-right clears perspective diagonals (ceiling/floor) while D=1 wall at col 54 is intact
//   B3: near-left clears col 0 (outer left wall removed for all rows 0-12)
// Total unit tests used: 5 (within budget)

// MARK: - Acceptance test

@Suite struct `NearOpening — near opening modifier removes D=0 outer wall` {

    // Acceptance: buildFrameTable() wires applyNearOpening for depth=3 nearRight
    @Test func `near-right frame from table has col 57 space and D=1 wall intact`() {
        let table = buildFrameTable()
        let key = DungeonFrameKey(depth: 3, nearLeft: false, nearRight: true, farLeft: false, farRight: false)
        guard let frame = table[key] else {
            Issue.record("No frame found for depth=3 nearRight key")
            return
        }
        let rows = frame.map { Array($0) }
        // col 57 row 0: outer right wall must be space (D=0 wall removed)
        #expect(rows[0][57] == " ", "Expected space at row 0 col 57 (D=0 right wall removed)")
        // col 54 row 3: D=1 right wall must be intact (| not touched)
        #expect(rows[3][54] == "|", "Expected | at row 3 col 54 (D=1 right wall intact)")
    }

    // MARK: - Unit tests for applyNearOpening (via driving port helper)

    // B1: near-right clears col 57 for all rows 0-12
    @Test func `applyNearOpening right clears col 57 for rows 0 through 12`() {
        var grid = baseCorridorGrid(depth: 3)
        applyNearOpening(&grid, side: .right)
        for row in 0...12 {
            #expect(grid[row][57] == " ", "Expected space at row \(row) col 57 after near-right")
        }
    }

    // B2a: near-right clears ceiling perspective diagonal at row 2 col 55
    @Test func `applyNearOpening right clears ceiling perspective at row 2 col 55`() {
        var grid = baseCorridorGrid(depth: 3)
        applyNearOpening(&grid, side: .right)
        #expect(grid[2][55] == " ", "Expected space at row 2 col 55 (ceiling perspective diagonal cleared)")
    }

    // B2b: near-right does NOT touch D=1 right wall at col 54 row 3
    @Test func `applyNearOpening right leaves D=1 wall at col 54 row 3 intact`() {
        var grid = baseCorridorGrid(depth: 3)
        let before = grid[3][54]
        applyNearOpening(&grid, side: .right)
        #expect(grid[3][54] == before, "D=1 right wall at row 3 col 54 must not be touched by near-right")
    }

    // B3: near-left clears col 0 for all rows 0-12
    @Test func `applyNearOpening left clears col 0 for rows 0 through 12`() {
        var grid = baseCorridorGrid(depth: 3)
        applyNearOpening(&grid, side: .left)
        for row in 0...12 {
            #expect(grid[row][0] == " ", "Expected space at row \(row) col 0 after near-left")
        }
    }

    // B3b: near-left clears ceiling perspective diagonal at row 2 col 2
    @Test func `applyNearOpening left clears ceiling perspective at row 2 col 2`() {
        var grid = baseCorridorGrid(depth: 3)
        applyNearOpening(&grid, side: .left)
        #expect(grid[2][2] == " ", "Expected space at row 2 col 2 (ceiling perspective diagonal cleared)")
    }
}
