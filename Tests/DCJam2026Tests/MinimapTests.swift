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
