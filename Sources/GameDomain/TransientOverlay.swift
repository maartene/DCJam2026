// TransientOverlay — short-lived HUD overlays driven by a frame countdown.
// Display text (SHIELDED!, STRUCK!, SWOOSH!) is a Renderer concern, not this type.

public enum TransientOverlay: Equatable, Sendable {
    case braceSuccess(framesRemaining: Int)
    case braceHit(framesRemaining: Int)
    case dash(framesRemaining: Int)
    case special(framesRemaining: Int)

    public static let defaultDuration: Int = 23
}
