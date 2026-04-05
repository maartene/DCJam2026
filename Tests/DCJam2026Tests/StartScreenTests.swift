import Testing
@testable import DCJam2026
@testable import GameDomain

// Start screen renderer tests — step 03-02
//
// Acceptance criteria:
//   AC1: render(.startScreen) does NOT call drawChrome() — verified by absence of chrome write at row 1
//   AC2: render(.startScreen) does NOT call drawStatusBar() — verified by absence of writes at row 18
//   AC3: rendered output contains "EMBER'S ESCAPE"
//   AC4: rendered output contains "Press any key to begin"
//   AC5: rendered output does NOT contain "Q" as a control reference
//   AC6: render(.dungeon) does NOT render start screen content
//
// Test budget: 6 behaviors × 2 = 12 max. Using 6 tests (1 per AC).

@Suite struct `Renderer — Start Screen` {

    private func capturedOutput(screenMode: ScreenMode) -> [TUIOutputSpy.Entry] {
        let spy = TUIOutputSpy()
        let renderer = Renderer(output: spy)
        var state = GameState.initial(config: .default)
        state = state.withScreenMode(screenMode)
        renderer.render(state)
        return spy.entries
    }

    private func allText(screenMode: ScreenMode) -> String {
        capturedOutput(screenMode: screenMode).map(\.string).joined()
    }

    // AC1: drawChrome() writes the top border at row 1 col 1; start screen must NOT produce that write
    @Test func `start screen does not call drawChrome`() {
        let entries = capturedOutput(screenMode: .startScreen)
        let row1Writes = entries.filter { $0.row == 1 }
        #expect(row1Writes.isEmpty, "drawChrome() must not be called for .startScreen; found writes at row 1: \(row1Writes.map(\.string))")
    }

    // AC2: drawStatusBar() writes at row 18; start screen must NOT produce that write
    @Test func `start screen does not call drawStatusBar`() {
        let entries = capturedOutput(screenMode: .startScreen)
        let row18Writes = entries.filter { $0.row == 18 }
        #expect(row18Writes.isEmpty, "drawStatusBar() must not be called for .startScreen; found writes at row 18: \(row18Writes.map(\.string))")
    }

    // AC3: rendered output contains title text
    @Test func `start screen output contains EMBER'S ESCAPE`() {
        let text = allText(screenMode: .startScreen)
        #expect(text.contains("EMBER'S ESCAPE"), "Start screen must contain title 'EMBER'S ESCAPE'")
    }

    // AC4: rendered output contains the prompt text
    @Test func `start screen output contains Press any key to begin`() {
        let text = allText(screenMode: .startScreen)
        #expect(text.contains("Press any key to begin"), "Start screen must contain 'Press any key to begin'")
    }

    // AC5: rendered output must not contain "Q" as a control reference
    // We check the raw text excluding ANSI escape sequences for Q as a standalone key binding
    @Test func `start screen output does not reference Q as a control`() {
        let text = allText(screenMode: .startScreen)
        let plain = stripANSI(text)
        // Q as a standalone control key appears as "Q  —", "Q:", "Q=" or at the start of a token
        // Check for Q followed by whitespace or punctuation that indicates a key binding
        #expect(!plain.contains("Q  —"), "Start screen must not list Q as a key binding")
        #expect(!plain.contains("Q: "), "Start screen must not list Q as a key binding")
        #expect(!plain.contains("Q="), "Start screen must not list Q as a key binding")
        #expect(!plain.contains("Q/"), "Start screen must not list Q as a key binding")
    }

    // AC6: dungeon mode does not render start screen content
    @Test func `dungeon mode does not render start screen content`() {
        let text = allText(screenMode: .dungeon)
        // Start screen writes title at specific rows (4-8); dungeon writes chrome at row 1
        let entries = capturedOutput(screenMode: .dungeon)
        let row1Writes = entries.filter { $0.row == 1 }
        #expect(!row1Writes.isEmpty, "Dungeon mode must call drawChrome() (writes at row 1)")
        // Also verify start screen prompt does NOT appear in dungeon output
        #expect(!text.contains("Press any key to begin"), "Dungeon mode must not contain start screen prompt")
    }
}

