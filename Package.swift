// swift-tools-version:5.7
import PackageDescription

let package = Package(
    name: "MoodV5",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        .library(
            name: "MoodV5",
            targets: ["MoodV5"]),
    ],
    dependencies: [
        .package(url: "https://github.com/realm/realm-swift.git", from: "10.45.0")
    ],
    targets: [
        .target(
            name: "MoodV5",
            dependencies: [
                .product(name: "RealmSwift", package: "realm-swift")
            ]),
        .testTarget(
            name: "MoodV5Tests",
            dependencies: ["MoodV5"]),
    ]
) 