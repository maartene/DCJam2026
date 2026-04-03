// PlatformCompat.swift — cross-platform shims for Darwin vs Glibc divergences.
// Use #if canImport(Darwin) / #elseif canImport(Glibc) guards throughout.

#if canImport(Darwin)
import Darwin
#elseif canImport(Glibc)
import Glibc
#endif

/// Returns the current monotonic clock value in nanoseconds.
/// Uses clock_gettime_nsec_np on Darwin and clock_gettime(CLOCK_MONOTONIC) on Linux.
func monoTimeNanoseconds() -> UInt64 {
#if canImport(Darwin)
    return clock_gettime_nsec_np(CLOCK_MONOTONIC)
#elseif canImport(Glibc)
    var ts = timespec()
    clock_gettime(CLOCK_MONOTONIC, &ts)
    return UInt64(ts.tv_sec) * 1_000_000_000 + UInt64(ts.tv_nsec)
#endif
}

/// Sets VMIN=1 and VTIME=0 on the c_cc field of a termios struct using
/// platform-defined VMIN and VTIME constants (not hardcoded tuple indices).
func setTermiosCCDefaults(_ raw: inout termios) {
    withUnsafeMutablePointer(to: &raw.c_cc) { ptr in
        let base = UnsafeMutableRawPointer(ptr)
        base.storeBytes(of: UInt8(1), toByteOffset: Int(VMIN), as: UInt8.self)
        base.storeBytes(of: UInt8(0), toByteOffset: Int(VTIME), as: UInt8.self)
    }
}
