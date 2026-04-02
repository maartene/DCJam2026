// FloorMap — the layout of a single dungeon floor.

struct FloorMap: Sendable {
    let floorNumber: Int
    let hasEggRoom: Bool
    let hasBossEncounter: Bool
    let hasExitSquare: Bool
    let isNavigable: Bool
    let entryPosition: Int
    let staircasePosition: Int
    let exitPosition: Int          // Only valid when hasExitSquare == true
    let eggRoomPosition: Int?      // Only valid when hasEggRoom == true
}

// GameRun — the ordered sequence of floors generated for a run.

struct GameRun: Sendable {
    let floors: [FloorMap]
}
