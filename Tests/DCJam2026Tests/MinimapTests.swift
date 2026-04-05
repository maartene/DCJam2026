import Testing
@testable import DCJam2026
@testable import GameDomain

// Minimap Tests — US-TM-04 (2D minimap with facing indicator)
//
// Per-cell write contract (step 03-07): each cell (x, y) writes at col = 61+x.
// Colored cells: write is color + char + reset. Passable '.' has no color prefix.

@Suite struct `Turning Mechanic — 2D Minimap Facing Indicator` {

    @Test func `Minimap shows ^ when Ember faces North`() {
        let spy = TUIOutputSpy()
        let renderer = Renderer(output: spy)
        let state = GameState.initial(config: .default)
            .withFacingDirection(.north)
            .withScreenMode(.dungeon)
        renderer.render(state)
        // Player at (x:7, y:0); screenRow = 3 + (6 - 0) = 9, col = 61 + 7 = 68
        let playerCellWrites = spy.entries.filter { $0.row == 9 && $0.col == 68 }
        let allText = playerCellWrites.map(\.string).joined()
        #expect(allText.contains("^"), "Expected '^' at player cell when facing north, got: \(allText)")
    }

    @Test func `Minimap shows > when Ember faces East`() {
        let spy = TUIOutputSpy()
        let renderer = Renderer(output: spy)
        let state = GameState.initial(config: .default)
            .withFacingDirection(.east)
            .withScreenMode(.dungeon)
        renderer.render(state)
        let playerCellWrites = spy.entries.filter { $0.row == 9 && $0.col == 68 }
        let allText = playerCellWrites.map(\.string).joined()
        #expect(allText.contains(">"), "Expected '>' at player cell when facing east, got: \(allText)")
    }

    @Test func `Minimap shows v when Ember faces South`() {
        let spy = TUIOutputSpy()
        let renderer = Renderer(output: spy)
        let state = GameState.initial(config: .default)
            .withFacingDirection(.south)
            .withScreenMode(.dungeon)
        renderer.render(state)
        let playerCellWrites = spy.entries.filter { $0.row == 9 && $0.col == 68 }
        let allText = playerCellWrites.map(\.string).joined()
        #expect(allText.contains("v"), "Expected 'v' at player cell when facing south, got: \(allText)")
    }

    @Test func `Minimap shows < when Ember faces West`() {
        let spy = TUIOutputSpy()
        let renderer = Renderer(output: spy)
        let state = GameState.initial(config: .default)
            .withFacingDirection(.west)
            .withScreenMode(.dungeon)
        renderer.render(state)
        let playerCellWrites = spy.entries.filter { $0.row == 9 && $0.col == 68 }
        let allText = playerCellWrites.map(\.string).joined()
        #expect(allText.contains("<"), "Expected '<' at player cell when facing west, got: \(allText)")
    }

    @Test func `Player marker overrides the encounter landmark when Ember is at the encounter cell`() {
        let spy = TUIOutputSpy()
        let renderer = Renderer(output: spy)
        let state = GameState.initial(config: .default)
            .withPlayerPosition(Position(x: 7, y: 3))
            .withFacingDirection(.north)
            .withScreenMode(.dungeon)
        renderer.render(state)
        // Player at (7,3): screenRow = 3 + (6 - 3) = 6, col = 61 + 7 = 68
        let playerCellWrites = spy.entries.filter { $0.row == 6 && $0.col == 68 }
        let allText = playerCellWrites.map(\.string).joined()
        #expect(allText.contains("^"), "Expected '^' at encounter cell when player is there facing north, got: \(allText)")
    }

    @Test func `Player marker overrides the entry landmark when Ember is at the entry cell`() {
        let spy = TUIOutputSpy()
        let renderer = Renderer(output: spy)
        let state = GameState.initial(config: .default)
            .withFacingDirection(.north)
            .withScreenMode(.dungeon)
        renderer.render(state)
        // Player at (7,0): screenRow = 9, col = 68
        let playerCellWrites = spy.entries.filter { $0.row == 9 && $0.col == 68 }
        let allText = playerCellWrites.map(\.string).joined()
        #expect(allText.contains("^"), "Expected '^' at entry cell when player is there facing north, got: \(allText)")
    }

    @Test func `Minimap reflects the new facing on the same rendered frame as a turn command`() {
        let spy = TUIOutputSpy()
        let renderer = Renderer(output: spy)
        let initialState = GameState.initial(config: .default)
        let turnedState = RulesEngine.apply(command: .turn(.left), to: initialState, deltaTime: 0)
            .withScreenMode(.dungeon)
        renderer.render(turnedState)
        // Player at (7,0): screenRow = 9, col = 68; after turning left from north, facing = west
        let playerCellWrites = spy.entries.filter { $0.row == 9 && $0.col == 68 }
        let allText = playerCellWrites.map(\.string).joined()
        #expect(allText.contains("<"), "Expected '<' at player cell after turning left (north->west), got: \(allText)")
    }

    @Test func `Each minimap panel row fits within the 19-column minimap panel width`() {
        let spy = TUIOutputSpy()
        let renderer = Renderer(output: spy)
        let state = GameState.initial(config: .default).withScreenMode(.dungeon)
        renderer.render(state)
        let minimapWrites = spy.entries.filter { (2...16).contains($0.row) && (61...79).contains($0.col) }
        #expect(!minimapWrites.isEmpty, "Expected minimap writes in rows 2-16, cols 61-79")
        for entry in minimapWrites {
            #expect(entry.string.count <= 20,
                    "Minimap cell write at row \(entry.row) col \(entry.col) exceeds 20 chars: \"\(entry.string)\"")
        }
    }

    @Test func `Minimap renders wall cells as # and corridor cells as a non-wall character`() {
        let spy = TUIOutputSpy()
        let renderer = Renderer(output: spy)
        let state = GameState.initial(config: .default).withScreenMode(.dungeon)
        renderer.render(state)
        let minimapWrites = spy.entries.filter { (2...16).contains($0.row) && (61...79).contains($0.col) }
        let allText = minimapWrites.map(\.string).joined()
        #expect(allText.contains("#"), "Expected '#' for wall cells in minimap panel (rows 2-16, cols 61-79)")
        #expect(allText.contains("."), "Expected '.' for corridor cells in minimap panel (rows 2-16, cols 61-79)")
    }
}

// MARK: - Landmark symbols in minimap

@Suite struct `Turning Mechanic — 2D Minimap Landmark Symbols` {

    // Test Budget: 7 distinct behaviors x 2 = 14 max tests; 7 used.

    private func minimapCharAt(x: Int, y: Int, spy: TUIOutputSpy) -> Character? {
        let targetRow = 3 + (6 - y)
        let targetCol = 61 + x
        guard let entry = spy.entries.first(where: { $0.row == targetRow && $0.col == targetCol }) else {
            return nil
        }
        return stripANSI(entry.string).first
    }

    private func stripANSI(_ s: String) -> String {
        var result = ""
        var i = s.startIndex
        while i < s.endIndex {
            if s[i] == "\u{1B}", s.index(after: i) < s.endIndex, s[s.index(after: i)] == "[" {
                var j = s.index(after: s.index(after: i))
                while j < s.endIndex && s[j] != "m" { j = s.index(after: j) }
                if j < s.endIndex { j = s.index(after: j) }
                i = j
            } else {
                result.append(s[i])
                i = s.index(after: i)
            }
        }
        return result
    }

    private func render(_ state: GameState) -> TUIOutputSpy {
        let spy = TUIOutputSpy()
        Renderer(output: spy).render(state)
        return spy
    }

    @Test func `Minimap shows E at the entry cell (7,0)`() {
        let state = GameState.initial(config: .default)
            .withPlayerPosition(Position(x: 7, y: 3))
            .withScreenMode(.dungeon)
        let spy = render(state)
        #expect(minimapCharAt(x: 7, y: 0, spy: spy) == "E", "Expected 'E' at entry (7,0)")
    }

    @Test func `Minimap shows G at the guard encounter cell on a non-final floor`() {
        let state = GameState.initial(config: .default)
            .withPlayerPosition(Position(x: 7, y: 0))
            .withScreenMode(.dungeon)
        let spy = render(state)
        #expect(minimapCharAt(x: 7, y: 2, spy: spy) == "G", "Expected 'G' at encounter (7,2)")
    }

    @Test func `Minimap shows B at the boss encounter cell on the final floor`() {
        let finalFloor = GameConfig.default.maxFloors
        let state = GameState.initial(config: .default)
            .withCurrentFloor(finalFloor)
            .withPlayerPosition(Position(x: 7, y: 0))
            .withScreenMode(.dungeon)
        let spy = render(state)
        #expect(minimapCharAt(x: 7, y: 3, spy: spy) == "B", "Expected 'B' at boss encounter (7,3) on final floor")
    }

    @Test func `Minimap shows * at the egg room cell before the egg is collected`() {
        let state = GameState.initial(config: .default)
            .withCurrentFloor(2)
            .withPlayerPosition(Position(x: 7, y: 0))
            .withScreenMode(.dungeon)
        let spy = render(state)
        #expect(minimapCharAt(x: 2, y: 3, spy: spy) == "*", "Expected '*' at uncollected egg room (2,3) on floor 2")
    }

    @Test func `Minimap shows dot at the egg room cell after the egg is collected`() {
        let state = GameState.initial(config: .default)
            .withCurrentFloor(2)
            .withPlayerPosition(Position(x: 7, y: 0))
            .withHasEgg(true)
            .withScreenMode(.dungeon)
        let spy = render(state)
        #expect(minimapCharAt(x: 2, y: 3, spy: spy) == ".", "Expected '.' at egg room (2,3) after collection")
    }

    @Test func `Minimap shows S at the staircase cell on a non-final floor`() {
        let state = GameState.initial(config: .default)
            .withPlayerPosition(Position(x: 7, y: 0))
            .withScreenMode(.dungeon)
        let spy = render(state)
        #expect(minimapCharAt(x: 7, y: 6, spy: spy) == "S", "Expected 'S' at staircase (7,6) on non-final floor")
    }

    @Test func `Minimap shows X at the exit cell on the final floor`() {
        let finalFloor = GameConfig.default.maxFloors
        let state = GameState.initial(config: .default)
            .withCurrentFloor(finalFloor)
            .withPlayerPosition(Position(x: 7, y: 0))
            .withScreenMode(.dungeon)
        let spy = render(state)
        #expect(minimapCharAt(x: 7, y: 6, spy: spy) == "X", "Expected 'X' at exit (7,6) on final floor")
    }
}

// MARK: - ADR-006 Screen Layout - Vertical Split

@Suite struct `Turning Mechanic — Vertical Split Layout (ADR-006)` {

    private func characterAtCol60(row: Int, in entries: [TUIOutputSpy.Entry]) -> Character? {
        for entry in entries where entry.row == row {
            if entry.col == 60 {
                return entry.string.first
            }
            if entry.col == 1 && entry.string.count >= 60 {
                let idx = entry.string.index(entry.string.startIndex, offsetBy: 59)
                return entry.string[idx]
            }
        }
        return nil
    }

    @Test func `Top border has split connector at column 60`() {
        let spy = TUIOutputSpy()
        let renderer = Renderer(output: spy)
        let state = GameState.initial(config: .default).withScreenMode(.dungeon)
        renderer.render(state)
        let ch = characterAtCol60(row: 1, in: spy.entries)
        #expect(ch == "\u{252C}", "Expected top-split connector at row 1 col 60, got: \(ch.map(String.init) ?? "nil")")
    }

    @Test func `Vertical divider is present at column 60 for all dungeon view rows (2-16)`() {
        let spy = TUIOutputSpy()
        let renderer = Renderer(output: spy)
        let state = GameState.initial(config: .default).withScreenMode(.dungeon)
        renderer.render(state)
        for row in 2...16 {
            let ch = characterAtCol60(row: row, in: spy.entries)
            #expect(ch == "\u{2502}", "Expected vertical divider at row \(row) col 60, got: \(ch.map(String.init) ?? "nil")")
        }
    }

    @Test func `Row 17 separator has bottom T-junction at column 60`() {
        let spy = TUIOutputSpy()
        let renderer = Renderer(output: spy)
        let state = GameState.initial(config: .default).withScreenMode(.dungeon)
        renderer.render(state)
        let ch = characterAtCol60(row: 17, in: spy.entries)
        #expect(ch == "\u{2534}", "Expected bottom T-junction at row 17 col 60, got: \(ch.map(String.init) ?? "nil")")
    }
}
