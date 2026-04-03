import Testing
@testable import DCJam2026
@testable import GameDomain

// Minimap Tests — US-TM-04 (2D minimap with facing indicator)
//
// Driving port: Renderer.render(_:) via TUIOutputSpy — the existing spy in this test target.
//               Tests observe what the Renderer writes to the output port at specific rows.
//
// All tests start as .disabled("not yet implemented"). Empty bodies ensure compilation succeeds
// until the crafter adds the required types. Enable one test at a time during DELIVER.
//
// Screen layout (DSGN-01): minimap panel at cols 61-79, rows 2-16.
// Symbol table (data-models.md):
//   ^ = north  > = east  v = south  < = west
//   # = wall   G = guard  E = entry  S = staircase
//   Player marker overrides all landmarks at same cell.
//
// Mandate compliance:
//   CM-A: Tests invoke Renderer (driving port for output) via TUIOutputPort spy.
//   CM-B: Test names describe what Ember sees on the minimap — no ANSI or cursor terms.
//   CM-C: Tests validate the observable minimap display, not internal rendering state.

@Suite("Turning Mechanic — 2D Minimap Facing Indicator")
struct MinimapTests {

    // MARK: - US-TM-04: Player facing symbol in minimap panel

    @Test("Minimap shows ^ when Ember faces North")
    func minimapShowsCaretNorthWhenFacingNorth() {
        let spy = TUIOutputSpy()
        let renderer = Renderer(output: spy)
        let state = GameState.initial(config: .default).withFacingDirection(.north)
        renderer.render(state)
        // Player starts at (x:7, y:0); screenRow = 2 + (6 - 0) = 8, col = 61 + 7 = 68
        let playerCellWrites = spy.entries.filter { $0.row == 8 && $0.col == 61 }
        let allText = playerCellWrites.map(\.string).joined()
        #expect(allText.contains("^"), "Expected '^' at player cell when facing north, got: \(allText)")
    }

    @Test("Minimap shows > when Ember faces East")
    func minimapShowsCaretEastWhenFacingEast() {
        let spy = TUIOutputSpy()
        let renderer = Renderer(output: spy)
        let state = GameState.initial(config: .default).withFacingDirection(.east)
        renderer.render(state)
        let playerCellWrites = spy.entries.filter { $0.row == 8 && $0.col == 61 }
        let allText = playerCellWrites.map(\.string).joined()
        #expect(allText.contains(">"), "Expected '>' at player cell when facing east, got: \(allText)")
    }

    @Test("Minimap shows v when Ember faces South")
    func minimapShowsCaretSouthWhenFacingSouth() {
        let spy = TUIOutputSpy()
        let renderer = Renderer(output: spy)
        let state = GameState.initial(config: .default).withFacingDirection(.south)
        renderer.render(state)
        let playerCellWrites = spy.entries.filter { $0.row == 8 && $0.col == 61 }
        let allText = playerCellWrites.map(\.string).joined()
        #expect(allText.contains("v"), "Expected 'v' at player cell when facing south, got: \(allText)")
    }

    @Test("Minimap shows < when Ember faces West")
    func minimapShowsCaretWestWhenFacingWest() {
        let spy = TUIOutputSpy()
        let renderer = Renderer(output: spy)
        let state = GameState.initial(config: .default).withFacingDirection(.west)
        renderer.render(state)
        let playerCellWrites = spy.entries.filter { $0.row == 8 && $0.col == 61 }
        let allText = playerCellWrites.map(\.string).joined()
        #expect(allText.contains("<"), "Expected '<' at player cell when facing west, got: \(allText)")
    }

    // MARK: - US-TM-04: Player marker overrides landmarks

    @Test("Player marker overrides the encounter landmark when Ember is at the encounter cell")
    func playerMarkerOverridesEncounterLandmarkOnSameCell() {
        let spy = TUIOutputSpy()
        let renderer = Renderer(output: spy)
        // Encounter is at (7,3); place player there facing north
        let state = GameState.initial(config: .default)
            .withPlayerPosition(Position(x: 7, y: 3))
            .withFacingDirection(.north)
        renderer.render(state)
        // Player at (7,3): screenRow = 2 + (6 - 3) = 5, col = 61
        let playerCellWrites = spy.entries.filter { $0.row == 5 && $0.col == 61 }
        let allText = playerCellWrites.map(\.string).joined()
        #expect(allText.contains("^"), "Expected '^' at encounter cell when player is there facing north, got: \(allText)")
    }

    @Test("Player marker overrides the entry landmark when Ember is at the entry cell")
    func playerMarkerOverridesEntryLandmarkAtStart() {
        let spy = TUIOutputSpy()
        let renderer = Renderer(output: spy)
        // Entry is at (7,0); player starts there by default
        let state = GameState.initial(config: .default).withFacingDirection(.north)
        renderer.render(state)
        // Player at (7,0): screenRow = 2 + (6 - 0) = 8, col = 61
        let playerCellWrites = spy.entries.filter { $0.row == 8 && $0.col == 61 }
        let allText = playerCellWrites.map(\.string).joined()
        #expect(allText.contains("^"), "Expected '^' at entry cell when player is there facing north, got: \(allText)")
    }

    // MARK: - US-TM-04: Same-frame update

    @Test("Minimap reflects the new facing on the same rendered frame as a turn command")
    func minimapUpdatesSameFrameAsTurnCommand() {
        let spy = TUIOutputSpy()
        let renderer = Renderer(output: spy)
        // Apply turn left (north -> west) and render the resulting state
        let initialState = GameState.initial(config: .default)
        let turnedState = RulesEngine.apply(command: .turn(.left), to: initialState, deltaTime: 0)
        renderer.render(turnedState)
        // Player at (7,0): screenRow = 8, col = 61; after turning left from north, facing = west
        let playerCellWrites = spy.entries.filter { $0.row == 8 && $0.col == 61 }
        let allText = playerCellWrites.map(\.string).joined()
        #expect(allText.contains("<"), "Expected '<' at player cell after turning left (north->west), got: \(allText)")
    }

    // MARK: - US-TM-04: Panel width constraint

    @Test("Each minimap panel row fits within the 19-column minimap panel width")
    func minimapRowsFitWithinPanelWidth() {
        let spy = TUIOutputSpy()
        let renderer = Renderer(output: spy)
        let state = GameState.initial(config: .default)
        renderer.render(state)

        // Filter to writes that start in the minimap panel region (rows 2-16, cols 61-79)
        let minimapWrites = spy.entries.filter { (2...16).contains($0.row) && (61...79).contains($0.col) }
        #expect(!minimapWrites.isEmpty, "Expected minimap writes in rows 2-16, cols 61-79")
        for entry in minimapWrites {
            #expect(entry.string.count <= 19,
                    "Minimap row \(entry.row) col \(entry.col) exceeds 19 chars: \"\(entry.string)\"")
        }
    }

    // MARK: - US-TM-04: Wall/corridor distinction

    @Test("Minimap renders wall cells as # and corridor cells as a non-wall character")
    func minimapRendersWallAndCorridorDistinctly() {
        let spy = TUIOutputSpy()
        let renderer = Renderer(output: spy)
        let state = GameState.initial(config: .default)
        renderer.render(state)

        // Filter to writes that start in the minimap panel region (rows 2-16, cols 61-79)
        let minimapWrites = spy.entries.filter { (2...16).contains($0.row) && (61...79).contains($0.col) }
        let allText = minimapWrites.map(\.string).joined()

        // Wall cells must appear as '#'
        #expect(allText.contains("#"), "Expected '#' for wall cells in minimap panel (rows 2-16, cols 61-79)")

        // Corridor cells must appear as '.' (passable, non-wall)
        #expect(allText.contains("."), "Expected '.' for corridor cells in minimap panel (rows 2-16, cols 61-79)")
    }
}

// MARK: - Landmark symbols in minimap

@Suite("Turning Mechanic — 2D Minimap Landmark Symbols")
struct MinimapLandmarkTests {

    // Test Budget: 7 distinct behaviors × 2 = 14 max tests; 7 used.
    //   B1: entry 'E' at (7,0)
    //   B2: guard 'G' at encounter cell on non-final floor
    //   B3: boss 'B' at encounter cell on final floor
    //   B4: egg '*' at egg room when not yet collected
    //   B5: egg 'e' at egg room after collection
    //   B6: staircase 'S' on non-final floor
    //   B7: exit 'X' on final floor

    // Minimap grid: y=6 renders at screen row 2; y=0 renders at screen row 8.
    // Each row is written to col 61 as a 15-character string; character x is at string index x.
    private func minimapCharAt(x: Int, y: Int, spy: TUIOutputSpy) -> Character? {
        let targetRow = 2 + (6 - y)   // screenRow formula from Renderer.renderMinimap
        guard let entry = spy.entries.first(where: { $0.row == targetRow && $0.col == 61 }) else {
            return nil
        }
        guard x >= 0 && x < entry.string.count else { return nil }
        return entry.string[entry.string.index(entry.string.startIndex, offsetBy: x)]
    }

    private func render(_ state: GameState) -> TUIOutputSpy {
        let spy = TUIOutputSpy()
        Renderer(output: spy).render(state)
        return spy
    }

    @Test("Minimap shows E at the entry cell (7,0)")
    func minimapShowsEntrySymbol() {
        // Player is north of entry so entry cell is visible (not overridden by player marker)
        let state = GameState.initial(config: .default).withPlayerPosition(Position(x: 7, y: 3))
        let spy = render(state)
        #expect(minimapCharAt(x: 7, y: 0, spy: spy) == "E", "Expected 'E' at entry (7,0)")
    }

    @Test("Minimap shows G at the guard encounter cell on a non-final floor")
    func minimapShowsGuardSymbol() {
        // Floor 1, player at entry; encounter is at (7,2) on non-final floor
        let state = GameState.initial(config: .default).withPlayerPosition(Position(x: 7, y: 0))
        let spy = render(state)
        #expect(minimapCharAt(x: 7, y: 2, spy: spy) == "G", "Expected 'G' at encounter (7,2)")
    }

    @Test("Minimap shows B at the boss encounter cell on the final floor")
    func minimapShowsBossSymbol() {
        // Final floor, boss at (7,3); player at entry
        let finalFloor = GameConfig.default.maxFloors
        let state = GameState.initial(config: .default)
            .withCurrentFloor(finalFloor)
            .withPlayerPosition(Position(x: 7, y: 0))
        let spy = render(state)
        #expect(minimapCharAt(x: 7, y: 3, spy: spy) == "B", "Expected 'B' at boss encounter (7,3) on final floor")
    }

    @Test("Minimap shows * at the egg room cell before the egg is collected")
    func minimapShowsEggSymbol() {
        // Floor 2 has the egg room at (2,3); player at entry, egg not yet collected
        let state = GameState.initial(config: .default)
            .withCurrentFloor(2)
            .withPlayerPosition(Position(x: 7, y: 0))
        let spy = render(state)
        #expect(minimapCharAt(x: 2, y: 3, spy: spy) == "*", "Expected '*' at uncollected egg room (2,3) on floor 2")
    }

    @Test("Minimap shows e at the egg room cell after the egg is collected")
    func minimapShowsCollectedEggSymbol() {
        let state = GameState.initial(config: .default)
            .withCurrentFloor(2)
            .withPlayerPosition(Position(x: 7, y: 0))
            .withHasEgg(true)
        let spy = render(state)
        #expect(minimapCharAt(x: 2, y: 3, spy: spy) == "e", "Expected 'e' at egg room (2,3) after collection")
    }

    @Test("Minimap shows S at the staircase cell on a non-final floor")
    func minimapShowsStaircaseSymbol() {
        let state = GameState.initial(config: .default).withPlayerPosition(Position(x: 7, y: 0))
        let spy = render(state)
        #expect(minimapCharAt(x: 7, y: 6, spy: spy) == "S", "Expected 'S' at staircase (7,6) on non-final floor")
    }

    @Test("Minimap shows X at the exit cell on the final floor")
    func minimapShowsExitSymbol() {
        let finalFloor = GameConfig.default.maxFloors
        let state = GameState.initial(config: .default)
            .withCurrentFloor(finalFloor)
            .withPlayerPosition(Position(x: 7, y: 0))
        let spy = render(state)
        #expect(minimapCharAt(x: 7, y: 6, spy: spy) == "X", "Expected 'X' at exit (7,6) on final floor")
    }
}

// MARK: - ADR-006 Screen Layout — Vertical Split

@Suite("Turning Mechanic — Vertical Split Layout (ADR-006)")
struct VerticalSplitLayoutTests {

    // Test Budget: 3 distinct behaviors × 2 = 6 max tests
    //   B1: vertical divider '│' at col 60 for rows 2-16
    //   B2: top connector '┬' at col 60 in row 1
    //   B3: bottom T-junction '┴' at col 60 in row 17

    /// Extracts the character at a 1-based column position from a write at a given row.
    /// Looks for a write that covers col 60 — either written starting at col 1 (full border)
    /// or written exactly at col 60 (individual divider character).
    private func characterAtCol60(row: Int, in entries: [TUIOutputSpy.Entry]) -> Character? {
        for entry in entries where entry.row == row {
            if entry.col == 60 {
                // Direct write at col 60
                return entry.string.first
            }
            if entry.col == 1 && entry.string.count >= 60 {
                // Full-width border string starting at col 1; col 60 is at index 59
                let idx = entry.string.index(entry.string.startIndex, offsetBy: 59)
                return entry.string[idx]
            }
        }
        return nil
    }

    @Test("Top border has split connector '┬' at column 60")
    func topBorderHasSplitConnectorAtCol60() {
        let spy = TUIOutputSpy()
        let renderer = Renderer(output: spy)
        let state = GameState.initial(config: .default)
        renderer.render(state)
        let ch = characterAtCol60(row: 1, in: spy.entries)
        #expect(ch == "┬", "Expected '┬' at row 1 col 60 for vertical split, got: \(ch.map(String.init) ?? "nil")")
    }

    @Test("Vertical divider '│' is present at column 60 for all dungeon view rows (2-16)")
    func verticalDividerPresentInAllDungeonViewRows() {
        let spy = TUIOutputSpy()
        let renderer = Renderer(output: spy)
        let state = GameState.initial(config: .default)
        renderer.render(state)
        for row in 2...16 {
            let ch = characterAtCol60(row: row, in: spy.entries)
            #expect(ch == "│", "Expected '│' at row \(row) col 60 for vertical split, got: \(ch.map(String.init) ?? "nil")")
        }
    }

    @Test("Row 17 separator has bottom T-junction '┴' at column 60")
    func row17SeparatorHasBottomTJunctionAtCol60() {
        let spy = TUIOutputSpy()
        let renderer = Renderer(output: spy)
        let state = GameState.initial(config: .default)
        renderer.render(state)
        let ch = characterAtCol60(row: 17, in: spy.entries)
        #expect(ch == "┴", "Expected '┴' at row 17 col 60 for vertical split, got: \(ch.map(String.init) ?? "nil")")
    }
}
