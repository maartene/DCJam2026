import Testing
@testable import GameDomain

// Dash Mechanics — US-02, US-09 (boss Dash block)
//
// Covers: successful Dash in regular encounters, Dash unavailability at 0 charges,
// boss encounter Dash block (SA-11 flag), charge-not-consumed on blocked attempt,
// Dash unlocked only in regular (non-boss) encounters.
//
// Error / edge paths: Dash with 0 charges, boss Dash block, blocked attempt does not consume charge.
// Error path ratio in this file: 3 of 8 = 37.5% (file-level); adequate when combined with overall suite.

@Suite("Dash Mechanics")
struct DashMechanicsTests {

    // MARK: - Happy path: Dash in a regular encounter

    @Test("Ember passes through the guard's square without stopping when she Dashes")
    func dashPassesThroughEnemySquare() {
        // Given — regular encounter, 1+ Dash charge
        let state = gameStateInRegularEncounter(dashCharges: 2)
        let positionBefore = state.playerPosition
        // When
        let result = RulesEngine.apply(command: .dash, to: state, deltaTime: 0.0)
        // Then — Ember is now 3 squares ahead and not at the enemy's former position
        #expect(result.playerPosition > positionBefore)
        #expect(result.playerPosition == positionBefore + 3)
    }

    @Test("Ember uses Dash with exactly 1 charge remaining and it depletes to 0")
    func dashWithOneRemainingChargeDepletesToZero() {
        // Given — only 1 Dash charge available
        let state = gameStateInRegularEncounter(dashCharges: 1)
        // When
        let result = RulesEngine.apply(command: .dash, to: state, deltaTime: 0.0)
        // Then
        #expect(result.dashCharges == 0)
    }

    @Test("The Dash cooldown timer begins immediately after a Dash is used")
    func dashCooldownBeginsAfterUse() {
        // Given
        let state = gameStateInRegularEncounter(dashCharges: 2)
        // When
        let result = RulesEngine.apply(command: .dash, to: state, deltaTime: 0.0)
        // Then — at least one cooldown slot is active
        #expect(result.timerModel.hasActiveCooldown)
    }

    @Test("A Dash charge replenishes after the configured cooldown duration elapses")
    func dashChargeReplenishesAfterCooldown() {
        // Given — Ember has used one Dash, one charge depleted
        let config = GameConfig.default
        var state = GameState.initial(config: config)
        state = gameStateInRegularEncounter(dashCharges: 1)
        let afterDash = RulesEngine.apply(command: .dash, to: state, deltaTime: 0.0)
        // When — advance time past the full cooldown
        let afterCooldown = RulesEngine.apply(
            command: .none,
            to: afterDash,
            deltaTime: config.dashCooldownSeconds + 1.0
        )
        // Then — charge is restored
        #expect(afterCooldown.dashCharges == 1)
    }

    // MARK: - Error path: Dash unavailable at 0 charges

    @Test("Dash is not selectable when both charges are depleted")
    func dashNotSelectableWithZeroCharges() {
        // Given — 0 Dash charges, in active encounter
        let state = gameStateInRegularEncounter(dashCharges: 0)
        // When
        let result = RulesEngine.apply(command: .dash, to: state, deltaTime: 0.0)
        // Then — position does not change, encounter persists, charge remains 0
        #expect(result.playerPosition == state.playerPosition)
        #expect(result.dashCharges == 0)
        if case .combat = result.screenMode {
            // expected — encounter not exited
        } else {
            Issue.record("Expected encounter to persist when Dash attempted with 0 charges")
        }
    }

    @Test("Dash charge is not consumed when Dash is attempted with 0 charges")
    func blockedDashDoesNotConsumeCharge() {
        // Given
        let state = gameStateInRegularEncounter(dashCharges: 0)
        // When
        let result = RulesEngine.apply(command: .dash, to: state, deltaTime: 0.0)
        // Then — still 0, not negative
        #expect(result.dashCharges == 0)
    }

    // MARK: - Error path: Boss encounter blocks Dash (SA-11 flag)

    @Test("Dash is blocked during the boss encounter")
    func dashBlockedDuringBossEncounter() {
        // Given — boss encounter (isBossEncounter = true), Ember has 2 charges
        let state = gameStateInBossEncounter(dashCharges: 2)
        let chargesBefore = state.dashCharges
        let positionBefore = state.playerPosition
        // When
        let result = RulesEngine.apply(command: .dash, to: state, deltaTime: 0.0)
        // Then — position unchanged, charge unchanged, still in combat
        #expect(result.playerPosition == positionBefore)
        #expect(result.dashCharges == chargesBefore)
        if case .combat = result.screenMode {
            // expected
        } else {
            Issue.record("Expected combat to persist when Dash blocked by boss encounter flag")
        }
    }

    @Test("Dash charge is not consumed when Dash is attempted during the boss encounter")
    func blockedDashOnBossDoesNotConsumeCharge() {
        // Given
        let state = gameStateInBossEncounter(dashCharges: 2)
        // When
        let result = RulesEngine.apply(command: .dash, to: state, deltaTime: 0.0)
        // Then
        #expect(result.dashCharges == 2)
    }

    @Test("Dash blocking is controlled by the boss encounter flag, not by the floor number")
    func dashBlockingDrivenByFlagNotFloorNumber() {
        // Given — regular encounter on Floor 5 (not boss; flag is false)
        var state = GameState.initial(config: GameConfig.default)
        state = state.withCurrentFloor(5)
        let regularEncounterOnFloor5 = EncounterModel.guard(isBossEncounter: false)
        state = state.withScreenMode(.combat(encounter: regularEncounterOnFloor5))
        state = state.withDashCharges(2)
        let positionBefore = state.playerPosition
        // When
        let result = RulesEngine.apply(command: .dash, to: state, deltaTime: 0.0)
        // Then — Dash succeeds because the boss flag is false, regardless of floor number
        #expect(result.playerPosition == positionBefore + 3)
    }
}

// MARK: - Test Setup Helpers

private extension DashMechanicsTests {

    func gameStateInRegularEncounter(dashCharges: Int) -> GameState {
        var state = GameState.initial(config: GameConfig.default)
        state = state.withDashCharges(dashCharges)
        let encounter = EncounterModel.guard(isBossEncounter: false)
        return state.withScreenMode(.combat(encounter: encounter))
    }

    func gameStateInBossEncounter(dashCharges: Int) -> GameState {
        var state = GameState.initial(config: GameConfig.default)
        state = state.withCurrentFloor(5)
        state = state.withDashCharges(dashCharges)
        let encounter = EncounterModel.guard(isBossEncounter: true)
        return state.withScreenMode(.combat(encounter: encounter))
    }
}
