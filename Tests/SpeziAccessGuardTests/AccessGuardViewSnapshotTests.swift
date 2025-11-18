//
// This source file is part of the Spezi open source project
//
// SPDX-FileCopyrightText: 2025 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import SnapshotTesting
@testable import SpeziAccessGuard
import SpeziKeychainStorage
import SpeziTesting
import SwiftUI
import Testing


@Suite("AccessGuardViewSnapshots")
struct AccessGuardViewSnapshotTests {
    struct TestConfiguration {
        let name: String
        let isLocked: Bool
        let deviceConfig: ViewImageConfig

        var testName: String {
            "\(name)-\(isLocked ? "locked" : "unlocked")"
        }
    }

    static let testConfigurations: [TestConfiguration] = [
        .init(name: "iPhone13Pro", isLocked: true, deviceConfig: .iPhone13Pro),
        .init(name: "iPhone13Pro", isLocked: false, deviceConfig: .iPhone13Pro)
    ]

    @Test("AccessGuard view displays correctly in different states", arguments: Self.testConfigurations)
    @MainActor
    func testAccessGuardViewSnapshots(_ configuration: TestConfiguration) async throws {
        try await performSnapshotTest(with: configuration)
    }

    @MainActor
    private func performSnapshotTest(with config: TestConfiguration) async throws {
        let module = AccessGuards {
            CodeAccessGuard.testConfig
        }
        withDependencyResolution {
            KeychainStorage()
            module
        }
        let model = module.model(for: AccessGuardIdentifier.fixedCodeTest)
        
        if config.isLocked {
            model.lock()
        } else {
            _ = await model.unlock("0218")
        }

        let accessGuardView = AccessGuardView(
            config: CodeAccessGuard.testConfig,
            model: model,
            guarded: { Color.green }
        )
        .border(Color.red, width: 1)

        assertSnapshot(
            of: accessGuardView,
            as: .image(layout: .device(config: config.deviceConfig)),
            named: config.testName
        )
    }
}


extension AccessGuardIdentifier where AccessGuard == CodeAccessGuard {
    static let fixedCodeTest: Self = .passcode("test.accessguard")
}

extension CodeAccessGuard {
    static let testConfig = Self(.fixedCodeTest, fixed: "0218")
}
