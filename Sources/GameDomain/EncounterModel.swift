// EncounterModel — state of a single enemy encounter.

struct EncounterModel: Sendable {
    let isBossEncounter: Bool
    var enemyHP: Int
    /// Seconds remaining until the enemy's next attack. Counts down each tick.
    var enemyAttackTimer: Double

    static func `guard`(isBossEncounter: Bool) -> EncounterModel {
        EncounterModel(
            isBossEncounter: isBossEncounter,
            enemyHP: isBossEncounter ? 120 : 40,
            enemyAttackTimer: GameConfig.default.enemyAttackInterval
        )
    }

    static func boss() -> EncounterModel {
        EncounterModel(isBossEncounter: true, enemyHP: 120, enemyAttackTimer: GameConfig.default.enemyAttackInterval)
    }
}
