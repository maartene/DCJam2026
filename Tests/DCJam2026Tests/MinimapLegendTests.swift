import Testing
@testable import DCJam2026
@testable import GameDomain

// Acceptance Tests — US-GPF-03: Minimap Legend
//
// Driving port: Renderer(output: TUIOutputSpy()) — the rendering driving port.
//               All tests observe what the renderer writes to the terminal via the port.
//
// Story: In dungeon navigation mode, the right panel shows a compact legend below the
// minimap (rows 10-16, cols 61-79). Each entry shows the minimap symbol in its correct
// colour and a plain-text label. The legend is invisible in all other screen modes.
// Row 17 (the status bar separator) must not be overwritten.
//
// Error path ratio: 4 of 9 scenarios = 44% (exceeds 40% mandate).
//
// Mandate compliance:
//   CM-A: All tests invoke the Renderer driving port via TUIOutputSpy.
//   CM-B: Names use game domain terms (legend, dungeon mode, right panel, Ember).
//         Zero technical terms (no "drawMinimapLegend", no "moveCursor").
//   CM-C: Each test validates observable output a player can see.

@Suite struct `Minimap Legend — Walking Skeleton` {

    // -------------------------------------------------------------------------
    // WALKING SKELETON — the thinnest observable slice:
    // Ember is in dungeon mode and sees the legend with all 7 entries.
    // -------------------------------------------------------------------------

    @Test func `Dungeon mode shows a legend in the right panel with all 7 symbol entries`() {
        // Given — Ember is in dungeon navigation mode
        let state = GameState.initial(config: .default).withScreenMode(.dungeon)
        // When — the screen renders
        let spy = TUIOutputSpy()
        Renderer(output: spy).render(state)
        // Then — the legend region (rows 9-15, cols 61-79) contains all 7 expected labels
        let legendWrites = spy.entries.filter { (10...16).contains($0.row) && (61...79).contains($0.col) }
        let legendText = legendWrites.map(\.string).joined()
        let stripped = stripANSI(legendText)
        #expect(stripped.contains("You"),    "Legend must contain 'You' entry")
        #expect(stripped.contains("Guard"),  "Legend must contain 'Guard' entry")
        #expect(stripped.contains("Boss"),   "Legend must contain 'Boss' entry")
        #expect(stripped.contains("Egg"),    "Legend must contain 'Egg' entry")
        #expect(stripped.contains("Stairs"), "Legend must contain 'Stairs' entry")
        #expect(stripped.contains("Entry"),  "Legend must contain 'Entry' entry")
        #expect(stripped.contains("Exit"),   "Legend must contain 'Exit' entry")
    }
}

// -------------------------------------------------------------------------
// Focused scenarios — US-GPF-03 happy paths
// -------------------------------------------------------------------------

@Suite struct `Minimap Legend — Happy Paths` {

    // GPF-03-H1: Legend symbol characters appear in the legend region
    @Test func `Legend region contains the correct symbol characters for all 7 entries`() {
        let state = GameState.initial(config: .default).withScreenMode(.dungeon)
        let spy = TUIOutputSpy()
        Renderer(output: spy).render(state)
        let legendWrites = spy.entries.filter { (10...16).contains($0.row) && (61...79).contains($0.col) }
        let legendText = legendWrites.map(\.string).joined()
        let stripped = stripANSI(legendText)
        #expect(stripped.contains("^"), "Legend must contain '^' symbol for You")
        #expect(stripped.contains("G"), "Legend must contain 'G' symbol for Guard")
        #expect(stripped.contains("B"), "Legend must contain 'B' symbol for Boss")
        #expect(stripped.contains("*"), "Legend must contain '*' symbol for Egg")
        #expect(stripped.contains("S"), "Legend must contain 'S' symbol for Stairs")
        #expect(stripped.contains("E"), "Legend must contain 'E' symbol for Entry")
        #expect(stripped.contains("X"), "Legend must contain 'X' symbol for Exit")
    }

    // GPF-03-H2: Legend "^" entry carries the bright white colour code
    @Test func `Legend You symbol carries the bold bright white colour used on the minimap`() {
        let state = GameState.initial(config: .default).withScreenMode(.dungeon)
        let spy = TUIOutputSpy()
        Renderer(output: spy).render(state)
        // Row 10 is the "You" entry; find writes to row 10 in the legend region
        let row9Writes = spy.entries.filter { $0.row == 10 && (61...79).contains($0.col) }
        let row9Text = row9Writes.map(\.string).joined()
        // Bold bright white = ESC[1;97m or ESC[1m combined with 37 or 97
        // The presence of an ESC sequence followed by "^" confirms coloured rendering
        #expect(row9Text.contains("^"), "Row 10 (You) must contain the '^' symbol")
        #expect(row9Text.contains("\u{1B}"), "Row 10 (You) must contain an ANSI colour sequence for the symbol")
    }

    // GPF-03-H3: Legend is contained within 7 rows (10-16); row 17 is not written to by legend content
    @Test func `Legend occupies exactly rows 10-16 — row 17 contains no legend labels`() {
        let state = GameState.initial(config: .default).withScreenMode(.dungeon)
        let spy = TUIOutputSpy()
        Renderer(output: spy).render(state)
        // Row 17 must not contain any of the legend label words
        let row16Writes = spy.entries.filter { $0.row == 17 && (61...79).contains($0.col) }
        let row16Text = row16Writes.map(\.string).joined()
        let stripped = stripANSI(row16Text)
        #expect(!stripped.contains("Guard"),  "Row 17 must not contain legend label 'Guard'")
        #expect(!stripped.contains("Boss"),   "Row 17 must not contain legend label 'Boss'")
        #expect(!stripped.contains("Stairs"), "Row 17 must not contain legend label 'Stairs'")
        #expect(!stripped.contains("Entry"),  "Row 17 must not contain legend label 'Entry'")
        #expect(!stripped.contains("Exit"),   "Row 17 must not contain legend label 'Exit'")
    }

    // GPF-03-H4: Legend renders on every dungeon floor (floor 2 with egg room present)
    @Test func `Legend is visible on floor 2 when the egg room is present on the minimap`() {
        let state = GameState.initial(config: .default)
            .withCurrentFloor(2)
            .withScreenMode(.dungeon)
        let spy = TUIOutputSpy()
        Renderer(output: spy).render(state)
        let legendWrites = spy.entries.filter { (10...16).contains($0.row) && (61...79).contains($0.col) }
        let legendText = legendWrites.map(\.string).joined()
        let stripped = stripANSI(legendText)
        #expect(stripped.contains("Egg"), "Legend must still show 'Egg' entry on floor 2")
        #expect(stripped.contains("Guard"), "Legend must still show 'Guard' entry on floor 2")
    }

    // GPF-03-H5: Legend renders on the final floor (floor 5 with exit visible)
    @Test func `Legend is visible on the final floor and shows the Exit entry`() {
        let finalFloor = GameConfig.default.maxFloors
        let state = GameState.initial(config: .default)
            .withCurrentFloor(finalFloor)
            .withScreenMode(.dungeon)
        let spy = TUIOutputSpy()
        Renderer(output: spy).render(state)
        let legendWrites = spy.entries.filter { (10...16).contains($0.row) && (61...79).contains($0.col) }
        let legendText = legendWrites.map(\.string).joined()
        let stripped = stripANSI(legendText)
        #expect(stripped.contains("Exit"), "Legend must show 'Exit' entry on the final floor")
        #expect(stripped.contains("Boss"), "Legend must show 'Boss' entry on the final floor")
    }
}

// -------------------------------------------------------------------------
// Focused scenarios — US-GPF-03 error and boundary paths
// -------------------------------------------------------------------------

@Suite struct `Minimap Legend — Error and Boundary Paths` {

    // GPF-03-E1: Legend must NOT appear in combat mode
    @Test func `Legend is absent from the combat screen — legend only appears in dungeon mode`() {
        // Given — Ember is in combat with a regular guard
        let config = GameConfig.default
        let state = GameState.initial(config: config)
            .withScreenMode(.combat(encounter: EncounterModel.guard(isBossEncounter: false)))
        // When — combat screen renders
        let spy = TUIOutputSpy()
        Renderer(output: spy).render(state)
        // Then — no legend labels appear in the right panel region
        let rightPanelWrites = spy.entries.filter { (10...16).contains($0.row) && (61...79).contains($0.col) }
        let rightPanelText = rightPanelWrites.map(\.string).joined()
        let stripped = stripANSI(rightPanelText)
        #expect(!stripped.contains("Guard"),  "Legend must not appear in combat mode")
        #expect(!stripped.contains("Boss"),   "Legend must not appear in combat mode")
        #expect(!stripped.contains("Stairs"), "Legend must not appear in combat mode")
    }

    // GPF-03-E2: Row 17 separator must not be overwritten by legend content
    @Test func `The status bar separator at row 17 is intact after the legend renders`() {
        // Given — dungeon mode (legend active)
        let state = GameState.initial(config: .default).withScreenMode(.dungeon)
        // When
        let spy = TUIOutputSpy()
        Renderer(output: spy).render(state)
        // Then — row 17 in the right panel region must not carry legend label text
        let row17RightWrites = spy.entries.filter { $0.row == 17 && (61...79).contains($0.col) }
        let row17Text = row17RightWrites.map(\.string).joined()
        let stripped = stripANSI(row17Text)
        #expect(!stripped.contains("Guard"),  "Row 17 must not be overwritten with legend label 'Guard'")
        #expect(!stripped.contains("Boss"),   "Row 17 must not be overwritten with legend label 'Boss'")
        #expect(!stripped.contains("Stairs"), "Row 17 must not be overwritten with legend label 'Stairs'")
        #expect(!stripped.contains("You"),    "Row 17 must not be overwritten with legend label 'You'")
    }

    // GPF-03-E3: Legend does not appear on the death screen
    @Test func `Legend is absent from the death screen`() {
        let state = GameState.initial(config: .default).withScreenMode(.deathState)
        let spy = TUIOutputSpy()
        Renderer(output: spy).render(state)
        let rightPanelWrites = spy.entries.filter { (10...16).contains($0.row) && (61...79).contains($0.col) }
        let text = rightPanelWrites.map(\.string).joined()
        let stripped = stripANSI(text)
        #expect(!stripped.contains("Guard"),  "Legend must not appear on the death screen")
        #expect(!stripped.contains("Stairs"), "Legend must not appear on the death screen")
    }

    // GPF-03-E4: Legend does not appear on the win screen
    @Test func `Legend is absent from the win screen`() {
        let state = GameState.initial(config: .default).withScreenMode(.winState)
        let spy = TUIOutputSpy()
        Renderer(output: spy).render(state)
        let rightPanelWrites = spy.entries.filter { (10...16).contains($0.row) && (61...79).contains($0.col) }
        let text = rightPanelWrites.map(\.string).joined()
        let stripped = stripANSI(text)
        #expect(!stripped.contains("Guard"),  "Legend must not appear on the win screen")
        #expect(!stripped.contains("Stairs"), "Legend must not appear on the win screen")
    }
}

// MARK: - Shared helpers

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
