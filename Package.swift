// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "MeuUso",
    platforms: [
        .macOS(.v15)
    ],
    products: [
        .executable(name: "MeuUso", targets: ["MeuUsoApp"]),
        .executable(name: "meu-uso-cli", targets: ["MeuUsoCLI"])
    ],
    dependencies: [
        // The de-facto standard recorder + global hotkey for Mac apps (System Settings-style field).
        .package(url: "https://github.com/sindresorhus/KeyboardShortcuts", from: "3.0.1"),
        // In-app auto-updates (appcast + EdDSA-signed downloads). 2.9.4 fixes the update window opening
        // behind other apps for menu-bar (dockless) apps (sparkle-project/Sparkle#2889).
        .package(url: "https://github.com/sparkle-project/Sparkle", from: "2.9.4")
    ],
    targets: [
        .target(
            name: "MeuUso",
            dependencies: [
                .product(name: "KeyboardShortcuts", package: "KeyboardShortcuts"),
                .product(name: "Sparkle", package: "Sparkle")
            ],
            path: "Sources/MeuUso",
            resources: [
                .copy("Resources/ProviderIcons"),
                .copy("Resources/pricing_supplement.json"),
                .copy("Resources/pricing_litellm_snapshot.json"),
                .copy("Resources/pricing_models_dev_snapshot.json")
            ],
            swiftSettings: [
                .swiftLanguageMode(.v6)
            ]
        ),
        .executableTarget(
            name: "MeuUsoApp",
            dependencies: ["MeuUso"],
            path: "Sources/MeuUsoApp",
            swiftSettings: [
                .swiftLanguageMode(.v6)
            ]
        ),
        .executableTarget(
            name: "MeuUsoCLI",
            dependencies: ["MeuUso"],
            path: "Sources/MeuUsoCLI",
            swiftSettings: [
                .swiftLanguageMode(.v6)
            ]
        ),
        .testTarget(
            name: "MeuUsoTests",
            dependencies: ["MeuUso"],
            path: "Tests/MeuUsoTests",
            swiftSettings: [
                .swiftLanguageMode(.v6)
            ]
        ),
        .testTarget(
            name: "MeuUsoCLITests",
            dependencies: ["MeuUsoCLI"],
            path: "Tests/MeuUsoCLITests",
            swiftSettings: [
                .swiftLanguageMode(.v6)
            ]
        )
    ]
)
