// swift-tools-version:5.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "MulticastDelegate",
    platforms: [.iOS(.v8), .macOS(.v10_10), .tvOS(.v9), .watchOS(.v2)],
    products: [
        .library(name: "MulticastDelegate", targets: ["MulticastDelegate"]),
    ],
    targets: [
        .target(
            name: "MulticastDelegate",
            cSettings: [.headerSearchPath(".")]
        ),
        .testTarget(name: "MulticastDelegateTests", dependencies: ["MulticastDelegate"]),
    ]
)
