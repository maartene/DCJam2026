// FloorMap — the layout of a single dungeon floor.
// Grid is row-major: cells[y][x]. Width=15, Height=7.
// Origin south-west: y=0 is south (entry), y=6 is north (staircase).

public struct FloorCell: Sendable {
    public let isPassable: Bool

    public init(isPassable: Bool) {
        self.isPassable = isPassable
    }
}

public struct FloorGrid: Sendable {
    public let width: Int
    public let height: Int
    // Row-major storage: cells[y][x]
    private let cells: [[FloorCell]]

    public init(width: Int, height: Int, cells: [[FloorCell]]) {
        self.width = width
        self.height = height
        self.cells = cells
    }

    public func cell(x: Int, y: Int) -> FloorCell {
        guard x >= 0, x < width, y >= 0, y < height else {
            return FloorCell(isPassable: false)
        }
        return cells[y][x]
    }
}

public struct FloorMap: Sendable {
    public let floorNumber: Int
    public let hasEggRoom: Bool
    public let hasBossEncounter: Bool
    public let hasExitSquare: Bool
    public let isNavigable: Bool

    // 2D landmark positions
    public let entryPosition2D: Position
    public let staircasePosition2D: Position
    public let exitPosition2D: Position          // Only valid when hasExitSquare == true
    public let eggRoomPosition2D: Position?      // Only valid when hasEggRoom == true
    public let encounterPosition2D: Position?    // Position where moving into triggers combat

    // 2D grid
    public let grid: FloorGrid

    // Unified position accessors — return Position for both 1D and 2D callers.
    // Integer literals and arithmetic operators on Position ensure legacy code compiles.
    public var entryPosition: Position { entryPosition2D }
    public var staircasePosition: Position {
        hasExitSquare ? Position(x: Int.max, y: Int.max) : staircasePosition2D
    }
    public var exitPosition: Position { exitPosition2D }
    public var eggRoomPosition: Position? { eggRoomPosition2D }
    public var encounterPosition: Position? { encounterPosition2D }
}

// GameRun — the ordered sequence of floors generated for a run.

public struct GameRun: Sendable {
    public let floors: [FloorMap]
}
