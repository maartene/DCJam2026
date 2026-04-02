// ScreenMode — drives renderer strategy selection (see CLAUDE.md).

public enum ScreenMode: Sendable {
    case dungeon
    case combat(encounter: EncounterModel)
    case narrativeOverlay(event: NarrativeEvent)
    case upgradePrompt(choices: [Upgrade])
    case deathState
    case winState
}
