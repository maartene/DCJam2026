import Testing
@testable import GameDomain

// StartScreen mode — step 02-01
//
// Test budget: 1 distinct behavior x 2 = 2 max unit tests (1 used)
// Behavior: ScreenMode.startScreen is a valid, distinct case

@Suite struct `StartScreen mode` {

    @Test func `startScreen is a valid ScreenMode distinct from dungeon`() {
        let mode = ScreenMode.startScreen
        if case .startScreen = mode {
            // correct — case is accessible
        } else {
            Issue.record("Expected ScreenMode.startScreen but got a different case")
        }
        // Verify it is structurally distinct from .dungeon
        if case .dungeon = mode {
            Issue.record("ScreenMode.startScreen must not match .dungeon")
        }
    }

}
