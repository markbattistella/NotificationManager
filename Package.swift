// swift-tools-version: 5.10

import PackageDescription

let package = Package(
    name: "NotificationManager",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
        .visionOS(.v1),
        .macCatalyst(.v17),
    ],
    products: [
        .library(
            name: "NotificationManager",
            targets: ["NotificationManager"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/markbattistella/DefaultsKit", from: "2.0.0"),
        .package(url: "https://github.com/markbattistella/SimpleLogger", from: "2.0.0")
    ],
    targets: [
        .target(
            name: "NotificationManager",
            dependencies: [
                "DefaultsKit",
                "SimpleLogger"
            ]
        ),
    ]
)
