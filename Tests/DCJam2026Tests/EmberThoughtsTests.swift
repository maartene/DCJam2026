import Testing
@testable import GameDomain

@Suite struct `EmberThoughts — thought selection` {

    // MARK: - Dungeon

    @Test func `dungeon default thought on floor 1`() {
        let state = GameState.initial(config: .default)
            .withScreenMode(.dungeon)
        #expect(EmberThoughts.thought(for: state).contains("escape"))
    }

    @Test func `dungeon recent dash thought`() {
        let state = GameState.initial(config: .default)
            .withScreenMode(.dungeon)
            .withRecentDash(true)
        #expect(EmberThoughts.thought(for: state).contains("flying"))
    }

    @Test func `dungeon low HP thought`() {
        let state = GameState.initial(config: .default)
            .withScreenMode(.dungeon)
            .withHP(10)
        #expect(EmberThoughts.thought(for: state).contains("careful"))
    }

    @Test func `dungeon has egg thought`() {
        let state = GameState.initial(config: .default)
            .withScreenMode(.dungeon)
            .withHasEgg(true)
        #expect(EmberThoughts.thought(for: state).contains("way out"))
    }

    @Test func `dungeon one tile from staircase without egg shows refusal thought`() {
        let config = GameConfig.default
        let floor = FloorRegistry.floor(2, config: config)
        let staircase = floor.staircasePosition2D
        // Player faces north (default); staircase is one step north of this position.
        let oneStepSouth = Position(x: staircase.x, y: staircase.y - 1)
        let state = GameState.initial(config: config)
            .withScreenMode(.dungeon)
            .withCurrentFloor(2)
            .withFacingDirection(.north)
            .withPlayerPosition(oneStepSouth)
        #expect(EmberThoughts.thought(for: state).contains("won't leave without it"))
    }

    @Test func `dungeon deeper floor thought`() {
        let state = GameState.initial(config: .default)
            .withScreenMode(.dungeon)
            .withCurrentFloor(2)
        #expect(EmberThoughts.thought(for: state).contains("Deeper"))
    }

    // MARK: - Combat

    @Test func `combat default thought`() {
        let encounter = EncounterModel(isBossEncounter: false, enemyHP: 3, enemyAttackTimer: 0)
        let state = GameState.initial(config: .default)
            .withScreenMode(.combat(encounter: encounter))
        #expect(EmberThoughts.thought(for: state).contains("Armoured"))
    }

    @Test func `combat boss thought`() {
        let encounter = EncounterModel(isBossEncounter: true, enemyHP: 5, enemyAttackTimer: 0)
        let state = GameState.initial(config: .default)
            .withScreenMode(.combat(encounter: encounter))
        #expect(EmberThoughts.thought(for: state).contains("Head Warden"))
    }

    @Test func `combat low HP thought`() {
        let encounter = EncounterModel(isBossEncounter: false, enemyHP: 3, enemyAttackTimer: 0)
        let state = GameState.initial(config: .default)
            .withScreenMode(.combat(encounter: encounter))
            .withHP(20)
        #expect(EmberThoughts.thought(for: state).contains("wounded"))
    }

    @Test func `combat no dash thought`() {
        let encounter = EncounterModel(isBossEncounter: false, enemyHP: 3, enemyAttackTimer: 0)
        let state = GameState.initial(config: .default)
            .withScreenMode(.combat(encounter: encounter))
            .withDashCharges(0)
        #expect(EmberThoughts.thought(for: state).contains("wings are spent"))
    }

    // MARK: - Narrative

    @Test func `narrative egg discovery thought`() {
        let state = GameState.initial(config: .default)
            .withScreenMode(.narrativeOverlay(event: .eggDiscovery))
        #expect(EmberThoughts.thought(for: state).contains("Thank the elements"))
    }

    @Test func `narrative exit patio thought`() {
        let state = GameState.initial(config: .default)
            .withScreenMode(.narrativeOverlay(event: .exitPatio))
        #expect(EmberThoughts.thought(for: state).contains("open sky"))
    }

    @Test func `narrative special attack thought`() {
        let state = GameState.initial(config: .default)
            .withScreenMode(.narrativeOverlay(event: .specialAttack))
        #expect(EmberThoughts.thought(for: state).contains("heat rises"))
    }

    // MARK: - Other screens

    @Test func `upgrade prompt thought`() {
        let state = GameState.initial(config: .default)
            .withScreenMode(.upgradePrompt(choices: []))
        #expect(EmberThoughts.thought(for: state).contains("important choice"))
    }

    @Test func `death state thought`() {
        let state = GameState.initial(config: .default)
            .withScreenMode(.deathState)
        #expect(EmberThoughts.thought(for: state).contains("darkness"))
    }

    @Test func `win state thought`() {
        let state = GameState.initial(config: .default)
            .withScreenMode(.winState)
        #expect(EmberThoughts.thought(for: state).contains("free"))
    }
}
