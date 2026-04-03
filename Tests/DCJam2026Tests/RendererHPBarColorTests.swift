import Testing
@testable import DCJam2026
@testable import GameDomain

// Test Budget: 3 behaviors (green, yellow, red) x 2 = 6 unit tests
// Parametrized across 6 boundary values covering all 3 color thresholds + both inclusive boundaries.

// HP bar color: the status bar (row 18) HP segment must contain the ANSI color code
// matching the current HP ratio, followed by an ANSI reset.
//   >= 40% → green (\u{1B}[32m)
//   >= 20% and < 40% → yellow (\u{1B}[33m)
//   < 20% → red (\u{1B}[31m)

@Suite struct `Renderer — HP bar color in status bar` {

    // Helper: extract all writes to row 18 as a single concatenated string.
    private func statusBarContent(hp: Int, maxHP: Int = 100) -> String {
        let spy = TUIOutputSpy()
        let renderer = Renderer(output: spy)
        var config = GameConfig.default
        config.maxHP = maxHP
        var state = GameState.initial(config: config)
        state = state.withHP(hp).withScreenMode(.dungeon)
        renderer.render(state)
        return spy.entries
            .filter { $0.row == 18 }
            .map { $0.string }
            .joined()
    }

    // MARK: - Green (>= 40% maxHP)

    @Test func `hp at 100 percent uses green`() {
        let content = statusBarContent(hp: 100)
        #expect(content.contains("\u{1B}[32m"), "Expected green ANSI code at 100% HP")
    }

    @Test func `hp at exactly 40 percent boundary uses green`() {
        // 40 / 100 = 0.40 — inclusive green boundary
        let content = statusBarContent(hp: 40)
        #expect(content.contains("\u{1B}[32m"), "Expected green ANSI code at exactly 40% HP")
        #expect(!content.contains("\u{1B}[33m"), "Should NOT contain yellow at 40% HP")
    }

    // MARK: - Yellow (>= 20% and < 40% maxHP)

    @Test func `hp at 39 percent uses yellow`() {
        let content = statusBarContent(hp: 39)
        #expect(content.contains("\u{1B}[33m"), "Expected yellow ANSI code at 39% HP")
        #expect(!content.contains("\u{1B}[32m"), "Should NOT contain green at 39% HP")
    }

    @Test func `hp at exactly 20 percent boundary uses yellow`() {
        // 20 / 100 = 0.20 — inclusive yellow boundary
        let content = statusBarContent(hp: 20)
        #expect(content.contains("\u{1B}[33m"), "Expected yellow ANSI code at exactly 20% HP")
        #expect(!content.contains("\u{1B}[31m"), "Should NOT contain red at 20% HP")
    }

    // MARK: - Red (< 20% maxHP)

    @Test func `hp at 19 percent uses red`() {
        let content = statusBarContent(hp: 19)
        #expect(content.contains("\u{1B}[31m"), "Expected red ANSI code at 19% HP")
        #expect(!content.contains("\u{1B}[33m"), "Should NOT contain yellow at 19% HP")
    }

    @Test func `hp at 0 uses red`() {
        let content = statusBarContent(hp: 0)
        #expect(content.contains("\u{1B}[31m"), "Expected red ANSI code at 0 HP")
    }

    // MARK: - Reset present after every colored HP segment

    @Test func `colored hp bar segment always followed by ANSI reset`() {
        for hp in [100, 40, 39, 20, 19, 0] {
            let content = statusBarContent(hp: hp)
            #expect(content.contains("\u{1B}[0m"),
                    "Expected ANSI reset code in status bar at hp=\(hp)")
        }
    }
}
