// EncounterModel — state of a single enemy encounter.

public struct EncounterModel: Sendable {
    public let isBossEncounter: Bool
    public var enemyHP: Int
    /// Seconds remaining until the enemy's next attack. Counts down each tick.
    public var enemyAttackTimer: Double

    /// Starting HP for this encounter type (used for HP bar rendering).
    public var maxHP: Int { isBossEncounter ? 120 : 40 }

    /// Damage dealt to the player on an unbraced hit.
    public var baseDamage: Int { isBossEncounter ? 25 : 15 }

    public static func `guard`(isBossEncounter: Bool) -> EncounterModel {
        let startingHP = isBossEncounter ? 120 : 40
        return EncounterModel(
            isBossEncounter: isBossEncounter,
            enemyHP: startingHP,
            enemyAttackTimer: GameConfig.default.enemyAttackInterval
        )
    }

    public static func boss() -> EncounterModel {
        `guard`(isBossEncounter: true)
    }
}
