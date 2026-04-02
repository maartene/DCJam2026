import Testing
@testable import GameDomain

// Floor Navigation Tests — US-04 (floor structure and descent)
//
// Covers: floor count range (3–5), egg room placement constraints (floors 2–4 exactly one),
// Floor 1 has no egg room, Floor 5 has no egg room and has boss + exit,
// 3-floor run final floor has boss + exit.
//
// These tests call FloorGenerator directly — the pure function driving port for floor generation.
//
// Error / edge paths: floor count below minimum is guarded, 3-floor run final floor has boss,
// egg room not on Floor 1, not on Floor 5.
// Error path ratio in this file: 4 of 9 = 44%

@Suite("Floor Navigation and Structure")
struct FloorNavigationTests {

    // MARK: - Floor generation constraints

    @Test("A new run generates between 3 and 5 floors")
    func runGeneratesBetweenThreeAndFiveFloors() {
        // Given
        let config = GameConfig.default
        // When
        let run = FloorGenerator.generateRun(config: config, seed: 42)
        // Then
        #expect(run.floors.count >= 3)
        #expect(run.floors.count <= 5)
    }

    @Test("Floor 1 contains no egg room")
    func floorOneHasNoEggRoom() {
        // Given
        let config = GameConfig.default
        // When
        let floor1 = FloorGenerator.generate(floorNumber: 1, config: config)
        // Then
        #expect(floor1.hasEggRoom == false)
    }

    @Test("Exactly one floor in the range 2 through 4 contains an egg room")
    func exactlyOneEggRoomOnMidFloors() {
        // Given
        let config = GameConfig.default
        let run = FloorGenerator.generateRun(config: config, seed: 42)
        // When
        let eggFloors = run.floors.filter { $0.floorNumber >= 2 && $0.floorNumber <= 4 && $0.hasEggRoom }
        // Then
        #expect(eggFloors.count == 1)
    }

    @Test("Floor 5 contains the boss encounter and the exit square")
    func floorFiveHasBossAndExit() {
        // Given — 5-floor run
        let config = GameConfig.withFloorCount(5)
        let run = FloorGenerator.generateRun(config: config, seed: 42)
        // When
        let floor5 = run.floors.first { $0.floorNumber == 5 }!
        // Then
        #expect(floor5.hasBossEncounter == true)
        #expect(floor5.hasExitSquare == true)
    }

    @Test("Floor 5 contains no egg room")
    func floorFiveHasNoEggRoom() {
        // Given
        let config = GameConfig.withFloorCount(5)
        let run = FloorGenerator.generateRun(config: config, seed: 42)
        // When
        let floor5 = run.floors.first { $0.floorNumber == 5 }!
        // Then
        #expect(floor5.hasEggRoom == false)
    }

    @Test("Each floor has a reachable path from entry to staircase with no inescapable dead ends")
    func everyFloorIsNavigable() {
        // Given — generate multiple runs with different seeds
        let config = GameConfig.default
        for seed in [1, 2, 3, 42, 99] {
            let run = FloorGenerator.generateRun(config: config, seed: seed)
            // When
            for floor in run.floors where floor.floorNumber < run.floors.count {
                // Then — staircase is reachable from entry
                #expect(floor.isNavigable == true, "Floor \(floor.floorNumber) with seed \(seed) is not navigable")
            }
        }
    }

    // MARK: - 3-floor minimum run constraints (edge path)

    @Test("In a 3-floor run, the final floor contains the boss encounter and exit")
    func threeFloorRunFinalFloorHasBossAndExit() {
        // Given
        let config = GameConfig.withFloorCount(3)
        let run = FloorGenerator.generateRun(config: config, seed: 42)
        // When
        let finalFloor = run.floors.last!
        // Then
        #expect(finalFloor.hasBossEncounter == true)
        #expect(finalFloor.hasExitSquare == true)
    }

    @Test("In a 3-floor run, the egg room is on Floor 2 because Floor 3 is the final floor")
    func threeFloorRunEggRoomIsOnFloorTwo() {
        // Given — 3 floors: Floor 1 = starter, Floor 2 = only regular floor, Floor 3 = boss+exit
        let config = GameConfig.withFloorCount(3)
        let run = FloorGenerator.generateRun(config: config, seed: 42)
        // When
        let eggFloors = run.floors.filter { $0.hasEggRoom }
        // Then — exactly one egg room, on Floor 2
        #expect(eggFloors.count == 1)
        #expect(eggFloors.first?.floorNumber == 2)
    }

    // MARK: - Floor descent places Ember at next floor entry (integration)

    @Test("Ember is placed at the entry point of the new floor after descending")
    func descentPlacesEmberAtFloorEntry() {
        // Given
        let config = GameConfig.default
        var state = GameState.initial(config: config)
        let floor1 = FloorGenerator.generate(floorNumber: 1, config: config)
        state = state.withPlayerPosition(floor1.staircasePosition)
        // When
        let result = RulesEngine.apply(command: .move(.forward), to: state, deltaTime: 0.0)
        // Then
        let floor2 = FloorGenerator.generate(floorNumber: 2, config: config)
        #expect(result.playerPosition == floor2.entryPosition)
        #expect(result.currentFloor == 2)
    }
}
