// swift-tools-version:5.8

//
// This source file is part of the Spezi open source project
// 
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
// 
// SPDX-License-Identifier: MIT
//

import PackageDescription


let package = Package(
    name: "SpeziAccessCode",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        .library(name: "SpeziAccessCode", targets: ["SpeziAccessCode"])
    ],
    targets: [
        .target(
            name: "SpeziAccessCode"
        ),
        .testTarget(
            name: "SpeziAccessCodeTests",
            dependencies: [
                .target(name: "SpeziAccessCode")
            ]
        )
    ]
)
