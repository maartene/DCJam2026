import Testing
@testable import DCJam2026
@testable import GameDomain

// DungeonFrameKey Depth Tests — Step 05-02
//
// Driving port: dungeonFrameKey(grid:position:facing:) — internal function in the App module.
// Tests derive DungeonFrameKey from a known FloorGrid, player position, and facing direction.
//
// Mandate compliance:
//   CM-A: Tests invoke the public API of the depth derivation function, not internal helpers.
//   CM-B: Test names use game domain terms (Ember, wall, corridor, depth).
//   CM-C: Each test validates observable DungeonFrameKey fields (depth, nearLeft, nearRight, farLeft, farRight).
//
// Test Budget: 8 distinct behaviors × 2 = 16 max unit tests
//   B1: depth=0 (wall directly ahead — 1 step is a wall)
//   B2: depth=1 (passable 1 ahead, wall 2 ahead)
//   B3: depth=2 (passable 1+2 ahead, wall 3 ahead)
//   B4: depth=3 (passable 1+2+3 ahead)
//   B5: nearLeft opening (left of player is passable)
//   B6: nearRight opening (right of player is passable)
//   B7: farLeft opening (left of 1-step-ahead is passable)
//   B8: farRight opening (right of 1-step-ahead is passable)
// Total tests used: 8 (within budget)

// Grid used in tests (standard L-shaped corridor from FloorGenerator):
//   Main corridor: x=7, y=0..6 (passable)
//   Branch corridor: y=3, x=2..7 (passable)
//   All other cells: wall (not passable)

@Suite("DungeonFrameKey — depth and opening flags derived from 2D grid")
struct DungeonFrameKeyTests {

    // The standard floor grid: main corridor x=7 (y=0..6), branch y=3 (x=2..7).
    private let grid: FloorGrid = {
        let floor = FloorGenerator.generate(floorNumber: 1, config: .default)
        return floor.grid
    }()

    // MARK: - B1..B4: Depth values

    @Test("depth=0 when wall is directly ahead (1 step ahead is a wall)",
          arguments: [
              // Facing north at y=6 (staircase): y=7 is out of bounds → wall
              (Position(x: 7, y: 6), CardinalDirection.north),
              // Facing south at y=0 (entry): y=-1 is out of bounds → wall
              (Position(x: 7, y: 0), CardinalDirection.south),
              // Facing west at x=2, y=3 (branch end): x=1 is wall
              (Position(x: 2, y: 3), CardinalDirection.west),
          ])
    func depthZeroWhenWallDirectlyAhead(position: Position, facing: CardinalDirection) {
        let key = dungeonFrameKey(grid: grid, position: position, facing: facing)
        #expect(key.depth == 0, "Expected depth=0 at \(position) facing \(facing), got \(key.depth)")
    }

    @Test("depth=1 when 1 step is passable and 2 steps ahead is a wall",
          arguments: [
              // Facing north at y=5: y=6 is passable, y=7 is wall
              (Position(x: 7, y: 5), CardinalDirection.north),
              // Facing south at y=1: y=0 is passable, y=-1 is wall
              (Position(x: 7, y: 1), CardinalDirection.south),
          ])
    func depthOneWhenOnePassableThenWall(position: Position, facing: CardinalDirection) {
        let key = dungeonFrameKey(grid: grid, position: position, facing: facing)
        #expect(key.depth == 1, "Expected depth=1 at \(position) facing \(facing), got \(key.depth)")
    }

    @Test("depth=2 when 2 steps ahead are passable and 3 steps ahead is a wall",
          arguments: [
              // Facing north at y=4: y=5, y=6 passable, y=7 wall
              (Position(x: 7, y: 4), CardinalDirection.north),
              // Facing south at y=2: y=1, y=0 passable, y=-1 wall
              (Position(x: 7, y: 2), CardinalDirection.south),
          ])
    func depthTwoWhenTwoPassableThenWall(position: Position, facing: CardinalDirection) {
        let key = dungeonFrameKey(grid: grid, position: position, facing: facing)
        #expect(key.depth == 2, "Expected depth=2 at \(position) facing \(facing), got \(key.depth)")
    }

    @Test("depth=3 when 3 or more steps ahead are all passable")
    func depthThreeWhenThreePassableAhead() {
        // Facing north at y=0: y=1,2,3,4,5,6 all passable → depth=3
        let key = dungeonFrameKey(grid: grid, position: Position(x: 7, y: 0), facing: .north)
        #expect(key.depth == 3)
    }

    // MARK: - B5: nearLeft opening

    @Test("nearLeft is true when left cell of player position is passable")
    func nearLeftTrueWhenLeftCellIsPassable() {
        // Facing north at (7,3): left=west=(6,3) which is in the branch corridor → passable
        let key = dungeonFrameKey(grid: grid, position: Position(x: 7, y: 3), facing: .north)
        #expect(key.nearLeft == true, "Expected nearLeft=true when facing north at (7,3): west cell (6,3) is passable")
    }

    // MARK: - B6: nearRight opening

    @Test("nearRight is true when right cell of player position is passable")
    func nearRightTrueWhenRightCellIsPassable() {
        // Facing south at (7,3): right=west=(6,3) which is in the branch corridor → passable
        let key = dungeonFrameKey(grid: grid, position: Position(x: 7, y: 3), facing: .south)
        #expect(key.nearRight == true, "Expected nearRight=true when facing south at (7,3): east cell (8,3) is not passable, west=(6,3) is")
    }

    // MARK: - B7: farLeft opening

    @Test("farLeft is true when left cell of one-step-ahead position is passable")
    func farLeftTrueWhenFarLeftCellIsPassable() {
        // Facing north at (7,2): one ahead = (7,3), left of (7,3) = west = (6,3) → passable
        let key = dungeonFrameKey(grid: grid, position: Position(x: 7, y: 2), facing: .north)
        #expect(key.farLeft == true, "Expected farLeft=true when facing north at (7,2): west cell of (7,3) is passable")
    }

    // MARK: - B8: farRight opening

    @Test("farRight is false when right cell of one-step-ahead position is a wall")
    func farRightFalseWhenFarRightCellIsWall() {
        // Facing north at (7,2): one ahead = (7,3), right of (7,3) = east = (8,3) → wall
        let key = dungeonFrameKey(grid: grid, position: Position(x: 7, y: 2), facing: .north)
        #expect(key.farRight == false, "Expected farRight=false when facing north at (7,2): east cell of (7,3) is wall")
    }
}
