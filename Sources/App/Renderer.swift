// Renderer — maps GameState to ANSI terminal output via TUIOutputPort.
// Screen layout (80×25 terminal):
//   Row 1       ┌──────────────────────────────────────────────────────────────────────────────┐
//   Rows 2-16   │ dungeon view (78×15) │
//   Row 17      ├──────────────────────────────────────────────────────────────────────────────┤
//   Row 18      │ HP/EGG/DASH/BRACE/SPEC status bar │
//   Row 19      │ controls hint line │
//   Row 20      ├─Thoughts──────────────────────────────────────────────────────────────────────┤
//   Rows 21-24  │ Ember's internal thoughts / flavor text │
//   Row 25      └──────────────────────────────────────────────────────────────────────────────┘

import Foundation
import GameDomain

final class Renderer {

    private let output: TUIOutputPort
    private let frames: [DungeonFrameKey: [String]]

    init(output: TUIOutputPort) {
        self.output = output
        self.frames = buildFrameTable()
    }

    func render(_ state: GameState) {
        output.clearScreen()
        drawChrome()
        switch state.screenMode {
        case .dungeon:
            renderDungeon(state)
            drawStatusBar(state)
            drawControlsBar("W/S: move forward/back   1: Dash through guard   2: Brace   3: Special   R: restart   Q: quit")
            drawThoughts(dungeonThoughts(state))
        case .combat(let encounter):
            renderCombat(state, encounter: encounter)
            drawStatusBar(state)
            drawControlsBar("1: Dash through (costs 1 charge)   2: Brace (parry window)   3: Special (needs full meter)")
            drawThoughts(combatThoughts(state, encounter: encounter))
        case .narrativeOverlay(let event):
            renderNarrativeOverlay(event)
            drawControlsBar("Space / Enter: continue")
            drawThoughts(narrativeThoughts(event))
        case .upgradePrompt(let choices):
            renderUpgradePrompt(state, choices: choices)
            drawControlsBar("1 / 2 / 3: select upgrade")
            drawThoughts(["An important choice awaits..."])
        case .deathState:
            renderDeathScreen(state)
        case .winState:
            renderWinScreen(state)
        }
        output.flush()
    }

    // MARK: - Chrome (box borders)

    private func drawChrome() {
        output.moveCursor(row: 1, col: 1)
        output.write("┌" + String(repeating: "─", count: 78) + "┐")

        for row in 2...16 {
            output.moveCursor(row: row, col: 1)
            output.write("│")
            output.moveCursor(row: row, col: 80)
            output.write("│")
        }

        output.moveCursor(row: 17, col: 1)
        output.write("├" + String(repeating: "─", count: 78) + "┤")

        for row in 18...19 {
            output.moveCursor(row: row, col: 1)
            output.write("│")
            output.moveCursor(row: row, col: 80)
            output.write("│")
        }

        output.moveCursor(row: 20, col: 1)
        output.write("├─Thoughts" + String(repeating: "─", count: 69) + "┤")

        for row in 21...24 {
            output.moveCursor(row: row, col: 1)
            output.write("│")
            output.moveCursor(row: row, col: 80)
            output.write("│")
        }

        output.moveCursor(row: 25, col: 1)
        output.write("└" + String(repeating: "─", count: 78) + "┘")
    }

    // MARK: - Dungeon view (rows 2-16, cols 2-79 = 78×15 interior)

    private func renderDungeon(_ state: GameState) {
        let floor = FloorGenerator.generate(floorNumber: state.currentFloor, config: state.config)
        // Use exitPosition on the final floor; staircasePosition otherwise.
        let targetPos = floor.hasExitSquare ? floor.exitPosition : floor.staircasePosition
        let squaresAhead = targetPos - state.playerPosition
        let depth: Int
        switch squaresAhead {
        case ...0:  depth = 0
        case 1:     depth = 1
        case 2:     depth = 2
        default:    depth = 3
        }
        let key = DungeonFrameKey(depth: depth, nearLeft: false, nearRight: false, farLeft: false, farRight: false)
        let frameLines = frames[key] ?? fallbackFrame(for: key)
        for (i, line) in frameLines.enumerated() {
            output.moveCursor(row: i + 2, col: 2)
            output.write(line)
        }

        let floorLabel = " Floor \(state.currentFloor)/\(state.config.maxFloors) "
        output.moveCursor(row: 2, col: 80 - floorLabel.count)
        output.write(floorLabel)
    }

    // MARK: - Combat view (rows 2-16)

    private func renderCombat(_ state: GameState, encounter: EncounterModel) {
        let lines = buildCombatFrame(state, encounter: encounter)
        for (i, line) in lines.enumerated() where i < 15 {
            output.moveCursor(row: i + 2, col: 2)
            output.write(line)
        }
    }

    private func buildCombatFrame(_ state: GameState, encounter: EncounterModel) -> [String] {
        let isBoss = encounter.isBossEncounter
        let maxEnemyHP = isBoss ? 120 : 40
        let enemyFillCount = Int(Double(encounter.enemyHP) / Double(maxEnemyHP) * 20.0)
        let clamped = max(0, min(enemyFillCount, 20))
        let enemyBar = String(repeating: "█", count: clamped) + String(repeating: "░", count: 20 - clamped)
        let attackIn = String(format: "%.1f", max(0.0, encounter.enemyAttackTimer))
        let enemyName = isBoss ? "DRAGON WARDEN" : "DUNGEON GUARD"
        let enemyHP = encounter.enemyHP

        let art: [String]
        if isBoss {
            art = [
                #"              /\___/\"#,
                #"             /  o o  \"#,
                #"            / ==^==  \"#,
                #"           /  \_V_/  \"#,
                #"   /\     /___/ \___\"#,
                #"  /  \   /   WARDEN  \"#,
                #" /    \_/             \"#,
                #"/______________________\"#,
            ]
        } else {
            art = [
                #"            _____"#,
                #"           /     \"#,
                #"          | o   o |"#,
                #"          |   ^   |"#,
                #"           \_____/"#,
                #"          /|     |\"#,
                #"         / |     | \"#,
                #"        /__|_____|__\"#,
            ]
        }

        var lines: [String] = []
        lines.append(pad78(""))
        lines.append(pad78(centered(enemyName, width: 78)))
        lines.append(pad78(""))
        for artLine in art {
            lines.append(pad78(centered(artLine, width: 78)))
        }
        lines.append(pad78(""))
        lines.append(pad78(centered("HP [\(enemyBar)] \(enemyHP)", width: 78)))
        lines.append(pad78(centered("ATTACK IN: \(attackIn)s", width: 78)))
        lines.append(pad78(""))
        lines.append(pad78(centered("(1) DASH    (2) BRACE    (3) SPECIAL", width: 78)))
        lines.append(pad78(""))

        while lines.count < 15 { lines.append(pad78("")) }
        return Array(lines.prefix(15))
    }

    // MARK: - Narrative overlay (rows 2-16)

    private func renderNarrativeOverlay(_ event: NarrativeEvent) {
        for row in 2...16 {
            output.moveCursor(row: row, col: 2)
            output.write(pad78(""))
        }
        let (title, body) = narrativeContent(event)
        output.moveCursor(row: 5, col: 2)
        output.write(pad78(centered("* * *  \(title)  * * *", width: 78)))
        for (i, line) in body.enumerated() {
            output.moveCursor(row: 7 + i, col: 2)
            output.write(pad78(line))
        }
        output.moveCursor(row: 14, col: 2)
        output.write(pad78(centered("[ Press SPACE to continue ]", width: 78)))
    }

    private func narrativeContent(_ event: NarrativeEvent) -> (String, [String]) {
        switch event {
        case .eggDiscovery:
            return ("THE EGG", [
                "",
                "  There — nestled in ash and shadow — the egg glows with quiet warmth.",
                "  Your scales bristle. This is what you came for.",
                "",
                "  You gather it gently in your claws. It pulses once, as if in recognition.",
                "  Now get out.",
            ])
        case .exitPatio:
            return ("THE PATIO", [
                "",
                "  Moonlight. Open sky. The faint smell of pine and cold stone.",
                "  You've found the exit patio — freedom is one leap away.",
                "",
                "  The wardens are close behind. Move now, or lose everything.",
            ])
        case .specialAttack:
            return ("DRAGON FIRE", [
                "",
                "  Something ancient stirs in your chest.",
                "  The charge is complete. Heat floods your throat.",
                "",
                "  You unleash it — a column of fire that scorches stone and silences",
                "  everything in its path.",
            ])
        }
    }

    // MARK: - Upgrade prompt (rows 2-16)

    private func renderUpgradePrompt(_ state: GameState, choices: [Upgrade]) {
        for row in 2...16 {
            output.moveCursor(row: row, col: 2)
            output.write(pad78(""))
        }
        output.moveCursor(row: 3, col: 2)
        output.write(pad78(centered("=== UPGRADE AVAILABLE ===", width: 78)))
        output.moveCursor(row: 4, col: 2)
        output.write(pad78(centered("Choose your power:", width: 78)))

        for (idx, upgrade) in choices.enumerated() {
            let row = 6 + idx * 2
            if row <= 15 {
                output.moveCursor(row: row, col: 2)
                output.write(pad78("  [\(idx + 1)]  \(upgrade.name)"))
                output.moveCursor(row: row + 1, col: 2)
                output.write(pad78("       \(upgradeDescription(upgrade))"))
            }
        }
    }

    private func upgradeDescription(_ upgrade: Upgrade) -> String {
        switch upgrade.effect {
        case .reduceDashCooldown(let factor):
            return "Dash cooldown reduced to \(Int(factor * 100))%"
        case .increaseDashChargeCap(let by):
            return "+\(by) dash charge capacity"
        case .increaseMaxHP(let by):
            return "+\(by) maximum HP"
        case .increaseSpecialRate(let factor):
            return "Special charges \(Int(factor * 100))% faster"
        }
    }

    // MARK: - Death screen

    private func renderDeathScreen(_ state: GameState) {
        for row in 2...16 {
            output.moveCursor(row: row, col: 2)
            output.write(pad78(""))
        }
        output.moveCursor(row: 5, col: 2)
        output.write(pad78(centered("- - - - - - - - - - - - - - -", width: 78)))
        output.moveCursor(row: 7, col: 2)
        output.write(pad78(centered("YOU HAVE FALLEN", width: 78)))
        output.moveCursor(row: 8, col: 2)
        output.write(pad78(centered("The darkness takes you...", width: 78)))
        output.moveCursor(row: 10, col: 2)
        output.write(pad78(centered("Floor reached: \(state.currentFloor)", width: 78)))
        output.moveCursor(row: 12, col: 2)
        output.write(pad78(centered("[ Press R to try again ]", width: 78)))
        output.moveCursor(row: 14, col: 2)
        output.write(pad78(centered("- - - - - - - - - - - - - - -", width: 78)))

        drawStatusBar(state)
        drawThoughts(["The darkness takes me... but perhaps the egg survived."])
    }

    // MARK: - Win screen

    private func renderWinScreen(_ state: GameState) {
        for row in 2...16 {
            output.moveCursor(row: row, col: 2)
            output.write(pad78(""))
        }
        output.moveCursor(row: 4, col: 2)
        output.write(pad78(centered("* * * * * * * * * * * * * * *", width: 78)))
        output.moveCursor(row: 6, col: 2)
        output.write(pad78(centered("ESCAPED!", width: 78)))
        output.moveCursor(row: 7, col: 2)
        output.write(pad78(centered("The egg is safe. You are free.", width: 78)))
        output.moveCursor(row: 9, col: 2)
        output.write(pad78(centered("Floors cleared: \(state.currentFloor - 1)", width: 78)))
        output.moveCursor(row: 10, col: 2)
        output.write(pad78(centered("HP remaining: \(state.hp)", width: 78)))
        output.moveCursor(row: 12, col: 2)
        output.write(pad78(centered("[ Press R to play again ]", width: 78)))
        output.moveCursor(row: 14, col: 2)
        output.write(pad78(centered("* * * * * * * * * * * * * * *", width: 78)))

        drawStatusBar(state)
        drawThoughts(["I am free! The egg is safe under the open sky."])
    }

    // MARK: - Status bar (row 18)

    private func drawStatusBar(_ state: GameState) {
        let hpFilled = Int(Double(state.hp) / Double(state.config.maxHP) * 10.0)
        let hpClamped = max(0, min(hpFilled, 10))
        let hpBar = String(repeating: "█", count: hpClamped) + String(repeating: "░", count: 10 - hpClamped)
        let eggSymbol = state.hasEgg ? "*" : " "

        let cooldown = state.timerModel.activeCooldownDuration
        let dashCooldownStr = cooldown > 0 ? String(format: " (cd=%.0fs)", cooldown) : ""
        let braceCooldownStr = state.braceOnCooldown ? String(format: " (cd=%.1fs)", state.braceCooldownTimer) : ""

        let specFilled = Int(state.specialCharge * 8.0)
        let specClamped = max(0, min(specFilled, 8))
        let specBar = String(repeating: "█", count: specClamped) + String(repeating: "░", count: 8 - specClamped)

        var bar = " HP [\(hpBar)]"
        bar += " EGG [\(eggSymbol)]"
        bar += "  (1)DASH[\(state.dashCharges)]\(dashCooldownStr)"
        bar += "  (2)BRACE\(braceCooldownStr)"
        bar += "  (3)SPEC[\(specBar)]"

        output.moveCursor(row: 18, col: 2)
        output.write(pad78(bar))
    }

    // MARK: - Controls bar (row 19)

    private func drawControlsBar(_ controls: String) {
        output.moveCursor(row: 19, col: 2)
        output.write(pad78(" \(controls)"))
    }

    // MARK: - Thoughts (rows 21-24)

    private func drawThoughts(_ lines: [String]) {
        // Word-wrap each entry to 77 chars (1 leading space eats the last column).
        var wrapped: [String] = []
        for line in lines {
            wrapped += wordWrap(line, width: 77)
        }
        for row in 21...24 {
            output.moveCursor(row: row, col: 2)
            output.write(pad78(""))
        }
        for (i, line) in wrapped.prefix(4).enumerated() {
            output.moveCursor(row: 21 + i, col: 2)
            output.write(pad78(" \(line)"))
        }
    }

    // MARK: - Word wrap

    private func wordWrap(_ text: String, width: Int) -> [String] {
        var lines: [String] = []
        var current = ""
        for word in text.split(separator: " ", omittingEmptySubsequences: false).map(String.init) {
            if current.isEmpty {
                current = word
            } else if current.count + 1 + word.count <= width {
                current += " " + word
            } else {
                lines.append(current)
                current = word
            }
        }
        if !current.isEmpty { lines.append(current) }
        return lines.isEmpty ? [""] : lines
    }

    // MARK: - Thought content

    private func dungeonThoughts(_ state: GameState) -> [String] {
        let map = buildMinimap(state)
        let flavor: String
        if state.recentDash {
            flavor = "I tear through! Wings snap, scales scrape stone — the guard never had a chance."
        } else if state.hp <= 20 {
            flavor = "My scales are scorched and my breath comes ragged. One more blow could finish me."
        } else if state.hasEgg {
            flavor = "I can feel the egg's warmth through my scales. Just a little further — hold together."
        } else if state.currentFloor == 1 {
            flavor = "Cold stone, ash, the smell of old magic. Something moves in the dark ahead. I keep walking."
        } else {
            flavor = "Deeper now. The air is thicker, heavier. My claws find the floor and I press on."
        }
        return [map, flavor]
    }

    /// Builds a minimap string: [E...G..○..S] showing entry, guard, player, staircase/exit.
    private func buildMinimap(_ state: GameState) -> String {
        let floor = FloorGenerator.generate(floorNumber: state.currentFloor, config: state.config)
        let end = floor.hasExitSquare ? floor.exitPosition : min(floor.staircasePosition, 10)
        var cells = [Character](repeating: ".", count: end + 1)

        // Landmarks
        cells[0] = "E"
        cells[end] = floor.hasExitSquare ? "X" : "S"
        if let eggPos = floor.eggRoomPosition, eggPos <= end {
            cells[eggPos] = state.hasEgg ? "e" : "*"
        }
        if let enc = floor.encounterPosition, enc <= end {
            cells[enc] = floor.hasBossEncounter ? "B" : "G"
        }
        // Player (overrides landmark if on same square)
        let pos = min(state.playerPosition, end)
        cells[pos] = "○"

        let bar = "[" + String(cells) + "]"
        return "Floor \(state.currentFloor):  \(bar)   E=entry  G=guard  *=egg  S=stairs  X=exit"
    }

    private func combatThoughts(_ state: GameState, encounter: EncounterModel) -> [String] {
        if encounter.isBossEncounter {
            return ["The Dragon Warden. Ancient. Enormous. My fire stirs — I'll need every trick I have."]
        } else if state.hp <= 30 {
            return ["I'm wounded and it knows it. I have to time this — brace the next strike, then move."]
        } else if state.dashCharges == 0 {
            return ["My wings are spent. No Dash left. I'll hold this ground until the fire builds."]
        } else {
            return ["A guard. Armoured, blocking the corridor. I can brace and take the hit — or just run."]
        }
    }

    private func narrativeThoughts(_ event: NarrativeEvent) -> [String] {
        switch event {
        case .eggDiscovery:  return ["There it is. The egg. I reach out and it pulses — warm, alive. Let's go."]
        case .exitPatio:     return ["Open sky. Cold air on my scales. I made it this far — one leap and I'm free."]
        case .specialAttack: return ["The heat rises in my chest and I let it out. Nothing in that corridor is standing."]
        }
    }

    // MARK: - Helpers

    private func pad78(_ s: String) -> String {
        let count = s.count
        if count >= 78 { return String(s.prefix(78)) }
        return s + String(repeating: " ", count: 78 - count)
    }

    private func centered(_ s: String, width: Int) -> String {
        let count = s.count
        guard count < width else { return String(s.prefix(width)) }
        let padding = (width - count) / 2
        return String(repeating: " ", count: padding) + s
    }
}
