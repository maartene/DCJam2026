// DungeonDepth — derives a DungeonFrameKey from a 2D grid, player position, and facing direction.
//
// Depth table (from CLAUDE.md):
//   depth=0  wall at 1 step ahead
//   depth=1  passable 1 step ahead, wall at 2 steps ahead
//   depth=2  passable 1+2 steps ahead, wall at 3 steps ahead
//   depth=3  passable 1+2+3 steps ahead (corridor continues)
//
// Opening flags:
//   nearLeft  — cell to the left of the player's current position is passable
//   nearRight — cell to the right of the player's current position is passable
//   farLeft   — cell to the left of the one-step-ahead position is passable
//   farRight  — cell to the right of the one-step-ahead position is passable

import GameDomain

/// Derives a DungeonFrameKey from the 2D grid, the player's position, and their facing direction.
func dungeonFrameKey(grid: FloorGrid, position: Position, facing: CardinalDirection) -> DungeonFrameKey {
    let fwd = facing.forwardDelta
    let lft = facing.turned(by: .left).forwardDelta
    let rgt = facing.turned(by: .right).forwardDelta

    func isPassable(x: Int, y: Int) -> Bool {
        grid.cell(x: x, y: y).isPassable
    }

    let step1X = position.x + fwd.dx,  step1Y = position.y + fwd.dy
    let step2X = step1X + fwd.dx,      step2Y = step1Y + fwd.dy
    let step3X = step2X + fwd.dx,      step3Y = step2Y + fwd.dy

    let step1Passable = isPassable(x: step1X, y: step1Y)
    let step2Passable = isPassable(x: step2X, y: step2Y)
    let step3Passable = isPassable(x: step3X, y: step3Y)

    let depth: Int
    if !step1Passable {
        depth = 0
    } else if !step2Passable {
        depth = 1
    } else if !step3Passable {
        depth = 2
    } else {
        depth = 3
    }

    let nearLeft  = isPassable(x: position.x + lft.dx, y: position.y + lft.dy)
    let nearRight = isPassable(x: position.x + rgt.dx, y: position.y + rgt.dy)
    let farLeft   = isPassable(x: step1X + lft.dx, y: step1Y + lft.dy)
    let farRight  = isPassable(x: step1X + rgt.dx, y: step1Y + rgt.dy)

    return DungeonFrameKey(
        depth: depth,
        nearLeft: nearLeft,
        nearRight: nearRight,
        farLeft: farLeft,
        farRight: farRight
    )
}
