// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Unctico",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        .library(
            name: "Unctico",
            targets: ["Unctico"]),
    ],
    dependencies: [
        // Add package dependencies here if needed
    ],
    targets: [
        .target(
            name: "Unctico",
            dependencies: [],
            path: "Sources/Unctico",
            resources: [
                .process("Assets.xcassets"),
                .process("Preview Content")
            ],
            swiftSettings: [
                .enableUpcomingFeature("BareSlashRegexLiterals")
            ]),
    ]
)
