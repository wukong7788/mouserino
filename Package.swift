// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "MouserinoApp",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "MouserinoApp", targets: ["MouserinoApp"])
    ],
    targets: [
        .executableTarget(
            name: "MouserinoApp",
            path: "Sources/MouserinoApp",
            resources: [
                .process("Resources")
            ]
        )
    ]
)
