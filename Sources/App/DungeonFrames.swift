// DungeonFrames — first-person wireframe dungeon corridor views.
// Each frame: exactly 15 rows, each row exactly 58 characters wide (padded with spaces).
// Fits within the 58-column dungeon view panel (cols 2-59 in the 80-col layout).
// Style: \ / | _ for structure; ▓░ at depth=2 only (sparingly); · for depth=3 fog.

// MARK: - Near-opening modifier

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

    for depth in 0...3 {
        // none: base grid as-is
        table[DungeonFrameKey(depth: depth, nearLeft: false, nearRight: false, farLeft: false, farRight: false)] =
            baseCorridorGrid(depth: depth).map { String($0) }

        // nearLeft
        var gL = baseCorridorGrid(depth: depth)
        applyNearOpening(&gL, side: .left)
        table[DungeonFrameKey(depth: depth, nearLeft: true, nearRight: false, farLeft: false, farRight: false)] =
            gL.map { String($0) }

        // nearRight
        var gR = baseCorridorGrid(depth: depth)
        applyNearOpening(&gR, side: .right)
        table[DungeonFrameKey(depth: depth, nearLeft: false, nearRight: true, farLeft: false, farRight: false)] =
            gR.map { String($0) }

        // nearBoth
        var gB = baseCorridorGrid(depth: depth)
        applyNearOpening(&gB, side: .left)
        applyNearOpening(&gB, side: .right)
        table[DungeonFrameKey(depth: depth, nearLeft: true, nearRight: true, farLeft: false, farRight: false)] =
            gB.map { String($0) }
    }

    return table
}

// MARK: - Fallback

func fallbackFrame(for key: DungeonFrameKey) -> [String] {
    // Strip farLeft/farRight (no frames use them) then progressively simplify nearLeft/nearRight.
    let candidates: [DungeonFrameKey] = [
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
