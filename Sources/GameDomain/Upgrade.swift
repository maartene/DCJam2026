// Upgrade — a single selectable upgrade from a milestone prompt.

enum UpgradeEffect: Sendable {
    case reduceDashCooldown(factor: Double)
    case increaseDashChargeCap(by: Int)
    case increaseMaxHP(by: Int)
    case increaseSpecialRate(factor: Double)
}

struct Upgrade: Sendable, Equatable {
    let id: String
    let name: String
    let effect: UpgradeEffect

    static func == (lhs: Upgrade, rhs: Upgrade) -> Bool { lhs.id == rhs.id }
}

extension UpgradeEffect: Equatable {}
