// GameState — complete snapshot of a run. Pure value type; all mutations produce new copies.

public struct GameState: Sendable {
    public var hp: Int
    public var dashCharges: Int
    public var specialCharge: Double
    public var hasEgg: Bool
    public var currentFloor: Int
    public var playerPosition: Int
    public var screenMode: ScreenMode
    public var timerModel: TimerModel
    public var activeUpgrades: [Upgrade]
    public var config: GameConfig

    /// Seconds remaining in the active Brace invulnerability window (0 = not active).
    public var braceWindowTimer: Double
    /// Seconds remaining before Brace can be used again (0 = ready).
    public var braceCooldownTimer: Double
    /// True for the first dungeon tick after a successful Dash — used to show feedback text.
    public var recentDash: Bool

    public var specialIsReady: Bool { specialCharge >= 1.0 }
    public var braceWindowActive: Bool { braceWindowTimer > 0 }
    public var braceOnCooldown: Bool { braceCooldownTimer > 0 }

    public static func initial(config: GameConfig) -> GameState {
        GameState(
            hp: config.maxHP,
            dashCharges: config.dashStartingCharges,
            specialCharge: 0.0,
            hasEgg: false,
            currentFloor: 1,
            playerPosition: 0,
            screenMode: .dungeon,
            timerModel: .empty,
            activeUpgrades: [],
            config: config,
            braceWindowTimer: 0.0,
            braceCooldownTimer: 0.0,
            recentDash: false
        )
    }

    // MARK: - Functional update helpers

    public func withHP(_ hp: Int) -> GameState {
        var s = self; s.hp = hp; return s
    }

    public func withDashCharges(_ charges: Int) -> GameState {
        var s = self; s.dashCharges = charges; return s
    }

    public func withSpecialCharge(_ charge: Double) -> GameState {
        var s = self; s.specialCharge = charge; return s
    }

    public func withHasEgg(_ hasEgg: Bool) -> GameState {
        var s = self; s.hasEgg = hasEgg; return s
    }

    public func withCurrentFloor(_ floor: Int) -> GameState {
        var s = self; s.currentFloor = floor; return s
    }

    public func withPlayerPosition(_ pos: Int) -> GameState {
        var s = self; s.playerPosition = pos; return s
    }

    public func withScreenMode(_ mode: ScreenMode) -> GameState {
        var s = self; s.screenMode = mode; return s
    }

    public func withTimerModel(_ model: TimerModel) -> GameState {
        var s = self; s.timerModel = model; return s
    }

    public func withActiveUpgrades(_ upgrades: [Upgrade]) -> GameState {
        var s = self; s.activeUpgrades = upgrades; return s
    }

    public func withConfig(_ config: GameConfig) -> GameState {
        var s = self; s.config = config; return s
    }

    public func withBraceWindowTimer(_ t: Double) -> GameState {
        var s = self; s.braceWindowTimer = t; return s
    }

    public func withBraceCooldownTimer(_ t: Double) -> GameState {
        var s = self; s.braceCooldownTimer = t; return s
    }

    public func withRecentDash(_ v: Bool) -> GameState {
        var s = self; s.recentDash = v; return s
    }
}
