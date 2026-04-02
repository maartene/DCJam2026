// GameState — complete snapshot of a run. Pure value type; all mutations produce new copies.

struct GameState: Sendable {
    var hp: Int
    var dashCharges: Int
    var specialCharge: Double
    var hasEgg: Bool
    var currentFloor: Int
    var playerPosition: Int
    var screenMode: ScreenMode
    var timerModel: TimerModel
    var activeUpgrades: [Upgrade]
    var config: GameConfig

    /// Seconds remaining in the active Brace invulnerability window (0 = not active).
    var braceWindowTimer: Double
    /// Seconds remaining before Brace can be used again (0 = ready).
    var braceCooldownTimer: Double

    var specialIsReady: Bool { specialCharge >= 1.0 }
    var braceWindowActive: Bool { braceWindowTimer > 0 }
    var braceOnCooldown: Bool { braceCooldownTimer > 0 }

    static func initial(config: GameConfig) -> GameState {
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
            braceCooldownTimer: 0.0
        )
    }

    // MARK: - Functional update helpers

    func withHP(_ hp: Int) -> GameState {
        var s = self; s.hp = hp; return s
    }

    func withDashCharges(_ charges: Int) -> GameState {
        var s = self; s.dashCharges = charges; return s
    }

    func withSpecialCharge(_ charge: Double) -> GameState {
        var s = self; s.specialCharge = charge; return s
    }

    func withHasEgg(_ hasEgg: Bool) -> GameState {
        var s = self; s.hasEgg = hasEgg; return s
    }

    func withCurrentFloor(_ floor: Int) -> GameState {
        var s = self; s.currentFloor = floor; return s
    }

    func withPlayerPosition(_ pos: Int) -> GameState {
        var s = self; s.playerPosition = pos; return s
    }

    func withScreenMode(_ mode: ScreenMode) -> GameState {
        var s = self; s.screenMode = mode; return s
    }

    func withTimerModel(_ model: TimerModel) -> GameState {
        var s = self; s.timerModel = model; return s
    }

    func withActiveUpgrades(_ upgrades: [Upgrade]) -> GameState {
        var s = self; s.activeUpgrades = upgrades; return s
    }

    func withConfig(_ config: GameConfig) -> GameState {
        var s = self; s.config = config; return s
    }

    func withBraceWindowTimer(_ t: Double) -> GameState {
        var s = self; s.braceWindowTimer = t; return s
    }

    func withBraceCooldownTimer(_ t: Double) -> GameState {
        var s = self; s.braceCooldownTimer = t; return s
    }
}
