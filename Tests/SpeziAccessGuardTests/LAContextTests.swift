//
// This source file is part of the Spezi open source project
//
// SPDX-FileCopyrightText: 2023 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import LocalAuthentication
@testable import SpeziAccessGuard
import XCTest


class MockLAContext: LAContext {
    var shouldSucceed = true

    override func evaluatePolicy(
        _ policy: LAPolicy,
        localizedReason: String,
        reply: @escaping (Bool, Error?) -> Void
    ) {
        if shouldSucceed {
            reply(true, nil)
        } else {
            let error = NSError(domain: "com.example.error", code: -1, userInfo: nil)
            reply(false, error)
        }
    }
}

class LAContextTests: XCTestCase {
    func testEvaluatePolicyAsyncSuccess() async throws {
        let mockContext = MockLAContext()
        mockContext.shouldSucceed = true

        let result = try await mockContext.evaluatePolicyAsync(.deviceOwnerAuthenticationWithBiometrics, localizedReason: "Test for success")
        XCTAssertTrue(result, "Policy evaluation should succeed")
    }

    func testEvaluatePolicyAsyncFailure() async throws {
        let mockContext = MockLAContext()
        mockContext.shouldSucceed = false

        do {
            try await mockContext.evaluatePolicyAsync(.deviceOwnerAuthenticationWithBiometrics, localizedReason: "Test for failure")
            XCTFail("Policy evaluation should fail but succeeded")
        } catch {
            // Test passes if an error is thrown as expected
        }
    }
}
