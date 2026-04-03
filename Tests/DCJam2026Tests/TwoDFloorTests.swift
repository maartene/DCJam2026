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
//   Entry=(7,0), staircase=(7,6), egg=(2,3), encounter=(7,4).
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

    @Test("Moving forward while facing North advances Ember by (dx:0, dy:+1)")
    func forwardNorthAppliesCorrectDelta() {
        let start = GameState.initial(config: .default)
            .withPlayerPosition(Position(x: 7, y: 4))
            .withFacingDirection(.north)
        let result = RulesEngine.apply(command: .move(.forward), to: start, deltaTime: 0)
        #expect(result.playerPosition == Position(x: 7, y: 5))
    }

    @Test("Moving forward while facing East advances Ember by (dx:+1, dy:0)")
    func forwardEastAppliesCorrectDelta() {
        // Use branch corridor (y=3, x=4..5 are passable) to verify East delta.
        let start = GameState.initial(config: .default)
            .withPlayerPosition(Position(x: 4, y: 3))
            .withFacingDirection(.east)
        let result = RulesEngine.apply(command: .move(.forward), to: start, deltaTime: 0)
        #expect(result.playerPosition == Position(x: 5, y: 3))
    }

    @Test("Moving forward while facing South retreats Ember by (dx:0, dy:-1)")
    func forwardSouthAppliesCorrectDelta() {
        let start = GameState.initial(config: .default)
            .withPlayerPosition(Position(x: 7, y: 5))
            .withFacingDirection(.south)
        let result = RulesEngine.apply(command: .move(.forward), to: start, deltaTime: 0)
        #expect(result.playerPosition == Position(x: 7, y: 4))
    }

    @Test("Moving forward while facing West retreats Ember by (dx:-1, dy:0)")
    func forwardWestAppliesCorrectDelta() {
        // Use branch corridor (y=3, x=5..4 are passable) to verify West delta.
        let start = GameState.initial(config: .default)
            .withPlayerPosition(Position(x: 5, y: 3))
            .withFacingDirection(.west)
        let result = RulesEngine.apply(command: .move(.forward), to: start, deltaTime: 0)
        #expect(result.playerPosition == Position(x: 4, y: 3))
    }

    @Test("Moving backward produces the inverse delta for all four facings")
    func backwardIsInverseOfForward() {
        // Each case uses a start position where the backward target is a passable corridor cell.
        // backward north (dy:-1): (7,4)→(7,3) — main corridor
        // backward east  (dx:-1): (5,3)→(4,3) — branch corridor
        // backward south (dy:+1): (7,4)→(7,5) — main corridor
        // backward west  (dx:+1): (4,3)→(5,3) — branch corridor
        let cases: [(start: Position, facing: CardinalDirection, expected: Position)] = [
            (Position(x: 7, y: 4), .north, Position(x: 7, y: 3)),
            (Position(x: 5, y: 3), .east,  Position(x: 4, y: 3)),
            (Position(x: 7, y: 4), .south, Position(x: 7, y: 5)),
            (Position(x: 4, y: 3), .west,  Position(x: 5, y: 3)),
        ]
        for c in cases {
            let start = GameState.initial(config: .default)
                .withPlayerPosition(c.start)
                .withFacingDirection(c.facing)
            let result = RulesEngine.apply(command: .move(.backward), to: start, deltaTime: 0)
            #expect(result.playerPosition == c.expected, "backward from \(c.facing) should give \(c.expected)")
        }
    }

    // MARK: - US-TM-03: Wall collision

    @Test("Ember cannot step into a wall cell — position is unchanged")
    func movementIntoWallIsBlocked() {
        // Player at (7,4) facing East. Cell (8,4) is a wall (off the main corridor).
        let start = GameState.initial(config: .default)
            .withPlayerPosition(Position(x: 7, y: 4))
            .withFacingDirection(.east)
        let result = RulesEngine.apply(command: .move(.forward), to: start, deltaTime: 0)
        #expect(result.playerPosition == Position(x: 7, y: 4), "Stepping into a wall should leave position unchanged")
    }

    // MARK: - US-TM-03: Bounds clamping

    @Test("Ember's position is clamped at the south boundary — cannot step below y=0")
    func movementClampedAtSouthBoundary() {
        // Player at (7,0) facing South. Candidate (7,-1) is out-of-bounds → treated as wall.
        let start = GameState.initial(config: .default)
            .withPlayerPosition(Position(x: 7, y: 0))
            .withFacingDirection(.south)
        let result = RulesEngine.apply(command: .move(.forward), to: start, deltaTime: 0)
        #expect(result.playerPosition == Position(x: 7, y: 0), "Stepping south off the grid should leave position unchanged")
    }

    @Test("Ember's position is clamped at the west boundary — cannot step past x=0")
    func movementClampedAtWestBoundary() {
        // Player at (2,3) facing West. Cell (1,3) is a wall (branch corridor starts at x=2).
        let start = GameState.initial(config: .default)
            .withPlayerPosition(Position(x: 2, y: 3))
            .withFacingDirection(.west)
        let result = RulesEngine.apply(command: .move(.forward), to: start, deltaTime: 0)
        #expect(result.playerPosition == Position(x: 2, y: 3), "Stepping into a wall at the west end of the branch should leave position unchanged")
    }

    // MARK: - US-TM-03: Game rule preservation after movement

    @Test("Encounter proximity check still fires when Ember steps onto the encounter cell")
    func encounterProximityCheckAppliedAfterMove() {
        // Ember is one step south of the encounter cell (7,4), facing North.
        let start = GameState.initial(config: .default)
            .withPlayerPosition(Position(x: 7, y: 3))
            .withFacingDirection(.north)
        let result = RulesEngine.apply(command: .move(.forward), to: start, deltaTime: 0)
        if case .combat = result.screenMode {
            // Expected: stepping onto encounter cell (7,4) triggers combat mode.
        } else {
            Issue.record("Expected .combat screen mode after stepping onto encounter cell, got \(result.screenMode)")
        }
    }

    @Test("Win condition is checked when Ember reaches the exit cell with the egg")
    func winConditionCheckedAfterMoveToExit() {
        // Ember is one step south of the exit cell (7,6) on the final floor, facing North, carrying the egg.
        // The final floor (maxFloors=5) has hasExitSquare=true, which activates the win condition check.
        let finalFloor = GameConfig.default.maxFloors
        let start = GameState.initial(config: .default)
            .withCurrentFloor(finalFloor)
            .withPlayerPosition(Position(x: 7, y: 5))
            .withFacingDirection(.north)
            .withHasEgg(true)
        let result = RulesEngine.apply(command: .move(.forward), to: start, deltaTime: 0)
        if case .narrativeOverlay(let event) = result.screenMode, event == .exitPatio {
            // Expected: stepping onto exit cell (7,6) with egg triggers the exit narrative overlay.
        } else {
            Issue.record("Expected .narrativeOverlay(.exitPatio) screen mode after stepping onto exit with egg, got \(result.screenMode)")
        }
    }

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
        #expect(floor.encounterPosition2D == Position(x: 7, y: 4))
    }
}
