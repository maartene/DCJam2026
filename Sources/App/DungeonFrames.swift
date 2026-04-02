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

// MARK: - depth=0: wall right in front

private func frame_d0_none() -> [String] {
    return [
        pad(#"\                                                                            /"#),
        pad(#" \                                                                          / "#),
        pad(#"  \________________________________________________________________________/  "#),
        pad(#"  |                                                                        |  "#),
        pad(#"  |                                                                        |  "#),
        pad(#"  |                                                                        |  "#),
        pad(#"  |                          [ WALL ]                                     |  "#),
        pad(#"  |                                                                        |  "#),
        pad(#"  |                                                                        |  "#),
        pad(#"  |                                                                        |  "#),
        pad(#"  |________________________________________________________________________|  "#),
        pad(#" /                                                                          \ "#),
        pad(#"/                                                                            \"#),
        pad(#"                                                                              "#),
        pad(#"                                                                              "#),
    ]
}

// MARK: - depth=1: wall one square ahead

private func frame_d1_none() -> [String] {
    return [
        pad(#"|                                                                            |"#),
        pad(#"|\                                                                          /|"#),
        pad(#"| \______________________________________________________________________/ | "#),
        pad(#"|  |                                                                    |  | "#),
        pad(#"|  |                                                                    |  | "#),
        pad(#"|  |                                                                    |  | "#),
        pad(#"|  |                        [ WALL ]                                   |  | "#),
        pad(#"|  |                                                                    |  | "#),
        pad(#"|  |                                                                    |  | "#),
        pad(#"|  |____________________________________________________________________|  | "#),
        pad(#"| /                                                                      \ | "#),
        pad(#"|/                                                                        \| "#),
        pad(#"|                                                                            |"#),
        pad(#"                                                                              "#),
        pad(#"                                                                              "#),
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

// MARK: - depth=2: wall two squares ahead, sparse brick face

private func frame_d2_none() -> [String] {
    return [
        pad(#"|                                                                            |"#),
        pad(#"|\                                                                          /|"#),
        pad(#"| \                                                                        / |"#),
        pad(#"|  \____________________________________________________________________/  | "#),
        pad(#"|   |                                                                  |   | "#),
        pad(#"|   |           ▓░▓  ░▓░  ▓░░  ░▓▓  ░▓░  ▓░▓  ░▓░            |   | "#),
        pad(#"|   |           ░▓░  ▓░▓  ░▓▓  ▓░░  ▓░▓  ░▓░  ▓░▓            |   | "#),
        pad(#"|   |           ▓░▓  ░▓░  ▓░▓  ░▓▓  ░▓▓  ▓░░  ░▓░            |   | "#),
        pad(#"|   |                                                                  |   | "#),
        pad(#"|   |__________________________________________________________________|   | "#),
        pad(#"|  /                                                                    \  | "#),
        pad(#"| /                                                                      \ | "#),
        pad(#"|/                                                                        \| "#),
        pad(#"|                                                                            |"#),
        pad(#"                                                                              "#),
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
