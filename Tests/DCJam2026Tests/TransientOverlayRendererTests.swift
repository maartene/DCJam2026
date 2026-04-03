import Testing
@testable import DCJam2026
@testable import GameDomain

// TransientOverlay Renderer Tests — step 04-01 (US-P06)
// Test budget: 5 distinct behaviors × 2 = 10 unit tests max
//
// B1: braceSuccess renders "SHIELDED!" in dungeon/combat mode
// B2: braceHit renders "STRUCK!" in dungeon/combat mode
// B3: Overlay uses correct ANSI color + reset wrapping, positioned at row 9
// B4: Non-dungeon/combat screen modes suppress overlay regardless of transientOverlay
// B5: nil transientOverlay produces no overlay word

@Suite struct `Renderer — Transient Overlay` {

    private func makeDungeonState(overlay: TransientOverlay?) -> GameState {
        GameState.initial(config: .default)
            .withScreenMode(.dungeon)
            .withTransientOverlay(overlay)
    }

    // MARK: - B1: braceSuccess renders "SHIELDED!"

    @Test func `braceSuccess overlay in dungeon mode renders SHIELDED! word`() {
        let spy = TUIOutputSpy()
        let state = makeDungeonState(overlay: .braceSuccess(framesRemaining: 10))
        Renderer(output: spy).render(state)

        let allText = spy.entries.map { $0.string }.joined()
        #expect(allText.contains("SHIELDED!"))
    }

    @Test func `braceSuccess overlay wraps SHIELDED! in bright cyan with reset`() {
        let spy = TUIOutputSpy()
        let state = makeDungeonState(overlay: .braceSuccess(framesRemaining: 10))
        Renderer(output: spy).render(state)

        let allText = spy.entries.map { $0.string }.joined()
        // AC2 + AC7: bright cyan (\u{1B}[96m) wrapping + ANSI reset (\u{1B}[0m)
        #expect(allText.contains("\u{1B}[96mSHIELDED!\u{1B}[0m"))
    }

    // MARK: - B2: braceHit renders "STRUCK!"

    @Test func `braceHit overlay in dungeon mode renders STRUCK! word`() {
        let spy = TUIOutputSpy()
        let state = makeDungeonState(overlay: .braceHit(framesRemaining: 10))
        Renderer(output: spy).render(state)

        let allText = spy.entries.map { $0.string }.joined()
        #expect(allText.contains("STRUCK!"))
    }

    @Test func `braceHit overlay wraps STRUCK! in bright red with reset`() {
        let spy = TUIOutputSpy()
        let state = makeDungeonState(overlay: .braceHit(framesRemaining: 10))
        Renderer(output: spy).render(state)

        let allText = spy.entries.map { $0.string }.joined()
        // AC4 + AC7: bright red (\u{1B}[91m) wrapping + ANSI reset (\u{1B}[0m)
        #expect(allText.contains("\u{1B}[91mSTRUCK!\u{1B}[0m"))
    }

    // MARK: - B3: Overlay positioned at row 9, centered in 60-wide main view

    @Test func `braceSuccess overlay is rendered at row 9`() {
        let spy = TUIOutputSpy()
        let state = makeDungeonState(overlay: .braceSuccess(framesRemaining: 10))
        Renderer(output: spy).render(state)

        // Find the entry that contains the colored overlay word
        let overlayEntry = spy.entries.first { $0.string.contains("SHIELDED!") }
        #expect(overlayEntry?.row == 9)
    }

    @Test func `braceSuccess overlay column is centered within 60-wide main view`() {
        let spy = TUIOutputSpy()
        let state = makeDungeonState(overlay: .braceSuccess(framesRemaining: 10))
        Renderer(output: spy).render(state)

        // "SHIELDED!" is 9 chars; col = (60 - 9) / 2 + 1 = 26
        let overlayEntry = spy.entries.first { $0.string.contains("SHIELDED!") }
        #expect(overlayEntry?.col == 26)
    }

    // MARK: - B4: Non-dungeon/combat modes suppress overlay

    @Test func `no overlay rendered when screenMode is startScreen`() {
        let spy = TUIOutputSpy()
        let state = GameState.initial(config: .default)
            .withScreenMode(.startScreen)
            .withTransientOverlay(.braceSuccess(framesRemaining: 10))
        Renderer(output: spy).render(state)

        let allText = spy.entries.map { $0.string }.joined()
        #expect(!allText.contains("SHIELDED!"))
        #expect(!allText.contains("STRUCK!"))
    }

    @Test func `no overlay rendered when screenMode is winState`() {
        let spy = TUIOutputSpy()
        let state = GameState.initial(config: .default)
            .withScreenMode(.winState)
            .withTransientOverlay(.braceHit(framesRemaining: 5))
        Renderer(output: spy).render(state)

        let allText = spy.entries.map { $0.string }.joined()
        #expect(!allText.contains("SHIELDED!"))
        #expect(!allText.contains("STRUCK!"))
    }

    // MARK: - B5: nil transientOverlay produces no overlay

    @Test func `no overlay word rendered when transientOverlay is nil`() {
        let spy = TUIOutputSpy()
        let state = makeDungeonState(overlay: nil)
        Renderer(output: spy).render(state)

        let allText = spy.entries.map { $0.string }.joined()
        #expect(!allText.contains("SHIELDED!"))
        #expect(!allText.contains("STRUCK!"))
    }
}
