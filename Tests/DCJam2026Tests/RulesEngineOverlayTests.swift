import Testing
@testable import GameDomain

// RulesEngine: startScreen transition and transient overlay lifecycle — step 02-03
//
// Test Budget: 8 distinct behaviors x 2 = 16 max unit tests (8 used)
// Behaviors:
//   1. startScreen + non-quit command → screenMode == .dungeon
//   2. successful parry → transientOverlay == .braceSuccess(framesRemaining: 23)
//   3. unbraced non-fatal hit → transientOverlay == .braceHit(framesRemaining: 23)
//   4. fatal hit → transientOverlay == nil AND screenMode == .deathState
//   5. advanceTimers decrements framesRemaining by 1 each tick
//   6. advanceTimers sets transientOverlay to nil when framesRemaining reaches 0
//   7. successful dash → transientOverlay == .dash(framesRemaining: 23)
//   8. startScreen → timers not advanced (game paused)

@Suite struct `RulesEngine overlay lifecycle` {

    // MARK: - AC1: startScreen transitions to dungeon on any non-quit command

    @Test func `any non-quit command on startScreen transitions screenMode to dungeon`() {
        // Given — initial state, which starts on .startScreen
        let state = GameState.initial(config: .default)
        // When — send confirmOverlay (a non-quit, non-movement command)
        let result = RulesEngine.apply(command: .confirmOverlay, to: state, deltaTime: 0.0)
        // Then
        if case .dungeon = result.screenMode {
            // correct
        } else {
            Issue.record("Expected screenMode .dungeon after confirmOverlay on startScreen, got \(result.screenMode)")
        }
    }

    // MARK: - AC2: successful parry sets .braceSuccess(framesRemaining: 23)

    @Test func `a successful Brace parry sets transientOverlay to braceSuccess with default duration`() {
        // Given — regular encounter, Ember braces, enemy attack is imminent
        let config = GameConfig.default
        var state = GameState.initial(config: config)
        let encounter = EncounterModel.guard(isBossEncounter: false)
        state = state.withScreenMode(.combat(encounter: encounter))
        // Activate brace window
        let afterBrace = RulesEngine.apply(command: .brace, to: state, deltaTime: 0.0)
        // When — advance past attack interval so enemy fires during brace window
        let result = RulesEngine.apply(
            command: .none, to: afterBrace,
            deltaTime: config.enemyAttackInterval + 0.1
        )
        // Then
        #expect(result.transientOverlay == .braceSuccess(framesRemaining: 23))
    }

    // MARK: - AC3: unbraced non-fatal hit sets .braceHit(framesRemaining: 23)

    @Test func `an unbraced hit that does not kill sets transientOverlay to braceHit with default duration`() {
        // Given — regular encounter, Ember at high HP (no brace)
        let config = GameConfig.default
        var state = GameState.initial(config: config)
        let encounter = EncounterModel.guard(isBossEncounter: false)
        state = state.withScreenMode(.combat(encounter: encounter))
        // Ensure HP is high enough that the hit is not fatal
        state = state.withHP(config.maxHP)
        // When — advance past attack interval, no brace
        let result = RulesEngine.apply(
            command: .none, to: state,
            deltaTime: config.enemyAttackInterval + 0.1
        )
        // Then — not dead, so braceHit overlay
        #expect(result.transientOverlay == .braceHit(framesRemaining: 23))
    }

    // MARK: - AC4: fatal hit sets transientOverlay = nil and screenMode = .deathState

    @Test func `a fatal unbraced hit sets transientOverlay to nil and screenMode to deathState`() {
        // Given — regular encounter, Ember at 1 HP (next hit is fatal)
        let config = GameConfig.default
        var state = GameState.initial(config: config)
        let encounter = EncounterModel.guard(isBossEncounter: false)
        state = state.withScreenMode(.combat(encounter: encounter))
        state = state.withHP(1)
        // When — advance past attack interval, no brace
        let result = RulesEngine.apply(
            command: .none, to: state,
            deltaTime: config.enemyAttackInterval + 0.1
        )
        // Then
        #expect(result.transientOverlay == nil)
        if case .deathState = result.screenMode {
            // correct
        } else {
            Issue.record("Expected .deathState on fatal hit, got \(result.screenMode)")
        }
    }

    // MARK: - AC5: advanceTimers decrements framesRemaining by 1 each tick

    @Test func `advanceTimers decrements framesRemaining by 1 per tick`() {
        // Given — state with braceSuccess overlay at 5 frames remaining
        var state = GameState.initial(config: .default)
        state = state.withScreenMode(.dungeon)
        state = state.withTransientOverlay(.braceSuccess(framesRemaining: 5))
        // When — one tick (deltaTime > 0 to trigger advanceTimers)
        let result = RulesEngine.apply(command: .none, to: state, deltaTime: 0.016)
        // Then
        #expect(result.transientOverlay == .braceSuccess(framesRemaining: 4))
    }

    // MARK: - AC6: advanceTimers sets transientOverlay to nil when framesRemaining reaches 0

    @Test func `advanceTimers clears transientOverlay when framesRemaining reaches 0`() {
        // Given — state with braceSuccess overlay at 1 frame remaining
        var state = GameState.initial(config: .default)
        state = state.withScreenMode(.dungeon)
        state = state.withTransientOverlay(.braceSuccess(framesRemaining: 1))
        // When — one tick
        let result = RulesEngine.apply(command: .none, to: state, deltaTime: 0.016)
        // Then
        #expect(result.transientOverlay == nil)
    }

    // MARK: - AC7: successful dash sets .dash(framesRemaining: 23)

    @Test func `a successful Dash sets transientOverlay to dash with default duration`() {
        // Given — regular encounter with dash charges available
        var state = GameState.initial(config: .default)
        let encounter = EncounterModel.guard(isBossEncounter: false)
        state = state.withScreenMode(.combat(encounter: encounter))
        state = state.withDashCharges(2)
        // When
        let result = RulesEngine.apply(command: .dash, to: state, deltaTime: 0.0)
        // Then
        #expect(result.transientOverlay == .dash(framesRemaining: 23))
    }

    // MARK: - AC9: firing special sets .special(framesRemaining: 23)

    @Test func `firing special sets transientOverlay to special with default duration`() {
        // Given — combat encounter with special ready
        let config = GameConfig.default
        var state = GameState.initial(config: config)
        let encounter = EncounterModel.guard(isBossEncounter: false)
        state = state.withScreenMode(.combat(encounter: encounter))
        state = state.withSpecialCharge(1.0)
        // When
        let result = RulesEngine.apply(command: .special, to: state, deltaTime: 0.0)
        // Then
        #expect(result.transientOverlay == .special(framesRemaining: 23))
    }

    // MARK: - AC8: startScreen pauses timer advancement

    @Test func `timers are not advanced when screenMode is startScreen`() {
        // Given — state on startScreen with a transient overlay set
        var state = GameState.initial(config: .default)
        // Initial state is already .startScreen; inject an overlay to observe if it is decremented
        state = state.withTransientOverlay(.braceSuccess(framesRemaining: 5))
        // When — tick with positive deltaTime
        let result = RulesEngine.apply(command: .none, to: state, deltaTime: 0.016)
        // Then — overlay unchanged because timers are paused on startScreen
        #expect(result.transientOverlay == .braceSuccess(framesRemaining: 5))
    }
}
