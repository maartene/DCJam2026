import Testing
@testable import DCJam2026
@testable import GameDomain

// Renderer win screen tests — step 03-04
// Acceptance criteria:
//   AC1: stat block contains player's current HP value
//   AC2: stat block contains floors cleared count
//   AC3: prompt reads "Press R to play again"
//   AC4: all colored segments terminated with ANSI reset
//
// Test budget: 4 behaviors × 2 = 8 max. Using 1 parametrized test covering 4 ACs.

@Suite struct `Renderer — Win Screen` {

    // Helper: spy captures all writes when rendering win state
    private func capturedWinScreenOutput(hp: Int, floor: Int) -> String {
        let spy = TUIOutputSpy()
        let renderer = Renderer(output: spy)
        var state = GameState.initial(config: .default)
        state = state.withHP(hp)
        state = state.withCurrentFloor(floor)
        state = state.withScreenMode(.winState)
        renderer.render(state)
        return spy.entries.map(\.string).joined()
    }

    // Helper: only rows 2-16 (main view area where win screen content is drawn)
    private func capturedWinScreenMainView(hp: Int, floor: Int) -> String {
        let spy = TUIOutputSpy()
        let renderer = Renderer(output: spy)
        var state = GameState.initial(config: .default)
        state = state.withHP(hp)
        state = state.withCurrentFloor(floor)
        state = state.withScreenMode(.winState)
        renderer.render(state)
        return spy.entries.filter { (2...16).contains($0.row) }.map(\.string).joined()
    }

    @Test("Win screen stat block includes HP value", arguments: [
        (hp: 42, floor: 3),
        (hp: 100, floor: 5),
    ])
    func winScreenContainsHP(hp: Int, floor: Int) {
        let output = capturedWinScreenOutput(hp: hp, floor: floor)
        #expect(output.contains("\(hp)"), "Expected HP value \(hp) in win screen output")
    }

    @Test("Win screen stat block includes floors cleared count", arguments: [
        (hp: 80, floor: 3),
        (hp: 100, floor: 5),
    ])
    func winScreenContainsFloorsCleared(hp: Int, floor: Int) {
        let output = capturedWinScreenOutput(hp: hp, floor: floor)
        // floors cleared = currentFloor - 1 (player is on next floor when win triggers)
        let floorsCleared = floor - 1
        #expect(output.contains("\(floorsCleared)"), "Expected floors cleared \(floorsCleared) in win screen output")
    }

    @Test func `Win screen prompt reads Press R to play again`() {
        let output = capturedWinScreenOutput(hp: 100, floor: 5)
        #expect(output.contains("Press R to play again"), "Expected 'Press R to play again' in win screen prompt")
    }

    @Test func `Win screen main view uses ANSI colors and every color open is terminated with a reset`() {
        // Scope: rows 2-16 only (win screen content area, excludes status bar)
        let output = capturedWinScreenMainView(hp: 75, floor: 3)
        let resetSequence = "\u{1B}[0m"
        // Count non-reset ANSI escapes: replace resets first, then count remaining ESC[
        let withoutResets = output.replacingOccurrences(of: resetSequence, with: "")
        let colorOpenCount = withoutResets.components(separatedBy: "\u{1B}[").count - 1
        let resetCount = output.components(separatedBy: resetSequence).count - 1
        // Win screen content MUST use at least one ANSI color
        #expect(colorOpenCount > 0, "Win screen main view must use at least one ANSI color sequence")
        // Every color open must be paired with a reset
        #expect(resetCount >= colorOpenCount,
                "Expected at least \(colorOpenCount) resets for \(colorOpenCount) color opens, found \(resetCount)")
    }
}
