// TimerModel — tracks active Dash cooldown slots.
// Delta-time driven; no real clocks in domain logic.

public struct TimerModel: Sendable {
    // Each slot represents one depleted charge and the seconds remaining until replenishment.
    public var cooldownSlots: [Double]

    public static let empty = TimerModel(cooldownSlots: [])

    public var hasActiveCooldown: Bool { cooldownSlots.contains { $0 > 0 } }

    /// Duration of the first active cooldown slot, or 0 if none active.
    public var activeCooldownDuration: Double { cooldownSlots.first(where: { $0 > 0 }) ?? 0.0 }

    /// Advance all slots by deltaTime; returns replenished charge count and updated model.
    public func advance(deltaTime: Double, cooldownDuration: Double) -> (replenished: Int, model: TimerModel) {
        var updated: [Double] = []
        var replenished = 0
        for slot in cooldownSlots {
            let remaining = slot - deltaTime
            if remaining <= 0 {
                replenished += 1
            } else {
                updated.append(remaining)
            }
        }
        return (replenished, TimerModel(cooldownSlots: updated))
    }

    /// Adds a new cooldown slot for one depleted charge.
    public func addingCooldown(duration: Double) -> TimerModel {
        TimerModel(cooldownSlots: cooldownSlots + [duration])
    }
}
