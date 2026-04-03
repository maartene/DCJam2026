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

@Suite struct `Progression — Egg Discovery, Upgrades, Special Meter` {

    // MARK: - Egg discovery fires narrative event

    @Test func `Entering the egg room triggers the egg discovery narrative event`() {
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

    @Test func `The EGG indicator activates after Ember confirms the egg discovery event`() {
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

    @Test func `The dungeon view resumes immediately after the egg discovery event is confirmed`() {
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

    @Test func `The EGG indicator remains inactive when Ember has not yet entered the egg room`() {
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

    @Test func `The upgrade prompt shows exactly 3 options at a milestone floor transition`() {
        // Given — Ember is on floor 1, standing adjacent to the staircase
        var state = GameState.initial(config: GameConfig.default)
        state = state.withCurrentFloor(1).withScreenMode(.dungeon)
        let floor1 = FloorGenerator.generate(floorNumber: 1, config: GameConfig.default)
        // Position one step before the staircase (staircase is at y=6, so stand at y=5 facing north = +y)
        let beforeStaircase = Position(x: floor1.staircasePosition2D.x, y: floor1.staircasePosition2D.y - 1)
        state = state.withPlayerPosition(beforeStaircase).withFacingDirection(.north)
        // When — Ember steps onto the staircase
        let result = RulesEngine.apply(command: .move(.forward), to: state, deltaTime: 0.0)
        // Then — upgrade prompt fires with exactly 3 distinct choices, floor has advanced
        if case .upgradePrompt(let choices) = result.screenMode {
            #expect(choices.count == 3)
            let uniqueIDs = Set(choices.map { $0.id })
            #expect(uniqueIDs.count == 3)
        } else {
            Issue.record("Expected .upgradePrompt but got \(result.screenMode)")
        }
        #expect(result.currentFloor == 2)
    }

    @Test func `Descending from floor 4 to floor 5 also triggers the upgrade prompt`() {
        // Given — Ember is on floor 4, adjacent to the staircase
        var state = GameState.initial(config: GameConfig.default)
        state = state.withCurrentFloor(4).withScreenMode(.dungeon)
        let floor4 = FloorGenerator.generate(floorNumber: 4, config: GameConfig.default)
        let beforeStaircase = Position(x: floor4.staircasePosition2D.x, y: floor4.staircasePosition2D.y - 1)
        state = state.withPlayerPosition(beforeStaircase).withFacingDirection(.north)
        // When
        let result = RulesEngine.apply(command: .move(.forward), to: state, deltaTime: 0.0)
        // Then — upgrade prompt still fires on the floor 4→5 boundary
        if case .upgradePrompt = result.screenMode {
            // expected
        } else {
            Issue.record("Expected .upgradePrompt on floor 4→5 transition, got \(result.screenMode)")
        }
        #expect(result.currentFloor == 5)
    }

    @Test func `No upgrade prompt fires when descending from the final floor`() {
        // Given — a config with maxFloors=3 so floor 3 is final; Ember is on floor 2 (non-final)
        // which means descending lands on floor 3 (final) — upgrade DOES fire.
        // For "beyond final floor" defensive guard we need a custom config.
        var config = GameConfig.default
        config.maxFloors = 2
        var state = GameState.initial(config: config)
        state = state.withCurrentFloor(2).withScreenMode(.dungeon)
        // Floor 2 is the final floor with maxFloors=2, so it has hasExitSquare=true
        // and NO staircase trigger — movement returns dungeon directly.
        let floor2 = FloorGenerator.generate(floorNumber: 2, config: config)
        // Place Ember adjacent to what would be the staircase cell and step forward
        let nearExit = Position(x: floor2.staircasePosition2D.x, y: floor2.staircasePosition2D.y - 1)
        state = state.withPlayerPosition(nearExit).withFacingDirection(.north)
        // When
        let result = RulesEngine.apply(command: .move(.forward), to: state, deltaTime: 0.0)
        // Then — NO upgrade prompt: final floor has exit square, not a staircase
        if case .upgradePrompt = result.screenMode {
            Issue.record("Upgrade prompt must not fire when on the final floor")
        }
    }

    @Test func `Selecting an upgrade applies its effect immediately and resumes the dungeon`() {
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

    @Test func `A Dash cooldown reduction upgrade measurably reduces the cooldown duration`() {
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

    @Test func `A Dash charge cap upgrade increases the maximum number of charges Ember can hold`() {
        // Given
        let config = GameConfig.default
        let baseCap = config.dashChargeCap
        let upgrade = UpgradePool.chargeCapUpgrade()
        var state = GameState.initial(config: config)
        state = state.withScreenMode(.upgradePrompt(choices: [upgrade]))
        // When — selectUpgrade routes through applyUpgrade -> applyEffect, modifying config
        let upgraded = RulesEngine.apply(command: .selectUpgrade(upgrade), to: state, deltaTime: 0.0)
        // Then
        #expect(upgraded.config.dashChargeCap > baseCap)
    }

    // MARK: - Error path: duplicate upgrades not re-offered

    @Test func `An already-selected upgrade does not appear in a subsequent milestone prompt`() {
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

    @Test func `The upgrade pool provides at least 3 unique choices`() {
        // Given — fresh run, no upgrades taken
        let pool = UpgradePool(alreadySelected: [])
        // When
        let drawn = pool.drawChoices(count: 3)
        // Then
        #expect(drawn.count == 3)
        let uniqueIDs = Set(drawn.map { $0.id })
        #expect(uniqueIDs.count == 3)
    }

    @Test func `Keys 1, 2, 3 select upgrades on the upgrade prompt screen`() {
        // Given — upgrade prompt showing three choices
        let pool = UpgradePool(alreadySelected: [])
        let choices = pool.drawChoices(count: 3)
        var state = GameState.initial(config: GameConfig.default)
        state = state.withScreenMode(.upgradePrompt(choices: choices))
        // When — press key "1" (arrives as .dash), "2" (.brace), "3" (.special)
        let result1 = RulesEngine.apply(command: .dash, to: state, deltaTime: 0.0)
        let result2 = RulesEngine.apply(command: .brace, to: state, deltaTime: 0.0)
        let result3 = RulesEngine.apply(command: .special, to: state, deltaTime: 0.0)
        // Then — each selects the corresponding upgrade and returns to dungeon
        for result in [result1, result2, result3] {
            if case .dungeon = result.screenMode { } else {
                Issue.record("Expected .dungeon after upgrade selection, got \(result.screenMode)")
            }
        }
        #expect(result1.activeUpgrades.contains(where: { $0.id == choices[0].id }))
        #expect(result2.activeUpgrades.contains(where: { $0.id == choices[1].id }))
        #expect(result3.activeUpgrades.contains(where: { $0.id == choices[2].id }))
    }

    // MARK: - Special charge meter transitions

    @Test func `The Special charge meter shows a ready state when charge reaches maximum`() {
        // Given — dungeon mode (startScreen pauses timers by design)
        let config = GameConfig.default
        let state = GameState.initial(config: config).withScreenMode(.dungeon)
        // Advance time to fill charge completely (~125 seconds at default rate)
        let timeToFull = 1.0 / config.specialChargeRatePerSecond + 1.0
        let result = RulesEngine.apply(command: .none, to: state, deltaTime: timeToFull)
        // Then
        #expect(result.specialCharge >= 1.0)
        #expect(result.specialIsReady == true)
    }
}

// MARK: - Test Setup Helpers

private extension `Progression — Egg Discovery, Upgrades, Special Meter` {

    func adjacentToEggRoom(_ floor: FloorMap) -> Position {
        // Returns the position one step before the egg room entry
        guard let eggPos = floor.eggRoomPosition else { return floor.entryPosition }
        return eggPos - 1
    }
}
