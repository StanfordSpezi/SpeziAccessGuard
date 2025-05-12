// swift-tools-version:6.0

//
// This source file is part of the Spezi open source project
// 
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
// 
// SPDX-License-Identifier: MIT
//

import PackageDescription


let package = Package(
    name: "SpeziAccessGuard",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(name: "SpeziAccessGuard", targets: ["SpeziAccessGuard"])
    ],
    dependencies: [
        .package(url: "https://github.com/StanfordSpezi/Spezi.git", from: "1.8.0"),
        .package(url: "https://github.com/StanfordSpezi/SpeziStorage.git", from: "2.1.0"),
        .package(url: "https://github.com/StanfordSpezi/SpeziViews.git", from: "1.9.0"),
        .package(url: "https://github.com/StanfordSpezi/SpeziFoundation.git", from: "2.1.1"),
        .package(url: "https://github.com/pointfreeco/swift-snapshot-testing.git", from: "1.17.0")
    ],
    targets: [
        .target(
            name: "SpeziAccessGuard",
            dependencies: [
                .product(name: "Spezi", package: "Spezi"),
                .product(name: "SpeziKeychainStorage", package: "SpeziStorage"),
                .product(name: "SpeziViews", package: "SpeziViews"),
                .product(name: "SpeziFoundation", package: "SpeziFoundation")
            ],
            swiftSettings: [.enableUpcomingFeature("ExistentialAny")]
        ),
        .testTarget(
            name: "SpeziAccessGuardTests",
            dependencies: [
                .target(name: "SpeziAccessGuard"),
                .product(name: "SnapshotTesting", package: "swift-snapshot-testing")
            ],
            resources: [
                .process("__Snapshots__")
            ],
            swiftSettings: [.enableUpcomingFeature("ExistentialAny")]
        )
    ]
)
