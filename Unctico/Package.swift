// swift-tools-version: 5.9
// This file defines the package dependencies for Unctico

import PackageDescription

let package = Package(
    name: "Unctico",
    platforms: [
        .iOS(.v17) // Requires iOS 17 or later
    ],
    products: [
        .library(
            name: "Unctico",
            targets: ["Unctico"]
        )
    ],
    dependencies: [
        // No external dependencies yet - keeping it native and simple
        // Future: Add dependencies as needed (payment processing, etc.)
    ],
    targets: [
        .target(
            name: "Unctico",
            dependencies: []
        ),
        .testTarget(
            name: "UncticoTests",
            dependencies: ["Unctico"]
        )
    ]
)
