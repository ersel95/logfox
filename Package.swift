// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "LogFox",
    platforms: [
        .iOS(.v17),
        .macOS(.v14) // Core, UIKit'siz olduğu için macOS'ta da test edilebilir
    ],
    products: [
        // Faz 0+1: yalnız Core. LogFoxUI / LogFoxNetfoxBridge sonraki fazlarda eklenecek.
        .library(name: "LogFoxCore", targets: ["LogFoxCore"])
    ],
    targets: [
        .target(
            name: "LogFoxCore",
            swiftSettings: [
                .enableExperimentalFeature("StrictConcurrency")
            ]
        ),
        .testTarget(
            name: "LogFoxCoreTests",
            dependencies: ["LogFoxCore"]
        )
    ]
)
