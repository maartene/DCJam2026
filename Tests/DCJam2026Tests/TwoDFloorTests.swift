import Testing
@testable import GameDomain

// 2D Floor Tests — US-TM-03 (2D floor model and facing-relative movement)
//
// Driving port: RulesEngine.apply(command:to:deltaTime:) and FloorGenerator.generate(floorNumber:config:).
//
// All tests start as .disabled("not yet implemented"). Empty bodies ensure compilation succeeds
// until the crafter adds the required types. Enable one test at a time during DELIVER.
//
// Grid topology (ADR-004, data-models.md):
//   15×7 L-shaped corridor. Main corridor x=7, y=0..6. Branch y=3, x=2..7.
//   Entry=(7,0), staircase=(7,6), egg=(2,3), encounter=(7,3).
//   Origin south-west; y northward; x eastward.
//
// Mandate compliance:
//   CM-A: Tests drive through RulesEngine or FloorGenerator (domain driving ports).
//   CM-B: Test names use spatial/navigational terms — no SQL, HTTP, or framework jargon.
//   CM-C: Each test validates an observable positional outcome for Ember.

@Suite("Turning Mechanic — 2D Floor and Facing-Relative Movement")
struct TwoDFloorTests {

    // MARK: - US-TM-03: playerPosition is a 2D coordinate

    @Test("playerPosition has x and y integer fields (Position struct)")
    func playerPositionIsTwoDimensional() {
        let state = GameState.initial(config: .default)
        let pos = state.playerPosition
        // Position must be a named struct with x and y fields (not a tuple or plain Int)
        let _: Int = pos.x
        let _: Int = pos.y
    }

    @Test("Ember starts a new run at the floor entry cell (7, 0)")
    func newRunStartsAtEntryCell() {
        let state = GameState.initial(config: .default)
        #expect(state.playerPosition.x == 7)
        #expect(state.playerPosition.y == 0)
    }

    // MARK: - US-TM-03: Facing-relative movement deltas

    @Test("Moving forward while facing North advances Ember by (dx:0, dy:+1)", .disabled("not yet implemented"))
    func forwardNorthAppliesCorrectDelta() {}

    @Test("Moving forward while facing East advances Ember by (dx:+1, dy:0)", .disabled("not yet implemented"))
    func forwardEastAppliesCorrectDelta() {}

    @Test("Moving forward while facing South retreats Ember by (dx:0, dy:-1)", .disabled("not yet implemented"))
    func forwardSouthAppliesCorrectDelta() {}

    @Test("Moving forward while facing West retreats Ember by (dx:-1, dy:0)", .disabled("not yet implemented"))
    func forwardWestAppliesCorrectDelta() {}

    @Test("Moving backward produces the inverse delta for all four facings", .disabled("not yet implemented"))
    func backwardIsInverseOfForward() {}

    // MARK: - US-TM-03: Wall collision

    @Test("Ember cannot step into a wall cell — position is unchanged", .disabled("not yet implemented"))
    func movementIntoWallIsBlocked() {}

    // MARK: - US-TM-03: Bounds clamping

    @Test("Ember's position is clamped at the south boundary — cannot step below y=0", .disabled("not yet implemented"))
    func movementClampedAtSouthBoundary() {}

    @Test("Ember's position is clamped at the west boundary — cannot step past x=0", .disabled("not yet implemented"))
    func movementClampedAtWestBoundary() {}

    // MARK: - US-TM-03: Game rule preservation after movement

    @Test("Encounter proximity check still fires when Ember steps onto the encounter cell", .disabled("not yet implemented"))
    func encounterProximityCheckAppliedAfterMove() {}

    @Test("Win condition is checked when Ember reaches the exit cell with the egg", .disabled("not yet implemented"))
    func winConditionCheckedAfterMoveToExit() {}

    // MARK: - US-TM-03: 2D floor grid structure

    @Test("Generated floor has the correct 15-wide by 7-tall grid dimensions")
    func floorGridHasCorrectDimensions() {
        let floor = FloorGenerator.generate(floorNumber: 1, config: .default)
        #expect(floor.grid.width == 15)
        #expect(floor.grid.height == 7)
    }

    @Test("Main corridor cells at x=7 are passable and off-corridor cells at y=0 are walls")
    func mainCorridorCellsArePassable() {
        let floor = FloorGenerator.generate(floorNumber: 1, config: .default)
        // All cells at x=7 (main corridor) are passable
        for y in 0..<7 {
            #expect(floor.grid.cell(x: 7, y: y).isPassable, "cell (7,\(y)) should be passable")
        }
        // Spot-check: non-corridor cells at y=0 are walls
        for x in [0, 1, 2, 3, 4, 5, 6, 8, 9, 10, 11, 12, 13, 14] {
            #expect(!floor.grid.cell(x: x, y: 0).isPassable, "cell (\(x),0) should be a wall")
        }
    }

    @Test("Branch corridor cells at y=3 from x=2 to x=7 are passable")
    func branchCorridorCellsArePassable() {
        let floor = FloorGenerator.generate(floorNumber: 1, config: .default)
        for x in 2...7 {
            #expect(floor.grid.cell(x: x, y: 3).isPassable, "cell (\(x),3) should be passable")
        }
        // Cells outside branch range at y=3 are walls
        for x in [0, 1, 8, 9] {
            #expect(!floor.grid.cell(x: x, y: 3).isPassable, "cell (\(x),3) should be a wall")
        }
    }

    @Test("Landmark positions match the L-shaped corridor topology")
    func landmarkPositionsAreCorrect() {
        let floor = FloorGenerator.generate(floorNumber: 1, config: .default)
        #expect(floor.entryPosition2D == Position(x: 7, y: 0))
        #expect(floor.staircasePosition2D == Position(x: 7, y: 6))
        #expect(floor.encounterPosition2D == Position(x: 7, y: 3))
    }
}
