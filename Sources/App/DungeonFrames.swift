// DungeonFrames — first-person wireframe dungeon corridor views.
// Each frame: exactly 15 rows, each row exactly 78 characters wide (padded with spaces).
// Style: \ / | _ for structure; ▓░ at depth=2 only (sparingly); · for depth=3 fog.

// MARK: - Frame table builder

func buildFrameTable() -> [DungeonFrameKey: [String]] {
    var table: [DungeonFrameKey: [String]] = [:]

    // depth=0: wall dead ahead, no side openings
    table[DungeonFrameKey(depth: 0, nearLeft: false, nearRight: false, farLeft: false, farRight: false)] = frame_d0_none()

    // depth=1: wall one square ahead
    table[DungeonFrameKey(depth: 1, nearLeft: false, nearRight: false, farLeft: false, farRight: false)] = frame_d1_none()
    table[DungeonFrameKey(depth: 1, nearLeft: true,  nearRight: false, farLeft: false, farRight: false)] = frame_d1_nearLeft()
    table[DungeonFrameKey(depth: 1, nearLeft: false, nearRight: true,  farLeft: false, farRight: false)] = frame_d1_nearRight()
    table[DungeonFrameKey(depth: 1, nearLeft: true,  nearRight: true,  farLeft: false, farRight: false)] = frame_d1_nearBoth()

    // depth=2: wall two squares ahead, sparse brick
    table[DungeonFrameKey(depth: 2, nearLeft: false, nearRight: false, farLeft: false, farRight: false)] = frame_d2_none()
    table[DungeonFrameKey(depth: 2, nearLeft: true,  nearRight: false, farLeft: false, farRight: false)] = frame_d2_nearLeft()
    table[DungeonFrameKey(depth: 2, nearLeft: false, nearRight: true,  farLeft: false, farRight: false)] = frame_d2_nearRight()
    table[DungeonFrameKey(depth: 2, nearLeft: true,  nearRight: true,  farLeft: false, farRight: false)] = frame_d2_nearBoth()

    // depth=3: fog
    table[DungeonFrameKey(depth: 3, nearLeft: false, nearRight: false, farLeft: false, farRight: false)] = frame_d3_fog()

    return table
}

// MARK: - Fallback

func fallbackFrame(for key: DungeonFrameKey) -> [String] {
    let candidates: [DungeonFrameKey] = [
        DungeonFrameKey(depth: key.depth, nearLeft: key.nearLeft,  nearRight: key.nearRight,  farLeft: false, farRight: false),
        DungeonFrameKey(depth: key.depth, nearLeft: key.nearLeft,  nearRight: false,           farLeft: false, farRight: false),
        DungeonFrameKey(depth: key.depth, nearLeft: false,          nearRight: key.nearRight,  farLeft: false, farRight: false),
        DungeonFrameKey(depth: key.depth, nearLeft: false,          nearRight: false,           farLeft: false, farRight: false),
    ]
    let table = buildFrameTable()
    for candidate in candidates {
        if let frame = table[candidate] { return frame }
    }
    return frame_d3_fog()
}

// MARK: - Pad helper

private func pad(_ s: String, to width: Int = 78) -> String {
    let count = s.count
    if count >= width { return String(s.prefix(width)) }
    return s + String(repeating: " ", count: width - count)
}

// MARK: - depth=0: wall right in front (staircase)
// Shares the same outer skeleton as d1/d2/d3. Wall face fills the level-1 space.

private func frame_d0_none() -> [String] {
    let sp76  = String(repeating: " ", count: 76)
    let sp74  = String(repeating: " ", count: 74)
    let us72  = String(repeating: "_", count: 72)
    let us70  = String(repeating: "_", count: 70)
    // medium-shade stone: close wall reads as solid, not brick-patterned
    let stone = String(repeating: "▒", count: 70)
    let label = String(repeating: " ", count: 28) + "[ STAIRCASE ]" + String(repeating: " ", count: 29) // 28+13+29=70
    return [
        "|\(sp76)|",                    // row  0
        "|\\\(sp74)/|",                 // row  1
        "| \\\(us72)/ |",               // row  2: level-1 ceiling
        "|  |\(us70)|  |",              // row  3: top of wall face
        "|  |\(stone)|  |",             // row  4
        "|  |\(stone)|  |",             // row  5
        "|  |\(label)|  |",             // row  6: label
        "|  |\(stone)|  |",             // row  7
        "|  |\(stone)|  |",             // row  8
        "|  |\(us70)|  |",              // row  9: bottom of wall face
        "| /\(us72)\\ |",               // row 10: level-1 floor
        "|/\(sp74)\\|",                 // row 11
        "|\(sp76)|",                    // row 12
        String(repeating: " ", count: 78),
        String(repeating: " ", count: 78),
    ]
}

// MARK: - depth=1: wall one square ahead

private func frame_d1_none() -> [String] {
    let sp76  = String(repeating: " ", count: 76)
    let sp74  = String(repeating: " ", count: 74)
    let us72  = String(repeating: "_", count: 72)
    let us70  = String(repeating: "_", count: 70)
    // brick at level-1 scale: 70-char wide face, alternating rows
    let brickA = String(repeating: "▓░", count: 35)   // 70 chars
    let brickB = String(repeating: "░▓", count: 35)   // 70 chars
    let label  = String(repeating: " ", count: 31) + "[ WALL ]" + String(repeating: " ", count: 31) // 31+8+31=70
    return [
        "|\(sp76)|",                    // row  0
        "|\\\(sp74)/|",                 // row  1
        "| \\\(us72)/ |",               // row  2: level-1 ceiling
        "|  |\(us70)|  |",              // row  3: top of wall face
        "|  |\(brickA)|  |",            // row  4
        "|  |\(brickB)|  |",            // row  5
        "|  |\(label)|  |",             // row  6: label centred in brick
        "|  |\(brickB)|  |",            // row  7
        "|  |\(brickA)|  |",            // row  8
        "|  |\(us70)|  |",              // row  9: bottom of wall face
        "| /\(us72)\\ |",               // row 10: level-1 floor
        "|/\(sp74)\\|",                 // row 11
        "|\(sp76)|",                    // row 12
        String(repeating: " ", count: 78),
        String(repeating: " ", count: 78),
    ]
}

private func frame_d1_nearLeft() -> [String] {
    return [
        pad(#"                                                                            |"#),
        pad(#"  \                                                                        /|"#),
        pad(#"   \____________________________________________________________________/ /|"#),
        pad(#"   |                                                                    | / "#),
        pad(#"   |                                                                    |/  "#),
        pad(#"   |                                                                    /   "#),
        pad(#"   |                      [ WALL ]                                    /|   "#),
        pad(#"   |                                                                    \   "#),
        pad(#"   |                                                                    |\  "#),
        pad(#"   |____________________________________________________________________|\ "#),
        pad(#"   /                                                                    \ \|"#),
        pad(#"  /                                                                      \\|"#),
        pad(#"                                                                            |"#),
        pad(#"                                                                              "#),
        pad(#"                                                                              "#),
    ]
}

private func frame_d1_nearRight() -> [String] {
    return [
        pad(#"|                                                                            "#),
        pad(#"|\                                                                        /  "#),
        pad(#"|\____________________________________________________________________/ /   "#),
        pad(#"\ |                                                                    |     "#),
        pad(#" \|                                                                    |     "#),
        pad(#"  \                                                                    |     "#),
        pad(#"  |\                    [ WALL ]                                      |     "#),
        pad(#"  /                                                                    |     "#),
        pad(#" /|                                                                    |     "#),
        pad(#"/ |____________________________________________________________________|     "#),
        pad(#"| /                                                                    /     "#),
        pad(#"|/                                                                    /      "#),
        pad(#"|                                                                            "#),
        pad(#"                                                                              "#),
        pad(#"                                                                              "#),
    ]
}

private func frame_d1_nearBoth() -> [String] {
    return [
        pad(#"                                                                              "#),
        pad(#"  \                                                                        /  "#),
        pad(#"   \______________________________________________________________________/  "#),
        pad(#"   |                                                                      |  "#),
        pad(#"   |                                                                      |  "#),
        pad(#"   |                                                                      |  "#),
        pad(#"   |                       [ WALL ]                                      |  "#),
        pad(#"   |                                                                      |  "#),
        pad(#"   |                                                                      |  "#),
        pad(#"   |______________________________________________________________________|  "#),
        pad(#"   /                                                                      \  "#),
        pad(#"  /                                                                        \ "#),
        pad(#"                                                                              "#),
        pad(#"                                                                              "#),
        pad(#"                                                                              "#),
    ]
}

// MARK: - depth=2: wall two squares ahead, brick face at level-2
// Identical outer skeleton to d3; only content rows 5-7 differ (brick vs fog).

private func frame_d2_none() -> [String] {
    let sp76   = String(repeating: " ", count: 76)
    let sp74   = String(repeating: " ", count: 74)
    let us72   = String(repeating: "_", count: 72)
    let sp70   = String(repeating: " ", count: 70)
    let us66   = String(repeating: "_", count: 66)
    // brick at level-2 scale: 64-char wide face
    let brickA = String(repeating: "▓░", count: 32)   // 64 chars
    let brickB = String(repeating: "░▓", count: 32)   // 64 chars
    return [
        "|\(sp76)|",                         // row  0
        "|\\\(sp74)/|",                      // row  1
        "| \\\(us72)/ |",                    // row  2: level-1 ceiling
        "|  |\(sp70)|  |",                   // row  3: level-1 walls
        "|  | \\\(us66)/ |  |",              // row  4: level-2 ceiling
        "|  |  |\(brickA)|  |  |",           // row  5: brick
        "|  |  |\(brickB)|  |  |",           // row  6: brick (offset row)
        "|  |  |\(brickA)|  |  |",           // row  7: brick
        "|  | /\(us66)\\ |  |",              // row  8: level-2 floor
        "|  |\(sp70)|  |",                   // row  9: level-1 walls
        "| /\(us72)\\ |",                    // row 10: level-1 floor
        "|/\(sp74)\\|",                      // row 11
        "|\(sp76)|",                         // row 12
        String(repeating: " ", count: 78),
        String(repeating: " ", count: 78),
    ]
}

private func frame_d2_nearLeft() -> [String] {
    return [
        pad(#"                                                                            |"#),
        pad(#"  \                                                                        /|"#),
        pad(#"   \                                                                      / |"#),
        pad(#"    \__________________________________________________________________/  | "#),
        pad(#"    |                                                                  |   | "#),
        pad(#"    |           ▓░▓  ░▓░  ▓░░  ░▓▓  ░▓░  ▓░▓  ░▓░            |   | "#),
        pad(#"    |           ░▓░  ▓░▓  ░▓▓  ▓░░  ▓░▓  ░▓░  ▓░▓            |   | "#),
        pad(#"    |           ▓░▓  ░▓░  ▓░▓  ░▓▓  ░▓▓  ▓░░  ░▓░            |   | "#),
        pad(#"    |                                                                  |   | "#),
        pad(#"    |__________________________________________________________________|   | "#),
        pad(#"   /                                                                    \  | "#),
        pad(#"  /                                                                      \ | "#),
        pad(#"                                                                          \| "#),
        pad(#"                                                                            |"#),
        pad(#"                                                                              "#),
    ]
}

private func frame_d2_nearRight() -> [String] {
    return [
        pad(#"|                                                                            "#),
        pad(#"|\                                                                        /  "#),
        pad(#"| \                                                                      /   "#),
        pad(#"|  \__________________________________________________________________/ /   "#),
        pad(#"|   |                                                                  |     "#),
        pad(#"|   |           ▓░▓  ░▓░  ▓░░  ░▓▓  ░▓░  ▓░▓  ░▓░            |     "#),
        pad(#"|   |           ░▓░  ▓░▓  ░▓▓  ▓░░  ▓░▓  ░▓░  ▓░▓            |     "#),
        pad(#"|   |           ▓░▓  ░▓░  ▓░▓  ░▓▓  ░▓▓  ▓░░  ░▓░            |     "#),
        pad(#"|   |                                                                  |     "#),
        pad(#"|   |__________________________________________________________________|     "#),
        pad(#"|  /                                                                    \    "#),
        pad(#"| /                                                                      \   "#),
        pad(#"|/                                                                           "#),
        pad(#"|                                                                            "#),
        pad(#"                                                                              "#),
    ]
}

private func frame_d2_nearBoth() -> [String] {
    return [
        pad(#"                                                                              "#),
        pad(#"  \                                                                        /  "#),
        pad(#"   \                                                                      /   "#),
        pad(#"    \__________________________________________________________________/     "#),
        pad(#"    |                                                                  |     "#),
        pad(#"    |           ▓░▓  ░▓░  ▓░░  ░▓▓  ░▓░  ▓░▓  ░▓░            |     "#),
        pad(#"    |           ░▓░  ▓░▓  ░▓▓  ▓░░  ▓░▓  ░▓░  ▓░▓            |     "#),
        pad(#"    |           ▓░▓  ░▓░  ▓░▓  ░▓▓  ░▓▓  ▓░░  ░▓░            |     "#),
        pad(#"    |                                                                  |     "#),
        pad(#"    |__________________________________________________________________|     "#),
        pad(#"   /                                                                    \    "#),
        pad(#"  /                                                                      \   "#),
        pad(#"                                                                              "#),
        pad(#"                                                                              "#),
        pad(#"                                                                              "#),
    ]
}

// MARK: - depth=3: fog

private func frame_d3_fog() -> [String] {
    let sp76  = String(repeating: " ", count: 76)
    let sp74  = String(repeating: " ", count: 74)
    let us72  = String(repeating: "_", count: 72)
    let sp70  = String(repeating: " ", count: 70)
    let us66  = String(repeating: "_", count: 66)
    // fog content — each row exactly 64 display chars
    let fog   = "  " + String(repeating: "· ", count: 30) + "  "        // 2+60+2 = 64
    let fogC  = "        " + String(repeating: "· ", count: 24) + "        " // 8+48+8 = 64
    return [
        "|\(sp76)|",                        // row  0: outer ceiling (76 sp)
        "|\\\(sp74)/|",                     // row  1: ceiling perspective
        "| \\\(us72)/ |",                   // row  2: level-1 ceiling  (72 _)
        "|  |\(sp70)|  |",                  // row  3: level-1 walls    (70 sp)
        "|  | \\\(us66)/ |  |",             // row  4: level-2 ceiling  (66 _)
        "|  |  |\(fog)|  |  |",             // row  5: fog
        "|  |  |\(fogC)|  |  |",            // row  6: fog (centre, lighter)
        "|  |  |\(fog)|  |  |",             // row  7: fog
        "|  | /\(us66)\\ |  |",             // row  8: level-2 floor    (66 _)
        "|  |\(sp70)|  |",                  // row  9: level-1 walls    (70 sp)
        "| /\(us72)\\ |",                   // row 10: level-1 floor    (72 _)
        "|/\(sp74)\\|",                     // row 11: floor perspective
        "|\(sp76)|",                        // row 12: outer floor      (76 sp)
        String(repeating: " ", count: 78),  // row 13
        String(repeating: " ", count: 78),  // row 14
    ]
}
