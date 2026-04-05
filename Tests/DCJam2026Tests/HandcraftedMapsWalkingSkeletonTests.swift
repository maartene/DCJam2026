// Acceptance tests — will not compile until FloorRegistry is implemented.
// ACCEPTANCE: pre-implementation
//
// Walking Skeleton — US-HM-01 + US-HM-02 (safe migration gate)
//
// The thinnest end-to-end slice with observable user value:
//   FloorRegistry.floor(1, config:) returns a FloorMap that is cell-for-cell
//   identical to the current FloorGenerator output. All existing gameplay tests
//   continue to pass unchanged. The player sees no visible change on floor 1.
//
// This is the hard gate before any new floor topologies are authored (DEC-DESIGN-07).
//
// Driving port: FloorRegistry.floor(_:config:) — the primary driving port for
//               all map-related acceptance tests (component-boundaries.md).
//
// Mandate compliance:
//   CM-A: Tests invoke FloorRegistry.floor(_:config:) (driving port only).
//         FloorDefinitionParser is never called directly (internal to GameDomain).
//   CM-B: Test names use dungeon/floor domain terms — zero technical jargon.
//   CM-C: Each test validates an observable outcome: Ember navigates the same
//         corridor she always has, now served from a character grid.

import Testing
@testable import GameDomain

@Suite struct `Handcrafted Maps — Walking Skeleton: Floor 1 Safe Migration` {

    // -------------------------------------------------------------------------
    // SKELETON-01: FloorRegistry serves floor 1 with the correct dimensions
    // -------------------------------------------------------------------------
    // The first test to enable. Confirms the pipeline end-to-end:
    // character grid → FloorDefinitionParser → FloorMap with correct width/height.

    @Test func `Floor 1 served by FloorRegistry has 15 columns and 7 rows`() {
        // Given — FloorRegistry is wired and floor 1 is registered
        // When
        let floor = FloorRegistry.floor(1, config: .default)
        // Then — dimensions match the existing L-shaped corridor
        #expect(floor.grid.width == 15, "Floor 1 must be 15 columns wide, got \(floor.grid.width)")
        #expect(floor.grid.height == 7, "Floor 1 must be 7 rows tall, got \(floor.grid.height)")
    }

    // -------------------------------------------------------------------------
    // SKELETON-02: Entry position survives the migration
    // -------------------------------------------------------------------------

    @Test func `Floor 1 entry position is at column 7 row 0 when served by FloorRegistry`() {
        // Given
        let floor = FloorRegistry.floor(1, config: .default)
        // Then — entry position unchanged from original
        #expect(floor.entryPosition2D == Position(x: 7, y: 0),
                "Floor 1 entry must be at (7,0), got \(floor.entryPosition2D)")
    }

    // -------------------------------------------------------------------------
    // SKELETON-03: Staircase position survives the migration
    // -------------------------------------------------------------------------

    @Test func `Floor 1 staircase is at column 7 row 6 when served by FloorRegistry`() {
        // Given
        let floor = FloorRegistry.floor(1, config: .default)
        // Then
        #expect(floor.staircasePosition2D == Position(x: 7, y: 6),
                "Floor 1 staircase must be at (7,6), got \(floor.staircasePosition2D)")
    }

    // -------------------------------------------------------------------------
    // SKELETON-04: Guard encounter position survives the migration
    // -------------------------------------------------------------------------

    @Test func `Floor 1 guard encounter is at column 7 row 2 when served by FloorRegistry`() {
        // Given
        let floor = FloorRegistry.floor(1, config: .default)
        // Then
        #expect(floor.encounterPosition2D == Position(x: 7, y: 2),
                "Floor 1 guard encounter must be at (7,2), got \(String(describing: floor.encounterPosition2D))")
    }

    // -------------------------------------------------------------------------
    // SKELETON-05: No egg room on floor 1 — regression guard
    // -------------------------------------------------------------------------

    @Test func `Floor 1 has no egg room when served by FloorRegistry`() {
        // Given
        let floor = FloorRegistry.floor(1, config: .default)
        // Then
        #expect(floor.hasEggRoom == false, "Floor 1 must not have an egg room")
        #expect(floor.eggRoomPosition2D == nil, "Floor 1 egg room position must be nil")
    }

    // -------------------------------------------------------------------------
    // SKELETON-06: Cell-for-cell passability identical to FloorGenerator
    // This is the migration gate. If any cell differs, the character grid has a
    // transcription error and must be corrected before floors 2-5 are authored.
    // -------------------------------------------------------------------------

    @Test func `Every cell on floor 1 has the same passability whether served by FloorRegistry or FloorGenerator`() {
        // Given
        let fromRegistry  = FloorRegistry.floor(1, config: .default)
        let fromGenerator = FloorGenerator.generate(floorNumber: 1, config: .default)
        // When — compare every cell
        var mismatches: [(x: Int, y: Int, registry: Bool, generator: Bool)] = []
        for y in 0..<fromGenerator.grid.height {
            for x in 0..<fromGenerator.grid.width {
                let regPassable = fromRegistry.grid.cell(x: x, y: y).isPassable
                let genPassable = fromGenerator.grid.cell(x: x, y: y).isPassable
                if regPassable != genPassable {
                    mismatches.append((x: x, y: y, registry: regPassable, generator: genPassable))
                }
            }
        }
        // Then — zero mismatches
        #expect(mismatches.isEmpty,
                "Cell passability mismatches between FloorRegistry and FloorGenerator: \(mismatches)")
    }

    // -------------------------------------------------------------------------
    // SKELETON-07: FloorRegistry and FloorGenerator agree on all landmark flags
    // -------------------------------------------------------------------------

    @Test func `FloorRegistry floor 1 landmark flags match FloorGenerator output exactly`() {
        // Given
        let fromRegistry  = FloorRegistry.floor(1, config: .default)
        let fromGenerator = FloorGenerator.generate(floorNumber: 1, config: .default)
        // Then — all flag fields match
        #expect(fromRegistry.hasEggRoom       == fromGenerator.hasEggRoom,
                "hasEggRoom differs: registry=\(fromRegistry.hasEggRoom) generator=\(fromGenerator.hasEggRoom)")
        #expect(fromRegistry.hasBossEncounter == fromGenerator.hasBossEncounter,
                "hasBossEncounter differs")
        #expect(fromRegistry.hasExitSquare    == fromGenerator.hasExitSquare,
                "hasExitSquare differs")
        #expect(fromRegistry.entryPosition2D  == fromGenerator.entryPosition2D,
                "entryPosition2D differs: registry=\(fromRegistry.entryPosition2D) generator=\(fromGenerator.entryPosition2D)")
        #expect(fromRegistry.staircasePosition2D == fromGenerator.staircasePosition2D,
                "staircasePosition2D differs")
    }

    // -------------------------------------------------------------------------
    // Error path: requesting an unregistered floor number falls back safely
    // -------------------------------------------------------------------------

    @Test func `FloorRegistry returns a navigable floor map even for an out-of-range floor number`() {
        // Given — floor number beyond the authored range
        let floor = FloorRegistry.floor(99, config: .default)
        // Then — a valid, navigable FloorMap is returned (no crash, no nil-equivalent)
        #expect(floor.grid.width > 0,  "Fallback floor must have a positive width")
        #expect(floor.grid.height > 0, "Fallback floor must have a positive height")
    }
}
