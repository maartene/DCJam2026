// DungeonFrames — first-person wireframe dungeon corridor views.
// Each frame: exactly 15 rows, each row exactly 58 characters wide (padded with spaces).
// Fits within the 58-column dungeon view panel (cols 2-59 in the 80-col layout).
// Style: \ / | _ for structure; ▓░ at depth=2 only (sparingly); · for depth=3 fog.

// MARK: - Opening modifiers

enum Side { case left, right }

/// Removes the D=0 outer wall on one side of a [[Character]] corridor grid.
/// Clears the outer wall column and the perspective diagonals at ceiling and floor.
/// The D=1 inner wall is NOT touched.
func applyNearOpening(_ grid: inout [[Character]], side: Side) {
    switch side {
    case .right:
        for row in 0...12 { grid[row][57] = " " }
        grid[1][56] = " "
        grid[2][55] = " "
        grid[10][55] = " "
        grid[11][56] = " "
    case .left:
        for row in 0...12 { grid[row][0] = " " }
        grid[1][1] = " "
        grid[2][2] = " "
        grid[10][2] = " "
        grid[11][1] = " "
    }
}

/// Removes the D=1 inner wall on one side for rows 4-8 (the gap zone between D=2 ceiling and floor).
/// Rows 0-3 and 9-14 are NOT touched (lintels and outer walls remain intact).
/// The D=0 outer wall is completely untouched.
func applyFarOpening(_ grid: inout [[Character]], side: Side) {
    switch side {
    case .right:
        grid[4][52] = " "
        grid[4][54] = " "
        grid[5][54] = " "
        grid[6][54] = " "
        grid[7][54] = " "
        grid[8][52] = " "
        grid[8][54] = " "
    case .left:
        grid[4][5] = " "
        grid[4][3] = " "
        grid[5][3] = " "
        grid[6][3] = " "
        grid[7][3] = " "
        grid[8][5] = " "
        grid[8][3] = " "
    }
}

/// Extends ceiling and floor underscores to the frame edge for a near opening (Slice B).
/// Near-right: rows 2 and 10, cols 55-57 → `_`
/// Near-left:  rows 2 and 10, cols 0-2  → `_`
func applyNearCorridor(_ grid: inout [[Character]], side: Side) {
    switch side {
    case .right:
        for col in 55...57 { grid[2][col] = "_" }
        for col in 55...57 { grid[10][col] = "_" }
    case .left:
        for col in 0...2 { grid[2][col] = "_" }
        for col in 0...2 { grid[10][col] = "_" }
    }
}

/// Draws the visible side corridor geometry for a far opening (Slice B).
/// Far-right: ceiling stub `_` at row 3 col 53, back wall `|` at col 55 rows 4-8, floor stub `_` at row 8 col 53.
/// Far-left:  ceiling stub `_` at row 3 col 4,  back wall `|` at col 2  rows 4-8, floor stub `_` at row 8 col 4.
func applyFarCorridor(_ grid: inout [[Character]], side: Side) {
    switch side {
    case .right:
        // Ceiling stub: underscores at cols 53-54, back wall top at col 55
        grid[3][53] = "_"
        grid[3][54] = "_"
        grid[3][55] = "|"
        // Restore D=2 ceiling/floor diagonals (cleared by Slice A)
        grid[4][52] = "/"
        grid[8][52] = "\\"
        // Doorjamb (col 53) and back wall (col 55) through opening
        for row in 4...8 {
            grid[row][53] = "|"
            grid[row][55] = "|"
        }
        // Floor stub: underscore at col 54 (between doorjamb and back wall)
        grid[8][54] = "_"
        // Row 9: back wall extends below opening, D=1 lintel shifts to col 55
        grid[9][54] = " "
        grid[9][55] = "|"
    case .left:
        // Ceiling stub: underscores at cols 3-4, back wall top at col 2
        grid[3][4] = "_"
        grid[3][3] = "_"
        grid[3][2] = "|"
        // Restore D=2 ceiling/floor diagonals (cleared by Slice A)
        grid[4][5] = "\\"
        grid[8][5] = "/"
        // Doorjamb (col 4) and back wall (col 2) through opening
        for row in 4...8 {
            grid[row][4] = "|"
            grid[row][2] = "|"
        }
        // Floor stub: underscore at col 3 (between back wall and doorjamb)
        grid[8][3] = "_"
        // Row 9: back wall extends below opening, D=1 lintel shifts to col 2
        grid[9][3] = " "
        grid[9][2] = "|"
    }
}

// MARK: - Base corridor grid builder

/// Returns a mutable [[Character]] grid (58 cols × 15 rows) with both walls intact
/// for the given depth (0-3). The grid captures the structural skeleton of the corridor:
/// outer walls, perspective diagonals, depth-specific ceiling/floor geometry, and wall face.
func baseCorridorGrid(depth: Int) -> [[Character]] {
    let strings: [String]
    switch depth {
    case 0:  strings = frame_d0_none()
    case 1:  strings = frame_d1_none()
    case 2:  strings = frame_d2_none()
    default: strings = frame_d3_fog()
    }
    return strings.map { Array($0) }
}

// MARK: - Frame table builder

func buildFrameTable() -> [DungeonFrameKey: [String]] {
    var table: [DungeonFrameKey: [String]] = [:]

    // Depth 0: near-opening variants only (far openings make no visual sense at depth 0)
    for nearLeft in [false, true] {
        for nearRight in [false, true] {
            var g = baseCorridorGrid(depth: 0)
            if nearLeft  { applyNearOpening(&g, side: .left) }
            if nearRight { applyNearOpening(&g, side: .right) }
            if nearLeft  { applyNearCorridor(&g, side: .left) }
            if nearRight { applyNearCorridor(&g, side: .right) }
            table[DungeonFrameKey(depth: 0, nearLeft: nearLeft, nearRight: nearRight, farLeft: false, farRight: false)] =
                g.map { String($0) }
        }
    }

    // Depths 1-3: all 16 combinations of near/far openings
    for depth in 1...3 {
        for nearLeft in [false, true] {
            for nearRight in [false, true] {
                for farLeft in [false, true] {
                    for farRight in [false, true] {
                        var g = baseCorridorGrid(depth: depth)
                        if nearLeft  { applyNearOpening(&g, side: .left) }
                        if nearRight { applyNearOpening(&g, side: .right) }
                        if farLeft   { applyFarOpening(&g, side: .left) }
                        if farRight  { applyFarOpening(&g, side: .right) }
                        if nearLeft  { applyNearCorridor(&g, side: .left) }
                        if nearRight { applyNearCorridor(&g, side: .right) }
                        if farLeft   { applyFarCorridor(&g, side: .left) }
                        if farRight  { applyFarCorridor(&g, side: .right) }
                        table[DungeonFrameKey(depth: depth, nearLeft: nearLeft, nearRight: nearRight, farLeft: farLeft, farRight: farRight)] =
                            g.map { String($0) }
                    }
                }
            }
        }
    }

    return table
}

// MARK: - Fallback

func fallbackFrame(for key: DungeonFrameKey) -> [String] {
    // Try exact match first (all combinations are now in the table),
    // then progressively simplify near/far flags as a safety net.
    let candidates: [DungeonFrameKey] = [
        key,
        DungeonFrameKey(depth: key.depth, nearLeft: key.nearLeft, nearRight: key.nearRight, farLeft: false, farRight: false),
        DungeonFrameKey(depth: key.depth, nearLeft: key.nearLeft, nearRight: false,          farLeft: false, farRight: false),
        DungeonFrameKey(depth: key.depth, nearLeft: false,         nearRight: key.nearRight, farLeft: false, farRight: false),
        DungeonFrameKey(depth: key.depth, nearLeft: false,         nearRight: false,          farLeft: false, farRight: false),
    ]
    let table = buildFrameTable()
    for candidate in candidates {
        if let frame = table[candidate] { return frame }
    }
    return frame_d3_fog()
}

// MARK: - Pad helper

private func pad(_ s: String, to width: Int = 58) -> String {
    let count = s.count
    if count >= width { return String(s.prefix(width)) }
    return s + String(repeating: " ", count: width - count)
}

// MARK: - depth=0: wall right in front (close wall)
// 58-col layout: | + 56 interior + |

private func frame_d0_none() -> [String] {
    let sp56  = String(repeating: " ", count: 56)
    let sp54  = String(repeating: " ", count: 54)
    let us52  = String(repeating: "_", count: 52)
    let us50  = String(repeating: "_", count: 50)
    let stone = String(repeating: "▓▒", count: 25)
    return [
        "|\(sp56)|",                    // row  0
        "|\\\(sp54)/|",                 // row  1
        "| \\\(us52)/ |",               // row  2: level-1 ceiling
        "|  |\(us50)|  |",              // row  3: top of wall face
        "|  |\(stone)|  |",             // row  4
        "|  |\(stone)|  |",             // row  5
        "|  |\(stone)|  |",             // row  6
        "|  |\(stone)|  |",             // row  7
        "|  |\(stone)|  |",             // row  8
        "|  |\(us50)|  |",              // row  9: bottom of wall face
        "| /\(us52)\\ |",               // row 10: level-1 floor
        "|/\(sp54)\\|",                 // row 11
        "|\(sp56)|",                    // row 12
        String(repeating: " ", count: 58),
        String(repeating: " ", count: 58),
    ]
}

// MARK: - depth=1: wall one square ahead

private func frame_d1_none() -> [String] {
    let sp56  = String(repeating: " ", count: 56)
    let sp54  = String(repeating: " ", count: 54)
    let us52  = String(repeating: "_", count: 52)
    let us50  = String(repeating: "_", count: 50)
    // brick: 25 pairs = 50 chars
    let brickA = String(repeating: "▓░", count: 25)
    let brickB = String(repeating: "░▓", count: 25)
    return [
        "|\(sp56)|",                    // row  0
        "|\\\(sp54)/|",                 // row  1
        "| \\\(us52)/ |",               // row  2: level-1 ceiling
        "|  |\(us50)|  |",              // row  3: top of wall face
        "|  |\(brickA)|  |",            // row  4
        "|  |\(brickB)|  |",            // row  5
        "|  |\(brickA)|  |",            // row  6
        "|  |\(brickB)|  |",            // row  7
        "|  |\(brickA)|  |",            // row  8
        "|  |\(us50)|  |",              // row  9: bottom of wall face
        "| /\(us52)\\ |",               // row 10: level-1 floor
        "|/\(sp54)\\|",                 // row 11
        "|\(sp56)|",                    // row 12
        String(repeating: " ", count: 58),
        String(repeating: " ", count: 58),
    ]
}

// MARK: - depth=2: wall two squares ahead, brick face at level-2
// 58-col layout:
// Row 0: |<56sp>|
// Row 1: |\<54sp>/|
// Row 2: | \<52_>/ |
// Row 3: |  |<50sp>|  |
// Row 4: |  | \<46_>/ |  |
// Row 5-7: |  |  |<44chars>|  |  |
// Row 8: |  | /<46_>\ |  |
// Row 9: |  |<50sp>|  |
// Row 10: | /<52_>\ |
// Row 11: |/<54sp>\|
// Row 12: |<56sp>|

private func frame_d2_none() -> [String] {
    let sp56   = String(repeating: " ", count: 56)
    let sp54   = String(repeating: " ", count: 54)
    let us52   = String(repeating: "_", count: 52)
    let sp50   = String(repeating: " ", count: 50)
    let us46   = String(repeating: "_", count: 46)
    // brick at level-2 scale: 44-char wide face
    let brickA = String(repeating: "▓░", count: 22)   // 44 chars
    let brickB = String(repeating: "░▓", count: 22)   // 44 chars
    return [
        "|\(sp56)|",                         // row  0
        "|\\\(sp54)/|",                      // row  1
        "| \\\(us52)/ |",                    // row  2: level-1 ceiling
        "|  |\(sp50)|  |",                   // row  3: level-1 walls
        "|  | \\\(us46)/ |  |",              // row  4: level-2 ceiling
        "|  |  |\(brickA)|  |  |",           // row  5: brick
        "|  |  |\(brickB)|  |  |",           // row  6: brick (offset row)
        "|  |  |\(brickA)|  |  |",           // row  7: brick
        "|  | /\(us46)\\ |  |",              // row  8: level-2 floor
        "|  |\(sp50)|  |",                   // row  9: level-1 walls
        "| /\(us52)\\ |",                    // row 10: level-1 floor
        "|/\(sp54)\\|",                      // row 11
        "|\(sp56)|",                         // row 12
        String(repeating: " ", count: 58),
        String(repeating: " ", count: 58),
    ]
}

// MARK: - depth=3: fog

private func frame_d3_fog() -> [String] {
    let sp56  = String(repeating: " ", count: 56)
    let sp54  = String(repeating: " ", count: 54)
    let us52  = String(repeating: "_", count: 52)
    let sp50  = String(repeating: " ", count: 50)
    let us46  = String(repeating: "_", count: 46)
    // fog content — each row exactly 44 display chars
    let fog   = "  " + String(repeating: "· ", count: 20) + "  "        // 2+40+2 = 44
    let fogC  = "      " + String(repeating: "· ", count: 16) + "      " // 6+32+6 = 44
    return [
        "|\(sp56)|",                        // row  0: outer ceiling (56 sp)
        "|\\\(sp54)/|",                     // row  1: ceiling perspective
        "| \\\(us52)/ |",                   // row  2: level-1 ceiling  (52 _)
        "|  |\(sp50)|  |",                  // row  3: level-1 walls    (50 sp)
        "|  | \\\(us46)/ |  |",             // row  4: level-2 ceiling  (46 _)
        "|  |  |\(fog)|  |  |",             // row  5: fog
        "|  |  |\(fogC)|  |  |",            // row  6: fog (centre, lighter)
        "|  |  |\(fog)|  |  |",             // row  7: fog
        "|  | /\(us46)\\ |  |",             // row  8: level-2 floor    (46 _)
        "|  |\(sp50)|  |",                  // row  9: level-1 walls    (50 sp)
        "| /\(us52)\\ |",                   // row 10: level-1 floor    (52 _)
        "|/\(sp54)\\|",                     // row 11: floor perspective
        "|\(sp56)|",                        // row 12: outer floor      (56 sp)
        String(repeating: " ", count: 58),  // row 13
        String(repeating: " ", count: 58),  // row 14
    ]
}
