//
// This source file is part of the Spezi open source project
//
// SPDX-FileCopyrightText: 2023 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import LocalAuthentication


extension LAContext {
    /// Evaluates the specified policy asynchronously and reports the result.
    ///
    /// - Parameters:
    ///   - policy: The `LAPolicy` to evaluate. This policy determines the type of authentication required (e.g., biometric or device passcode).
    ///   - localizedReason: A string explaining why the app requests authentication. This string is displayed in the authentication dialog presented to the user.
    ///
    /// - Returns: A Boolean value indicating whether the policy evaluation was successful.
    ///
    /// - Throws: An error if policy evaluation fails. The error provides details about the reason for the failure.
    func evaluatePolicyAsync(_ policy: LAPolicy, localizedReason: String) async throws -> Bool {
        try await withCheckedThrowingContinuation { continuation in
            self.evaluatePolicy(policy, localizedReason: localizedReason) { success, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: success)
                }
            }
        }
    }
}
