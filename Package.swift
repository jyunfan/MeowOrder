// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "orderbot",
    platforms: [
        .macOS(.v15)
    ],
    products: [
        .executable(name: "orderbot", targets: ["orderbot"]),
        .library(name: "OrderBotCore", targets: ["OrderBotCore"])
    ],
    targets: [
        .target(name: "OrderBotCore"),
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
