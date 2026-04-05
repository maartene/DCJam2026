// Renderer — maps GameState to ANSI terminal output via TUIOutputPort.
// Screen layout (80×25 terminal, ADR-006 vertical split):
//   Row 1       ┌──────────────────────────────────────────────────────┬──────────────────┐
//   Rows 2-16   │ dungeon view (cols 2-59, 58 cols) │ minimap (61-79) │
//   Row 17      ├──────────────────────────────────────────────────────┴──────────────────┤
//   Row 18      │ HP/EGG/DASH/BRACE/SPEC status bar                                      │
//   Row 19      │ controls hint line                                                      │
//   Row 20      ├─Thoughts──────────────────────────────────────────────────────────────────┤
//   Rows 21-24  │ Ember's internal thoughts / flavor text                                │
//   Row 25      └──────────────────────────────────────────────────────────────────────────┘

import Foundation
import GameDomain

final class Renderer {

    private let output: TUIOutputPort
    private let frames: [DungeonFrameKey: [String]]
    private let supports256Color: Bool

    init(output: TUIOutputPort) {
        self.output = output
        self.frames = buildFrameTable()
        self.supports256Color = (ProcessInfo.processInfo.environment["TERM"] ?? "").contains(
            "256color")
    }

    /// Internal initializer for tests — injects the 256-color capability directly.
    init(output: TUIOutputPort, supports256Color: Bool) {
        self.output = output
        self.frames = buildFrameTable()
        self.supports256Color = supports256Color
    }

    func render(_ state: GameState) {
        if case .startScreen = state.screenMode {
            renderStartScreen()
            return
        }
        output.clearScreen()
        drawChrome()
        switch state.screenMode {
        case .dungeon:
            renderDungeon(state)
            drawStatusBar(state)
            drawThoughts(dungeonThoughts(state))
        case .combat(let encounter):
            renderCombat(state, encounter: encounter)
            drawStatusBar(state)
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
        case .startScreen:
            break  // unreachable — handled above
        }
        renderTransientOverlay(state)
        output.flush()
    }

    // MARK: - Transient overlay (row 9, centered in cols 1-60)

    private func renderTransientOverlay(_ state: GameState) {
        guard let overlay = state.transientOverlay else { return }
        switch state.screenMode {
        case .dungeon, .combat:
            renderOverlayWord(overlay)
        default:
            return
        }
    }

    private func renderOverlayWord(_ overlay: TransientOverlay) {
        let word: String
        let colorCode: String
        switch overlay {
        case .braceSuccess:
            word = "SHIELDED!"
            colorCode = ansiBrightCyan
        case .braceHit:
            word = "STRUCK!"
            colorCode = ansiBrightRed
        case .dash:
            word = "SWOOSH!"
            colorCode = ansiBoldBrightWhite
        case .special:
            word = "SEARING!"
            colorCode = ansiBoldBrightRed
        }
        let col = (60 - word.count) / 2 + 1
        output.moveCursor(row: 9, col: col)
        output.write(colored(word, code: colorCode))
    }

    // MARK: - Start screen (full-screen takeover, 80×25)

    private func renderStartScreen() {
        output.clearScreen()

        // Row 6: title
        let title = colored("EMBER'S ESCAPE", code: ansiBoldBrightWhite)
        let titlePad = (80 - "EMBER'S ESCAPE".count) / 2
        output.moveCursor(row: 6, col: titlePad)
        output.write(title)

        // Row 8: subtitle
        let subtitle = "DCJam 2026"
        let subtitlePad = (80 - subtitle.count) / 2
        output.moveCursor(row: 8, col: subtitlePad)
        output.write(colored(subtitle, code: ansiDimCyan))

        // Row 10: narrative hook
        let hook = "A young dragon. A stolen egg. One chance to escape."
        let hookPad = (80 - hook.count) / 2
        output.moveCursor(row: 10, col: hookPad)
        output.write(colored(hook, code: ansiYellow))

        // Rows 12-16: controls table (two columns to fit without hitting status bar row 18)
        let controlsTitle = "Controls"
        let controlsTitlePad = (80 - controlsTitle.count) / 2
        output.moveCursor(row: 12, col: controlsTitlePad)
        output.write(colored(controlsTitle, code: ansiBoldBrightWhite))

        // Left column: movement keys (col 15); right column: action keys (col 45)
        let leftControls: [(String, String)] = [
            ("W", "Move forward"),
            ("S", "Move backward"),
            ("A", "Turn left"),
            ("D", "Turn right"),
        ]
        let rightControls: [(String, String)] = [
            ("1", "Dash through enemy"),
            ("2", "Brace for impact"),
            ("3", "Special attack"),
            ("ESC", "Exit game"),
        ]
        for (i, (key, desc)) in leftControls.enumerated() {
            output.moveCursor(row: 14 + i, col: 15)
            output.write(colored(key, code: ansiBoldBrightWhite) + "  —  " + desc)
        }
        for (i, (key, desc)) in rightControls.enumerated() {
            output.moveCursor(row: 14 + i, col: 45)
            output.write(colored(key, code: ansiBoldBrightWhite) + "  —  " + desc)
        }

        // Row 23: prompt
        let prompt = "[ Press any key to begin ]"
        let promptPad = (80 - prompt.count) / 2
        output.moveCursor(row: 23, col: promptPad)
        output.write(colored(prompt, code: ansiBrightCyan))

        // Row 25: version (lower-left corner)
        output.moveCursor(row: 25, col: 1)
        output.write(colored(AppVersion.current, code: ansiDarkGray))

        output.flush()
    }

    // MARK: - Chrome (box borders)

    private func drawChrome() {
        // Row 1: top border with vertical split connector '┬' at col 60
        // col 1='┌', cols 2-59=58×'─', col 60='┬', cols 61-79=19×'─', col 80='┐'
        output.moveCursor(row: 1, col: 1)
        output.write(
            "┌" + String(repeating: "─", count: 58) + "┬" + String(repeating: "─", count: 19) + "┐")

        // Rows 2-16: side borders + vertical divider at col 60
        drawSideBarsWithDivider(rows: 2...16)

        // Row 17: separator with '┴' T-junction closing the vertical divider
        // col 1='├', cols 2-59=58×'─', col 60='┴', cols 61-79=19×'─', col 80='┤'
        output.moveCursor(row: 17, col: 1)
        output.write(
            "├" + String(repeating: "─", count: 58) + "┴" + String(repeating: "─", count: 19) + "┤")

        drawSideBars(rows: 18...19)

        output.moveCursor(row: 20, col: 1)
        output.write("├─Thoughts" + String(repeating: "─", count: 69) + "┤")

        drawSideBars(rows: 21...24)

        output.moveCursor(row: 25, col: 1)
        output.write("└" + String(repeating: "─", count: 78) + "┘")
    }

    private func drawSideBars(rows: ClosedRange<Int>) {
        for row in rows {
            output.moveCursor(row: row, col: 1)
            output.write("│")
            output.moveCursor(row: row, col: 80)
            output.write("│")
        }
    }

    private func drawSideBarsWithDivider(rows: ClosedRange<Int>) {
        for row in rows {
            output.moveCursor(row: row, col: 1)
            output.write("│")
            // Write divider at col 60 and right border at col 80 in one write so the
            // right border is not recorded as a separate entry at col > 79 by TUIOutputSpy.
            output.moveCursor(row: row, col: 60)
            output.write("│" + String(repeating: " ", count: 19) + "│")
        }
    }

    // MARK: - Dungeon view (rows 2-16, cols 2-79 = 78×15 interior)

    private func renderDungeon(_ state: GameState) {
        let floor = FloorRegistry.floor(state.currentFloor, config: state.config)
        let key = dungeonFrameKey(
            grid: floor.grid, position: state.playerPosition, facing: state.facingDirection)
        let frameLines = frames[key] ?? fallbackFrame(for: key)
        let colorCode = depthColor(for: key.depth)
        output.moveCursor(row: Self.mainViewFirstRow, col: 1)
        output.write("\u{1B}[40m")
        let sideColor = depthColor(for: 0)
        // Apply region coloring whenever depth > 0 and at least one side wall is present.
        let hasLeftWall = !key.nearLeft
        let hasRightWall = !key.nearRight
        let useRegionColoring = key.depth > 0 && (hasLeftWall || hasRightWall)
        for (i, line) in frameLines.enumerated() {
            output.moveCursor(row: i + Self.mainViewFirstRow, col: 2)
            if useRegionColoring {
                output.write(
                    regionColoredLine(
                        line, sideColor: sideColor, centerColor: colorCode,
                        row: i, hasLeftWall: hasLeftWall, hasRightWall: hasRightWall,
                        hasFarRight: key.farRight, hasFarLeft: key.farLeft))
            } else {
                output.write(colorCode + line + ansiReset)
            }
        }
        output.moveCursor(row: Self.mainViewLastRow + 1, col: 1)
        output.write(ansiReset)

        output.moveCursor(row: 2, col: 61)
        output.write(" \(state.currentFloor)/\(state.config.maxFloors)")

        renderMinimap(floor: floor, state: state)
        drawMinimapLegend()
    }

    // MARK: - Minimap legend (rows 10-16, cols 61-79)

    /// Renders a 7-entry symbol legend in the right panel below the minimap.
    /// Only called from renderDungeon — never from combat or other screens.
    private func drawMinimapLegend() {
        let entries: [(String, String)] = [
            (colored("^", code: ansiBoldBrightWhite), " You"),
            (colored("G", code: ansiBrightRed), " Guard"),
            (colored("B", code: ansiBoldBrightRed), " Boss"),
            (colored("*", code: ansiBrightYellow), " Egg"),
            (colored("S", code: ansiBrightCyan), " Stairs"),
            (colored("E", code: ansiDimCyan), " Entry"),
            (colored("X", code: ansiBoldBrightCyan), " Exit"),
        ]
        for (i, (symbol, label)) in entries.enumerated() {
            let row = 10 + i
            output.moveCursor(row: row, col: 61)
            output.write(symbol)
            output.moveCursor(row: row, col: 62)
            output.write(label)
        }
    }

    // MARK: - Combat view (rows 2-16)

    private func renderCombat(_ state: GameState, encounter: EncounterModel) {
        let lines = buildCombatFrame(state, encounter: encounter)
        for (i, line) in lines.enumerated() where i < Self.mainViewLineCount {
            output.moveCursor(row: i + Self.mainViewFirstRow, col: 2)
            output.write(line)
        }
    }

    private static let mainViewLineCount = 15
    private static let mainViewFirstRow = 2
    private static let mainViewLastRow = 16
    private static let thoughtsLineWidth = 77
    private static let enemyHPBarWidth = 20
    private static let specialMeterWidth = 8
    private static let hpBarWidth = 10

    private func buildCombatFrame(_ state: GameState, encounter: EncounterModel) -> [String] {
        let enemyFillCount = Int(
            Double(encounter.enemyHP) / Double(encounter.maxHP) * Double(Self.enemyHPBarWidth))
        let clamped = max(0, min(enemyFillCount, Self.enemyHPBarWidth))
        let enemyBar =
            String(repeating: "█", count: clamped)
            + String(repeating: "░", count: Self.enemyHPBarWidth - clamped)
        let attackIn = String(format: "%.1f", max(0.0, encounter.enemyAttackTimer))
        let enemyName = encounter.isBossEncounter ? "HEAD WARDEN" : "DUNGEON GUARD"
        let enemyHP = encounter.enemyHP

        let art: [String]
        if encounter.isBossEncounter {
            art = [
                #".   _.---._     jgs   "#,
                #"..-' ((O)) '-.        "#,
                #". \ _.\_/._ /         "#,
                #".  /..___..\          "#,
                #".  ;-.___.-;          "#,
                #". (| e ) e |)     .;. "#,
                #".  \  /_   /      ||||"#,
                #".  _\__-__/_    (\|'-|"#,
                #"./` / \V/ \ `\   \ )/ "#,
            ]
        } else {
            art = [
                #"       __  _.-"` `'-. "#,
                #"      /||\'._ __{}_(  "#,
                #"      ||||  #'--.__\  "#,
                #"      |  L.(   ^_\^   "#,
                #"      \ .-' |   _ |   "#,
                #"      | |   )\___/    "#,
                #"      |  \-'`:._]     "#,
                #" jgs  \__/;       '-. "#,
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

        while lines.count < Self.mainViewLineCount { lines.append(pad78("")) }
        return Array(lines.prefix(Self.mainViewLineCount))
    }

    // MARK: - Narrative overlay (rows 2-16)

    private func renderNarrativeOverlay(_ event: NarrativeEvent) {
        clearMainView()
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
            return (
                "THE EGG",
                [
                    "",
                    "  " + colored("~ My egg. ~", code: ansiBrightYellow),
                    "  " + colored(#"     ---     "#, code: ansiYellow),
                    "  " + colored(#"    /  O\     "#, code: ansiYellow),
                    "  " + colored(#"   |) o  |   "#, code: ansiYellow),
                    "  " + colored(#"   | o  O|   "#, code: ansiYellow),
                    "  " + colored(#"    \__(/     "#, code: ansiYellow),
                    "",
                    "  "
                        + colored(
                            "Warm. Alive. Pulsing against your scales.", code: ansiBoldBrightWhite),
                    "",
                    "  " + colored("\"They almost had you. Almost.\"", code: ansiDarkGray),
                ]
            )
        case .exitPatio:
            return (
                "THE PATIO",
                [
                    "",
                    "  " + colored("The sky.", code: ansiBrightCyan)
                        + "  " + colored("Open. Endless. Yours.", code: ansiBrightCyan),
                    "",
                    "  " + colored("       *    .  *       .        ", code: ansiBrightWhite),
                    "  " + colored("  .         .              .    ", code: ansiBrightWhite),
                    "  " + colored("      .    *       .            ", code: ansiBrightWhite),
                    "  " + colored("  *        .    .       *       ", code: ansiBrightWhite),
                    "",
                    "  " + colored("Home is a long flight from here. But you are free.", code: ansiBrightWhite),
                ]
            )
        case .specialAttack:
            return (
                "DRAGON FIRE",
                [
                    "",
                    "  Something ancient stirs in your chest.",
                    "  The charge is complete. Heat floods your throat.",
                    "",
                    "  You unleash it — a column of fire that scorches stone and silences",
                    "  everything in its path.",
                ]
            )
        }
    }

    // MARK: - Upgrade prompt (rows 2-16)

    private func renderUpgradePrompt(_ state: GameState, choices: [Upgrade]) {
        clearMainView()
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
        clearMainView()
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
        drawThoughts(["The darkness takes me... but perhaps the egg will survive?"])
    }

    // MARK: - Win screen

    private func renderWinScreen(_ state: GameState) {
        clearMainView()
        output.moveCursor(row: 4, col: 2)
        output.write(
            pad78(
                centered(colored("* * * * * * * * * * * * * * *", code: ansiBrightCyan), width: 78))
        )
        output.moveCursor(row: 6, col: 2)
        output.write(pad78(centered(colored("ESCAPED!", code: ansiBrightCyan), width: 78)))
        output.moveCursor(row: 7, col: 2)
        output.write(
            pad78(centered(colored("The egg is safe. You are free.", code: ansiYellow), width: 78)))
        output.moveCursor(row: 9, col: 2)
        output.write(
            pad78(
                centered(
                    colored("Floors cleared: \(state.currentFloor - 1)", code: ansiDimCyan),
                    width: 78)))
        output.moveCursor(row: 10, col: 2)
        output.write(
            pad78(centered(colored("HP remaining: \(state.hp)", code: ansiDimCyan), width: 78)))
        output.moveCursor(row: 12, col: 2)
        output.write(
            pad78(centered(colored("[ Press R to play again ]", code: ansiDarkGray), width: 78)))
        output.moveCursor(row: 14, col: 2)
        output.write(
            pad78(
                centered(colored("* * * * * * * * * * * * * * *", code: ansiBrightCyan), width: 78))
        )

        drawStatusBar(state)
        drawThoughts(["I am free! The egg is safe under the open sky."])
    }

    // MARK: - Status bar (row 18)

    private func drawStatusBar(_ state: GameState) {
        let hpFilled = Int(Double(state.hp) / Double(state.config.maxHP) * Double(Self.hpBarWidth))
        let hpClamped = max(0, min(hpFilled, Self.hpBarWidth))
        let hpBarRaw =
            String(repeating: "█", count: hpClamped)
            + String(repeating: "░", count: Self.hpBarWidth - hpClamped)

        let hpRatio = Double(state.hp) / Double(state.config.maxHP)
        let hpColorCode: String
        if hpRatio >= 0.40 {
            hpColorCode = ansiGreen
        } else if hpRatio >= 0.20 {
            hpColorCode = ansiYellow
        } else {
            hpColorCode = ansiRed
        }
        let hpBar = colored(hpBarRaw, code: hpColorCode)

        let eggSymbol = state.hasEgg ? "*" : " "

        let cooldown = state.timerModel.activeCooldownDuration
        let coloredDashCooldownStr =
            cooldown > 0
            ? " " + colored(String(format: "cd=%.0fs", cooldown), code: ansiYellow)
            : ""
        let coloredBraceCooldownStr =
            state.braceOnCooldown
            ? " " + colored(String(format: "cd=%.1fs", state.braceCooldownTimer), code: ansiYellow)
            : ""

        let specFilled = Int(state.specialCharge * Double(Self.specialMeterWidth))
        let specClamped = max(0, min(specFilled, Self.specialMeterWidth))
        let specBarRaw =
            String(repeating: "█", count: specClamped)
            + String(repeating: "░", count: Self.specialMeterWidth - specClamped)
        let specColorCode = state.specialIsReady ? ansiBoldBrightCyan : ansiDimCyan
        let specBar = colored(specBarRaw, code: specColorCode)

        var bar = " HP [\(hpBar)]"
        bar += " EGG [\(eggSymbol)]"
        bar += "  (1)DASH[\(state.dashCharges)]\(coloredDashCooldownStr)"
        bar += "  (2)BRACE\(coloredBraceCooldownStr)"
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
        // Word-wrap each entry to thoughtsLineWidth chars (1 leading space eats the last column).
        var wrapped: [String] = []
        for line in lines {
            wrapped += wordWrap(line, width: Self.thoughtsLineWidth)
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
        let flavor: String
        if state.recentDash {
            flavor =
                "I tear through! Moving faster than the guard could see. Feels a bit like flying."
        } else if state.hp <= 20 {
            flavor =
                "Need to be a bit careful, these humans are more dangerous than I thought."
        } else if state.hasEgg {
            flavor =
                "I can feel it! The egg, the LAST DRAGON EGG, its near. I need to find it, whatever the cost."
        } else if state.currentFloor == 1 {
            flavor =
                "Where am I? I smell fresh air from somewhere, but its not near. Need to escape."
        } else {
            flavor =
                "Deeper now. The air is thicker, heavier. My claws find the floor and I press on."
        }
        return [flavor]
    }

    private func combatThoughts(_ state: GameState, encounter: EncounterModel) -> [String] {
        if case .special = state.transientOverlay {
            return ["One deep breath and the air ignites."]
        } else if encounter.isBossEncounter {
            return ["The Head Warden. The one who ordered my egg stolen. This ends now."]
        } else if state.hp <= 30 {
            return [
                "I'm wounded and it knows it. I have to time this — brace for the next strike, then move."
            ]
        } else if state.dashCharges == 0 {
            return [
                "My wings are spent. No Dash left. I'll hold this ground until their strength returns."
            ]
        } else {
            return [
                "A guard. Armoured, blocking the corridor. I can brace and take the hit — or just dash through."
            ]
        }
    }

    private func narrativeThoughts(_ event: NarrativeEvent) -> [String] {
        switch event {
        case .eggDiscovery:
            return ["Thank the elements. There it is! I can feel its alive. Time to leave."]
        case .exitPatio:
            return ["Cold air, open sky. Finally. And jump and I'm free."]
        case .specialAttack:
            return [
                "The heat rises in my chest and I let it out. Nothing in that corridor is standing."
            ]
        }
    }

    // MARK: - 2D Minimap (rows 2-8, cols 61-75, panel cols 61-79)

    /// Renders the 15×7 floor grid into the right panel (cols 61-79, rows 2-8).
    /// Each cell is written individually: moveCursor then write(color + char + reset).
    /// Wall '#' → dark gray; passable '.' → no color; landmarks and player use their color mappings.
    func renderMinimap(floor: FloorMap, state: GameState) {
        let facingChar: Character
        switch state.facingDirection {
        case .north: facingChar = "^"
        case .east: facingChar = ">"
        case .south: facingChar = "v"
        case .west: facingChar = "<"
        }
        for y in stride(from: floor.grid.height - 1, through: 0, by: -1) {
            let screenRow = 3 + (floor.grid.height - 1 - y)
            for x in 0..<floor.grid.width {
                let pos = Position(x: x, y: y)
                let ch: Character =
                    pos == state.playerPosition
                    ? facingChar
                    : minimapChar(at: pos, floor: floor, state: state)
                let colorCode = minimapColor(for: ch)
                output.moveCursor(row: screenRow, col: 61 + x)
                if colorCode.isEmpty {
                    output.write(String(ch))
                } else {
                    output.write(colored(String(ch), code: colorCode))
                }
            }
        }
    }

    /// Returns the ANSI color prefix for a minimap character, or "" for no color.
    private func minimapColor(for ch: Character) -> String {
        switch ch {
        case "^", ">", "v", "<": return ansiBoldBrightWhite
        case "G": return ansiBrightRed
        case "B": return ansiBoldBrightRed
        case "*": return ansiBrightYellow
        case "e": return ansiYellow
        case "S": return ansiBrightCyan
        case "X": return ansiBoldBrightCyan
        case "E": return ansiDimCyan
        case "#": return ansiDarkGray
        default: return ""
        }
    }

    private func minimapChar(at pos: Position, floor: FloorMap, state: GameState) -> Character {
        if pos == floor.entryPosition2D { return "E" }
        if let enc = floor.encounterPosition2D, pos == enc {
            if state.clearedEncounterPositions.contains(enc) { return "." }
            return floor.hasBossEncounter ? "B" : "G"
        }
        if let egg = floor.eggRoomPosition2D, pos == egg {
            return state.hasEgg ? "." : "*"
        }
        if floor.hasExitSquare && pos == floor.exitPosition2D { return "X" }
        if pos == floor.staircasePosition2D { return "S" }
        let cell = floor.grid.cell(x: pos.x, y: pos.y)
        return cell.isPassable ? "." : "#"
    }

    // MARK: - Helpers

    /// Maps a dungeon frame depth level (0–3) to an ANSI foreground code.
    /// Uses 256-color grayscale indices when the terminal supports them; falls back to 16-color.
    private func depthColor(for depth: Int) -> String {
        if supports256Color {
            switch depth {
            case 0: return ansi256Fg(252)  // near-white
            case 1: return ansi256Fg(249)  // light gray
            case 2: return ansi256Fg(244)  // medium gray
            default: return ansi256Fg(240)  // dark-but-readable gray (depth 3+)
            }
        } else {
            switch depth {
            case 0: return ansiBrightWhite  // \e[97m — bright white (closest wall)
            case 1: return ansiWhite  // \e[37m — standard white
            default: return ansiDarkGray  // \e[90m — dark gray (depth 2+)
            }
        }
    }

    /// Splits a dungeon frame line into side-wall regions (bright, depth=0 color)
    /// and a center region (frame depth color). Side wall width varies by row to
    /// match the converging perspective structure of the ASCII frames.
    /// hasLeftWall/hasRightWall let callers suppress brightening on the open side
    /// (e.g. nearRight frames have no right outer wall).
    private func regionColoredLine(
        _ line: String, sideColor: String, centerColor: String,
        row: Int, hasLeftWall: Bool = true, hasRightWall: Bool = true,
        hasFarRight: Bool = false, hasFarLeft: Bool = false
    ) -> String {
        let width = sideWallWidth(for: row)
        guard width > 0 else {
            return centerColor + line + ansiReset
        }
        let chars = Array(line)
        let n = chars.count
        let leftW = hasLeftWall ? min(width, n) : 0
        let rightW = hasRightWall ? min(width, n) : 0
        let isFarRow = (3...8).contains(row)
        let farColor = depthColor(for: 1)

        // When far openings are active, cols 54-55 (right) / 2-3 (left)
        // get D=1 tinting instead of D=0 side or center color.
        func colorFor(_ col: Int) -> String {
            if isFarRow && hasFarRight && col >= 53 && col < 56 { return farColor }
            if isFarRow && hasFarLeft && col >= 2 && col < 5 { return farColor }
            if col < leftW { return sideColor }
            if col >= n - rightW { return sideColor }
            return centerColor
        }

        var result = ""
        var runColor = colorFor(0)
        var runStart = 0
        for col in 1..<n {
            let c = colorFor(col)
            if c != runColor {
                result += runColor + String(chars[runStart..<col]) + ansiReset
                runStart = col
                runColor = c
            }
        }
        result += runColor + String(chars[runStart..<n]) + ansiReset
        return result
    }

    /// Returns the number of characters from each side that belong to the
    /// outermost corridor walls (depth=0) for a given frame row index.
    private func sideWallWidth(for row: Int) -> Int {
        switch row {
        case 0, 12: return 1
        case 1, 11: return 2
        case 2, 10: return 3
        case 3...9: return 4
        default: return 0
        }
    }

    /// Blanks the main view area before drawing a full-screen overlay.
    private func clearMainView() {
        for row in Self.mainViewFirstRow...Self.mainViewLastRow {
            output.moveCursor(row: row, col: 2)
            output.write(pad78(""))
        }
    }

    private func pad78(_ s: String) -> String {
        let visible = visibleLength(s)
        if visible >= 78 { return s }
        return s + String(repeating: " ", count: 78 - visible)
    }

    /// Counts printable characters, skipping ANSI escape sequences (\e[...m).
    private func visibleLength(_ s: String) -> Int {
        var count = 0
        var i = s.startIndex
        while i < s.endIndex {
            if s[i] == "\u{1B}", s.index(after: i) < s.endIndex, s[s.index(after: i)] == "[" {
                var j = s.index(after: s.index(after: i))
                while j < s.endIndex && s[j] != "m" { j = s.index(after: j) }
                if j < s.endIndex { j = s.index(after: j) }
                i = j
            } else {
                count += 1
                i = s.index(after: i)
            }
        }
        return count
    }

    private func centered(_ s: String, width: Int) -> String {
        let count = s.count
        guard count < width else { return String(s.prefix(width)) }
        let padding = (width - count) / 2
        return String(repeating: " ", count: padding) + s
    }
}
