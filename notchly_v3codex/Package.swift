// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "notchly_v3codex",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(
            name: "notchly_v3codex",
            targets: ["NotchlyV3Codex"]
        )
    ],
    targets: [
        .executableTarget(
            name: "NotchlyV3Codex",
            path: "Sources/NotchlyV3Codex",
            resources: [
                .process("../../Resources")
            ],
            swiftSettings: [
                .unsafeFlags(["-suppress-warnings"])
            ],
            linkerSettings: [
                .linkedFramework("CoreAudio"),
                .linkedFramework("IOBluetooth"),
                .linkedFramework("EventKit")
            ]
        )
    ]
)
