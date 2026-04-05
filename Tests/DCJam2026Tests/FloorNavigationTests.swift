import Testing
@testable import GameDomain

// Floor Navigation Tests — US-04 (floor structure and descent)
//
// Covers: Floor 1 has no egg room, Floor 5 has boss + exit and no egg room,
// staircase descent blocked on egg floor without egg,
// staircase descent allowed when egg is collected,
// staircase descent allowed on non-egg floors.
//
// Tests now drive through FloorRegistry (handcrafted maps) — the sole source of
// floor maps after FloorGenerator was removed (Mikado: remove-floor-generator).
//
// Error / edge paths: 3 of 6 = 50%

@Suite struct `Floor Navigation and Structure` {

    // MARK: - Floor landmark constraints (handcrafted map)

    @Test func `Floor 1 contains no egg room`() {
        // Given
        let config = GameConfig.default
        // When
        let floor1 = FloorRegistry.floor(1, config: config)
        // Then
        #expect(floor1.hasEggRoom == false)
    }

    @Test func `Floor 5 contains the boss encounter and the exit square`() {
        // Given — 5-floor config
        let config = GameConfig.default
        // When
        let floor5 = FloorRegistry.floor(5, config: config)
        // Then
        #expect(floor5.hasBossEncounter == true)
        #expect(floor5.hasExitSquare == true)
    }

    @Test func `Floor 5 contains no egg room`() {
        // Given
        let config = GameConfig.default
        // When
        let floor5 = FloorRegistry.floor(5, config: config)
        // Then
        #expect(floor5.hasEggRoom == false)
    }

    // MARK: - Floor descent places Ember at next floor entry (integration)

    @Test func `Ember is placed at the entry point of the new floor after descending`() {
        // Given
        let config = GameConfig.default
        var state = GameState.initial(config: config)
        let floor1 = FloorRegistry.floor(1, config: config)
        state = state.withPlayerPosition(floor1.staircasePosition)
        // When
        let result = RulesEngine.apply(command: .move(.forward), to: state, deltaTime: 0.0)
        // Then
        let floor2 = FloorRegistry.floor(2, config: config)
        #expect(result.playerPosition == floor2.entryPosition)
        #expect(result.currentFloor == 2)
    }

    // MARK: - Staircase descent blocked on egg floor without egg

    // Test Budget: 3 behaviors x 2 = 6 max; using 3 tests.

    @Test func `Staircase descent blocked on egg floor when egg not collected`() {
        // Given — 3-floor run: floor 2 is the egg floor (registry map has egg room)
        let config = GameConfig.withFloorCount(3)
        let floor2 = FloorRegistry.floor(2, config: config)
        var state = GameState.initial(config: config)
        state = state
            .withCurrentFloor(2)
            .withPlayerPosition(floor2.staircasePosition2D)
        // hasEgg defaults to false in GameState.initial
        // When — attempt descent without egg
        let result = RulesEngine.apply(command: .move(.forward), to: state, deltaTime: 0.0)
        // Then — player remains at staircase, floor unchanged
        #expect(result.currentFloor == 2)
        #expect(result.playerPosition == floor2.staircasePosition2D)
    }

    @Test func `Staircase descent proceeds on egg floor when egg is collected`() {
        // Given — 3-floor run: floor 2 is the egg floor (registry map), player has egg
        let config = GameConfig.withFloorCount(3)
        let floor2 = FloorRegistry.floor(2, config: config)
        let floor3 = FloorRegistry.floor(3, config: config)
        var state = GameState.initial(config: config)
        state = state
            .withCurrentFloor(2)
            .withPlayerPosition(floor2.staircasePosition2D)
            .withHasEgg(true)
        // When — descend with egg
        let result = RulesEngine.apply(command: .move(.forward), to: state, deltaTime: 0.0)
        // Then — player advances to floor 3 entry
        #expect(result.currentFloor == 3)
        #expect(result.playerPosition == floor3.entryPosition)
    }

    @Test func `Staircase descent proceeds on non-egg floor even without egg`() {
        // Given — 3-floor run: floor 1 has no egg room, player has no egg
        let config = GameConfig.withFloorCount(3)
        let floor1 = FloorRegistry.floor(1, config: config)
        let floor2 = FloorRegistry.floor(2, config: config)
        var state = GameState.initial(config: config)
        state = state.withPlayerPosition(floor1.staircasePosition2D)
        // hasEgg defaults to false
        // When — descend from non-egg floor
        let result = RulesEngine.apply(command: .move(.forward), to: state, deltaTime: 0.0)
        // Then — player advances to floor 2 entry
        #expect(result.currentFloor == 2)
        #expect(result.playerPosition == floor2.entryPosition)
    }
}
