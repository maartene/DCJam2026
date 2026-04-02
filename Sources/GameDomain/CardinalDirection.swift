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
