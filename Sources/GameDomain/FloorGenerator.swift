// FloorGenerator — stateless namespace for floor and run generation.

public enum FloorGenerator {

    // MARK: - Grid constants

    public static let gridWidth = 15
    public static let gridHeight = 7

    // MARK: - 2D landmark positions (ADR-004 L-shaped corridor topology)

    private static let entry2D         = Position(x: 7, y: 0)
    private static let staircase2D     = Position(x: 7, y: 6)
    private static let encounter2D     = Position(x: 7, y: 3)
    private static let egg2D           = Position(x: 2, y: 3)
    private static let bossEncounter2D = Position(x: 7, y: 3)

    /// Generate a single floor. Entry is at (7,0); staircase at (7,6).
    /// Egg room defaults to floor 2 for mid-floors; absent on floor 1 and final floor.
    public static func generate(floorNumber: Int, config: GameConfig) -> FloorMap {
        generate(floorNumber: floorNumber, config: config, eggFloor: 2)
    }

    /// Shared floor builder — knows which floor holds the egg room.
    private static func generate(floorNumber: Int, config: GameConfig, eggFloor: Int) -> FloorMap {
        let isFinalFloor = floorNumber == config.maxFloors
        let isFirstFloor = floorNumber == 1
        let hasEggRoom = !isFirstFloor && !isFinalFloor && floorNumber == eggFloor
        let eggPos2D: Position? = hasEggRoom ? egg2D : nil

        let encounterPos2D: Position?
        if isFinalFloor {
            encounterPos2D = bossEncounter2D
        } else if hasEggRoom || (!isFirstFloor && !isFinalFloor) {
            encounterPos2D = encounter2D
        } else {
            encounterPos2D = encounter2D
        }

        let grid = buildGrid(eggPosition: eggPos2D)

        return FloorMap(
            floorNumber: floorNumber,
            hasEggRoom: hasEggRoom,
            hasBossEncounter: isFinalFloor,
            hasExitSquare: isFinalFloor,
            isNavigable: true,
            entryPosition2D: entry2D,
            staircasePosition2D: staircase2D,
            exitPosition2D: isFinalFloor ? staircase2D : staircase2D,
            eggRoomPosition2D: eggPos2D,
            encounterPosition2D: encounterPos2D,
            grid: grid
        )
    }

    /// Build the 15×7 L-shaped corridor grid.
    /// Passable cells: main corridor x=7 (all y 0..6), branch y=3 (x=2..7).
    private static func buildGrid(eggPosition: Position?) -> FloorGrid {
        let rows: [[FloorCell]] = (0..<gridHeight).map { y in
            (0..<gridWidth).map { x in
                let isMainCorridor = (x == 7)
                let isBranchCorridor = (y == 3 && x >= 2 && x <= 7)
                return FloorCell(isPassable: isMainCorridor || isBranchCorridor)
            }
        }
        return FloorGrid(width: gridWidth, height: gridHeight, cells: rows)
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
