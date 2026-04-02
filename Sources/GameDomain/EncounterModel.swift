// EncounterModel — state of a single enemy encounter.

public struct EncounterModel: Sendable {
    public let isBossEncounter: Bool
    public var enemyHP: Int
    /// Seconds remaining until the enemy's next attack. Counts down each tick.
    public var enemyAttackTimer: Double

    public static func `guard`(isBossEncounter: Bool) -> EncounterModel {
        EncounterModel(
            isBossEncounter: isBossEncounter,
            enemyHP: isBossEncounter ? 120 : 40,
            enemyAttackTimer: GameConfig.default.enemyAttackInterval
        )
    }

    public static func boss() -> EncounterModel {
        EncounterModel(isBossEncounter: true, enemyHP: 120, enemyAttackTimer: GameConfig.default.enemyAttackInterval)
    }
}
