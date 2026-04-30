// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "orderbot",
    platforms: [
        .iOS(.v17),
        .macOS(.v15)
    ],
    products: [
        .executable(name: "orderbot", targets: ["orderbot"]),
        .library(name: "OrderBotAppFeature", targets: ["OrderBotAppFeature"]),
        .library(name: "OrderBotCore", targets: ["OrderBotCore"])
    ],
    targets: [
        .target(name: "OrderBotCore"),
        .target(
            name: "OrderBotAppFeature",
            dependencies: ["OrderBotCore"]
        ),
        .executableTarget(
            name: "orderbot",
            dependencies: ["OrderBotCore"]
        ),
        .testTarget(
            name: "OrderBotCoreTests",
            dependencies: ["OrderBotCore"]
        )
    ]
)
