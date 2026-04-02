// CardinalDirection — the four compass directions Ember can face.
// TurnDirection — the two directions Ember can turn.

public enum CardinalDirection: Sendable, Equatable, Hashable, CaseIterable {
    case north
    case east
    case south
    case west
}

public enum TurnDirection: Sendable, Equatable {
    case left
    case right
}

// MARK: - Navigation helpers

public extension CardinalDirection {

    /// The direction obtained by turning 90 degrees in the given direction.
    func turned(by turn: TurnDirection) -> CardinalDirection {
        switch (self, turn) {
        case (.north, .left):  return .west
        case (.north, .right): return .east
        case (.east,  .left):  return .north
        case (.east,  .right): return .south
        case (.south, .left):  return .east
        case (.south, .right): return .west
        case (.west,  .left):  return .south
        case (.west,  .right): return .north
        }
    }

    /// The (dx, dy) step for moving one cell in this direction.
    var forwardDelta: (dx: Int, dy: Int) {
        switch self {
        case .north: return (dx:  0, dy: +1)
        case .east:  return (dx: +1, dy:  0)
        case .south: return (dx:  0, dy: -1)
        case .west:  return (dx: -1, dy:  0)
        }
    }
}
