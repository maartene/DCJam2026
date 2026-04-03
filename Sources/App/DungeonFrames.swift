// DungeonFrames — first-person wireframe dungeon corridor views.
// Each frame: exactly 15 rows, each row exactly 58 characters wide (padded with spaces).
// Fits within the 58-column dungeon view panel (cols 2-59 in the 80-col layout).
// Style: \ / | _ for structure; ▓░ at depth=2 only (sparingly); · for depth=3 fog.

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

    // depth=0: wall dead ahead, no side openings
    table[DungeonFrameKey(depth: 0, nearLeft: false, nearRight: false, farLeft: false, farRight: false)] =
        baseCorridorGrid(depth: 0).map { String($0) }

    // depth=1: wall one square ahead
    table[DungeonFrameKey(depth: 1, nearLeft: false, nearRight: false, farLeft: false, farRight: false)] =
        baseCorridorGrid(depth: 1).map { String($0) }
    table[DungeonFrameKey(depth: 1, nearLeft: true,  nearRight: false, farLeft: false, farRight: false)] = frame_d1_nearLeft()
    table[DungeonFrameKey(depth: 1, nearLeft: false, nearRight: true,  farLeft: false, farRight: false)] = frame_d1_nearRight()
    table[DungeonFrameKey(depth: 1, nearLeft: true,  nearRight: true,  farLeft: false, farRight: false)] = frame_d1_nearBoth()

    // depth=2: wall two squares ahead, sparse brick
    table[DungeonFrameKey(depth: 2, nearLeft: false, nearRight: false, farLeft: false, farRight: false)] =
        baseCorridorGrid(depth: 2).map { String($0) }
    table[DungeonFrameKey(depth: 2, nearLeft: true,  nearRight: false, farLeft: false, farRight: false)] = frame_d2_nearLeft()
    table[DungeonFrameKey(depth: 2, nearLeft: false, nearRight: true,  farLeft: false, farRight: false)] = frame_d2_nearRight()
    table[DungeonFrameKey(depth: 2, nearLeft: true,  nearRight: true,  farLeft: false, farRight: false)] = frame_d2_nearBoth()

    // depth=3: fog (plain and near-opening variants)
    table[DungeonFrameKey(depth: 3, nearLeft: false, nearRight: false, farLeft: false, farRight: false)] =
        baseCorridorGrid(depth: 3).map { String($0) }
    table[DungeonFrameKey(depth: 3, nearLeft: true,  nearRight: false, farLeft: false, farRight: false)] = frame_d3_nearLeft()
    table[DungeonFrameKey(depth: 3, nearLeft: false, nearRight: true,  farLeft: false, farRight: false)] = frame_d3_nearRight()
    table[DungeonFrameKey(depth: 3, nearLeft: true,  nearRight: true,  farLeft: false, farRight: false)] = frame_d3_nearBoth()

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

// nearLeft: left wall open, right wall closed — 58-col version
// Outer right wall at col 57 (0-indexed), left side open
private func frame_d1_nearLeft() -> [String] {
    return [
        pad(#"                                                    |"#),
        pad(#"  \                                                /|"#),
        pad(#"   \______________________________________________/ /|"#),
        pad(#"   |                                            | /  "#),
        pad(#"   |                                            |/   "#),
        pad(#"   |                                            /    "#),
        pad(#"   |                                           /|    "#),
        pad(#"   |                                            \    "#),
        pad(#"   |                                            |\   "#),
        pad(#"   |____________________________________________|\ "#),
        pad(#"   /                                            \ \|"#),
        pad(#"  /                                              \\|"#),
        pad(#"                                                    |"#),
        pad(#"                                                      "#),
        pad(#"                                                      "#),
    ]
}

// nearRight: right wall open, left wall closed — 58-col version
private func frame_d1_nearRight() -> [String] {
    return [
        pad(#"|                                                    "#),
        pad(#"|\                                                /  "#),
        pad(#"|\______________________________________________/ /   "#),
        pad(#"\ |                                            |     "#),
        pad(#" \|                                            |     "#),
        pad(#"  \                                            |     "#),
        pad(#"  |\                                           |     "#),
        pad(#"  /                                            |     "#),
        pad(#" /|                                            |     "#),
        pad(#"/ |____________________________________________|     "#),
        pad(#"| /                                            /     "#),
        pad(#"|/                                            /      "#),
        pad(#"|                                                    "#),
        pad(#"                                                      "#),
        pad(#"                                                      "#),
    ]
}

// nearBoth: both side walls open — 58-col version
private func frame_d1_nearBoth() -> [String] {
    return [
        pad(#"                                                      "#),
        pad(#"  \                                                /  "#),
        pad(#"   \________________________________________________/  "#),
        pad(#"   |                                              |  "#),
        pad(#"   |                                              |  "#),
        pad(#"   |                                              |  "#),
        pad(#"   |                                              |  "#),
        pad(#"   |                                              |  "#),
        pad(#"   |                                              |  "#),
        pad(#"   |______________________________________________|  "#),
        pad(#"   /                                              \  "#),
        pad(#"  /                                                \ "#),
        pad(#"                                                      "#),
        pad(#"                                                      "#),
        pad(#"                                                      "#),
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

private func frame_d2_nearLeft() -> [String] {
    return [
        pad(#"                                                    |"#),
        pad(#"  \                                                /|"#),
        pad(#"   \                                              / |"#),
        pad(#"    \____________________________________________/  | "#),
        pad(#"    |                                          |   | "#),
        pad(#"    |      ▓░▓  ░▓░  ▓░▓  ░▓░  ▓░▓       |   | "#),
        pad(#"    |      ░▓░  ▓░▓  ░▓░  ▓░▓  ░▓░       |   | "#),
        pad(#"    |      ▓░▓  ░▓░  ▓░▓  ░▓░  ▓░▓       |   | "#),
        pad(#"    |                                          |   | "#),
        pad(#"    |__________________________________________|   | "#),
        pad(#"   /                                          \  | "#),
        pad(#"  /                                            \ | "#),
        pad(#"                                                \| "#),
        pad(#"                                                    |"#),
        pad(#"                                                      "#),
    ]
}

private func frame_d2_nearRight() -> [String] {
    return [
        pad(#"|                                                    "#),
        pad(#"|\                                                /  "#),
        pad(#"| \                                              /   "#),
        pad(#"|  \____________________________________________/ /   "#),
        pad(#"|   |                                          |     "#),
        pad(#"|   |      ▓░▓  ░▓░  ▓░▓  ░▓░  ▓░▓       |     "#),
        pad(#"|   |      ░▓░  ▓░▓  ░▓░  ▓░▓  ░▓░       |     "#),
        pad(#"|   |      ▓░▓  ░▓░  ▓░▓  ░▓░  ▓░▓       |     "#),
        pad(#"|   |                                          |     "#),
        pad(#"|   |__________________________________________|     "#),
        pad(#"|  /                                          \    "#),
        pad(#"| /                                            \   "#),
        pad(#"|/                                                   "#),
        pad(#"|                                                    "#),
        pad(#"                                                      "#),
    ]
}

private func frame_d2_nearBoth() -> [String] {
    return [
        pad(#"                                                      "#),
        pad(#"  \                                                /  "#),
        pad(#"   \                                              /   "#),
        pad(#"    \____________________________________________/     "#),
        pad(#"    |                                          |     "#),
        pad(#"    |      ▓░▓  ░▓░  ▓░▓  ░▓░  ▓░▓       |     "#),
        pad(#"    |      ░▓░  ▓░▓  ░▓░  ▓░▓  ░▓░       |     "#),
        pad(#"    |      ▓░▓  ░▓░  ▓░▓  ░▓░  ▓░▓       |     "#),
        pad(#"    |                                          |     "#),
        pad(#"    |__________________________________________|     "#),
        pad(#"   /                                          \    "#),
        pad(#"  /                                            \   "#),
        pad(#"                                                      "#),
        pad(#"                                                      "#),
        pad(#"                                                      "#),
    ]
}

// MARK: - depth=3: fog variants with near side openings

// nearLeft: left wall open at player position, fog corridor ahead
// Each row 3-9 is exactly 58 chars: "     |" (6) + fog44 (44) + "    " (4) + junction (4).
// The last 4 chars fall in the right bright zone — they are the mirror of nearRight's
// left junction chars (\↔/, reversed): rows 3-9 = " | /", " |/ ", " /  ", "/|  ", " \  ", " |\ ", "_| \"
private func frame_d3_nearLeft() -> [String] {
    let fog44 = "  " + String(repeating: "· ", count: 20) + "  "  // 44 chars
    let us48  = String(repeating: "_", count: 48)
    func r(_ c: String, _ j: String) -> String { "     |\(c)    \(j)" }
    return [
        String(repeating: " ", count: 57) + "|",             // row  0: 57sp + | = 58
        "  \\" + String(repeating: " ", count: 53) + "/|",   // row  1: 3+53+2=58
        "   \\" + String(repeating: "_", count: 51) + " /|", // row  2: 4+51+3=58
        r(fog44, " | /"),                                     // row  3: mirror "\ | "
        r(fog44, " |/ "),                                     // row  4: mirror " \| "
        r(fog44, " /  "),                                     // row  5: mirror "  \ "
        r(fog44, "/|  "),                                     // row  6: mirror "  |\"
        r(fog44, " \\  "),                                    // row  7: mirror "  / "
        r(fog44, " |\\ "),                                    // row  8: mirror " /| "
        "     |\(us48)_| \\",                                 // row  9: 6+48+4=58, mirror "/ |_"
        "   /" + String(repeating: "_", count: 51) + " \\|", // row 10: 4+51+3=58
        "  /" + String(repeating: " ", count: 53) + "\\|",   // row 11: 3+53+2=58
        String(repeating: " ", count: 57) + "|",             // row 12: 57sp + | = 58
        String(repeating: " ", count: 58),                   // row 13
        String(repeating: " ", count: 58),                   // row 14
    ]
}

// nearRight: right wall open at player position, fog corridor ahead
// Rows 3-9: left junction (3 chars) + fog44 (44) + "|     " (6) = 53 → padded to 58.
// Row 6 uses fog43 (43 chars) because the "  |\" junction is 4 chars, keeping the
// right | at the same column as all other rows.
// First 4 chars fall in the left bright zone.
private func frame_d3_nearRight() -> [String] {
    let fog44 = "  " + String(repeating: "· ", count: 20) + "  "   // 44 chars
    let fog43 = "  " + String(repeating: "· ", count: 19) + "   "  // 43 chars (row 6 only)
    let us44  = String(repeating: "_", count: 44)
    return [
        pad(#"|                                                    "#),  // row  0
        pad(#"|\                                                /  "#),  // row  1
        pad(#"|\______________________________________________/ /   "#), // row  2: |\_... bright
        pad("\\ |\(String(repeating: " ", count: 44))|     "),           // row  3: "\ | " bright
        pad(" \\|\(fog44)|     "),                                        // row  4: " \| " bright
        pad("  \\\(fog44)|     "),                                        // row  5: "  \ " bright
        pad("  |\\\(fog43)|     "),                                       // row  6: "  |\" — fog43 keeps right | aligned
        pad("  /\(fog44)|     "),                                         // row  7: "  / " bright
        pad(" /|\(fog44)|     "),                                         // row  8: " /| " bright
        pad("/ |\(us44)|     "),                                          // row  9: "/ |_" bright
        pad(#"| /                                            /     "#),  // row 10
        pad(#"|/                                            /      "#),  // row 11
        pad(#"|                                                    "#),  // row 12
        String(repeating: " ", count: 58),                               // row 13
        String(repeating: " ", count: 58),                               // row 14
    ]
}

// nearBoth: both side walls open at player position, fog corridor ahead
private func frame_d3_nearBoth() -> [String] {
    let fog   = "  " + String(repeating: "· ", count: 16) + "  "
    let fogC  = "    " + String(repeating: "· ", count: 14) + "    "
    return [
        pad(#"                                                      "#), // row  0
        pad(#"  \                                                /  "#), // row  1
        pad(#"   \                                              /   "#), // row  2
        pad(#"    \____________________________________________/     "#),// row  3
        pad(#"    |                                          |     "#), // row  4
        pad("    |\(fog)|     "),                                        // row  5: fog
        pad("    |\(fogC)|     "),                                       // row  6: fog centre
        pad("    |\(fog)|     "),                                        // row  7: fog
        pad(#"    |                                          |     "#), // row  8
        pad(#"    |__________________________________________|     "#), // row  9
        pad(#"   /                                          \    "#),  // row 10
        pad(#"  /                                            \   "#),  // row 11
        pad(#"                                                      "#), // row 12
        pad(#"                                                      "#), // row 13
        pad(#"                                                      "#), // row 14
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
