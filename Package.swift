// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Tunes",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "Tunes", targets: ["Tunes"])
    ],
    targets: [
        .executableTarget(
            name: "Tunes",
            path: "Sources/Tunes",
            swiftSettings: [
                .unsafeFlags([
                    "-plugin-path", "/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/usr/lib/swift/host/plugins"
                ])
            ],
            linkerSettings: [
                .linkedFramework("iTunesLibrary"),
                .linkedFramework("AVFoundation"),
                .linkedFramework("MediaPlayer"),
                .linkedFramework("AppKit"),
                .linkedFramework("SwiftUI")
            ]
        )
    ]
)
