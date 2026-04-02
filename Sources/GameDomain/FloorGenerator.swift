// FloorGenerator — stateless namespace for floor and run generation.

public enum FloorGenerator {

    // MARK: - Floor layout constants

    private static let entryPosition = 0
    private static let standardStaircasePosition = 10
    private static let standardExitPosition = 10
    private static let eggRoomPosition = 5
    private static let standardEncounterPosition = 5
    private static let postEggEncounterPosition = 7    // guard after egg room
    private static let bossEncounterPosition = 7

    /// Generate a single floor. Entry is at position 0; staircase at a fixed depth.
    /// Egg room defaults to floor 2 for mid-floors; absent on floor 1 and final floor.
    public static func generate(floorNumber: Int, config: GameConfig) -> FloorMap {
        generate(floorNumber: floorNumber, config: config, eggFloor: 2)
    }

    /// Shared floor builder — knows which floor holds the egg room.
    private static func generate(floorNumber: Int, config: GameConfig, eggFloor: Int) -> FloorMap {
        let isFinalFloor = floorNumber == config.maxFloors
        let isFirstFloor = floorNumber == 1
        let hasEggRoom = !isFirstFloor && !isFinalFloor && floorNumber == eggFloor
        let eggPos: Int? = hasEggRoom ? eggRoomPosition : nil
        let encounterPos: Int?
        if isFinalFloor {
            encounterPos = bossEncounterPosition
        } else if hasEggRoom {
            encounterPos = postEggEncounterPosition
        } else {
            encounterPos = standardEncounterPosition
        }

        return FloorMap(
            floorNumber: floorNumber,
            hasEggRoom: hasEggRoom,
            hasBossEncounter: isFinalFloor,
            hasExitSquare: isFinalFloor,
            isNavigable: true,
            entryPosition: entryPosition,
            staircasePosition: isFinalFloor ? Int.max : standardStaircasePosition,
            exitPosition: isFinalFloor ? standardExitPosition : 0,
            eggRoomPosition: eggPos,
            encounterPosition: encounterPos
        )
    }

    /// Generate a complete run of floors using a reproducible seed.
    /// Always generates exactly config.maxFloors floors.
    public static func generateRun(config: GameConfig, seed: Int) -> GameRun {
        let floorCount = config.maxFloors
        // Select one egg floor from [2..floorCount-1] using seed.
        let eligibleCount = max(1, floorCount - 2)  // floors 2..floorCount-1
        let eggFloor = 2 + (seed % eligibleCount)
        let floors = (1...floorCount).map { n in
            generate(floorNumber: n, config: config, eggFloor: eggFloor)
        }
        return GameRun(floors: floors)
    }
}
