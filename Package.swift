// swift-tools-version: 5.6
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "CoverageTracker",
    platforms: [.macOS(.v10_15)],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .executable(
            name: "CoverageTracker",
            targets: ["CoverageTracker"]),
    ],
    dependencies: [
        //.package(name: "XCParseCore", url: "https://github.com/ChargePoint/xcparse", .upToNextMajor(from: "2.2.1")),
    ],
    targets: [
        .executableTarget(
            name: "CoverageTracker",
            dependencies: []),
        .testTarget(
            name: "CoverageTrackerTests",
            dependencies: ["CoverageTracker"]),
    ]
)
