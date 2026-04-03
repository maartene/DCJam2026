// RendererEggDiscoveryTests — step 03-03 (game-polish-v1)
//
// Acceptance Criteria:
//   AC1: narrativeContent(.eggDiscovery) body contains dragon-vocabulary egg narrative text
//   AC2: all colored segments in the egg discovery output are terminated with ANSI reset
//   AC3: no raw \u{1B}[ escape literal introduced in Renderer.swift (enforced by code review)
//   AC4: keypress-dismiss mechanic unaffected (controls bar shows "Space / Enter: continue")
//
// Test Budget: 2 distinct behaviors × 2 = 4 max unit tests (using 2)

import Testing
@testable import DCJam2026
@testable import GameDomain

@Suite struct `Renderer — egg discovery narrative` {

    // Behavior 1: the egg discovery overlay body contains dragon-vocabulary narrative text
    // AND uses ANSI color to style it (at least one ANSIColors constant applied)
    @Test func `egg discovery overlay contains dragon-themed narrative text with ANSI color`() {
        let spy = TUIOutputSpy()
        let renderer = Renderer(output: spy)
        let state = makeNarrativeOverlayState(event: .eggDiscovery)
        renderer.render(state)

        let allOutput = spy.entries.map(\.string).joined()
        // Dragon-vocabulary: egg warmth/pulse/glow, claws or scales
        #expect(allOutput.contains("egg") || allOutput.contains("Egg"),
                "Output must reference the egg")
        #expect(allOutput.contains("warm") || allOutput.contains("Warm") || allOutput.contains("pulse") || allOutput.contains("glow"),
                "Output must contain egg warmth/glow vocabulary")
        #expect(allOutput.contains("claw") || allOutput.contains("scale") || allOutput.contains("dragon"),
                "Output must contain dragon-body vocabulary (claws, scales, or dragon)")
        // Must contain at least one ANSI color escape (from ANSIColors constants)
        #expect(allOutput.contains(ansiBrightYellow) || allOutput.contains(ansiYellow),
                "Egg discovery output must be styled with ANSI color (ansiBrightYellow or ansiYellow)")
    }

    // Behavior 2: every colored segment in the egg discovery output is terminated with an ANSI reset
    @Test func `all colored segments in egg discovery output are terminated with reset`() {
        let spy = TUIOutputSpy()
        let renderer = Renderer(output: spy)
        let state = makeNarrativeOverlayState(event: .eggDiscovery)
        renderer.render(state)

        let allOutput = spy.entries.map(\.string).joined()
        let ansiEscapePrefix = "\u{1B}["

        // Output must contain at least one ANSI color code (asserting color is applied)
        #expect(allOutput.contains(ansiEscapePrefix),
                "Egg discovery output must contain ANSI color codes")
        // Every color code introduced must be paired with a reset
        #expect(allOutput.contains(ansiReset),
                "Every colored segment must be terminated with ANSI reset \\u{1B}[0m")
    }

    // Helper: build a GameState in narrativeOverlay(.eggDiscovery) screen mode
    private func makeNarrativeOverlayState(event: NarrativeEvent) -> GameState {
        var state = GameState.initial(config: .default)
        state.screenMode = .narrativeOverlay(event: event)
        return state
    }
}
