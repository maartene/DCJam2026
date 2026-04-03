// GameState — complete snapshot of a run. Pure value type; all mutations produce new copies.

public struct GameState: Sendable {
    public var hp: Int
    public var dashCharges: Int
    public var specialCharge: Double
    public var hasEgg: Bool
    public var currentFloor: Int
    public var playerPosition: Position
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
    /// The cardinal direction Ember is currently facing.
    public var facingDirection: CardinalDirection
    /// Short-lived HUD overlay driven by a frame countdown; nil when inactive.
    public var transientOverlay: TransientOverlay?

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
            playerPosition: Position(x: 7, y: 0),
            screenMode: .startScreen,
            timerModel: .empty,
            activeUpgrades: [],
            config: config,
            braceWindowTimer: 0.0,
            braceCooldownTimer: 0.0,
            recentDash: false,
            facingDirection: .north,
            transientOverlay: nil
        )
    }

    // MARK: - Functional update helpers

    public func withHP(_ hp: Int) -> GameState {
        var copy = self; copy.hp = hp; return copy
    }

    public func withDashCharges(_ charges: Int) -> GameState {
        var copy = self; copy.dashCharges = charges; return copy
    }

    public func withSpecialCharge(_ charge: Double) -> GameState {
        var copy = self; copy.specialCharge = charge; return copy
    }

    public func withHasEgg(_ hasEgg: Bool) -> GameState {
        var copy = self; copy.hasEgg = hasEgg; return copy
    }

    public func withCurrentFloor(_ floor: Int) -> GameState {
        var copy = self; copy.currentFloor = floor; return copy
    }

    public func withPlayerPosition(_ position: Position) -> GameState {
        var copy = self; copy.playerPosition = position; return copy
    }

    public func withScreenMode(_ mode: ScreenMode) -> GameState {
        var copy = self; copy.screenMode = mode; return copy
    }

    public func withTimerModel(_ model: TimerModel) -> GameState {
        var copy = self; copy.timerModel = model; return copy
    }

    public func withActiveUpgrades(_ upgrades: [Upgrade]) -> GameState {
        var copy = self; copy.activeUpgrades = upgrades; return copy
    }

    public func withConfig(_ config: GameConfig) -> GameState {
        var copy = self; copy.config = config; return copy
    }

    public func withBraceWindowTimer(_ seconds: Double) -> GameState {
        var copy = self; copy.braceWindowTimer = seconds; return copy
    }

    public func withBraceCooldownTimer(_ seconds: Double) -> GameState {
        var copy = self; copy.braceCooldownTimer = seconds; return copy
    }

    public func withRecentDash(_ didDash: Bool) -> GameState {
        var copy = self; copy.recentDash = didDash; return copy
    }

    public func withFacingDirection(_ direction: CardinalDirection) -> GameState {
        var copy = self; copy.facingDirection = direction; return copy
    }

    public func withTransientOverlay(_ overlay: TransientOverlay?) -> GameState {
        var copy = self; copy.transientOverlay = overlay; return copy
    }
}
