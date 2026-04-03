// GameLoop — synchronous 30Hz game loop. No async/await, no DispatchQueue.
// Pure blocking while loop on the main thread.

import GameDomain

#if canImport(Darwin)
    import Darwin
#elseif canImport(Glibc)
    import Glibc
#elseif canImport(Musl)
    import Musl
#endif

final class GameLoop {

    private let terminal: ANSITerminal
    private let inputHandler: InputHandler
    private let renderer: Renderer
    private var state: GameState

    init() {
        terminal = ANSITerminal()
        inputHandler = InputHandler()
        renderer = Renderer(output: terminal)
        state = GameState.initial(config: .default)
    }

    func run() {
        terminal.enableRawMode()
        terminal.hideCursor()
        defer {
            terminal.showCursor()
            terminal.restoreTerminal()
            terminal.clearScreen()
            terminal.flush()
        }

        let targetFrameNs: UInt64 = 1_000_000_000 / 30  // ~33.3ms per frame
        var lastTime = monoTimeNanoseconds()

        while true {
            let now = monoTimeNanoseconds()
            let deltaTime = Double(now - lastTime) / 1_000_000_000.0
            lastTime = now

            let command = inputHandler.poll()

            if inputHandler.shouldQuit {
                break
            }

            state = RulesEngine.apply(command: command, to: state, deltaTime: deltaTime)
            renderer.render(state)

            // Cap to 30Hz
            let elapsed = monoTimeNanoseconds() - now
            if elapsed < targetFrameNs {
                usleep(UInt32((targetFrameNs - elapsed) / 1000))
            }
        }
    }
}
