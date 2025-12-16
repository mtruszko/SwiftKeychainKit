// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SwiftKeychainKit",
    platforms: [
        .iOS(.v13),
        .macOS(.v10_15),
        .tvOS(.v13),
        .watchOS(.v6)
    ],
    products: [
        .library(
            name: "SwiftKeychainKit",
            targets: ["SwiftKeychainKit"]
        ),
    ],
    targets: [
        .target(
            name: "SwiftKeychainKit"
        ),
        .testTarget(
            name: "SwiftKeychainKitTests",
            dependencies: ["SwiftKeychainKit"]
        ),
    ]
)
