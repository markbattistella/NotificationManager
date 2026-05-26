// swift-tools-version: 6.0

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
    )
  ],
  dependencies: [
    .package(url: "https://github.com/markbattistella/DefaultsKit", from: "26.0.0"),
    .package(url: "https://github.com/markbattistella/SimpleLogger", from: "26.0.0"),
  ],
  targets: [
    .target(
      name: "NotificationManager",
      dependencies: [
        "DefaultsKit",
        "SimpleLogger",
      ],
      swiftSettings: [
        .swiftLanguageMode(.v6)
      ]
    ),
    .testTarget(
      name: "NotificationManagerTests",
      dependencies: ["NotificationManager"],
      swiftSettings: [
        .swiftLanguageMode(.v6)
      ]
    ),
  ],
  swiftLanguageModes: [.v6]
)
