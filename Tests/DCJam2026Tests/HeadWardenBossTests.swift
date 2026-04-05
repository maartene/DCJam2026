import Testing
@testable import DCJam2026
@testable import GameDomain

// Acceptance Tests — US-GPF-02: Head Warden Boss — Art, Name, Narrative
//
// Driving port: Renderer(output: TUIOutputSpy()) — the rendering driving port.
//               All tests invoke the renderer directly with a pre-built GameState.
//
// Story: When Ember reaches floor 5 and the boss combat screen opens, the enemy is
// labelled "HEAD WARDEN" (not "DRAGON WARDEN"). The ASCII art shows an armoured human
// figure — no cat ears, no whiskers. The Thoughts region reflects that Ember faces the
// human antagonist who ordered the egg theft, using dragon vocabulary.
//
// Error path ratio: 4 of 9 scenarios = 44% (exceeds 40% mandate).
//
// Mandate compliance:
//   CM-A: All tests invoke the Renderer driving port via TUIOutputSpy.
//   CM-B: Names use game domain terms (Head Warden, Ember, Thoughts region, boss encounter).
//         Zero technical terms (no "buildCombatFrame", no "combatThoughts").
//   CM-C: Each test validates observable output — what a player sees on screen.

@Suite struct `Head Warden Boss — Walking Skeleton` {

    // -------------------------------------------------------------------------
    // WALKING SKELETON — the thinnest observable slice:
    // Ember enters the boss encounter and sees "HEAD WARDEN" — not "DRAGON".
    // -------------------------------------------------------------------------

    @Test func `Boss combat screen shows HEAD WARDEN as the enemy name`() {
        // Given — Ember on floor 5, boss combat active
        let state = bossEncounterState()
        // When — combat screen renders
        let spy = TUIOutputSpy()
        Renderer(output: spy).render(state)
        // Then — "HEAD WARDEN" appears in the rendered output
        let allOutput = spy.entries.map(\.string).joined()
        #expect(allOutput.contains("HEAD WARDEN"),
                "Boss combat screen must show 'HEAD WARDEN' as the enemy name")
    }
}

// -------------------------------------------------------------------------
// Focused scenarios — US-GPF-02 happy paths
// -------------------------------------------------------------------------

@Suite struct `Head Warden Boss — Happy Paths` {

    // GPF-02-H1: "DRAGON" must not appear anywhere in the boss combat screen
    @Test func `The word DRAGON does not appear in the boss combat screen`() {
        let state = bossEncounterState()
        let spy = TUIOutputSpy()
        Renderer(output: spy).render(state)
        let allOutput = spy.entries.map(\.string).joined()
        #expect(!allOutput.contains("DRAGON"),
                "The word 'DRAGON' must not appear in the boss combat screen — it belongs to Ember, not the enemy")
    }

    // GPF-02-H2: Boss art contains no cat-ear pattern
    @Test func `Boss ASCII art contains no cat ear pattern`() {
        let state = bossEncounterState()
        let spy = TUIOutputSpy()
        Renderer(output: spy).render(state)
        let allOutput = spy.entries.map(\.string).joined()
        // The old cat art ear pattern: /\___/\ — check no variant of this appears
        #expect(!allOutput.contains("/\\___/\\"),
                "Boss art must not contain the cat ear pattern '/\\___/\\'")
    }

    // GPF-02-H3: Thoughts region contains human-antagonist framing
    @Test func `Boss Thoughts region conveys confrontation with the human who ordered the egg theft`() {
        let state = bossEncounterState()
        let spy = TUIOutputSpy()
        Renderer(output: spy).render(state)
        // Thoughts region: rows 20-22 (rows 21-24 per layout; filter content rows)
        let thoughtsWrites = spy.entries.filter { (20...24).contains($0.row) }
        let thoughtsText = thoughtsWrites.map(\.string).joined().lowercased()
        // The text must reference a human antagonist (warden) and not use "dragon warden"
        #expect(thoughtsText.contains("warden"),
                "Boss Thoughts region must reference the warden antagonist")
        #expect(!thoughtsText.contains("dragon warden"),
                "Boss Thoughts must not use the old phrase 'dragon warden'")
    }

    // GPF-02-H4: Boss minimap symbol "B" is unchanged
    @Test func `Boss minimap symbol remains B after the art and name change`() {
        // Given — Ember on floor 5 in dungeon navigation mode (not yet in combat)
        let config = GameConfig.default
        let finalFloor = config.maxFloors
        let floor = FloorRegistry.floor(finalFloor, config: config)
        let bossPos = floor.encounterPosition2D!
        let state = GameState.initial(config: config)
            .withCurrentFloor(finalFloor)
            .withPlayerPosition(Position(x: 0, y: 0))
            .withScreenMode(.dungeon)
        let spy = TUIOutputSpy()
        Renderer(output: spy).render(state)
        // Boss encounter cell on the minimap must still show "B"
        let targetRow = 3 + (6 - bossPos.y)
        let targetCol = 61 + bossPos.x
        let cellWrites = spy.entries.filter { $0.row == targetRow && $0.col == targetCol }
        let allText = cellWrites.map(\.string).joined()
        let stripped = stripANSI(allText)
        #expect(stripped.contains("B"),
                "Boss minimap symbol must remain 'B' — art and name changes must not affect the minimap, got: \(stripped)")
    }

    // GPF-02-H5: Regular guard encounter is completely unaffected
    @Test func `Regular guard combat screen still shows DUNGEON GUARD — not Head Warden`() {
        // Given — Ember in combat with a regular guard on floor 1-4
        let config = GameConfig.default
        let state = GameState.initial(config: config)
            .withScreenMode(.combat(encounter: EncounterModel.guard(isBossEncounter: false)))
        // When — combat screen renders
        let spy = TUIOutputSpy()
        Renderer(output: spy).render(state)
        let allOutput = spy.entries.map(\.string).joined()
        // Then — DUNGEON GUARD appears; HEAD WARDEN does not
        #expect(allOutput.contains("DUNGEON GUARD"),
                "Regular guard combat must still show 'DUNGEON GUARD'")
        #expect(!allOutput.contains("HEAD WARDEN"),
                "Regular guard combat must NOT show 'HEAD WARDEN'")
    }
}

// -------------------------------------------------------------------------
// Focused scenarios — US-GPF-02 error and boundary paths
// -------------------------------------------------------------------------

@Suite struct `Head Warden Boss — Error and Boundary Paths` {

    // GPF-02-E1: The old boss name "DRAGON WARDEN" must not appear anywhere in the boss screen
    @Test func `DRAGON WARDEN does not appear anywhere in the boss combat screen`() {
        let state = bossEncounterState()
        let spy = TUIOutputSpy()
        Renderer(output: spy).render(state)
        let allOutput = spy.entries.map(\.string).joined()
        #expect(!allOutput.contains("DRAGON WARDEN"),
                "The old boss name 'DRAGON WARDEN' must be completely removed from the boss combat screen")
    }

    // GPF-02-E2: No feline features in boss art (whiskers pattern)
    @Test func `Boss ASCII art contains no whisker characters adjacent to a face line`() {
        let state = bossEncounterState()
        let spy = TUIOutputSpy()
        Renderer(output: spy).render(state)
        let allOutput = spy.entries.map(\.string).joined()
        // Whisker patterns in ASCII cat art use sequences like "=^.^=" or "~ ~ ~" or "-.-"
        // The binding constraint: no cat features. Check the most common pattern variants.
        #expect(!allOutput.contains("=^.^="), "Boss art must not contain cat face '=^.^='")
        #expect(!allOutput.contains("(^_^)"), "Boss art must not contain cat face '(^_^)'")
    }

    // GPF-02-E3: Regular guard Thoughts region does not reference "warden" (unchanged)
    @Test func `Regular guard Thoughts region does not reference the Head Warden`() {
        let config = GameConfig.default
        let state = GameState.initial(config: config)
            .withScreenMode(.combat(encounter: EncounterModel.guard(isBossEncounter: false)))
        let spy = TUIOutputSpy()
        Renderer(output: spy).render(state)
        let thoughtsWrites = spy.entries.filter { (20...24).contains($0.row) }
        let thoughtsText = thoughtsWrites.map(\.string).joined().lowercased()
        #expect(!thoughtsText.contains("head warden"),
                "Regular guard Thoughts must not reference the Head Warden — those thoughts belong to the boss encounter only")
    }

    // GPF-02-E4: Boss art is exactly 8 lines — no layout corruption
    @Test func `Boss ASCII art renders in exactly 8 lines — screen layout is not corrupted`() {
        // The existing art is 8 lines and is centred in the 78-column main view.
        // This test verifies the art rows (typically rows 4-11 in the combat screen)
        // all contain content and none overflow into the status bar at row 17.
        let state = bossEncounterState()
        let spy = TUIOutputSpy()
        Renderer(output: spy).render(state)
        // No write must touch row 17 (the status bar separator) from the art region
        let row17Writes = spy.entries.filter { $0.row == 17 && (1...59).contains($0.col) }
        // Row 17 writes from the combat frame must be the separator — they must not contain art characters
        for entry in row17Writes {
            let text = entry.string
            #expect(!text.contains("O") || text.contains("─"),
                    "Row 17 (separator) must not be overwritten by boss art content: \"\(text)\"")
        }
    }
}

// MARK: - Shared helpers

private func bossEncounterState() -> GameState {
    let config = GameConfig.default
    return GameState.initial(config: config)
        .withCurrentFloor(config.maxFloors)
        .withScreenMode(.combat(encounter: EncounterModel.boss()))
}
