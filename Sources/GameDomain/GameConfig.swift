// GameConfig — tuning constants for a run. Value type; upgrades produce a mutated copy.

public struct GameConfig: Sendable {
    public var maxHP: Int
    public var dashCooldownSeconds: Double
    public var dashStartingCharges: Int
    public var dashChargeCap: Int
    public var specialChargeRatePerSecond: Double
    public var maxFloors: Int

    // Brace / enemy-attack timing
    public var enemyAttackInterval: Double       // seconds between enemy attacks
    public var braceWindowDuration: Double       // invulnerability window after Brace input
    public var braceCooldownSeconds: Double      // cooldown before Brace can be used again
    public var braceSpecialBonus: Double         // Special charge bonus on a successful parry
    public var upgradeChoiceCount: Int           // Number of choices presented at each milestone

    public static let `default` = GameConfig(
        maxHP: 100,
        dashCooldownSeconds: 25.0,
        dashStartingCharges: 2,
        dashChargeCap: 2,
        specialChargeRatePerSecond: 0.008,
        maxFloors: 5,
        enemyAttackInterval: 2.0,
        braceWindowDuration: 0.5,
        braceCooldownSeconds: 1.5,
        braceSpecialBonus: 0.15,
        upgradeChoiceCount: 3
    )

    public static func withFloorCount(_ count: Int) -> GameConfig {
        var c = GameConfig.default
        c.maxFloors = count
        return c
    }

    // MARK: - Derived

    /// True when the Brace window is short enough that the player must react quickly.
    public var braceRequiresReaction: Bool { braceWindowDuration < 1.0 }
}
