// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "LogFox",
    platforms: [
        .iOS(.v17),
        .macOS(.v14) // Core, UIKit'siz olduğu için macOS'ta da test edilebilir
    ],
    products: [
        // Çekirdek motor (UIKit/SwiftUI'sız, her platformda).
        .library(name: "LogFoxCore", targets: ["LogFoxCore"]),
        // In-app viewer (shake → düz metin). iOS hedefli; içerik `#if canImport(UIKit)` ile gate'li.
        .library(name: "LogFoxUI", targets: ["LogFoxUI"])
    ],
    targets: [
        .target(
            name: "LogFoxCore",
            swiftSettings: [
                .enableExperimentalFeature("StrictConcurrency")
            ]
        ),
        .target(
            name: "LogFoxUI",
            dependencies: ["LogFoxCore"],
            swiftSettings: [
                .enableExperimentalFeature("StrictConcurrency")
            ]
        ),
        .testTarget(
            name: "LogFoxCoreTests",
            dependencies: ["LogFoxCore"]
        ),
        .testTarget(
            name: "LogFoxUITests",
            dependencies: ["LogFoxUI"]
        )
    ]
)
