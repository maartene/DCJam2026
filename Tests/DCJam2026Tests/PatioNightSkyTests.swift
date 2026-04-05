// PatioNightSkyTests — step 03-01 (gameplay-polish-fixes)
//
// Scenario: Exit patio overlay shows night sky with stars
//
// Acceptance Criteria:
//   AC1: renderNarrativeOverlay(.exitPatio) output contains star characters ('*') in the body
//   AC2: renderNarrativeOverlay(.exitPatio) output contains the header 'THE PATIO'
//   AC3: renderNarrativeOverlay(.exitPatio) output contains the text 'free'
//   AC4: Night sky art renders within the dungeon view area (no corruption of chrome)
//
// Test Budget: 3 distinct behaviors × 2 = 6 max unit tests (using 3)

import Testing
@testable import DCJam2026
@testable import GameDomain

@Suite struct `Renderer — exit patio night sky` {

    // Behavior 1: overlay body contains star-field art (AC1)
    // The night sky body lines contain both '*' and '.' characters (star-field pattern)
    // e.g. "       *    .  *       .        "
    // This is distinct from the header row which contains "* * *  THE PATIO  * * *" (no dots)
    @Test func `exit patio overlay body contains star field art`() {
        let spy = TUIOutputSpy()
        let renderer = Renderer(output: spy)
        let state = makeNarrativeOverlayState(event: .exitPatio)
        renderer.render(state)

        let allText = spy.entries.map(\.string).joined()
        let plain = stripANSI(allText)
        // Star-field body lines contain both '*' and '.' on the same line
        // Split by newline is unreliable (cursor moves are used), so check for the specific pattern
        // where '*' appears adjacent to spaces and dots (the sky art pattern)
        let hasStarDotPattern = plain.contains("*    .") || plain.contains(".  *") || plain.contains("*       .")
        #expect(hasStarDotPattern, "Body must contain night sky star-field art combining '*' and '.' characters")
    }

    // Behavior 2: overlay header contains 'THE PATIO' (AC2)
    @Test func `exit patio overlay contains THE PATIO header`() {
        let spy = TUIOutputSpy()
        let renderer = Renderer(output: spy)
        let state = makeNarrativeOverlayState(event: .exitPatio)
        renderer.render(state)

        let allText = spy.entries.map(\.string).joined()
        let plain = stripANSI(allText)
        #expect(plain.contains("THE PATIO"), "Overlay header must read 'THE PATIO'")
    }

    // Behavior 3: overlay body contains the word 'free' (AC3)
    @Test func `exit patio overlay body contains the word free`() {
        let spy = TUIOutputSpy()
        let renderer = Renderer(output: spy)
        let state = makeNarrativeOverlayState(event: .exitPatio)
        renderer.render(state)

        let allText = spy.entries.map(\.string).joined()
        let plain = stripANSI(allText)
        #expect(plain.contains("free"), "Body must contain the word 'free'")
    }

    // Helper
    private func makeNarrativeOverlayState(event: NarrativeEvent) -> GameState {
        var state = GameState.initial(config: .default)
        state.screenMode = .narrativeOverlay(event: event)
        return state
    }
}

