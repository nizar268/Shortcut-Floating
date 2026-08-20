// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "ProjectDeck",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(
            name: "ProjectDeck",
            targets: ["ProjectDeck"]
        )
    ],
    targets: [
        .executableTarget(
            name: "ProjectDeck",
            path: "ProjectDeck",
            exclude: ["Info.plist", "Resources"]
        )
    ]
)
