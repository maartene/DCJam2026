import Testing
@testable import GameDomain

// Dash Distance — step 01-01 (gameplay-polish-fixes)
//
// Verifies that Dash advances the player exactly 2 squares (not 3) in the
// facing direction (y-axis) while leaving charge/cooldown behaviour intact.

@Suite("Dash moves player exactly 2 squares forward") struct DashDistanceTests {

    // MARK: - AC1: Dash advances exactly 2 squares

    @Test func dashAdvancesPlayerExactly2Squares() {
        let state = gameStateInCombat(dashCharges: 2)
        let positionBefore = state.playerPosition
        let result = RulesEngine.apply(command: .dash, to: state, deltaTime: 0.0)
        #expect(result.playerPosition == positionBefore + 2)
    }

    // MARK: - AC2: Dash does NOT advance 3 squares

    @Test func dashDoesNotAdvancePlayer3Squares() {
        let state = gameStateInCombat(dashCharges: 2)
        let positionBefore = state.playerPosition
        let result = RulesEngine.apply(command: .dash, to: state, deltaTime: 0.0)
        #expect(result.playerPosition != positionBefore + 3)
    }

    // MARK: - AC3: Dash charge and cooldown behaviour is unchanged

    @Test func dashConsumesOneCharge() {
        let state = gameStateInCombat(dashCharges: 2)
        let result = RulesEngine.apply(command: .dash, to: state, deltaTime: 0.0)
        #expect(result.dashCharges == 1)
    }

    @Test func dashStartsCooldownTimer() {
        let state = gameStateInCombat(dashCharges: 2)
        let result = RulesEngine.apply(command: .dash, to: state, deltaTime: 0.0)
        #expect(result.timerModel.hasActiveCooldown)
    }
}

// MARK: - Helpers

private extension DashDistanceTests {
    func gameStateInCombat(dashCharges: Int) -> GameState {
        GameState.initial(config: .default)
            .withScreenMode(.combat(encounter: EncounterModel.guard(isBossEncounter: false)))
            .withDashCharges(dashCharges)
    }
}
