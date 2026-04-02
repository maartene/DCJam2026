// swift-tools-version: 6.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "DCJam2026",
    targets: [
        // Pure domain logic — zero I/O, zero dependencies. Driving port for all acceptance tests.
        .target(
            name: "GameDomain",
            path: "Sources/GameDomain"
        ),
        // Entry point executable. Imports GameDomain; all TUI layers compiled as one module.
        .executableTarget(
            name: "DCJam2026",
            dependencies: ["GameDomain"],
            path: "Sources/App"
        ),
        // Acceptance tests invoke GameDomain directly. No mocks. No terminal I/O.
        .testTarget(
            name: "DCJam2026Tests",
            dependencies: ["GameDomain"],
            path: "Tests/DCJam2026Tests"
        ),
    ],
    swiftLanguageModes: [.v6]
)
