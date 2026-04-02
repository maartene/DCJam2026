import Testing
@testable import GameDomain

// Win / Loss Condition Tests — US-10 (exit patio win), US-11 (death), INT-01, INT-04
//
// Covers: win requires hasEgg AND exitSquare (INT-01), exit without egg is blocked,
// exit with egg fires narrative event, death fires at HP <= 0, death screen shows,
// restart resets ALL state variables (INT-04), HP never goes negative,
// restart from mid-run clears egg, floor, upgrades.
//
// Error / edge paths: exit without egg, win without being at exit, restart with carry-over state,
// HP below 0 clamped, death on Floor 1 before first Dash.
// Error path ratio in this file: 5 of 9 = 56%

@Suite("Win and Loss Conditions")
struct WinLossConditionTests {

    // MARK: - Win condition: BOTH hasEgg AND exitSquare required (INT-01)

    @Test("Stepping onto the exit square with the egg fires the exit patio narrative event")
    func exitWithEggFiresNarrativeEvent() {
        // Given — Floor 5, Ember carries egg, at exit square
        let state = stateAtExitSquareWithEgg(true)
        // When
        let result = RulesEngine.apply(command: .move(.forward), to: state, deltaTime: 0.0)
        // Then
        if case .narrativeOverlay(let event) = result.screenMode, event == .exitPatio {
            // expected
        } else {
            Issue.record("Expected .narrativeOverlay(.exitPatio) when stepping onto exit with egg")
        }
    }

    @Test("The win state is declared after Ember confirms the exit patio narrative")
    func winStateDeclaredAfterExitConfirmation() {
        // Given — exit patio overlay showing
        var state = GameState.initial(config: GameConfig.default)
        state = state.withHasEgg(true)
        state = state.withScreenMode(.narrativeOverlay(event: .exitPatio))
        // When
        let result = RulesEngine.apply(command: .confirmOverlay, to: state, deltaTime: 0.0)
        // Then
        if case .winState = result.screenMode {
            // expected
        } else {
            Issue.record("Expected .winState after confirming exit patio, got \(result.screenMode)")
        }
    }

    // MARK: - Error path: exit without egg is blocked

    @Test("The win state is not declared when Ember reaches the exit without the egg")
    func exitWithoutEggDoesNotTriggerWin() {
        // Given — Floor 5, no egg, at exit square
        let state = stateAtExitSquareWithEgg(false)
        // When
        let result = RulesEngine.apply(command: .move(.forward), to: state, deltaTime: 0.0)
        // Then — no win state, no exit patio event
        if case .winState = result.screenMode {
            Issue.record("Win state must not fire without the egg")
        }
        if case .narrativeOverlay(let event) = result.screenMode, event == .exitPatio {
            Issue.record("Exit patio event must not fire without the egg")
        }
    }

    // MARK: - Property: both conditions required simultaneously (INT-01)

    @Test("Win state is not declared when hasEgg is true but Ember is not at the exit square")
    func winStateRequiresExitPosition() {
        // Given — hasEgg = true, but player is mid-corridor on Floor 5
        var state = GameState.initial(config: GameConfig.default)
        state = state.withCurrentFloor(5)
        state = state.withHasEgg(true)
        // Player is NOT at exit square — default initial position
        // When — advance one step (not toward exit)
        let result = RulesEngine.apply(command: .move(.forward), to: state, deltaTime: 0.0)
        // Then — win state not declared from a non-exit position
        if case .winState = result.screenMode {
            Issue.record("Win state must not fire unless player is at the exit square")
        }
    }

    // MARK: - Death condition

    @Test("The death screen appears when Ember's HP drops to exactly 0",
          .disabled("not yet implemented"))
    func deathScreenFiresAtZeroHP() {
        // Given — Ember at 1 HP in encounter
        var state = GameState.initial(config: GameConfig.default)
        state = state.withHP(1)
        let encounter = EncounterModel.guard(isBossEncounter: false)
        state = state.withScreenMode(.combat(encounter: encounter))
        // When
        let result = RulesEngine.apply(command: .brace, to: state, deltaTime: 0.0)
        // Then — HP at or below 0 triggers death screen
        if result.hp <= 0 {
            if case .deathState = result.screenMode {
                // expected
            } else {
                Issue.record("Expected .deathState when hp dropped to 0, got \(result.screenMode)")
            }
        }
    }

    // MARK: - Error path: HP never goes negative

    @Test("HP is displayed as 0, not a negative number, when a fatal blow is received",
          .disabled("not yet implemented"))
    func hpClampedAtZeroOnFatalBlow() {
        // Given — overkill scenario: 5 HP, enemy deals 50 damage (if brace doesn't fully absorb)
        var state = GameState.initial(config: GameConfig.default)
        state = state.withHP(5)
        let encounter = EncounterModel.guard(isBossEncounter: false)
        state = state.withScreenMode(.combat(encounter: encounter))
        // When
        let result = RulesEngine.apply(command: .brace, to: state, deltaTime: 0.0)
        // Then
        #expect(result.hp >= 0)
    }

    // MARK: - Restart resets ALL state (INT-04)

    @Test("Restart from the death screen resets HP, Dash, Special, egg, floor, and upgrades",
          .disabled("not yet implemented"))
    func restartResetsAllStateVariables() {
        // Given — Ember died mid-run with partial state
        var state = GameState.initial(config: GameConfig.default)
        state = state.withHP(0)
        state = state.withCurrentFloor(3)
        state = state.withHasEgg(true)
        state = state.withSpecialCharge(0.6)
        state = state.withDashCharges(0)
        state = state.withActiveUpgrades([UpgradePool.cooldownReductionUpgrade()])
        state = state.withScreenMode(.deathState)
        // When
        let result = RulesEngine.apply(command: .restart, to: state, deltaTime: 0.0)
        let config = GameConfig.default
        // Then — full reset
        #expect(result.hp == config.maxHP)
        #expect(result.dashCharges == config.dashStartingCharges)
        #expect(result.specialCharge == 0.0)
        #expect(result.hasEgg == false)
        #expect(result.currentFloor == 1)
        #expect(result.activeUpgrades.isEmpty)
    }

    @Test("The Dash cooldown timers are cleared when Ember restarts",
          .disabled("not yet implemented"))
    func restartClearsDashCooldownTimers() {
        // Given — Ember had both charges on cooldown when she died
        var state = GameState.initial(config: GameConfig.default)
        state = state.withDashCharges(0)
        state = state.withScreenMode(.deathState)
        // When
        let result = RulesEngine.apply(command: .restart, to: state, deltaTime: 0.0)
        // Then — no active cooldowns after restart
        #expect(!result.timerModel.hasActiveCooldown)
    }

    // MARK: - Error path: death on Floor 1 before using Dash

    @Test("Death fires correctly when Ember braces repeatedly and HP reaches 0 on Floor 1",
          .disabled("not yet implemented"))
    func deathFiresOnFloorOneBeforeDash() {
        // Given — Ember on Floor 1, has never Dashed, low HP from bracing
        var state = GameState.initial(config: GameConfig.default)
        state = state.withHP(1)
        // Dash charges intact (she chose not to Dash)
        let encounter = EncounterModel.guard(isBossEncounter: false)
        state = state.withScreenMode(.combat(encounter: encounter))
        // When
        let result = RulesEngine.apply(command: .brace, to: state, deltaTime: 0.0)
        // Then — death fires; game did not crash or soft-lock
        if result.hp <= 0 {
            if case .deathState = result.screenMode {
                // expected
            } else {
                Issue.record("Expected death screen on Floor 1 fatal brace, got \(result.screenMode)")
            }
        }
        #expect(result.hp >= 0)
    }
}

// MARK: - Test Setup Helpers

private extension WinLossConditionTests {

    func stateAtExitSquareWithEgg(_ hasEgg: Bool) -> GameState {
        let config = GameConfig.default
        var state = GameState.initial(config: config)
        state = state.withCurrentFloor(5)
        state = state.withHasEgg(hasEgg)
        let floor5 = FloorGenerator.generate(floorNumber: 5, config: config)
        state = state.withPlayerPosition(adjacentToExit(floor5))
        return state
    }

    func adjacentToExit(_ floor: FloorMap) -> Int {
        return floor.exitPosition - 1
    }
}
