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

    @Test("Complete turn rotation table is correct for all 8 combinations", .disabled("not yet implemented"))
    func fullRotationTableIsCorrect() {}

    @Test("Turning does not change Ember's HP, Dash charges, Special charge, or position", .disabled("not yet implemented"))
    func turningHasNoSideEffectsOnVitalStats() {}

    @Test("Four consecutive turns left return Ember to her original facing", .disabled("not yet implemented"))
    func fourConsecutiveLeftTurnsReturnToStart() {}

    @Test("Four consecutive turns right return Ember to her original facing", .disabled("not yet implemented"))
    func fourConsecutiveRightTurnsReturnToStart() {}
}
