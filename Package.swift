// swift-tools-version:5.3

import PackageDescription

let package = Package(
    name: "LiveCollections",
    platforms: [
        .iOS(.v9),
    ],
    products: [
        .library(
            name: "LiveCollections",
            type: .static,
            targets: ["LiveCollections"]),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "LiveCollections",
            dependencies: [],
            resources: [
                .process("LICENSE")
            ]),
        .testTarget(
            name: "LiveCollectionsTests",
            dependencies: ["LiveCollections"]),

    ]
)
