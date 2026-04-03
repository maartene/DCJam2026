import Testing
@testable import GameDomain

// GameState transientOverlay field and startScreen initial mode — step 02-02
//
// Test budget: 4 distinct behaviors x 2 = 8 max unit tests (5 used)
// Behaviors:
//   1. initial(config:).screenMode equals .startScreen
//   2. initial(config:).transientOverlay is nil
//   3. withTransientOverlay sets overlay to a given value
//   4. withTransientOverlay(nil) clears the overlay
//   (Bonus) withTransientOverlay does not affect other fields

@Suite struct `GameState transientOverlay` {

    private var state: GameState { GameState.initial(config: .default) }

    @Test func `initial screenMode is startScreen`() {
        if case .startScreen = state.screenMode {
            // correct
        } else {
            Issue.record("Expected screenMode .startScreen but got \(state.screenMode)")
        }
    }

    @Test func `initial transientOverlay is nil`() {
        #expect(state.transientOverlay == nil)
    }

    @Test func `withTransientOverlay sets overlay`() {
        let updated = state.withTransientOverlay(.braceSuccess(framesRemaining: 23))
        #expect(updated.transientOverlay == .braceSuccess(framesRemaining: 23))
    }

    @Test func `withTransientOverlay nil clears overlay`() {
        let withOverlay = state.withTransientOverlay(.braceSuccess(framesRemaining: 23))
        let cleared = withOverlay.withTransientOverlay(nil)
        #expect(cleared.transientOverlay == nil)
    }

    @Test func `withTransientOverlay does not affect other fields`() {
        let updated = state.withTransientOverlay(.dash(framesRemaining: 10))
        #expect(updated.hp == state.hp)
        #expect(updated.dashCharges == state.dashCharges)
        #expect(updated.currentFloor == state.currentFloor)
    }

}
