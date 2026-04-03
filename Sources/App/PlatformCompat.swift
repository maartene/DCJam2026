// PlatformCompat.swift — cross-platform shims for Darwin vs Glibc divergences.
// Use #if canImport(Darwin) / #elseif canImport(Glibc) guards throughout.

#if canImport(Darwin)
import Darwin
#elseif canImport(Glibc)
import Glibc
#endif

/// Returns the current monotonic clock value in nanoseconds.
func monoTimeNanoseconds() -> UInt64 {
#if canImport(Darwin)
    return clock_gettime_nsec_np(CLOCK_MONOTONIC)
#elseif canImport(Glibc)
    var ts = timespec()
    clock_gettime(CLOCK_MONOTONIC, &ts)
    return UInt64(ts.tv_sec) * 1_000_000_000 + UInt64(ts.tv_nsec)
#else
    return 0
#endif
}

/// Configures a termios struct for single-byte, non-blocking character reads:
/// VMIN=1 (return after 1 byte) and VTIME=0 (no read timeout).
func setTermiosCCDefaults(_ raw: inout termios) {
    withUnsafeMutablePointer(to: &raw.c_cc) { ptr in
        let base = UnsafeMutableRawPointer(ptr)
        base.storeBytes(of: UInt8(1), toByteOffset: Int(VMIN), as: UInt8.self)
        base.storeBytes(of: UInt8(0), toByteOffset: Int(VTIME), as: UInt8.self)
    }
}

/// Writes bytes to a file descriptor, dispatching to the correct platform write symbol.
/// Returns the number of bytes written, or -1 on error (errno is set).
@discardableResult
func platformWrite(_ fd: Int32, _ ptr: UnsafeRawPointer, _ count: Int) -> Int {
#if canImport(Darwin)
    return Darwin.write(fd, ptr, count)
#elseif canImport(Glibc)
    return Glibc.write(fd, ptr, count)
#else
    return Foundation.write(fd, ptr, count)
#endif
}
