// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Coldsleep",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(
            name: "Coldsleep",
            path: "Sources"
        )
    ]
)
