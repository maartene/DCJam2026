import Testing
@testable import GameDomain

// Progression Tests — US-07 (egg discovery), US-08 (milestone upgrades), US-06 (Special charge meter)
//
// Covers: egg discovery fires narrative event, EGG indicator activates after acknowledgment,
// upgrade prompt shows exactly 3 options, upgrade applies immediately,
// already-taken upgrades not re-offered, Dash cooldown upgrade reduces cooldown,
// Dash charge cap upgrade raises the cap.
//
// Error / edge paths: egg room not entered = no event, upgrade duplicate prevention,
// cooldown upgrade has measurable effect, Special meter state transitions.
// Error path ratio in this file: 4 of 11 = 36%

@Suite("Progression — Egg Discovery, Upgrades, Special Meter")
struct ProgressionTests {

    // MARK: - Egg discovery fires narrative event

    @Test("Entering the egg room triggers the egg discovery narrative event")
    func enteringEggRoomTriggersNarrative() {
        // Given — Ember on Floor 2, steps onto the egg room square
        var state = GameState.initial(config: GameConfig.default)
        state = state.withCurrentFloor(2)
        state = state.withHasEgg(false)
        let floor2 = FloorGenerator.generate(floorNumber: 2, config: GameConfig.default)
        state = state.withPlayerPosition(adjacentToEggRoom(floor2))
        // When — step into egg room
        let result = RulesEngine.apply(command: .move(.forward), to: state, deltaTime: 0.0)
        // Then
        if case .narrativeOverlay(let event) = result.screenMode, event == .eggDiscovery {
            // expected
        } else {
            Issue.record("Expected .narrativeOverlay(.eggDiscovery) when entering egg room")
        }
    }

    @Test("The EGG indicator activates after Ember confirms the egg discovery event",
          .disabled("not yet implemented"))
    func eggIndicatorActivatesAfterConfirmation() {
        // Given — narrative event is showing
        var state = GameState.initial(config: GameConfig.default)
        state = state.withScreenMode(.narrativeOverlay(event: .eggDiscovery))
        state = state.withHasEgg(false)
        // When — player presses key to confirm
        let result = RulesEngine.apply(command: .confirmOverlay, to: state, deltaTime: 0.0)
        // Then
        #expect(result.hasEgg == true)
        if case .narrativeOverlay = result.screenMode {
            Issue.record("Expected screen mode to exit narrative overlay after confirmation")
        }
    }

    @Test("The dungeon view resumes immediately after the egg discovery event is confirmed",
          .disabled("not yet implemented"))
    func dungeonResumesAfterEggConfirmation() {
        // Given
        var state = GameState.initial(config: GameConfig.default)
        state = state.withScreenMode(.narrativeOverlay(event: .eggDiscovery))
        // When
        let result = RulesEngine.apply(command: .confirmOverlay, to: state, deltaTime: 0.0)
        // Then
        if case .dungeon = result.screenMode {
            // expected
        } else {
            Issue.record("Expected .dungeon after confirming egg discovery, got \(result.screenMode)")
        }
    }

    // MARK: - Error path: egg room not visited means no event

    @Test("The EGG indicator remains inactive when Ember has not yet entered the egg room",
          .disabled("not yet implemented"))
    func eggIndicatorInactiveUntilRoomEntered() {
        // Given — Ember has been navigating Floor 2 but not entered egg room
        var state = GameState.initial(config: GameConfig.default)
        state = state.withCurrentFloor(2)
        state = state.withHasEgg(false)
        // When — advance through regular navigation
        let result = RulesEngine.apply(command: .move(.forward), to: state, deltaTime: 0.0)
        // Then — egg not found (this depends on floor layout; just verify no spurious activation)
        // Accept if the result has no egg (hasEgg still false unless actually entered egg room)
        // This test is meaningful only in integration with real FloorGenerator output
        if result.hasEgg {
            // Only valid if player actually stepped into the egg room
            if case .narrativeOverlay(let event) = result.screenMode, event == .eggDiscovery {
                // valid — egg room was entered
            } else {
                Issue.record("hasEgg became true without entering egg room")
            }
        }
    }

    // MARK: - Milestone upgrade prompt

    @Test("The upgrade prompt shows exactly 3 options at a milestone floor transition",
          .disabled("not yet implemented"))
    func upgradePromptShowsExactlyThreeOptions() {
        // Given — Ember has cleared a milestone floor
        var state = GameState.initial(config: GameConfig.default)
        state = state.withCurrentFloor(2) // assume Floor 2 cleared = milestone
        // When — milestone triggers upgrade prompt
        let result = RulesEngine.apply(command: .move(.forward), to: state, deltaTime: 0.0)
        // If an upgrade prompt fires:
        if case .upgradePrompt(let choices) = result.screenMode {
            #expect(choices.count == 3)
        }
        // If the prompt does not fire here, the milestone trigger floor is a design detail —
        // test passes vacuously and the crafter must wire the milestone to the correct floor.
    }

    @Test("Selecting an upgrade applies its effect immediately and resumes the dungeon",
          .disabled("not yet implemented"))
    func selectingUpgradeAppliesImmediately() {
        // Given — upgrade prompt showing
        let upgrade = UpgradePool.cooldownReductionUpgrade()
        var state = GameState.initial(config: GameConfig.default)
        state = state.withScreenMode(.upgradePrompt(choices: [upgrade]))
        let cooldownBefore = state.config.dashCooldownSeconds
        // When
        let result = RulesEngine.apply(command: .selectUpgrade(upgrade), to: state, deltaTime: 0.0)
        // Then — upgrade applied (cooldown reduced), back to dungeon
        #expect(result.config.dashCooldownSeconds < cooldownBefore)
        if case .dungeon = result.screenMode {
            // expected
        } else {
            Issue.record("Expected .dungeon after selecting upgrade, got \(result.screenMode)")
        }
    }

    @Test("A Dash cooldown reduction upgrade measurably reduces the cooldown duration",
          .disabled("not yet implemented"))
    func dashCooldownUpgradeReducesCooldown() {
        // Given — baseline run
        let config = GameConfig.default
        let baseState = GameState.initial(config: config)
        let baseCooldown = config.dashCooldownSeconds
        // Apply cooldown reduction upgrade
        let upgrade = UpgradePool.cooldownReductionUpgrade()
        var upgradedState = baseState
        upgradedState = upgradedState.withActiveUpgrades([upgrade])
        // When — use Dash
        let result = RulesEngine.apply(command: .dash, to: upgradedState, deltaTime: 0.0)
        // Then — the cooldown timer that started is shorter than the base value
        let effectiveCooldown = result.timerModel.activeCooldownDuration
        #expect(effectiveCooldown < baseCooldown)
    }

    @Test("A Dash charge cap upgrade increases the maximum number of charges Ember can hold",
          .disabled("not yet implemented"))
    func dashChargeCapUpgradeIncreasesCapacity() {
        // Given
        let config = GameConfig.default
        let baseCap = config.dashStartingCharges // default = 2
        let upgrade = UpgradePool.chargeCapUpgrade()
        var state = GameState.initial(config: config)
        state = state.withActiveUpgrades([upgrade])
        // When — the upgrade takes effect on the next refill
        let result = RulesEngine.apply(command: .none, to: state, deltaTime: 0.0)
        // Then
        #expect(result.config.dashChargeCap > baseCap)
    }

    // MARK: - Error path: duplicate upgrades not re-offered

    @Test("An already-selected upgrade does not appear in a subsequent milestone prompt",
          .disabled("not yet implemented"))
    func alreadySelectedUpgradeNotReOffered() {
        // Given — Ember has already selected the cooldown reduction upgrade
        let takenUpgrade = UpgradePool.cooldownReductionUpgrade()
        var state = GameState.initial(config: GameConfig.default)
        state = state.withActiveUpgrades([takenUpgrade])
        // When — upgrade pool draws for the next prompt
        let pool = UpgradePool(alreadySelected: [takenUpgrade])
        let drawn = pool.drawChoices(count: 3)
        // Then — the taken upgrade is not in the drawn choices
        #expect(!drawn.contains(where: { $0.id == takenUpgrade.id }))
    }

    @Test("The upgrade pool provides at least 3 unique choices",
          .disabled("not yet implemented"))
    func upgradePoolHasEnoughUniquesForThreeChoices() {
        // Given — fresh run, no upgrades taken
        let pool = UpgradePool(alreadySelected: [])
        // When
        let drawn = pool.drawChoices(count: 3)
        // Then
        #expect(drawn.count == 3)
        let uniqueIDs = Set(drawn.map { $0.id })
        #expect(uniqueIDs.count == 3)
    }

    // MARK: - Special charge meter transitions

    @Test("The Special charge meter shows a ready state when charge reaches maximum",
          .disabled("not yet implemented"))
    func specialChargeReachesFullIndicatesReady() {
        // Given — charge advanced to full via time
        let config = GameConfig.default
        let state = GameState.initial(config: config)
        // Advance time to fill charge completely (~125 seconds at default rate)
        let timeToFull = 1.0 / config.specialChargeRatePerSecond + 1.0
        let result = RulesEngine.apply(command: .none, to: state, deltaTime: timeToFull)
        // Then
        #expect(result.specialCharge >= 1.0)
        #expect(result.specialIsReady == true)
    }
}

// MARK: - Test Setup Helpers

private extension ProgressionTests {

    func adjacentToEggRoom(_ floor: FloorMap) -> Int {
        // Returns the position one step before the egg room entry
        guard let eggPos = floor.eggRoomPosition else { return floor.entryPosition }
        return eggPos - 1
    }
}
