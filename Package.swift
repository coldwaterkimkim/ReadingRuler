// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "ReadingRuler",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(
            name: "ReadingRuler",
            targets: ["ReadingRuler"]
        )
    ],
    targets: [
        .executableTarget(
            name: "ReadingRuler",
            path: "Sources/ReadingRuler"
        )
    ]
)
