// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "AsyncTimeSequences",
    platforms: [.iOS(.v13), .macOS(.v10_15), .watchOS(.v6), .tvOS(.v13)],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "AsyncTimeSequences",
            targets: ["AsyncTimeSequences"]
        ),
        .library(
            name: "AsyncTimeSequencesSupport",
            targets: ["AsyncTimeSequencesSupport"]
        ),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "AsyncTimeSequencesDataStructures",
            dependencies: [],
            path: "Sources/AsyncTimeSequencesDataStructures"
        ),
        .target(
            name: "AsyncTimeSequences",
            dependencies: [
                "AsyncTimeSequencesDataStructures",
            ],
            path: "Sources/AsyncTimeSequences"
        ),
        .target(
            name: "AsyncTimeSequencesSupport",
            dependencies: [
                "AsyncTimeSequencesDataStructures",
            ],
            path: "Sources/AsyncTimeSequencesSupport"
        ),
        .testTarget(
            name: "AsyncTimeSequencesTests",
            dependencies: [
                "AsyncTimeSequences",
                "AsyncTimeSequencesSupport"
            ],
            path: "Tests"
        ),
    ]
)
