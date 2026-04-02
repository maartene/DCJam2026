// GameLoop — synchronous 30Hz game loop. No async/await, no DispatchQueue.
// Pure blocking while loop on the main thread.

import Darwin
import GameDomain

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
        var lastTime = clock_gettime_nsec_np(CLOCK_MONOTONIC)

        while true {
            let now = clock_gettime_nsec_np(CLOCK_MONOTONIC)
            let deltaTime = Double(now - lastTime) / 1_000_000_000.0
            lastTime = now

            let command = inputHandler.poll()

            if inputHandler.shouldQuit {
                break
            }

            state = RulesEngine.apply(command: command, to: state, deltaTime: deltaTime)
            renderer.render(state)

            // Cap to 30Hz
            let elapsed = clock_gettime_nsec_np(CLOCK_MONOTONIC) - now
            if elapsed < targetFrameNs {
                usleep(UInt32((targetFrameNs - elapsed) / 1000))
            }
        }
    }
}
