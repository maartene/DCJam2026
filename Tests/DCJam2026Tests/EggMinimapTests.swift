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

    // Floor 2 has an egg room at position (2, 3) per FloorRegistry
    private let eggFloor = 2
    private let eggPos = Position(x: 2, y: 1)

    // AC1: egg room shows '*' before the egg is collected
    @Test func `Minimap shows star at egg room position when egg has not been collected`() {
        let state = GameState.initial(config: .default)
            .withCurrentFloor(eggFloor)
            .withPlayerPosition(Position(x: 7, y: 0))
            .withHasEgg(false)
            .withScreenMode(.dungeon)
        let spy = render(state)
        let ch = minimapChar(x: eggPos.x, y: eggPos.y, spy: spy)
        #expect(ch == "*", "Egg room must show '*' before collection, got: \(ch.map(String.init) ?? "nil")")
        let stripped = stripANSI(minimapContent(x: eggPos.x, y: eggPos.y, spy: spy))
        #expect(!stripped.contains("e"), "Egg room must NOT show 'e' before collection (AC3), got: \(stripped)")
    }

    // AC2: egg room shows '.' after the egg is collected
    @Test func `Minimap shows dot at egg room position after Ember picks up the egg`() {
        let state = GameState.initial(config: .default)
            .withCurrentFloor(eggFloor)
            .withPlayerPosition(Position(x: 7, y: 0))
            .withHasEgg(true)
            .withScreenMode(.dungeon)
        let spy = render(state)
        let ch = minimapChar(x: eggPos.x, y: eggPos.y, spy: spy)
        #expect(ch == ".", "Egg room must show '.' after collection, got: \(ch.map(String.init) ?? "nil")")
        let stripped = stripANSI(minimapContent(x: eggPos.x, y: eggPos.y, spy: spy))
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
            let spy = render(state)
            let stripped = stripANSI(minimapContent(x: eggPos.x, y: eggPos.y, spy: spy))
            #expect(!stripped.contains("e"), "Egg room must never show 'e' (\(label) state), got: \(stripped)")
        }
    }
}

