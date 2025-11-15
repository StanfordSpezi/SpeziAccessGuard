//
// This source file is part of the Stanford Spezi open-source project
//
// SPDX-FileCopyrightText: 2025 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Observation
import Spezi
import SpeziAccessGuard


@Observable
@MainActor
final class ConsumableCodesModule: Module, EnvironmentAccessible, Sendable {
    private(set) var consumedCodes: [String] = []
    private(set) var remainingCodes = [
        "1111", "2222", "3333", "4444"
    ]
    
    func validate(_ code: String) -> CodeAccessGuard.ValidationResult {
        if let idx = remainingCodes.firstIndex(of: code) {
            remainingCodes.remove(at: idx)
            consumedCodes.append(code)
            return .valid
        } else {
            return consumedCodes.contains(code) ? .invalid(message: "Already Consumed") : .invalid
        }
    }
}
