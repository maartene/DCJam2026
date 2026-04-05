// Acceptance tests — will not compile until FloorRegistry and the updated
// Renderer (floor label at row 2, cols 61-79) are implemented.
// ACCEPTANCE: pre-implementation
//
// Feature: US-HM-03 — Floor label moved to row 2 of the right panel
//
// The existing label at row 2 (written at col 80 - label.count) overwrites
// the top row of the minimap on any floor whose entry cell is at y=0. Moving
// the label to row 2, cols 61-79, frees the minimap to start at row 3.
//
// DESIGN decision DEC-DESIGN-05:
//   Label is written at row 2, cols 61-79, inside renderDungeon() only.
//   drawChrome() signature is unchanged.
//   In all other screen modes, row 2 cols 61-79 contain no label text.
//
// Driving port: Renderer(output: TUIOutputSpy()).render(state)
//
// Mandate compliance:
//   CM-A: All tests invoke the Renderer driving port via TUIOutputSpy.
//   CM-B: Names use screen/floor/dungeon domain terms — no method names or cursor coords.
//   CM-C: Each test validates what a player or developer observes on screen.
//
// Error path ratio: 4 of 9 scenarios = 44% (exceeds 40% mandate).

import Testing
@testable import DCJam2026
@testable import GameDomain

@Suite struct `Handcrafted Maps — Floor Label Placement` {

    // -------------------------------------------------------------------------
    // WALKING SKELETON: floor label visible in dungeon mode right panel
    // -------------------------------------------------------------------------

    @Test func `Floor label appears in the right panel on row 2 when Ember is exploring a dungeon`() {
        // Given — Ember is on floor 3 in dungeon navigation mode
        let state = GameState.initial(config: .default)
            .withCurrentFloor(3)
            .withScreenMode(.dungeon)
        // When — the screen renders
        let spy = TUIOutputSpy()
        Renderer(output: spy).render(state)
        // Then — row 2, cols 61-79 contains the floor label
        let row2RightWrites = spy.entries.filter { $0.row == 2 && (61...79).contains($0.col) }
        let text = row2RightWrites.map(\.string).joined()
        #expect(text.contains("3"), "Floor label in row 2 right panel must include '3' for floor 3, got: \(text)")
        #expect(text.contains("5"), "Floor label in row 2 right panel must include '5' for maxFloors 5, got: \(text)")
    }

    // -------------------------------------------------------------------------
    // Happy path: floor number updates as Ember descends
    // -------------------------------------------------------------------------

    @Test func `Floor label shows floor 1 of 5 when Ember begins her run`() {
        // Given
        let state = GameState.initial(config: .default).withScreenMode(.dungeon)
        // When
        let spy = TUIOutputSpy()
        Renderer(output: spy).render(state)
        // Then
        let row2RightWrites = spy.entries.filter { $0.row == 2 && (61...79).contains($0.col) }
        let text = row2RightWrites.map(\.string).joined()
        #expect(text.contains("1"), "Floor label must contain '1' on floor 1, got: \(text)")
    }

    @Test func `Floor label shows floor 5 of 5 when Ember reaches the final level`() {
        // Given
        let state = GameState.initial(config: .default)
            .withCurrentFloor(5)
            .withScreenMode(.dungeon)
        // When
        let spy = TUIOutputSpy()
        Renderer(output: spy).render(state)
        // Then
        let row2RightWrites = spy.entries.filter { $0.row == 2 && (61...79).contains($0.col) }
        let text = row2RightWrites.map(\.string).joined()
        #expect(text.contains("5"), "Floor label must contain '5' on floor 5, got: \(text)")
    }

    @Test func `Floor label fits within the 19-character right panel width`() {
        // Given — worst-case floor number (single digit / single digit = 9 chars "Floor 5/5")
        let state = GameState.initial(config: .default)
            .withCurrentFloor(5)
            .withScreenMode(.dungeon)
        // When
        let spy = TUIOutputSpy()
        Renderer(output: spy).render(state)
        // Then — no single write to row 2 cols 61-79 extends beyond col 79
        let overflowWrites = spy.entries.filter { $0.row == 2 && $0.col > 79 }
        #expect(overflowWrites.isEmpty,
                "Floor label must not write beyond col 79, overflow: \(overflowWrites.map { $0.col })")
    }

    // -------------------------------------------------------------------------
    // Error paths: label absent in all non-dungeon screen modes
    // -------------------------------------------------------------------------

    @Test func `Floor label is absent from the right panel row 2 during combat`() {
        // Given — Ember is in a combat encounter
        let encounter = EncounterModel.guard(isBossEncounter: false)
        let state = GameState.initial(config: .default)
            .withCurrentFloor(2)
            .withScreenMode(.combat(encounter: encounter))
        // When
        let spy = TUIOutputSpy()
        Renderer(output: spy).render(state)
        // Then — row 2 right panel contains no floor label text
        let row2RightWrites = spy.entries.filter { $0.row == 2 && (61...79).contains($0.col) }
        let text = row2RightWrites.map(\.string).joined()
        #expect(!text.contains("Floor"),
                "Floor label must not appear in combat mode row 2 right panel, got: \(text)")
    }

    @Test func `Floor label is absent from the right panel row 2 on the death screen`() {
        // Given — Ember has died
        let state = GameState.initial(config: .default)
            .withScreenMode(.deathState)
        // When
        let spy = TUIOutputSpy()
        Renderer(output: spy).render(state)
        // Then
        let row2RightWrites = spy.entries.filter { $0.row == 2 && (61...79).contains($0.col) }
        let text = row2RightWrites.map(\.string).joined()
        #expect(!text.contains("Floor"),
                "Floor label must not appear on death screen, got: \(text)")
    }

    @Test func `Floor label is absent from the right panel row 2 on the win screen`() {
        // Given — Ember has escaped with the egg
        let state = GameState.initial(config: .default)
            .withScreenMode(.winState)
        // When
        let spy = TUIOutputSpy()
        Renderer(output: spy).render(state)
        // Then
        let row2RightWrites = spy.entries.filter { $0.row == 2 && (61...79).contains($0.col) }
        let text = row2RightWrites.map(\.string).joined()
        #expect(!text.contains("Floor"),
                "Floor label must not appear on win screen, got: \(text)")
    }

    // -------------------------------------------------------------------------
    // Error path: row 2 right panel is not written by the old label position
    // The old code wrote at col = 80 - floorLabel.count which for " Floor 1/5 "
    // (12 chars) is col 68. That write must no longer occur.
    // -------------------------------------------------------------------------

    @Test func `Floor label is not written at the old position (computed from right edge) in dungeon mode`() {
        // Given — floor 1 dungeon mode
        let state = GameState.initial(config: .default).withScreenMode(.dungeon)
        // When
        let spy = TUIOutputSpy()
        Renderer(output: spy).render(state)
        // Then — the write that previously placed the label should not appear at
        // col >= 68 via the old formula; the label must begin at col 61
        // (This test checks the label is anchored left within cols 61-79, not right-floated)
        let row2RightWrites = spy.entries.filter { $0.row == 2 && (61...79).contains($0.col) }
        // At least one write must be at or near col 61 (left anchor)
        let leftAnchoredWrite = row2RightWrites.first(where: { $0.col <= 65 })
        #expect(leftAnchoredWrite != nil,
                "Floor label must be left-anchored at col 61-65, not right-floated. row 2 right panel writes: \(row2RightWrites.map { ($0.col, $0.string) })")
    }

    // -------------------------------------------------------------------------
    // Integration: minimap starts at row 3, not row 2, after label relocation
    // -------------------------------------------------------------------------

    @Test func `Minimap first row is at row 3 after the floor label occupies row 2`() {
        // Given — floor 1 dungeon mode, entry cell is at y=0 (top of the grid)
        let state = GameState.initial(config: .default).withScreenMode(.dungeon)
        // When
        let spy = TUIOutputSpy()
        Renderer(output: spy).render(state)
        // Then — row 2 right panel is the floor label, not a minimap cell
        // The northernmost minimap row (y = grid.height - 1 = 6) renders at
        // screenRow = 3 + (6 - 6) = 3. The entry cell (y=0) renders at row 3 + 6 = 9.
        // Verify: at least one minimap write exists at row 3
        let row3RightWrites = spy.entries.filter { $0.row == 3 && (61...79).contains($0.col) }
        #expect(!row3RightWrites.isEmpty,
                "Minimap must produce at least one write at row 3 (northernmost row) in dungeon mode")
    }
}
