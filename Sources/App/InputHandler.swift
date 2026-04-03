// InputHandler — non-blocking keyboard input via a separate /dev/tty fd.
// CRITICAL: STDOUT_FILENO is never set O_NONBLOCK. Only this fd is non-blocking.

import GameDomain

#if canImport(Darwin)
    import Darwin
#elseif canImport(Glibc)
    import Glibc
#elseif canImport(Musl)
    import Musl
#endif

final class InputHandler {

    private let fd: Int32
    /// Set to true when the user requests quit (ESC only).
    private(set) var shouldQuit: Bool = false

    init() {
        fd = open("/dev/tty", O_RDONLY | O_NONBLOCK)
    }

    deinit {
        if fd >= 0 { close(fd) }
    }

    /// Poll for a single keypress. Returns .none if no input is available.
    func poll() -> GameCommand {
        var buf = [UInt8](repeating: 0, count: 8)
        let n = read(fd, &buf, buf.count)
        guard n > 0 else { return .none }
        return mapKey(buf, count: Int(n))
    }

    /// Map a raw byte sequence to a GameCommand. Exposed for testing.
    func mapKey(bytes: [UInt8]) -> GameCommand {
        return mapKey(bytes, count: bytes.count)
    }

    private func mapKey(_ buf: [UInt8], count: Int) -> GameCommand {
        // Escape sequence: ESC [ A/B/C/D
        if count >= 3 && buf[0] == 0x1B && buf[1] == 0x5B {
            switch buf[2] {
            case 0x41: return .move(.forward)   // Arrow Up
            case 0x42: return .move(.backward)  // Arrow Down
            case 0x43: return .turn(.right)     // Arrow Right
            case 0x44: return .turn(.left)      // Arrow Left
            default: break
            }
        }

        // ESC alone
        if count == 1 && buf[0] == 0x1B {
            shouldQuit = true
            return .none
        }

        let ch = buf[0]
        switch ch {
        case UInt8(ascii: "w"), UInt8(ascii: "W"): return .move(.forward)
        case UInt8(ascii: "s"), UInt8(ascii: "S"): return .move(.backward)
        case UInt8(ascii: "a"), UInt8(ascii: "A"): return .turn(.left)
        case UInt8(ascii: "d"), UInt8(ascii: "D"): return .turn(.right)
        case UInt8(ascii: "1"): return .dash
        case UInt8(ascii: "2"): return .brace
        case UInt8(ascii: "3"): return .special
        case 0x20, 0x0D: return .confirmOverlay  // space / enter
        case UInt8(ascii: "r"), UInt8(ascii: "R"): return .restart
        default:
            break
        }
        return .none
    }
}
