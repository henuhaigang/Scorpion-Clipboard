// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "ScorpionClipboard",
    platforms: [.macOS(.v14)],
    dependencies: [
        .package(url: "https://github.com/sindresorhus/KeyboardShortcuts.git", from: "2.0.0")
    ],
    targets: [
        .executableTarget(
            name: "ScorpionClipboard",
            dependencies: ["KeyboardShortcuts"],
            path: "Sources",
            resources: [
                .copy("../Resources/AppIcon.icns")
            ],
            linkerSettings: [
                .unsafeFlags(["-Xlinker", "-sectcreate", "-Xlinker", "__TEXT", "-Xlinker", "__info_plist", "-Xlinker", "Info.plist"]),
                .unsafeFlags(["-Xlinker", "-sectcreate", "-Xlinker", "__TEXT", "-Xlinker", "__entitlements", "-Xlinker", "ScorpionClipboard.entitlements"])
            ]
        ),
        .testTarget(
            name: "ScorpionClipboardTests",
            dependencies: ["ScorpionClipboard"],
            path: "Tests"
        )
    ]
)
