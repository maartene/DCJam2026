// FloorRegistry — maps floor numbers to FloorMap via character-grid definitions.
// FloorDefinitionParser — internal parser converting FloorDefinition → FloorMap components.

// MARK: - FloorDefinitionParser (internal)

internal struct ParsedFloor {
    let grid: FloorGrid
    let entryPosition: Position?
    let staircasePosition: Position?
    let encounterPosition: Position?
    let bossPosition: Position?
    let eggPosition: Position?
    let exitPosition: Position?
}

internal enum FloorDefinitionParser {

    /// Parse a FloorDefinition into a ParsedFloor.
    /// Grid convention: first line = northernmost row = y = height-1.
    static func parse(_ definition: FloorDefinition) -> ParsedFloor {
        let lines = definition.grid.split(separator: "\n", omittingEmptySubsequences: false)
            .map { String($0) }
            .filter { !$0.allSatisfy({ $0 == " " }) && !$0.isEmpty }

        let height = lines.count
        guard height > 0 else {
            return ParsedFloor(
                grid: FloorGrid(width: 0, height: 0, cells: []),
                entryPosition: nil,
                staircasePosition: nil,
                encounterPosition: nil,
                bossPosition: nil,
                eggPosition: nil,
                exitPosition: nil
            )
        }

        let width = lines.map { $0.count }.max() ?? 0

        var entryPosition: Position? = nil
        var staircasePosition: Position? = nil
        var encounterPosition: Position? = nil
        var bossPosition: Position? = nil
        var eggPosition: Position? = nil
        var exitPosition: Position? = nil

        // Build grid: lines[0] = northernmost = y = height-1
        var rows: [[FloorCell]] = []
        for y in 0..<height {
            let lineIndex = height - 1 - y  // line 0 = y=height-1, line height-1 = y=0
            let line = lines[lineIndex]
            var row: [FloorCell] = []
            for (x, ch) in line.enumerated() {
                let isPassable = ch != "#"
                row.append(FloorCell(isPassable: isPassable))

                // Extract landmark positions
                switch ch {
                case "^", "v", "<", ">", "E":
                    entryPosition = Position(x: x, y: y)
                case "S":
                    staircasePosition = Position(x: x, y: y)
                case "G":
                    encounterPosition = Position(x: x, y: y)
                case "B":
                    bossPosition = Position(x: x, y: y)
                case "*":
                    eggPosition = Position(x: x, y: y)
                case "X":
                    exitPosition = Position(x: x, y: y)
                default:
                    break
                }
            }
            // Pad row to width if needed
            while row.count < width {
                row.append(FloorCell(isPassable: false))
            }
            rows.append(row)
        }

        let grid = FloorGrid(width: width, height: height, cells: rows)
        return ParsedFloor(
            grid: grid,
            entryPosition: entryPosition,
            staircasePosition: staircasePosition,
            encounterPosition: encounterPosition,
            bossPosition: bossPosition,
            eggPosition: eggPosition,
            exitPosition: exitPosition
        )
    }

    /// Convert a ParsedFloor + metadata into a FloorMap.
    static func buildFloorMap(floorNumber: Int, parsed: ParsedFloor) -> FloorMap {
        let hasEggRoom        = parsed.eggPosition != nil
        let hasBossEncounter  = parsed.bossPosition != nil
        let hasExitSquare     = parsed.exitPosition != nil

        let fallback          = Position(x: 0, y: 0)
        let entryPos          = parsed.entryPosition ?? fallback
        let staircasePos      = parsed.staircasePosition ?? parsed.entryPosition ?? fallback
        let exitPos           = parsed.exitPosition ?? parsed.staircasePosition ?? fallback
        let encounterPos: Position? = parsed.encounterPosition ?? parsed.bossPosition
        let eggPos: Position?       = parsed.eggPosition

        return FloorMap(
            floorNumber: floorNumber,
            hasEggRoom: hasEggRoom,
            hasBossEncounter: hasBossEncounter,
            hasExitSquare: hasExitSquare,
            isNavigable: true,
            entryPosition2D: entryPos,
            staircasePosition2D: staircasePos,
            exitPosition2D: exitPos,
            eggRoomPosition2D: eggPos,
            encounterPosition2D: encounterPos,
            grid: parsed.grid
        )
    }
}

// MARK: - FloorRegistry (public)

public enum FloorRegistry {

    // MARK: - Floor definitions

    /// Floor 1: L-shaped corridor — 15×7, identical topology to original procedural output.
    /// North = top (line 0 = y=6), south = bottom (line 6 = y=0).
    /// Main corridor: x=7 for all y=0..6.
    /// Branch corridor: y=3, x=2..7.
    private static let floor1 = FloorDefinition(grid:
    "#######S#######\n" +
    "#######.#######\n" +
    "#######.#######\n" +
    "##......#######\n" +
    "#######G#######\n" +
    "#######.#######\n" +
    "#######^#######"
    )

    private static let floor2 = FloorDefinition(grid:
    """
    ###S###############
    ###..............##
    #######.######.####
    ##.###########.####
    ##...G.........####
    ##*####.###########
    #######^###########
    """
    )

    private static let floor3 = FloorDefinition(grid:
    """
    ###########S#######
    #######.........###
    #######.#######.###
    ###.........G...###
    ###.###.#######.###
    ###.###.........###
    ###^###############
    """
    )

    /// Floor 4: compatible stub — 18×7 L-shaped topology, entry/staircase/guard match original procedural layout.
    /// Egg room at (2,3), guard encounter at (7,2), staircase at (7,6), entry at (7,0).
    /// Width 18 distinguishes dimensions from floors 1, 2, and 3.
    private static let floor4 = FloorDefinition(grid:
    """
    #########S#########
    ###.#####.#####.###
    ###.#####.#####.###
    ###.#####G#####.###
    ###.#####.#####.###
    ###.............###
    ###########^#######
    """
    )

    /// Floor 5: compatible stub — 19×7 L-shaped topology with boss and exit.
    /// Boss encounter at (7,3), exit at (7,6), entry at (7,0). No egg room, no staircase.
    /// Width 19 (maximum allowed) distinguishes dimensions from all other floors.
    private static let floor5 = FloorDefinition(grid:
    """
    #########X#########
    #########.#########
    #########.#########
    #########B#########
    #########.#########
    #########.#########
    #########^#########
    """
    )

    // MARK: - Public API

    /// Return the FloorMap for the given floor number.
    /// Unknown floor numbers fall back to floor 1.
    public static func floor(_ floorNumber: Int, config: GameConfig) -> FloorMap {
        let definition: FloorDefinition
        switch floorNumber {
        case 1: definition = floor1
        case 2: definition = floor2
        case 3: definition = floor3
        case 4: definition = floor4
        case 5: definition = floor5
        default: definition = floor1  // fallback: return floor 1 for unknown numbers
        }
        let parsed = FloorDefinitionParser.parse(definition)
        return FloorDefinitionParser.buildFloorMap(floorNumber: floorNumber, parsed: parsed)
    }
}
