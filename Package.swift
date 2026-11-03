// swift-tools-version: 6.0
// Builds Shared/ as a plain package so `swift test` covers the schedule logic.
// The apps themselves build from VOEMonitor.xcodeproj; this package is only for tests.
import PackageDescription

let package = Package(
    name: "VOECore",
    platforms: [.macOS(.v15), .iOS(.v18)],
    targets: [
        .target(
            name: "VOECore",
            path: "Shared",
            exclude: ["Resources", "PrivacyInfo.xcprivacy"]
        ),
        .testTarget(
            name: "VOECoreTests",
            dependencies: ["VOECore"],
            path: "Tests/VOECoreTests",
            resources: [.copy("Fixtures")]
        ),
    ]
)
