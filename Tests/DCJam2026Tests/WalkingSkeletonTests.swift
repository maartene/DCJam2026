import Testing
@testable import GameDomain

// Walking Skeleton — US-01 + US-02 + US-04 + US-11
//
// These tests trace the thinnest end-to-end slice that proves the core loop:
//   Player spawns on Floor 1 → encounters one guard → Dashes through →
//   reaches stairs → descends → can die when HP reaches 0.
//
// Mandate compliance:
//   CM-A: All tests invoke GameDomain (driving port) directly — GameState, RulesEngine
//   CM-B: Test names and comments use game domain terms only (Ember, Dash, Floor, egg).
//   CM-C: Each test validates an observable player outcome, not an internal side effect.

@Suite struct `Walking Skeleton — Core Loop` {

    // MARK: - Ember spawns on Floor 1 with full readiness

    @Test func `Ember's HP is full when a new run begins`() {
        // Given
        let config = GameConfig.default
        // When
        let state = GameState.initial(config: config)
        // Then
        #expect(state.hp == config.maxHP)
    }

    @Test func `Ember has exactly 2 Dash charges when a new run begins`() {
        // Given
        let config = GameConfig.default
        // When
        let state = GameState.initial(config: config)
        // Then
        #expect(state.dashCharges == 2)
    }

    @Test func `Ember's Special charge is 0 when a new run begins`() {
        // Given
        let config = GameConfig.default
        // When
        let state = GameState.initial(config: config)
        // Then
        #expect(state.specialCharge == 0.0)
    }

    @Test func `Ember does not carry the egg when a new run begins`() {
        // Given
        let config = GameConfig.default
        // When
        let state = GameState.initial(config: config)
        // Then
        #expect(state.hasEgg == false)
    }

    @Test func `Ember begins on Floor 1 when a new run begins`() {
        // Given
        let config = GameConfig.default
        // When
        let state = GameState.initial(config: config)
        // Then
        #expect(state.currentFloor == 1)
    }

    // MARK: - Ember passes through a guard using Dash

    @Test func `Ember's position advances 2 squares after a successful Dash through a guard`() {
        // Given — Ember on Floor 1, 1 Dash charge, in encounter with regular enemy
        let config = GameConfig.default
        var state = GameState.initial(config: config)
        let startPosition = state.playerPosition
        state = stateWithActiveEncounter(state, isBoss: false)
        // When
        let result = RulesEngine.apply(command: .dash, to: state, deltaTime: 0.0)
        // Then
        #expect(result.playerPosition == startPosition + 2)
    }

    @Test func `Ember's Dash charge count decrements by 1 after a successful Dash`() {
        // Given
        let config = GameConfig.default
        var state = GameState.initial(config: config)
        let chargesBefore = state.dashCharges
        state = stateWithActiveEncounter(state, isBoss: false)
        // When
        let result = RulesEngine.apply(command: .dash, to: state, deltaTime: 0.0)
        // Then
        #expect(result.dashCharges == chargesBefore - 1)
    }

    @Test func `The encounter ends after Ember uses Dash`() {
        // Given
        let config = GameConfig.default
        var state = GameState.initial(config: config)
        state = stateWithActiveEncounter(state, isBoss: false)
        // When
        let result = RulesEngine.apply(command: .dash, to: state, deltaTime: 0.0)
        // Then — screen mode returns to dungeon navigation
        if case .dungeon = result.screenMode {
            // expected
        } else {
            Issue.record("Expected screen mode .dungeon after Dash, got \(result.screenMode)")
        }
    }

    @Test func `Normal movement is unavailable when Ember is in an active encounter`() {
        // Given
        let config = GameConfig.default
        var state = GameState.initial(config: config)
        state = stateWithActiveEncounter(state, isBoss: false)
        // When — attempt to move forward without Dash
        let result = RulesEngine.apply(command: .move(.forward), to: state, deltaTime: 0.0)
        // Then — player position does not change; encounter persists
        #expect(result.playerPosition == state.playerPosition)
        if case .combat = result.screenMode {
            // expected — encounter still active
        } else {
            Issue.record("Expected .combat screen mode after blocked move, got \(result.screenMode)")
        }
    }

    // MARK: - Ember descends stairs to the next floor

    @Test func `The floor counter increments when Ember steps onto the stairs`() {
        // Given — Ember on Floor 1, at the staircase position
        let config = GameConfig.default
        var state = GameState.initial(config: config)
        state = stateAtStaircase(state)
        let floorBefore = state.currentFloor
        // When
        let result = RulesEngine.apply(command: .move(.forward), to: state, deltaTime: 0.0)
        // Then
        #expect(result.currentFloor == floorBefore + 1)
    }

    @Test func `Ember's position resets to the Floor 2 entry point after descending`() {
        // Given
        let config = GameConfig.default
        var state = GameState.initial(config: config)
        state = stateAtStaircase(state)
        // When
        let result = RulesEngine.apply(command: .move(.forward), to: state, deltaTime: 0.0)
        // Then
        let floor2 = FloorRegistry.floor(2, config: config)
        #expect(result.playerPosition == floor2.entryPosition)
    }

    // MARK: - Ember dies when HP reaches 0

    @Test func `The death screen appears when Ember's HP drops to 0`() {
        // Given — Ember at 1 HP in encounter
        let config = GameConfig.default
        var state = GameState.initial(config: config)
        state = stateWithHP(state, hp: 1)
        state = stateWithActiveEncounter(state, isBoss: false)
        // When — advance time past the enemy attack interval (unbraced → takes full hit)
        let result = RulesEngine.apply(command: .none, to: state, deltaTime: config.enemyAttackInterval + 0.1)
        // Then
        if case .deathState = result.screenMode {
            // expected
        } else {
            Issue.record("Expected .deathState when HP drops to 0, got \(result.screenMode)")
        }
    }

    @Test func `HP display does not show a negative value when damage exceeds remaining HP`() {
        // Given — Ember at 1 HP, fatal blow incoming (unbraced)
        let config = GameConfig.default
        var state = GameState.initial(config: config)
        state = stateWithHP(state, hp: 1)
        state = stateWithActiveEncounter(state, isBoss: false)
        // When — advance time past the enemy attack interval
        let result = RulesEngine.apply(command: .none, to: state, deltaTime: config.enemyAttackInterval + 0.1)
        // Then — HP floored at 0, never negative
        #expect(result.hp >= 0)
    }
}

// MARK: - Test Setup Helpers (business intent, not wiring)

private extension `Walking Skeleton — Core Loop` {

    func stateWithActiveEncounter(_ state: GameState, isBoss: Bool) -> GameState {
        let encounter = EncounterModel.guard(isBossEncounter: isBoss)
        return state.withScreenMode(.combat(encounter: encounter))
    }

    func stateAtStaircase(_ state: GameState) -> GameState {
        let floor = FloorRegistry.floor(state.currentFloor, config: GameConfig.default)
        return state.withPlayerPosition(floor.staircasePosition)
    }

    func stateWithHP(_ state: GameState, hp: Int) -> GameState {
        state.withHP(hp)
    }
}
