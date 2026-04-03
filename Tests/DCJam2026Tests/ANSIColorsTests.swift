// ANSIColorsTests — acceptance + unit tests for ANSIColors helper
// Test Budget: 2 behaviors x 2 = 4 max. Using 2 tests.
// Behavior 1: colored() wraps text with code + reset
// Behavior 2: all required constants are defined with correct values

import XCTest
@testable import DCJam2026

final class ANSIColorsTests: XCTestCase {

    // Behavior 1: colored() wraps input with ANSI code and appends reset unconditionally
    func test_colored_wrapsTextWithCodeAndReset() {
        XCTAssertEqual(colored("HP", code: "\u{1B}[32m"), "\u{1B}[32mHP\u{1B}[0m")
        XCTAssertEqual(colored("", code: "\u{1B}[31m"), "\u{1B}[31m\u{1B}[0m",
                       "colored() must append reset even for empty string")
    }

    // Behavior 2: all required ANSI color constants are defined with correct values
    func test_ansiColorConstants_haveCorrectValues() {
        XCTAssertEqual(ansiReset,           "\u{1B}[0m")
        XCTAssertEqual(ansiGreen,           "\u{1B}[32m")
        XCTAssertEqual(ansiYellow,          "\u{1B}[33m")
        XCTAssertEqual(ansiRed,             "\u{1B}[31m")
        XCTAssertEqual(ansiBoldBrightCyan,  "\u{1B}[1m\u{1B}[96m")
        XCTAssertEqual(ansiDimCyan,         "\u{1B}[36m")
        XCTAssertEqual(ansiBrightRed,       "\u{1B}[91m")
        XCTAssertEqual(ansiBoldBrightRed,   "\u{1B}[1m\u{1B}[91m")
        XCTAssertEqual(ansiBrightYellow,    "\u{1B}[93m")
        XCTAssertEqual(ansiBrightCyan,      "\u{1B}[96m")
        XCTAssertEqual(ansiBoldBrightWhite, "\u{1B}[1m\u{1B}[97m")
        XCTAssertEqual(ansiDarkGray,        "\u{1B}[90m")
    }

}
