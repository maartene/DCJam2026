import Testing
@testable import DCJam2026
@testable import GameDomain

// Test Budget: 5 behaviors x 2 = 10 max unit tests. Using 5 focused tests (one per AC behavior).
// AC coverage:
//   1. specialIsReady=true  → bold bright cyan (\u{1B}[1m\u{1B}[96m) in SPEC segment
//   2. specialIsReady=false → dim cyan (\u{1B}[36m) in SPEC segment
//   3. dash cooldown active → yellow (\u{1B}[33m) in dash segment
//   4. braceOnCooldown=true → yellow (\u{1B}[33m) in brace segment
//   5. Every colored segment terminated with ANSI reset (\u{1B}[0m)

@Suite struct `Renderer — status bar special and cooldown colors` {

    // Helper: extract all writes to row 18 as a single concatenated string.
    private func statusBarContent(
        specialCharge: Double = 0.0,
        dashCooldown: Double = 0.0,
        braceCooldownTimer: Double = 0.0
    ) -> String {
        let spy = TUIOutputSpy()
        let renderer = Renderer(output: spy)
        var state = GameState.initial(config: .default)
            .withSpecialCharge(specialCharge)
            .withScreenMode(.dungeon)
        if dashCooldown > 0 {
            state = state.withTimerModel(TimerModel(cooldownSlots: [dashCooldown]))
        }
        if braceCooldownTimer > 0 {
            state = state.withBraceCooldownTimer(braceCooldownTimer)
        }
        renderer.render(state)
        return spy.entries
            .filter { $0.row == 18 }
            .map { $0.string }
            .joined()
    }

    // MARK: - AC1: SPEC bar bold bright cyan when ready

    @Test func `spec bar contains bold bright cyan when specialIsReady is true`() {
        let content = statusBarContent(specialCharge: 1.0)
        #expect(content.contains("\u{1B}[1m\u{1B}[96m"),
                "Expected bold bright cyan ANSI codes when specialIsReady is true")
    }

    // MARK: - AC2: SPEC bar dim cyan when charging

    @Test func `spec bar contains dim cyan when specialIsReady is false`() {
        let content = statusBarContent(specialCharge: 0.5)
        #expect(content.contains("\u{1B}[36m"),
                "Expected dim cyan ANSI code when specialIsReady is false (charging)")
    }

    // MARK: - AC3: Dash cooldown indicator yellow when active

    @Test func `dash cooldown indicator contains yellow when dash cooldown is active`() {
        let content = statusBarContent(dashCooldown: 10.0)
        #expect(content.contains("\u{1B}[33m"),
                "Expected yellow ANSI code in dash cooldown indicator when cooldown is active")
    }

    // MARK: - AC4: Brace cooldown indicator yellow when braceOnCooldown

    @Test func `brace cooldown indicator contains yellow when braceOnCooldown is true`() {
        let content = statusBarContent(braceCooldownTimer: 1.5)
        #expect(content.contains("\u{1B}[33m"),
                "Expected yellow ANSI code in brace cooldown indicator when braceOnCooldown is true")
    }

    // MARK: - AC5: Every colored segment terminated with ANSI reset

    @Test func `all colored segments in status bar are terminated with ANSI reset`() {
        // Test all combinations that produce coloring
        let cases: [(Double, Double, Double)] = [
            (1.0, 0.0, 0.0),   // spec ready
            (0.5, 0.0, 0.0),   // spec charging
            (0.0, 10.0, 0.0),  // dash cooldown active
            (0.0, 0.0, 1.5),   // brace on cooldown
        ]
        for (spec, dash, brace) in cases {
            let content = statusBarContent(
                specialCharge: spec,
                dashCooldown: dash,
                braceCooldownTimer: brace
            )
            #expect(content.contains("\u{1B}[0m"),
                    "Expected ANSI reset in status bar for spec=\(spec) dash=\(dash) brace=\(brace)")
        }
    }
}
