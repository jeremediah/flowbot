// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "MaterialProDB",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "MaterialProDB",
            targets: ["MaterialProDB"]
        ),
    ],
    dependencies: [
        // Add any external dependencies here
        // Example: .package(url: "https://github.com/realm/realm-swift.git", from: "10.0.0")
    ],
    targets: [
        .target(
            name: "MaterialProDB",
            dependencies: []
        ),
        .testTarget(
            name: "MaterialProDBTests",
            dependencies: ["MaterialProDB"]
        ),
    ]
)

