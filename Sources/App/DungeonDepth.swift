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

/// Returns the delta (dx, dy) for one step in the given direction.
private func delta(for direction: CardinalDirection) -> (dx: Int, dy: Int) {
    switch direction {
    case .north: return (0,  1)
    case .south: return (0, -1)
    case .east:  return (1,  0)
    case .west:  return (-1, 0)
    }
}

/// Returns the direction to the left when facing `direction`.
private func leftOf(_ direction: CardinalDirection) -> CardinalDirection {
    switch direction {
    case .north: return .west
    case .west:  return .south
    case .south: return .east
    case .east:  return .north
    }
}

/// Returns the direction to the right when facing `direction`.
private func rightOf(_ direction: CardinalDirection) -> CardinalDirection {
    switch direction {
    case .north: return .east
    case .east:  return .south
    case .south: return .west
    case .west:  return .north
    }
}

/// Derives a DungeonFrameKey from the 2D grid, the player's position, and their facing direction.
func dungeonFrameKey(grid: FloorGrid, position: Position, facing: CardinalDirection) -> DungeonFrameKey {
    let fwd = delta(for: facing)
    let lft = delta(for: leftOf(facing))
    let rgt = delta(for: rightOf(facing))

    func isPassable(x: Int, y: Int) -> Bool {
        grid.cell(x: x, y: y).isPassable
    }

    let p1x = position.x + fwd.dx,  p1y = position.y + fwd.dy
    let p2x = p1x + fwd.dx,         p2y = p1y + fwd.dy
    let p3x = p2x + fwd.dx,         p3y = p2y + fwd.dy

    let step1Passable = isPassable(x: p1x, y: p1y)
    let step2Passable = isPassable(x: p2x, y: p2y)
    let step3Passable = isPassable(x: p3x, y: p3y)

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
    let farLeft   = isPassable(x: p1x + lft.dx, y: p1y + lft.dy)
    let farRight  = isPassable(x: p1x + rgt.dx, y: p1y + rgt.dy)

    return DungeonFrameKey(
        depth: depth,
        nearLeft: nearLeft,
        nearRight: nearRight,
        farLeft: farLeft,
        farRight: farRight
    )
}
