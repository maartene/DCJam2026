// Upgrade — a single selectable upgrade from a milestone prompt.

public enum UpgradeEffect: Sendable {
    case reduceDashCooldown(factor: Double)
    case increaseDashChargeCap(by: Int)
    case increaseMaxHP(by: Int)
    case increaseSpecialRate(factor: Double)
}

public struct Upgrade: Sendable, Equatable {
    public let id: String
    public let name: String
    public let effect: UpgradeEffect

    public init(id: String, name: String, effect: UpgradeEffect) {
        self.id = id
        self.name = name
        self.effect = effect
    }

    public static func == (lhs: Upgrade, rhs: Upgrade) -> Bool { lhs.id == rhs.id }
}

extension UpgradeEffect: Equatable {}
