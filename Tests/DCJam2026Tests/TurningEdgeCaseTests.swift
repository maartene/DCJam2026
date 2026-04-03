import Testing
@testable import GameDomain

// Turning Edge Case Tests — US-TM-06 (facing persistence and combat turn blocking)
//
// Driving port: RulesEngine.apply(command:to:deltaTime:) and GameState functional updaters.
//
// Two concerns:
//   1. facingDirection persists through floor transition (withCurrentFloor does not reset it)
//   2. RulesEngine discards .turn commands when screenMode == .combat (WD-08)
//
// All tests start as .disabled("not yet implemented"). Empty bodies ensure compilation succeeds
// until the crafter adds the required types. Enable one test at a time during DELIVER.
//
// Mandate compliance:
//   CM-A: All tests invoke RulesEngine (driving port) and GameState updaters directly.
//   CM-B: Test names use navigation/combat domain terms — no framework or API jargon.
//   CM-C: Each test validates an observable state outcome (facingDirection, screenMode, HP).

@Suite struct `Turning Mechanic — Facing Persistence and Combat Turn Blocking` {

    // MARK: - US-TM-06: Facing persists through floor transitions

    @Test func `Ember's facing direction is unchanged after descending to the next floor`() {
        let state = GameState.initial(config: .default)
            .withFacingDirection(.east)
            .withCurrentFloor(2)

        #expect(state.facingDirection == .east)
    }

    @Test func `Ember's facing direction is unchanged after descending from floor 2 to floor 3`() {
        let state = GameState.initial(config: .default)
            .withFacingDirection(.south)
            .withCurrentFloor(2)
            .withCurrentFloor(3)

        #expect(state.facingDirection == .south)
    }

    @Test func `withCurrentFloor does not reset facing direction to North`() {
        let state = GameState.initial(config: .default)
            .withFacingDirection(.west)
            .withCurrentFloor(2)

        #expect(state.facingDirection != .north)
    }

    // MARK: - US-TM-06: Turn command blocked in combat

    @Test func `Turn command is ignored during an active combat encounter — facing does not change`() {
        let encounter = EncounterModel.guard(isBossEncounter: false)
        let state = GameState.initial(config: .default)
            .withFacingDirection(.east)
            .withScreenMode(.combat(encounter: encounter))

        let result = RulesEngine.apply(command: .turn(.left), to: state, deltaTime: 0)

        #expect(result.facingDirection == .east)
    }

    @Test func `screenMode remains .combat after a blocked turn command`() {
        let encounter = EncounterModel.guard(isBossEncounter: false)
        let state = GameState.initial(config: .default)
            .withScreenMode(.combat(encounter: encounter))

        let result = RulesEngine.apply(command: .turn(.right), to: state, deltaTime: 0)

        if case .combat = result.screenMode {
            // expected — screenMode is still .combat
        } else {
            Issue.record("Expected screenMode to remain .combat, got \(result.screenMode)")
        }
    }

    @Test func `Enemy HP is unchanged when a turn command is blocked during combat`() {
        let encounter = EncounterModel(isBossEncounter: false, enemyHP: 40, enemyAttackTimer: 5.0)
        let state = GameState.initial(config: .default)
            .withScreenMode(.combat(encounter: encounter))

        let result = RulesEngine.apply(command: .turn(.left), to: state, deltaTime: 0)

        if case .combat(let resultEncounter) = result.screenMode {
            #expect(resultEncounter.enemyHP == 40)
        } else {
            Issue.record("Expected screenMode to remain .combat")
        }
    }

    @Test func `Turn-left command in combat does not change facing regardless of current direction`() {
        let encounter = EncounterModel.guard(isBossEncounter: false)
        let facings: [CardinalDirection] = [.north, .east, .south, .west]
        let directions: [TurnDirection] = [.left, .right]

        for facing in facings {
            for direction in directions {
                let state = GameState.initial(config: .default)
                    .withFacingDirection(facing)
                    .withScreenMode(.combat(encounter: encounter))

                let result = RulesEngine.apply(command: .turn(direction), to: state, deltaTime: 0)

                #expect(result.facingDirection == facing,
                    "Expected facing \(facing) to be unchanged after .turn(.\(direction)) in combat")
            }
        }
    }

    // MARK: - US-TM-06: Movement lock in combat is unaffected by facing

    @Test func `Normal movement is still locked in combat even after Ember has turned`() {
        let encounter = EncounterModel.guard(isBossEncounter: false)
        let facings: [CardinalDirection] = [.north, .east, .south, .west]

        for facing in facings {
            let state = GameState.initial(config: .default)
                .withFacingDirection(facing)
                .withScreenMode(.combat(encounter: encounter))
            let initialPosition = state.playerPosition

            let result = RulesEngine.apply(command: .move(.forward), to: state, deltaTime: 0)

            #expect(result.playerPosition == initialPosition,
                "Expected position unchanged after .moveForward in combat with facing \(facing)")
        }
    }

    @Test func `Ember's HP is unchanged when move is blocked in combat (no position change, no damage from move)`() {
        let encounter = EncounterModel(isBossEncounter: false, enemyHP: 40, enemyAttackTimer: 5.0)
        let state = GameState.initial(config: .default)
            .withScreenMode(.combat(encounter: encounter))
        let initialHP = state.hp

        let result = RulesEngine.apply(command: .move(.forward), to: state, deltaTime: 0)

        #expect(result.hp == initialHP)
    }
}
