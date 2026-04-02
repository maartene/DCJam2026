// Position — 2D coordinate in the dungeon grid.
// Origin is south-west: x increases eastward, y increases northward.

public struct Position: Equatable, Hashable, Sendable {
    public let x: Int
    public let y: Int

    public init(x: Int, y: Int) {
        self.x = x
        self.y = y
    }
}

// MARK: - Integer literal compatibility (migration bridge)
// Allows legacy code that uses Int positions to compile during 1D→2D migration.
// Integer literal maps to the main corridor (x=7): Position(x:7, y:n).

extension Position: ExpressibleByIntegerLiteral {
    public init(integerLiteral value: Int) {
        self.init(x: 7, y: value)
    }
}

// MARK: - Comparable (supports > and < used in legacy tests)

extension Position: Comparable {
    public static func < (lhs: Position, rhs: Position) -> Bool {
        if lhs.x == rhs.x { return lhs.y < rhs.y }
        return lhs.x < rhs.x
    }
}

// MARK: - Arithmetic operators (migration bridge for legacy + Int expressions)

public extension Position {
    static func + (lhs: Position, rhs: Int) -> Position {
        Position(x: lhs.x, y: lhs.y + rhs)
    }

    static func - (lhs: Position, rhs: Int) -> Position {
        Position(x: lhs.x, y: lhs.y - rhs)
    }
}
