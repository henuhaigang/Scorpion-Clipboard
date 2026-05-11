// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "ClipboardCanvas",
    platforms: [.macOS(.v14)],
    dependencies: [
        .package(url: "https://github.com/sindresorhus/KeyboardShortcuts.git", from: "2.0.0")
    ],
    targets: [
        .executableTarget(
            name: "ClipboardCanvas",
            dependencies: ["KeyboardShortcuts"],
            path: "Sources",
            linkerSettings: [
                .unsafeFlags(["-Xlinker", "-sectcreate", "-Xlinker", "__TEXT", "-Xlinker", "__info_plist", "-Xlinker", "Info.plist"]),
                .unsafeFlags(["-Xlinker", "-sectcreate", "-Xlinker", "__TEXT", "-Xlinker", "__entitlements", "-Xlinker", "ClipboardCanvas.entitlements"])
            ]
        ),
        .testTarget(
            name: "ClipboardCanvasTests",
            dependencies: ["ClipboardCanvas"],
            path: "Tests"
        )
    ]
)
