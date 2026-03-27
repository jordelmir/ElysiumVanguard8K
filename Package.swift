// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "ProPlayer",
    platforms: [
        .macOS(.v14)
    ],
    targets: [
        .executableTarget(
            name: "ProPlayer",
            path: "Sources/ProPlayer",
            swiftSettings: [
                .enableExperimentalFeature("StrictConcurrency")
            ]
        )
    ]
)
