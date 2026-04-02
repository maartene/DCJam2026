// FloorGenerator — stateless namespace for floor and run generation.

public enum FloorGenerator {

    /// Generate a single floor. Entry is at position 0; staircase at a fixed depth.
    /// Egg room defaults to floor 2 for mid-floors; absent on floor 1 and final floor.
    public static func generate(floorNumber: Int, config: GameConfig) -> FloorMap {
        let isFinalFloor = floorNumber == config.maxFloors
        let isFirstFloor = floorNumber == 1
        let hasEggRoom = !isFirstFloor && !isFinalFloor && floorNumber == 2
        let eggPos: Int? = hasEggRoom ? 5 : nil
        // Encounter placement: floor 2 puts guard after egg room (pos 7); boss floor at pos 7;
        // all other floors at pos 5.
        let encounterPos: Int?
        if isFinalFloor {
            encounterPos = 7   // boss
        } else if floorNumber == 2 {
            encounterPos = 7   // guard appears after egg room (egg at 5)
        } else {
            encounterPos = 5   // standard guard mid-corridor
        }

        return FloorMap(
            floorNumber: floorNumber,
            hasEggRoom: hasEggRoom,
            hasBossEncounter: isFinalFloor,
            hasExitSquare: isFinalFloor,
            isNavigable: true,
            entryPosition: 0,
            staircasePosition: isFinalFloor ? Int.max : 10,
            exitPosition: isFinalFloor ? 10 : 0,
            eggRoomPosition: eggPos,
            encounterPosition: encounterPos
        )
    }

    /// Internal overload used by generateRun — knows which floor holds the egg.
    private static func generate(floorNumber: Int, config: GameConfig, eggFloor: Int) -> FloorMap {
        let isFinalFloor = floorNumber == config.maxFloors
        let isFirstFloor = floorNumber == 1
        let hasEggRoom = !isFirstFloor && !isFinalFloor && floorNumber == eggFloor
        let eggPos: Int? = hasEggRoom ? 5 : nil
        let encounterPos: Int?
        if isFinalFloor {
            encounterPos = 7
        } else if hasEggRoom {
            encounterPos = 7   // guard appears after egg room
        } else {
            encounterPos = 5
        }

        return FloorMap(
            floorNumber: floorNumber,
            hasEggRoom: hasEggRoom,
            hasBossEncounter: isFinalFloor,
            hasExitSquare: isFinalFloor,
            isNavigable: true,
            entryPosition: 0,
            staircasePosition: isFinalFloor ? Int.max : 10,
            exitPosition: isFinalFloor ? 10 : 0,
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
