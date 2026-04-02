// GameCommand — all player inputs the RulesEngine can receive.

enum GameCommand: Sendable {
    case move(MoveDirection)
    case dash
    case brace
    case special
    case confirmOverlay
    case selectUpgrade(Upgrade)
    case restart
    case none
}

enum MoveDirection: Sendable {
    case forward
    case backward
    case turnLeft
    case turnRight
}
