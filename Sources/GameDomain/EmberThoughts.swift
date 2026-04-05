// EmberThoughts — Ember's inner voice, selected from GameState.
// Pure domain logic: no I/O, no rendering concerns.

public enum EmberThoughts {

    /// Returns the thought Ember expresses in the given game state.
    public static func thought(for state: GameState) -> String {
        switch state.screenMode {
        case .dungeon:
            return dungeonThought(state)
        case .combat(let encounter):
            return combatThought(state, encounter: encounter)
        case .narrativeOverlay(let event):
            return narrativeThought(event)
        case .upgradePrompt:
            return "An important choice awaits..."
        case .deathState:
            return "The darkness takes me... but perhaps the egg will survive?"
        case .winState:
            return "I am free! The egg is safe under the open sky."
        case .startScreen:
            return ""
        }
    }

    // MARK: - Private helpers

    private static func dungeonThought(_ state: GameState) -> String {
        if state.recentDash {
            return "I tear through! Moving faster than the guard could see. Feels a bit like flying."
        } else if state.hp <= 20 {
            return "Need to be a bit careful, these humans are more dangerous than I thought."
        } else if state.hasEgg {
            return "I can feel it! The egg, the LAST DRAGON EGG, its near. I need to find it, whatever the cost."
        } else if state.currentFloor == 1 {
            return "Where am I? I smell fresh air from somewhere, but its not near. Need to escape."
        } else {
            return "Deeper now. The air is thicker, heavier. My claws find the floor and I press on."
        }
    }

    private static func combatThought(_ state: GameState, encounter: EncounterModel) -> String {
        if case .special = state.transientOverlay {
            return "One deep breath and the air ignites."
        } else if encounter.isBossEncounter {
            return "The Head Warden. The one who ordered my egg stolen. This ends now."
        } else if state.hp <= 30 {
            return "I'm wounded and it knows it. I have to time this — brace for the next strike, then move."
        } else if state.dashCharges == 0 {
            return "My wings are spent. No Dash left. I'll hold this ground until their strength returns."
        } else {
            return "A guard. Armoured, blocking the corridor. I can brace and take the hit — or just dash through."
        }
    }

    private static func narrativeThought(_ event: NarrativeEvent) -> String {
        switch event {
        case .eggDiscovery:
            return "Thank the elements. There it is! I can feel its alive. Time to leave."
        case .exitPatio:
            return "Cold air, open sky. Finally. And jump and I'm free."
        case .specialAttack:
            return "The heat rises in my chest and I let it out. Nothing in that corridor is standing."
        }
    }
}
