//
// This source file is part of the Spezi open source project
//
// SPDX-FileCopyrightText: 2023 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import LocalAuthentication
@testable import SpeziAccessGuard
import Testing


class MockLAContext: LAContext {
    var shouldSucceed = true

    override func evaluatePolicy(
        _ policy: LAPolicy,
        localizedReason: String,
        reply: @escaping (Bool, (any Error)?) -> Void
    ) {
        if shouldSucceed {
            reply(true, nil)
        } else {
            let error = NSError(domain: "com.example.error", code: -1, userInfo: nil)
            reply(false, error)
        }
    }
}

struct LAContextTests {
    let mockContext = MockLAContext()

    @Test
    func evaluatePolicyAsyncSuccess() async throws {
        mockContext.shouldSucceed = true
        let result = try await mockContext.evaluatePolicyAsync(.deviceOwnerAuthenticationWithBiometrics, localizedReason: "Test for success")
        #expect(result == true, "Policy evaluation should succeed")
    }

    @Test
    func evaluatePolicyAsyncFailure() async throws {
        mockContext.shouldSucceed = false
        do {
            _ = try await mockContext.evaluatePolicyAsync(.deviceOwnerAuthenticationWithBiometrics, localizedReason: "Test for failure")
            Issue.record("Policy evaluation should fail but succeeded")
        } catch {
            // Test passes if an error is thrown as expected
        }
    }
}
