import Testing
@testable import DCJam2026
@testable import GameDomain

// Minimap Color Tests — step 03-07 (per-cell color writes)
//
// Driving port: Renderer.render(_:) via TUIOutputSpy.
// Tests assert that each minimap character type is wrapped with the correct ANSI color code
// and terminated with an ANSI reset.
//
// Test Budget: 9 distinct behaviors × 2 = 18 max tests; 9 used (one per symbol type).
//   B1: player direction chars (^>v<) — bold bright white
//   B2: G (guard)              — bright red
//   B3: B (boss)               — bold bright red
//   B4: * (egg uncollected)    — bright yellow
//   B5: e (egg collected)      — dim yellow
//   B6: S (staircase)          — bright cyan
//   B7: X (exit)               — bold bright cyan
//   B8: E (entry)              — dim cyan
//   B9: # (wall)               — dark gray
//
// Per-cell write contract: each cell (x, y) writes at col = 61 + x, row = 2 + (height-1 - y).
// Colored cells: write is color + char + reset.
// Passable ('.') cells: write is char only (no color prefix).

@Suite struct `Minimap — Per-Cell Color Coding` {

    private let ansiReset    = "\u{1B}[0m"
    private let boldBrightWhite = "\u{1B}[1m\u{1B}[97m"
    private let brightRed    = "\u{1B}[91m"
    private let boldBrightRed = "\u{1B}[1m\u{1B}[91m"
    private let brightYellow = "\u{1B}[93m"
    private let dimYellow    = "\u{1B}[33m"
    private let brightCyan   = "\u{1B}[96m"
    private let boldBrightCyan = "\u{1B}[1m\u{1B}[96m"
    private let dimCyan      = "\u{1B}[36m"
    private let darkGray     = "\u{1B}[90m"

    // Returns the concatenated write string(s) for a specific minimap cell.
    // With per-cell writes, each cell (x, y) is written at col = 61 + x, row = 2 + (gridHeight-1 - y).
    // gridHeight for default floor = 7.
    private func cellContent(x: Int, y: Int, spy: TUIOutputSpy, gridHeight: Int = 7) -> String {
        let targetRow = 2 + (gridHeight - 1 - y)
        let targetCol = 61 + x
        return spy.entries
            .filter { $0.row == targetRow && $0.col == targetCol }
            .map(\.string)
            .joined()
    }

    private func render(_ state: GameState) -> TUIOutputSpy {
        let spy = TUIOutputSpy()
        Renderer(output: spy).render(state)
        return spy
    }

    // B1: Player facing north (^) — bold bright white + reset
    @Test func `Player facing north uses bold bright white with ANSI reset`() {
        let state = GameState.initial(config: .default)
            .withFacingDirection(.north)
            .withScreenMode(.dungeon)
        // Player at (7,0): col = 61+7 = 68, row = 2+(6-0) = 8
        let spy = render(state)
        let content = cellContent(x: 7, y: 0, spy: spy)
        #expect(content.contains(boldBrightWhite), "Expected bold bright white for '^', got: \(content)")
        #expect(content.contains("^"), "Expected '^' character, got: \(content)")
        #expect(content.contains(ansiReset), "Expected ANSI reset after '^', got: \(content)")
    }

    // B2: G (guard) — bright red + reset
    @Test func `Guard cell uses bright red with ANSI reset`() {
        // Floor 1: guard at (7,2), player at (7,0) so guard is visible
        let state = GameState.initial(config: .default)
            .withPlayerPosition(Position(x: 7, y: 0))
            .withScreenMode(.dungeon)
        let spy = render(state)
        let content = cellContent(x: 7, y: 2, spy: spy)
        #expect(content.contains(brightRed), "Expected bright red for 'G', got: \(content)")
        #expect(content.contains("G"), "Expected 'G' character, got: \(content)")
        #expect(content.contains(ansiReset), "Expected ANSI reset after 'G', got: \(content)")
    }

    // B3: B (boss) — bold bright red + reset
    @Test func `Boss cell uses bold bright red with ANSI reset`() {
        let finalFloor = GameConfig.default.maxFloors
        let state = GameState.initial(config: .default)
            .withCurrentFloor(finalFloor)
            .withPlayerPosition(Position(x: 7, y: 0))
            .withScreenMode(.dungeon)
        let spy = render(state)
        let content = cellContent(x: 7, y: 3, spy: spy)
        #expect(content.contains(boldBrightRed), "Expected bold bright red for 'B', got: \(content)")
        #expect(content.contains("B"), "Expected 'B' character, got: \(content)")
        #expect(content.contains(ansiReset), "Expected ANSI reset after 'B', got: \(content)")
    }

    // B4: * (egg uncollected) — bright yellow + reset
    @Test func `Uncollected egg cell uses bright yellow with ANSI reset`() {
        // Floor 2 has egg room at (2,3)
        let state = GameState.initial(config: .default)
            .withCurrentFloor(2)
            .withPlayerPosition(Position(x: 7, y: 0))
            .withScreenMode(.dungeon)
        let spy = render(state)
        let content = cellContent(x: 2, y: 3, spy: spy)
        #expect(content.contains(brightYellow), "Expected bright yellow for '*', got: \(content)")
        #expect(content.contains("*"), "Expected '*' character, got: \(content)")
        #expect(content.contains(ansiReset), "Expected ANSI reset after '*', got: \(content)")
    }

    // B5: e (egg collected) — dim yellow + reset
    @Test func `Collected egg cell uses dim yellow with ANSI reset`() {
        let state = GameState.initial(config: .default)
            .withCurrentFloor(2)
            .withPlayerPosition(Position(x: 7, y: 0))
            .withHasEgg(true)
            .withScreenMode(.dungeon)
        let spy = render(state)
        let content = cellContent(x: 2, y: 3, spy: spy)
        #expect(content.contains(dimYellow), "Expected dim yellow for 'e', got: \(content)")
        #expect(content.contains("e"), "Expected 'e' character, got: \(content)")
        #expect(content.contains(ansiReset), "Expected ANSI reset after 'e', got: \(content)")
    }

    // B6: S (staircase) — bright cyan + reset
    @Test func `Staircase cell uses bright cyan with ANSI reset`() {
        let state = GameState.initial(config: .default)
            .withPlayerPosition(Position(x: 7, y: 0))
            .withScreenMode(.dungeon)
        let spy = render(state)
        let content = cellContent(x: 7, y: 6, spy: spy)
        #expect(content.contains(brightCyan), "Expected bright cyan for 'S', got: \(content)")
        #expect(content.contains("S"), "Expected 'S' character, got: \(content)")
        #expect(content.contains(ansiReset), "Expected ANSI reset after 'S', got: \(content)")
    }

    // B7: X (exit) — bold bright cyan + reset
    @Test func `Exit cell uses bold bright cyan with ANSI reset`() {
        let finalFloor = GameConfig.default.maxFloors
        let state = GameState.initial(config: .default)
            .withCurrentFloor(finalFloor)
            .withPlayerPosition(Position(x: 7, y: 0))
            .withScreenMode(.dungeon)
        let spy = render(state)
        let content = cellContent(x: 7, y: 6, spy: spy)
        #expect(content.contains(boldBrightCyan), "Expected bold bright cyan for 'X', got: \(content)")
        #expect(content.contains("X"), "Expected 'X' character, got: \(content)")
        #expect(content.contains(ansiReset), "Expected ANSI reset after 'X', got: \(content)")
    }

    // B8: E (entry) — dim cyan + reset
    @Test func `Entry cell uses dim cyan with ANSI reset`() {
        // Player at y=3 so entry at (7,0) is visible
        let state = GameState.initial(config: .default)
            .withPlayerPosition(Position(x: 7, y: 3))
            .withScreenMode(.dungeon)
        let spy = render(state)
        let content = cellContent(x: 7, y: 0, spy: spy)
        #expect(content.contains(dimCyan), "Expected dim cyan for 'E', got: \(content)")
        #expect(content.contains("E"), "Expected 'E' character, got: \(content)")
        #expect(content.contains(ansiReset), "Expected ANSI reset after 'E', got: \(content)")
    }

    // B9: # (wall) — dark gray + reset
    @Test func `Wall cell uses dark gray with ANSI reset`() {
        // Wall at (0,0) — leftmost cell on bottom row of floor 1 is a wall
        let state = GameState.initial(config: .default)
            .withPlayerPosition(Position(x: 7, y: 0))
            .withScreenMode(.dungeon)
        let spy = render(state)
        let content = cellContent(x: 0, y: 0, spy: spy)
        #expect(content.contains(darkGray), "Expected dark gray for '#', got: \(content)")
        #expect(content.contains("#"), "Expected '#' character, got: \(content)")
        #expect(content.contains(ansiReset), "Expected ANSI reset after '#', got: \(content)")
    }

    // Passable cell '.' has no color prefix
    @Test func `Passable corridor cell has no ANSI color prefix`() {
        // (7,1) should be a passable corridor cell on floor 1
        let state = GameState.initial(config: .default)
            .withPlayerPosition(Position(x: 7, y: 0))
            .withScreenMode(.dungeon)
        let spy = render(state)
        let content = cellContent(x: 7, y: 1, spy: spy)
        #expect(content == ".", "Expected bare '.' with no color for passable cell, got: \(content)")
    }
}
