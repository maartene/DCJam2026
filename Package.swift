// swift-tools-version: 6.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "DCJam2026",
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .executableTarget(
            name: "DCJam2026"
        ),
        .testTarget(
            name: "DCJam2026Tests",
            dependencies: ["DCJam2026"]
        ),
    ],
    swiftLanguageModes: [.v6]
)
