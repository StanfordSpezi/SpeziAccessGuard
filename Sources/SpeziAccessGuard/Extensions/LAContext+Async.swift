//
// This source file is part of the Spezi open source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//


import LocalAuthentication


extension LAContext {
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
