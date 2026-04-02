// GameConfig — tuning constants for a run. Value type; upgrades produce a mutated copy.

struct GameConfig: Sendable {
    var maxHP: Int
    var dashCooldownSeconds: Double
    var dashStartingCharges: Int
    var dashChargeCap: Int
    var specialChargeRatePerSecond: Double
    var maxFloors: Int

    // Brace / enemy-attack timing
    var enemyAttackInterval: Double       // seconds between enemy attacks
    var braceWindowDuration: Double       // invulnerability window after Brace input
    var braceCooldownSeconds: Double      // cooldown before Brace can be used again
    var braceSpecialBonus: Double         // Special charge bonus on a successful parry

    static let `default` = GameConfig(
        maxHP: 100,
        dashCooldownSeconds: 45.0,
        dashStartingCharges: 2,
        dashChargeCap: 2,
        specialChargeRatePerSecond: 0.008,
        maxFloors: 5,
        enemyAttackInterval: 2.0,
        braceWindowDuration: 0.5,
        braceCooldownSeconds: 1.5,
        braceSpecialBonus: 0.15
    )

    static func withFloorCount(_ count: Int) -> GameConfig {
        var c = GameConfig.default
        c.maxFloors = count
        return c
    }

    // MARK: - Derived

    /// True when the Brace window is short enough that the player must react quickly.
    var braceRequiresReaction: Bool { braceWindowDuration < 1.0 }
}
