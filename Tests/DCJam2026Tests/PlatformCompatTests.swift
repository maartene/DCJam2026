// PlatformCompatTests — tests for cross-platform helpers in PlatformCompat.swift
// Acceptance test: monoTimeNanoseconds() returns monotonically increasing values
// Unit test: setTermiosCCDefaults sets min=1 and timeout=0 via VMIN/VTIME constants

import XCTest
@testable import DCJam2026

final class PlatformCompatTests: XCTestCase {

    // Acceptance test: monoTimeNanoseconds() is monotonically increasing
    func test_monoTimeNanoseconds_isMonotonicallyIncreasing() {
        let t1 = monoTimeNanoseconds()
        usleep(1000)  // 1ms sleep — enough for the clock to advance
        let t2 = monoTimeNanoseconds()
        XCTAssertGreaterThan(t2, t1, "monoTimeNanoseconds() must return a strictly increasing value")
    }

    // Unit test: setTermiosCCDefaults sets min=1 (VMIN) and timeout=0 (VTIME)
    func test_setTermiosCCDefaults_setsMinAndTimeout() {
        var raw = termios()
        setTermiosCCDefaults(&raw)
        withUnsafeBytes(of: raw.c_cc) { bytes in
            XCTAssertEqual(bytes[Int(VMIN)], 1, "VMIN slot must be set to 1")
            XCTAssertEqual(bytes[Int(VTIME)], 0, "VTIME slot must be set to 0")
        }
    }

}
