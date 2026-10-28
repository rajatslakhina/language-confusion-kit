// swift-tools-version:6.0
import PackageDescription

let package = Package(
    name: "LanguageConfusionKit",
    platforms: [
        .macOS(.v13),
        .iOS(.v16),
        .tvOS(.v16),
        .watchOS(.v9)
    ],
    products: [
        .library(name: "LanguageConfusionKit", targets: ["LanguageConfusionKit"]),
        .executable(name: "LanguageConfusionDemo", targets: ["LanguageConfusionDemo"])
    ],
    targets: [
        .target(name: "LanguageConfusionKit"),
        .executableTarget(
            name: "LanguageConfusionDemo",
            dependencies: ["LanguageConfusionKit"]
        ),
        .testTarget(
            name: "LanguageConfusionKitTests",
            dependencies: ["LanguageConfusionKit"]
        )
    ],
    swiftLanguageModes: [.v6]
)
