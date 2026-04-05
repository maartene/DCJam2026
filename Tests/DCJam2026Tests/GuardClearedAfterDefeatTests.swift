import Testing
@testable import DCJam2026
@testable import GameDomain

// Acceptance Tests — US-GPF-01: Guard Cleared After Defeat
//
// Driving port: RulesEngine.apply(command:to:deltaTime:) and GameState (GameDomain module).
//               Renderer(output:) via TUIOutputSpy for minimap rendering assertions.
//
// Walking skeleton: the simplest observable user outcome — Ember defeats a guard
// via Special and walks back through that cell without re-triggering combat.
//
// Story: When Ember's fire breath (Special) brings a guard's HP to 0, the cell is
// marked cleared. Walking into a cleared cell costs no health and starts no fight.
// Dashing past a guard does NOT clear the cell — the guard was bypassed, not defeated.
//
// Error path ratio: 5 of 11 scenarios = 45% (exceeds 40% mandate).
//
// Mandate compliance:
//   CM-A: All tests invoke GameDomain driving port (RulesEngine, GameState) directly.
//         Renderer tests use Renderer(output: TUIOutputSpy()) — the rendering driving port.
//   CM-B: All names and comments use game domain terms (Ember, guard, Dash, cleared cell).
//         Zero technical terms (no "Set<Position>", no "clearedEncounterPositions").
//   CM-C: Each test validates an observable player outcome (can Ember pass freely? does
//         the minimap show "."?), not an internal data structure.

@Suite struct `Guard Cleared After Defeat — Walking Skeleton` {

    // -------------------------------------------------------------------------
    // WALKING SKELETON — the thinnest slice with observable user value:
    // Ember defeats a guard and walks back through the cell freely.
    // -------------------------------------------------------------------------

    @Test func `Ember can walk into a previously defeated guard cell without entering combat`() {
        // Given — Ember has defeated the guard at the encounter cell on floor 1
        let config = GameConfig.default
        let floor = FloorRegistry.floor(1, config: config)
        var state = GameState.initial(config: config)
            .withPlayerPosition(floor.encounterPosition2D!)
            .withScreenMode(.dungeon)
        // Place Ember at the encounter position and fire Special (full charge) to defeat the guard
        state = state
            .withScreenMode(.combat(encounter: EncounterModel.guard(isBossEncounter: false)))
            .withSpecialCharge(1.0)
        let afterDefeat = RulesEngine.apply(command: .special, to: state, deltaTime: 0.0)
        // Guard is now defeated — Ember should be back in dungeon mode
        guard case .dungeon = afterDefeat.screenMode else {
            Issue.record("Expected dungeon mode after defeating the guard with Special, got \(afterDefeat.screenMode)")
            return
        }
        // Position Ember one cell south of the encounter cell, facing north toward it
        let cellAhead = floor.encounterPosition2D!
        let startPosition = Position(x: cellAhead.x, y: cellAhead.y - 1)
        let positioned = afterDefeat.withPlayerPosition(startPosition).withFacingDirection(.north)
        // When — Ember walks forward into the cleared cell
        let result = RulesEngine.apply(command: .move(.forward), to: positioned, deltaTime: 0.0)
        // Then — no combat; Ember moved through freely
        if case .combat = result.screenMode {
            Issue.record("Ember should not enter combat when walking into a cleared guard cell")
        }
        #expect(result.playerPosition == cellAhead, "Ember's position should advance into the cleared cell")
    }
}

// -------------------------------------------------------------------------
// Focused scenarios — US-GPF-01 happy paths
// -------------------------------------------------------------------------

@Suite struct `Guard Cleared After Defeat — Happy Paths` {

    // GPF-01-H1: Minimap shows "." for a defeated guard cell
    @Test func `Minimap shows a corridor symbol at the guard cell after the guard is defeated`() throws {
        // Given — guard defeated on floor 1
        let config = GameConfig.default
        let floor = FloorRegistry.floor(1, config: config)
        let encounterPos = floor.encounterPosition2D!
        var state = GameState.initial(config: config)
            .withScreenMode(.combat(encounter: EncounterModel.guard(isBossEncounter: false)))
            .withSpecialCharge(1.0)
        let afterDefeat = RulesEngine.apply(command: .special, to: state, deltaTime: 0.0)
        guard case .dungeon = afterDefeat.screenMode else {
            Issue.record("Expected dungeon mode after guard defeat")
            return
        }
        // When — minimap renders
        let spy = TUIOutputSpy()
        Renderer(output: spy).render(afterDefeat)
        // Then — the encounter cell renders as "." (corridor), not "G"
        let targetRow = 3 + (6 - encounterPos.y)
        let targetCol = 61 + encounterPos.x
        let cellWrites = spy.entries.filter { $0.row == targetRow && $0.col == targetCol }
        let allText = cellWrites.map(\.string).joined()
        let stripped = stripANSI(allText)
        #expect(stripped.contains("."), "Cleared guard cell must show '.' on minimap, got: \(stripped)")
        #expect(!stripped.contains("G"), "Cleared guard cell must NOT show 'G' on minimap, got: \(stripped)")
    }

    // GPF-01-H2: Boss cell shows "." on minimap after boss is defeated
    @Test func `Minimap shows a corridor symbol at the boss cell after the boss is defeated`() {
        // Given — Ember on floor 5, boss defeated via Special
        let config = GameConfig.default
        let finalFloor = config.maxFloors
        let floor = FloorRegistry.floor(finalFloor, config: config)
        let bossPos = floor.encounterPosition2D!
        // Pre-weaken the boss to 40 HP so one Special (60 damage) defeats it in one hit
        let weakBoss = EncounterModel(isBossEncounter: true, enemyHP: 40, enemyAttackTimer: GameConfig.default.enemyAttackInterval)
        let state = GameState.initial(config: config)
            .withCurrentFloor(finalFloor)
            .withScreenMode(.combat(encounter: weakBoss))
            .withSpecialCharge(1.0)
        let afterDefeat = RulesEngine.apply(command: .special, to: state, deltaTime: 0.0)
        guard case .dungeon = afterDefeat.screenMode else {
            Issue.record("Expected dungeon mode after boss defeat")
            return
        }
        // When — minimap renders
        let spy = TUIOutputSpy()
        Renderer(output: spy).render(afterDefeat)
        // Then — boss cell shows "." not "B"
        let targetRow = 3 + (6 - bossPos.y)
        let targetCol = 61 + bossPos.x
        let cellWrites = spy.entries.filter { $0.row == targetRow && $0.col == targetCol }
        let allText = cellWrites.map(\.string).joined()
        let stripped = stripANSI(allText)
        #expect(stripped.contains("."), "Cleared boss cell must show '.' on minimap, got: \(stripped)")
        #expect(!stripped.contains("B"), "Cleared boss cell must NOT show 'B' on minimap, got: \(stripped)")
    }

    // GPF-01-H3: Walking into cleared cell keeps Ember in dungeon mode
    @Test func `Walking into a cleared guard cell keeps Ember in dungeon navigation mode`() {
        // Given — guard cell cleared
        let config = GameConfig.default
        let floor = FloorRegistry.floor(1, config: config)
        let encounterPos = floor.encounterPosition2D!
        var state = GameState.initial(config: config)
            .withScreenMode(.combat(encounter: EncounterModel.guard(isBossEncounter: false)))
            .withSpecialCharge(1.0)
        let afterDefeat = RulesEngine.apply(command: .special, to: state, deltaTime: 0.0)
        guard case .dungeon = afterDefeat.screenMode else {
            Issue.record("Expected dungeon mode after guard defeat")
            return
        }
        let startPos = Position(x: encounterPos.x, y: encounterPos.y - 1)
        let positioned = afterDefeat.withPlayerPosition(startPos).withFacingDirection(.north)
        // When — Ember walks forward
        let result = RulesEngine.apply(command: .move(.forward), to: positioned, deltaTime: 0.0)
        // Then — dungeon mode throughout
        if case .combat = result.screenMode {
            Issue.record("Expected dungeon navigation mode after walking into cleared cell, got combat")
        }
        if case .dungeon = result.screenMode { /* expected */ }
    }

    // GPF-01-H4: Cleared state resets when Ember descends to the next floor
    @Test func `Guard cleared on floor 1 does not affect the guard on floor 2`() {
        // Given — Ember cleared the guard on floor 1 and descends
        let config = GameConfig.default
        var state = GameState.initial(config: config)
            .withScreenMode(.combat(encounter: EncounterModel.guard(isBossEncounter: false)))
            .withSpecialCharge(1.0)
        let afterDefeat = RulesEngine.apply(command: .special, to: state, deltaTime: 0.0)
        guard case .dungeon = afterDefeat.screenMode else {
            Issue.record("Expected dungeon mode after guard defeat")
            return
        }
        // Move Ember to the staircase on floor 1
        let floor1 = FloorRegistry.floor(1, config: config)
        let atStairs = afterDefeat.withPlayerPosition(floor1.staircasePosition).withFacingDirection(.north)
        let onFloor2 = RulesEngine.apply(command: .move(.forward), to: atStairs, deltaTime: 0.0)
        #expect(onFloor2.currentFloor == 2, "Expected Ember to be on floor 2 after descending")
        // When — Ember walks into the encounter position on floor 2
        let floor2 = FloorRegistry.floor(2, config: config)
        let approaching = onFloor2
            .withPlayerPosition(Position(x: floor2.encounterPosition2D!.x, y: floor2.encounterPosition2D!.y - 1))
            .withFacingDirection(.north)
        let result = RulesEngine.apply(command: .move(.forward), to: approaching, deltaTime: 0.0)
        // Then — combat triggers on floor 2 (cleared state from floor 1 was reset)
        if case .combat = result.screenMode { /* expected — fresh guard on floor 2 */ }
        else {
            Issue.record("Expected combat on floor 2 — cleared state from floor 1 must not carry over")
        }
    }
}

// -------------------------------------------------------------------------
// Focused scenarios — US-GPF-01 error and boundary paths
// -------------------------------------------------------------------------

@Suite struct `Guard Cleared After Defeat — Error and Boundary Paths` {

    // GPF-01-E1: Dash bypasses guard but does NOT clear the cell (critical negative test)
    @Test func `Dashing past a guard leaves the guard on the minimap — guard cell was not cleared`() {
        // Given — Ember enters a guard encounter and uses Dash to escape
        let config = GameConfig.default
        let floor = FloorRegistry.floor(1, config: config)
        let encounterPos = floor.encounterPosition2D!
        var state = GameState.initial(config: config)
        state = state.withPlayerPosition(Position(x: encounterPos.x, y: encounterPos.y - 1))
        state = state.withScreenMode(.combat(encounter: EncounterModel.guard(isBossEncounter: false)))
        // When — Ember Dashes (bypasses guard, does not defeat it)
        let afterDash = RulesEngine.apply(command: .dash, to: state, deltaTime: 0.0)
        guard case .dungeon = afterDash.screenMode else {
            Issue.record("Expected dungeon mode after Dash")
            return
        }
        // Then — minimap still shows "G" at the encounter cell (guard not cleared)
        let spy = TUIOutputSpy()
        Renderer(output: spy).render(afterDash)
        let targetRow = 3 + (6 - encounterPos.y)
        let targetCol = 61 + encounterPos.x
        let cellWrites = spy.entries.filter { $0.row == targetRow && $0.col == targetCol }
        let allText = cellWrites.map(\.string).joined()
        let stripped = stripANSI(allText)
        #expect(stripped.contains("G"), "Guard cell must still show 'G' after a Dash — Dash does not clear the guard, got: \(stripped)")
        #expect(!stripped.contains("."), "Guard cell must NOT show '.' after Dash — guard was bypassed not defeated, got: \(stripped)")
    }

    // GPF-01-E2: Walking into an uncleared guard cell still triggers combat
    @Test func `Walking into an undefeated guard cell triggers combat`() {
        // Given — Ember has not fought the guard; the cell is uncleared
        let config = GameConfig.default
        let floor = FloorRegistry.floor(1, config: config)
        let encounterPos = floor.encounterPosition2D!
        let state = GameState.initial(config: config)
            .withPlayerPosition(Position(x: encounterPos.x, y: encounterPos.y - 1))
            .withFacingDirection(.north)
            .withScreenMode(.dungeon)
        // When — Ember walks into the guard cell
        let result = RulesEngine.apply(command: .move(.forward), to: state, deltaTime: 0.0)
        // Then — combat begins
        if case .combat = result.screenMode { /* expected */ }
        else {
            Issue.record("Expected combat when Ember walks into an undefeated guard cell, got \(result.screenMode)")
        }
    }

    // GPF-01-E3: Returning to a Dashed-past cell from the other side still triggers combat
    @Test func `Returning to a guard cell Dashed past triggers combat again`() {
        // Given — Ember Dashed past the guard (guard bypassed, not defeated)
        let config = GameConfig.default
        let floor = FloorRegistry.floor(1, config: config)
        let encounterPos = floor.encounterPosition2D!
        var state = GameState.initial(config: config)
        state = state.withScreenMode(.combat(encounter: EncounterModel.guard(isBossEncounter: false)))
        let afterDash = RulesEngine.apply(command: .dash, to: state, deltaTime: 0.0)
        // Ember is now past the guard; approach the encounter cell from the north
        let approachFromNorth = afterDash
            .withPlayerPosition(Position(x: encounterPos.x, y: encounterPos.y + 1))
            .withFacingDirection(.south)
        // When — Ember walks south into the guard cell
        let result = RulesEngine.apply(command: .move(.forward), to: approachFromNorth, deltaTime: 0.0)
        // Then — combat triggers again (guard was not defeated by Dash)
        if case .combat = result.screenMode { /* expected */ }
        else {
            Issue.record("Expected combat when returning to a guard cell only Dashed past, got \(result.screenMode)")
        }
    }

    // GPF-01-E4: Game restart resets all cleared encounter state
    @Test func `A fresh run starts with no cleared guard cells — every guard is present on the minimap`() {
        // Given — start a completely fresh run
        let config = GameConfig.default
        let state = GameState.initial(config: config).withScreenMode(.dungeon)
        // When — minimap renders on floor 1
        let spy = TUIOutputSpy()
        Renderer(output: spy).render(state)
        // Then — the guard cell shows "G", not "."
        let floor = FloorRegistry.floor(1, config: config)
        let encounterPos = floor.encounterPosition2D!
        let targetRow = 3 + (6 - encounterPos.y)
        let targetCol = 61 + encounterPos.x
        let cellWrites = spy.entries.filter { $0.row == targetRow && $0.col == targetCol }
        let allText = cellWrites.map(\.string).joined()
        let stripped = stripANSI(allText)
        #expect(stripped.contains("G"), "Fresh run must show 'G' at guard cell — no cleared state carries over, got: \(stripped)")
    }

    // GPF-01-E5: Attempting to walk into a cleared boss cell does not trigger combat
    @Test func `Walking into a cleared boss cell does not trigger a second boss fight`() {
        // Given — Ember has defeated the boss on floor 5
        let config = GameConfig.default
        let finalFloor = config.maxFloors
        let floor = FloorRegistry.floor(finalFloor, config: config)
        // Pre-weaken the boss to 40 HP so one Special (60 damage) defeats it in one hit
        let weakBoss = EncounterModel(isBossEncounter: true, enemyHP: 40, enemyAttackTimer: GameConfig.default.enemyAttackInterval)
        let state = GameState.initial(config: config)
            .withCurrentFloor(finalFloor)
            .withScreenMode(.combat(encounter: weakBoss))
            .withSpecialCharge(1.0)
        let afterDefeat = RulesEngine.apply(command: .special, to: state, deltaTime: 0.0)
        guard case .dungeon = afterDefeat.screenMode else {
            Issue.record("Expected dungeon mode after boss defeat")
            return
        }
        // Position Ember one cell south of boss, facing north
        let bossPos = floor.encounterPosition2D!
        let positioned = afterDefeat
            .withPlayerPosition(Position(x: bossPos.x, y: bossPos.y - 1))
            .withFacingDirection(.north)
        // When — Ember walks into the cleared boss cell
        let result = RulesEngine.apply(command: .move(.forward), to: positioned, deltaTime: 0.0)
        // Then — no second boss fight
        if case .combat = result.screenMode {
            Issue.record("A second boss fight must not start when walking into a cleared boss cell")
        }
    }
}

