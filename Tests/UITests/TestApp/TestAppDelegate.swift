//
// This source file is part of the Stanford Spezi open-source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Spezi
import SpeziAccessGuard
import SwiftUI


class TestAppDelegate: SpeziAppDelegate {
    override var configuration: Configuration {
        Configuration {
            let consumableCodes = ConsumableCodesModule()
            consumableCodes
            AccessGuards {
                BiometricAccessGuard(.testBiometrics)
                CodeAccessGuard(.test, codeFormat: .numeric(4), isOptional: true, timeout: .seconds(10))
                CodeAccessGuard(.testFixed, fixed: "1234")
                CodeAccessGuard(.testConsumable, format: .numeric(4)) { code in
                    await consumableCodes.validate(code)
                }
            }
        }
    }
}


extension AccessGuardIdentifier where AccessGuard == CodeAccessGuard {
    static let test: Self = .passcode("edu.stanford.spezi.accessguardtests.1.test")
    static let testFixed: Self = .passcode("edu.stanford.spezi.accessguardtests.1.testFixed")
    static let testConsumable: Self = .passcode("edu.stanford.spezi.accessguardtests.1.testConsumable")
}

extension AccessGuardIdentifier where AccessGuard == BiometricAccessGuard {
    static let testBiometrics: Self = .biometric("edu.stanford.spezi.accessguardtests.1.testBiometrics")
}
