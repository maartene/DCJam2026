import Testing
@testable import GameDomain

// Turning Mechanic Tests — US-TM-01 (CardinalDirection domain type) + US-TM-02 (turn command)
//
// Driving port: RulesEngine.apply(command:to:deltaTime:) for all turn-command tests.
//               GameState.initial(config:) and withFacingDirection(_:) for domain type tests.
//
// Walking skeleton (first test): Ember turns left and right — facingDirection changes.
// NEW TYPES REQUIRED: CardinalDirection, TurnDirection, GameCommand.turn, GameState.facingDirection
//
// All tests start as .disabled("not yet implemented"). Empty bodies ensure compilation succeeds
// until the crafter adds the required types. Enable one test at a time during DELIVER.
//
// Mandate compliance:
//   CM-A: All tests invoke GameDomain driving ports — RulesEngine, GameState.
//   CM-B: Test names use game domain terms only (Ember, facing, cardinal, turn).
//   CM-C: Each test validates an observable player outcome (facingDirection, HP, position).

@Suite("Turning Mechanic — CardinalDirection and Turn Command")
struct TurningMechanicTests {

    // MARK: - Walking Skeleton (first to enable during DELIVER)
    //
    // Thinnest proof: turn command flows from caller through RulesEngine into GameState.facingDirection.
    // Implements the walking skeleton described in story-map.md and the task brief.
    // NEW TYPES REQUIRED: CardinalDirection, TurnDirection, GameCommand.turn, GameState.facingDirection

    @Test("Ember faces West after turning left from North, and East after turning right from North")
    func emberTurnsLeftAndRight() {
        let config = GameConfig.default
        let initial = GameState.initial(config: config)

        let afterLeft = RulesEngine.apply(command: .turn(.left), to: initial, deltaTime: 0)
        let afterRight = RulesEngine.apply(command: .turn(.right), to: initial, deltaTime: 0)

        #expect(afterLeft.facingDirection == .west)
        #expect(afterRight.facingDirection == .east)
    }

    // MARK: - US-TM-01: CardinalDirection domain type

    @Test("Ember faces North when a new run begins", .disabled("not yet implemented"))
    func newRunInitialisesToNorthFacing() {}

    @Test("withFacingDirection produces a new state with the updated facing direction", .disabled("not yet implemented"))
    func withFacingDirectionReturnsCopiedState() {}

    @Test("All four cardinal directions are representable as CardinalDirection values", .disabled("not yet implemented"))
    func allFourCardinalDirectionsExist() {}

    // MARK: - US-TM-02: Rotation table

    @Test("Complete turn rotation table is correct for all 8 combinations")
    func fullRotationTableIsCorrect() {
        let config = GameConfig.default
        let base = GameState.initial(config: config)

        let combinations: [(CardinalDirection, TurnDirection, CardinalDirection)] = [
            (.north, .left,  .west),
            (.north, .right, .east),
            (.east,  .left,  .north),
            (.east,  .right, .south),
            (.south, .left,  .east),
            (.south, .right, .west),
            (.west,  .left,  .south),
            (.west,  .right, .north),
        ]

        for (facing, dir, expected) in combinations {
            let state = base.withFacingDirection(facing)
            let result = RulesEngine.apply(command: .turn(dir), to: state, deltaTime: 0)
            #expect(result.facingDirection == expected, "facing \(facing) + \(dir) should produce \(expected)")
        }
    }

    @Test("Turning does not change Ember's HP, Dash charges, Special charge, or position")
    func turningHasNoSideEffectsOnVitalStats() {
        let config = GameConfig.default
        let state = GameState.initial(config: config)
            .withHP(7)
            .withDashCharges(2)
            .withSpecialCharge(0.5)
            .withPlayerPosition(3)

        let result = RulesEngine.apply(command: .turn(.left), to: state, deltaTime: 0)

        #expect(result.hp == 7)
        #expect(result.dashCharges == 2)
        #expect(result.specialCharge == 0.5)
        #expect(result.playerPosition == 3)
    }

    @Test("Four consecutive turns left return Ember to her original facing")
    func fourConsecutiveLeftTurnsReturnToStart() {
        let config = GameConfig.default
        let initial = GameState.initial(config: config)

        let result = (0 ..< 4).reduce(initial) { state, _ in
            RulesEngine.apply(command: .turn(.left), to: state, deltaTime: 0)
        }

        #expect(result.facingDirection == initial.facingDirection)
    }

    @Test("Four consecutive turns right return Ember to her original facing")
    func fourConsecutiveRightTurnsReturnToStart() {
        let config = GameConfig.default
        let initial = GameState.initial(config: config)

        let result = (0 ..< 4).reduce(initial) { state, _ in
            RulesEngine.apply(command: .turn(.right), to: state, deltaTime: 0)
        }

        #expect(result.facingDirection == initial.facingDirection)
    }
}
