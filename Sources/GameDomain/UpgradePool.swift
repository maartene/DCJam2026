// UpgradePool — pool of available upgrades for milestone prompts.
// Excludes already-selected upgrades from future draws.

public struct UpgradePool: Sendable {
    private let available: [Upgrade]

    public init(alreadySelected: [Upgrade]) {
        let takenIDs = Set(alreadySelected.map { $0.id })
        available = UpgradePool.allUpgrades.filter { !takenIDs.contains($0.id) }
    }

    /// Returns up to `count` unique upgrades drawn from the pool.
    public func drawChoices(count: Int) -> [Upgrade] {
        Array(available.prefix(count))
    }

    // MARK: - Named upgrade factories (used by tests and RulesEngine)

    public static func cooldownReductionUpgrade() -> Upgrade {
        Upgrade(id: "cooldown-reduction", name: "Ember's Fury",
                effect: .reduceDashCooldown(factor: 0.75))
    }

    public static func chargeCapUpgrade() -> Upgrade {
        Upgrade(id: "charge-cap", name: "Dragon Endurance",
                effect: .increaseDashChargeCap(by: 1))
    }

    // MARK: - Full pool (8 upgrades per CLAUDE.md)

    public static let allUpgrades: [Upgrade] = [
        Upgrade(id: "cooldown-reduction",  name: "Ember's Fury",      effect: .reduceDashCooldown(factor: 0.75)),
        Upgrade(id: "charge-cap",          name: "Dragon Endurance",  effect: .increaseDashChargeCap(by: 1)),
        Upgrade(id: "hp-boost",            name: "Dragonhide",        effect: .increaseMaxHP(by: 25)),
        Upgrade(id: "special-rate",        name: "Inner Flame",       effect: .increaseSpecialRate(factor: 1.5)),
        Upgrade(id: "cooldown-reduction-2",name: "Swift Wings",       effect: .reduceDashCooldown(factor: 0.85)),
        Upgrade(id: "charge-cap-2",        name: "Iron Will",         effect: .increaseDashChargeCap(by: 1)),
        Upgrade(id: "hp-boost-2",          name: "Scaled Armor",      effect: .increaseMaxHP(by: 20)),
        Upgrade(id: "special-rate-2",      name: "Deep Breath",       effect: .increaseSpecialRate(factor: 1.25)),
    ]
}
