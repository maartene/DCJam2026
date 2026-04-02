// GameCommand — all player inputs the RulesEngine can receive.

public enum GameCommand: Sendable, Equatable {
    case move(MoveDirection)
    case turn(TurnDirection)
    case dash
    case brace
    case special
    case confirmOverlay
    case selectUpgrade(Upgrade)
    case restart
    case none
}

public enum MoveDirection: Sendable, Equatable {
    case forward
    case backward
}
