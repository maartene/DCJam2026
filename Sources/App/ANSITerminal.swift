// ANSITerminal — concrete implementation of TUIOutputPort.
// All terminal output is buffered and flushed atomically via looping write.
// STDOUT_FILENO stays blocking; only /dev/tty (input fd) is opened O_NONBLOCK.

import Darwin

final class ANSITerminal: TUIOutputPort {

    private var buffer: [UInt8] = []
    private var savedTermios = termios()
    private var rawModeEnabled = false

    init() {
        buffer.reserveCapacity(4096)
    }

    // MARK: - Raw mode

    func enableRawMode() {
        guard tcgetattr(STDIN_FILENO, &savedTermios) == 0 else { return }
        var raw = savedTermios
        // Disable canonical mode, echo, signals
        raw.c_lflag &= ~tcflag_t(ICANON | ECHO | ISIG)
        // Disable XON/XOFF flow control and CR translation
        raw.c_iflag &= ~tcflag_t(IXON | ICRNL)
        // Minimum 1 byte read, no timeout
        raw.c_cc.16 = 1  // VMIN
        raw.c_cc.17 = 0  // VTIME
        tcsetattr(STDIN_FILENO, TCSAFLUSH, &raw)
        rawModeEnabled = true
    }

    func restoreTerminal() {
        guard rawModeEnabled else { return }
        tcsetattr(STDIN_FILENO, TCSAFLUSH, &savedTermios)
        rawModeEnabled = false
    }

    // MARK: - TUIOutputPort

    func write(_ string: String) {
        buffer.append(contentsOf: string.utf8)
    }

    func moveCursor(row: Int, col: Int) {
        write("\u{1B}[\(row);\(col)H")
    }

    func clearScreen() {
        write("\u{1B}[H\u{1B}[2J")
    }

    func hideCursor() {
        write("\u{1B}[?25l")
    }

    func showCursor() {
        write("\u{1B}[?25h")
    }

    func flush() {
        guard !buffer.isEmpty else { return }
        buffer.withUnsafeBytes { ptr in
            guard let base = ptr.baseAddress else { return }
            var offset = 0
            let bytes = ptr.count
            while offset < bytes {
                let n = Darwin.write(STDOUT_FILENO, base + offset, bytes - offset)
                if n > 0 {
                    offset += n
                } else if errno == EINTR {
                    continue
                } else {
                    break
                }
            }
        }
        buffer.removeAll(keepingCapacity: true)
    }

    // MARK: - Color helpers

    func colorCode(_ code: Int) -> String {
        "\u{1B}[\(code)m"
    }

    func resetColor() -> String {
        "\u{1B}[0m"
    }
}
