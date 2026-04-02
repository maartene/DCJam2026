// FloorMap — the layout of a single dungeon floor.

public struct FloorMap: Sendable {
    public let floorNumber: Int
    public let hasEggRoom: Bool
    public let hasBossEncounter: Bool
    public let hasExitSquare: Bool
    public let isNavigable: Bool
    public let entryPosition: Int
    public let staircasePosition: Int
    public let exitPosition: Int          // Only valid when hasExitSquare == true
    public let eggRoomPosition: Int?      // Only valid when hasEggRoom == true
    public let encounterPosition: Int?    // Position where moving into triggers combat
}

// GameRun — the ordered sequence of floors generated for a run.

public struct GameRun: Sendable {
    public let floors: [FloorMap]
}
