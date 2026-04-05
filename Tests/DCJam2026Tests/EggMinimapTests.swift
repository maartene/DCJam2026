import Testing
@testable import DCJam2026
@testable import GameDomain

// Acceptance Tests — Step 02-01: Egg cell shows '.' on minimap after pickup
//
// Driving port: Renderer(output:) via TUIOutputSpy for minimap rendering assertions.
//
// AC1: Minimap renders '*' at egg position when hasEgg == false (egg not yet collected)
// AC2: Minimap renders '.' at egg position when hasEgg == true (egg collected)
// AC3: No 'e' character appears at the egg position in either state
//
// Test Budget: 3 distinct behaviors x 2 = 6 max unit tests; 3 used.

@Suite struct `Egg cell disappears from minimap after Ember picks up the egg` {

    // Floor 2 has an egg room at position (2, 3) per FloorGenerator
    private let eggFloor = 2
    private let eggPos = Position(x: 2, y: 3)

    // AC1: egg room shows '*' before the egg is collected
    @Test func `Minimap shows star at egg room position when egg has not been collected`() {
        let state = GameState.initial(config: .default)
            .withCurrentFloor(eggFloor)
            .withPlayerPosition(Position(x: 7, y: 0))
            .withHasEgg(false)
            .withScreenMode(.dungeon)
        let spy = TUIOutputSpy()
        Renderer(output: spy).render(state)

        let targetRow = 3 + (6 - eggPos.y)
        let targetCol = 61 + eggPos.x
        let cellWrites = spy.entries.filter { $0.row == targetRow && $0.col == targetCol }
        let allText = cellWrites.map(\.string).joined()
        let stripped = stripANSI(allText)

        #expect(stripped.contains("*"), "Egg room must show '*' before collection, got: \(stripped)")
        #expect(!stripped.contains("e"), "Egg room must NOT show 'e' before collection (AC3), got: \(stripped)")
    }

    // AC2: egg room shows '.' after the egg is collected
    @Test func `Minimap shows dot at egg room position after Ember picks up the egg`() {
        let state = GameState.initial(config: .default)
            .withCurrentFloor(eggFloor)
            .withPlayerPosition(Position(x: 7, y: 0))
            .withHasEgg(true)
            .withScreenMode(.dungeon)
        let spy = TUIOutputSpy()
        Renderer(output: spy).render(state)

        let targetRow = 3 + (6 - eggPos.y)
        let targetCol = 61 + eggPos.x
        let cellWrites = spy.entries.filter { $0.row == targetRow && $0.col == targetCol }
        let allText = cellWrites.map(\.string).joined()
        let stripped = stripANSI(allText)

        #expect(stripped.contains("."), "Egg room must show '.' after collection, got: \(stripped)")
        #expect(!stripped.contains("e"), "Egg room must NOT show 'e' in either state (AC3), got: \(stripped)")
    }

    // AC3: no 'e' character appears at egg position in uncollected state
    @Test func `No e character appears at egg room position in any state`() {
        let states: [(String, GameState)] = [
            ("uncollected", GameState.initial(config: .default)
                .withCurrentFloor(eggFloor)
                .withPlayerPosition(Position(x: 7, y: 0))
                .withHasEgg(false)
                .withScreenMode(.dungeon)),
            ("collected", GameState.initial(config: .default)
                .withCurrentFloor(eggFloor)
                .withPlayerPosition(Position(x: 7, y: 0))
                .withHasEgg(true)
                .withScreenMode(.dungeon)),
        ]

        for (label, state) in states {
            let spy = TUIOutputSpy()
            Renderer(output: spy).render(state)

            let targetRow = 3 + (6 - eggPos.y)
            let targetCol = 61 + eggPos.x
            let cellWrites = spy.entries.filter { $0.row == targetRow && $0.col == targetCol }
            let allText = cellWrites.map(\.string).joined()
            let stripped = stripANSI(allText)

            #expect(!stripped.contains("e"), "Egg room must never show 'e' (\(label) state), got: \(stripped)")
        }
    }
}

// MARK: - Shared test helpers

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
