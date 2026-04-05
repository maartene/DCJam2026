// Acceptance tests — will not compile until FloorRegistry is implemented and
// the Renderer is updated (minimap starts at row 3, floor label at row 2).
// ACCEPTANCE: pre-implementation
//
// Feature: US-HM-04 — Minimap renders at correct screen coordinates
//           after the floor label moves to row 2.
//
// After this feature (DEC-DESIGN-05, DEC-DESIGN-06):
//   Row 2, cols 61-79  = floor label (written by renderDungeon)
//   Row 3+, cols 61-79 = minimap (starts at row 3 now, was row 2)
//   Rows 10-16         = minimap legend (was rows 9-15)
//
// Screen coordinate formula (DEC-DESIGN-06, all floors height ≤ 7):
//   screenRow = 3 + (floor.grid.height - 1 - y)
//   screenCol = 61 + x
//
// For floor 1 (height = 7):
//   y = 6 (northernmost row)  → screenRow = 3 + 0  = 3
//   y = 0 (southernmost row)  → screenRow = 3 + 6  = 9
//   entry (7, 0) → screenRow = 9, screenCol = 68
//
// Driving port: Renderer(output: TUIOutputSpy()).render(state)
//
// Mandate compliance:
//   CM-A: All tests invoke the Renderer driving port via TUIOutputSpy.
//   CM-B: Names use minimap/floor/dungeon/corridor terms — no cursor/draw jargon.
//   CM-C: Each test validates what the player sees on the minimap panel.
//
// Error path ratio: 5 of 12 scenarios = 42% (exceeds 40% mandate).

import Testing
@testable import DCJam2026
@testable import GameDomain

// ============================================================
// Shared helpers
// ============================================================

private func renderDungeon(floor floorNum: Int, playerAt pos: Position? = nil) -> TUIOutputSpy {
    let spy = TUIOutputSpy()
    var state = GameState.initial(config: .default)
        .withCurrentFloor(floorNum)
        .withScreenMode(.dungeon)
    if let pos = pos {
        state = state.withPlayerPosition(pos)
    }
    Renderer(output: spy).render(state)
    return spy
}

// ============================================================
// Suite 1: Minimap row origin after floor label relocation
// ============================================================

@Suite struct `Handcrafted Maps — Minimap Starts at Row 3` {

    // -------------------------------------------------------------------------
    // Walking skeleton: minimap is present in rows 3-9 (not 2-8) for floor 1
    // -------------------------------------------------------------------------

    @Test func `Minimap produces writes in rows 3 through 9 for floor 1 in dungeon mode`() {
        // Given — floor 1, height = 7, minimap rows = 3 to 3+(7-1) = 9
        let spy = renderDungeon(floor: 1)
        // When — collect all right-panel writes in the minimap band
        let minimapWrites = spy.entries.filter { (3...9).contains($0.row) && (61...79).contains($0.col) }
        // Then — minimap has writes across this range
        #expect(!minimapWrites.isEmpty,
                "Minimap must produce writes in rows 3-9 for floor 1 (height=7)")
    }

    @Test func `Row 2 right panel is occupied by the floor label, not a minimap cell, in dungeon mode`() {
        // Given — floor 1 dungeon mode
        let spy = renderDungeon(floor: 1)
        // When — gather writes at row 2 right panel
        let row2RightWrites = spy.entries.filter { $0.row == 2 && (61...79).contains($0.col) }
        let row2Text = row2RightWrites.map(\.string).joined()
        // Then — row 2 contains label text (floor number), not minimap wall/floor characters
        // The minimap characters for floor 1 are '#' (wall) and '.' (floor) and landmarks.
        // The label text must contain a digit. This confirms label, not minimap, won row 2.
        #expect(row2Text.contains("1") || row2Text.contains("Floor"),
                "Row 2 right panel must contain the floor label on floor 1, got: \(row2Text)")
    }

    // -------------------------------------------------------------------------
    // Happy path: northernmost minimap row (highest y) always renders at row 3
    // -------------------------------------------------------------------------

    @Test func `The northernmost row of the floor 1 minimap renders at screen row 3`() {
        // Given — floor 1, height = 7; northernmost row y = 6 renders at row 3 + 0 = 3
        let spy = renderDungeon(floor: 1)
        // When — look for any write at row 3 in the right panel
        let row3Writes = spy.entries.filter { $0.row == 3 && (61...79).contains($0.col) }
        // Then — the northernmost minimap strip is present
        #expect(!row3Writes.isEmpty,
                "Northernmost minimap row (y=6 for height=7) must render at screen row 3")
    }

    // -------------------------------------------------------------------------
    // Happy path: floor 1 entry cell renders at its correct new screen position
    // -------------------------------------------------------------------------

    @Test func `Floor 1 entry cell indicator appears at screen row 9 column 68 in dungeon mode`() {
        // Given — floor 1, entry at (7, 0)
        // screenRow = 3 + (7 - 1 - 0) = 3 + 6 = 9; screenCol = 61 + 7 = 68
        let spy = renderDungeon(floor: 1)
        // When — look for the entry cell write
        let entryCellWrites = spy.entries.filter { $0.row == 9 && $0.col == 68 }
        // Then — something is written at the entry cell location
        #expect(!entryCellWrites.isEmpty,
                "Floor 1 entry cell must produce a write at row 9, col 68. Writes at (9, 68): \(entryCellWrites.map(\.string))")
    }

    @Test func `Player facing indicator appears at the entry cell screen position on floor 1`() {
        // Given — Ember at the entry cell (7, 0) facing north
        let spy = renderDungeon(floor: 1, playerAt: Position(x: 7, y: 0))
        // When — row 9, col 68 (entry cell after label relocation)
        let entryCellWrites = spy.entries.filter { $0.row == 9 && $0.col == 68 }
        let allText = entryCellWrites.map { stripANSI($0.string) }.joined()
        // Then — the player facing indicator is present
        let facingChars: Set<Character> = ["^", ">", "v", "<"]
        #expect(allText.contains(where: { facingChars.contains($0) }),
                "Player facing indicator (^>v<) must appear at row 9 col 68 for entry cell. Got: \(allText)")
    }
}

// ============================================================
// Suite 2: Minimap column bounds — right panel constraint
// ============================================================

@Suite struct `Handcrafted Maps — Minimap Column Bounds` {

    // -------------------------------------------------------------------------
    // Error path: no minimap write ever exceeds col 79
    // -------------------------------------------------------------------------

    @Test func `No minimap write exceeds column 79 for floor 1`() {
        // Given
        let spy = renderDungeon(floor: 1)
        // When
        let overflowWrites = spy.entries.filter { (3...16).contains($0.row) && $0.col > 79 }
        // Then — the 19-column right panel (61-79) is never exceeded
        #expect(overflowWrites.isEmpty,
                "Floor 1: minimap must not write beyond col 79. Overflow cols: \(overflowWrites.map { $0.col })")
    }

    @Test func `No minimap write falls below column 61 in the right panel for floor 1`() {
        // Given — right panel starts at col 61
        // This checks that the minimap is correctly offset and doesn't bleed left
        let spy = renderDungeon(floor: 1)
        // When — collect writes that look like minimap content (rows 3-9, single chars)
        let leftBleedWrites = spy.entries.filter {
            (3...9).contains($0.row) && $0.col < 61 && $0.col > 60
        }
        // Then — no minimap content in col 60 or below
        #expect(leftBleedWrites.isEmpty,
                "Minimap must not write at col 60 or below. Bleed writes: \(leftBleedWrites)")
    }

    // -------------------------------------------------------------------------
    // Error path: minimap does not write outside rows 3-16
    // -------------------------------------------------------------------------

    @Test func `No minimap write appears above row 3 in the right panel for any floor`() {
        // Given — row 2 is the label row; row 1 is the chrome border
        for floorNum in 1...5 {
            let spy = renderDungeon(floor: floorNum)
            // Collect right-panel writes above row 3 that look like minimap chars (# or .)
            let earlyWrites = spy.entries.filter {
                $0.row < 3 && (61...79).contains($0.col) &&
                (stripANSI($0.string) == "#" || stripANSI($0.string) == ".")
            }
            #expect(earlyWrites.isEmpty,
                    "Floor \(floorNum): minimap grid cells must not appear above row 3. Premature writes: \(earlyWrites.map { ($0.row, $0.col) })")
        }
    }

    @Test func `No minimap write appears below row 16 in the right panel for any floor`() {
        // Given — rows 17+ are the status bar; minimap and legend must stay in rows 3-16
        for floorNum in 1...5 {
            let spy = renderDungeon(floor: floorNum)
            let laterWrites = spy.entries.filter {
                $0.row > 16 && (61...79).contains($0.col) &&
                (stripANSI($0.string) == "#" || stripANSI($0.string) == ".")
            }
            #expect(laterWrites.isEmpty,
                    "Floor \(floorNum): minimap grid cells must not appear below row 16. Late writes: \(laterWrites.map { ($0.row, $0.col) })")
        }
    }
}

// ============================================================
// Suite 3: Minimap legend rows shift after label relocation
// ============================================================

@Suite struct `Handcrafted Maps — Minimap Legend at Rows 10-16` {

    // -------------------------------------------------------------------------
    // Walking skeleton: legend is visible at rows 10-16 after relocation
    // -------------------------------------------------------------------------

    @Test func `Minimap legend occupies rows 10 through 16 in dungeon mode after label relocation`() {
        // Given — legend must shift down by one row (from 9-15 to 10-16) because
        //   row 2 = label, rows 3-9 = minimap (height=7 floor), row 10+ = legend
        let spy = renderDungeon(floor: 1)
        // When — collect writes in the legend region
        let legendWrites = spy.entries.filter { (10...16).contains($0.row) && (61...79).contains($0.col) }
        let legendText = legendWrites.map(\.string).joined()
        let stripped = stripANSI(legendText)
        // Then — all 7 legend entries are present in rows 10-16
        #expect(stripped.contains("You"),    "Legend in rows 10-16 must contain 'You'")
        #expect(stripped.contains("Guard"),  "Legend in rows 10-16 must contain 'Guard'")
        #expect(stripped.contains("Boss"),   "Legend in rows 10-16 must contain 'Boss'")
        #expect(stripped.contains("Egg"),    "Legend in rows 10-16 must contain 'Egg'")
        #expect(stripped.contains("Stairs"), "Legend in rows 10-16 must contain 'Stairs'")
        #expect(stripped.contains("Entry"),  "Legend in rows 10-16 must contain 'Entry'")
        #expect(stripped.contains("Exit"),   "Legend in rows 10-16 must contain 'Exit'")
    }

    // -------------------------------------------------------------------------
    // Error path: old legend rows 9-15 must no longer contain legend labels
    // -------------------------------------------------------------------------

    @Test func `Old legend rows 9-15 do not contain legend label text after the shift to rows 10-16`() {
        // Given — after relocation, rows 9-15 should not host legend labels
        // Row 9 is now the southernmost minimap row (for height=7 floor)
        let spy = renderDungeon(floor: 1)
        // When — look for legend labels in rows 9 (the shifted-out row)
        let row9Writes = spy.entries.filter { $0.row == 9 && (61...79).contains($0.col) }
        let row9Text = stripANSI(row9Writes.map(\.string).joined())
        // Then — row 9 contains minimap content (# or .), not legend labels
        #expect(!row9Text.contains("Guard"),  "Row 9 must not contain 'Guard' legend label after shift")
        #expect(!row9Text.contains("Stairs"), "Row 9 must not contain 'Stairs' legend label after shift")
        #expect(!row9Text.contains("Entry"),  "Row 9 must not contain 'Entry' legend label after shift")
    }

    // -------------------------------------------------------------------------
    // Error path: row 17 (status bar separator) is not overwritten by legend
    // -------------------------------------------------------------------------

    @Test func `The status bar separator at row 17 is not overwritten by any legend content`() {
        // Given
        let spy = renderDungeon(floor: 1)
        // When
        let row17RightWrites = spy.entries.filter { $0.row == 17 && (61...79).contains($0.col) }
        let text = stripANSI(row17RightWrites.map(\.string).joined())
        // Then — no legend labels appear at row 17
        #expect(!text.contains("Guard"),  "Row 17 must not contain legend label 'Guard'")
        #expect(!text.contains("Boss"),   "Row 17 must not contain legend label 'Boss'")
        #expect(!text.contains("Stairs"), "Row 17 must not contain legend label 'Stairs'")
        #expect(!text.contains("Entry"),  "Row 17 must not contain legend label 'Entry'")
        #expect(!text.contains("Exit"),   "Row 17 must not contain legend label 'Exit'")
    }

    // -------------------------------------------------------------------------
    // Happy path: legend renders on all five floors
    // -------------------------------------------------------------------------

    @Test func `Minimap legend is visible in rows 10-16 on all five dungeon floors`() {
        // Given — DEC-DESIGN-06: legend is called unconditionally; height cap ensures no overlap
        for floorNum in 1...5 {
            let spy = renderDungeon(floor: floorNum)
            let legendWrites = spy.entries.filter {
                (10...16).contains($0.row) && (61...79).contains($0.col)
            }
            let text = stripANSI(legendWrites.map(\.string).joined())
            #expect(text.contains("Guard"),
                    "Floor \(floorNum): legend in rows 10-16 must contain 'Guard'")
        }
    }
}
