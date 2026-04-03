// ANSIColors — module-private ANSI escape string constants and colored() helper.
// Internal access (no public modifier). Lives in the App module; never imported by GameDomain.

// MARK: - Reset

let ansiReset = "\u{1B}[0m"

// MARK: - Color constants

let ansiGreen           = "\u{1B}[32m"
let ansiYellow          = "\u{1B}[33m"
let ansiRed             = "\u{1B}[31m"
let ansiBoldBrightCyan  = "\u{1B}[1m\u{1B}[96m"
let ansiDimCyan         = "\u{1B}[36m"
let ansiBrightRed       = "\u{1B}[91m"
let ansiBoldBrightRed   = "\u{1B}[1m\u{1B}[91m"
let ansiBrightYellow    = "\u{1B}[93m"
let ansiBrightCyan      = "\u{1B}[96m"
let ansiBoldBrightWhite = "\u{1B}[1m\u{1B}[97m"
let ansiDarkGray        = "\u{1B}[90m"
let ansiWhite           = "\u{1B}[37m"
let ansiBrightWhite     = "\u{1B}[97m"

// MARK: - 256-color helper

/// Returns an ANSI 256-color foreground escape sequence for the given color index (0–255).
func ansi256Fg(_ colorIndex: Int) -> String {
    "\u{1B}[38;5;\(colorIndex)m"
}

// MARK: - Helper

/// Returns `text` wrapped with the given ANSI escape `code` and a trailing reset sequence.
/// The reset is appended unconditionally, even for empty input.
func colored(_ text: String, code: String) -> String {
    code + text + ansiReset
}
