//
// This source file is part of the Spezi open source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Foundation
import LocalAuthentication
import Observation
import SpeziKeychainStorage


@Observable
@MainActor
public final class _BiometricAccessGuardModel: _AnyAccessGuardModel { // swiftlint:disable:this type_name
    private let context = LAContext()
    public let config: BiometricAccessGuard
    public private(set) var didUnlockFaceId = false
    var fallback: _PasscodeAccessGuardModel?
    
    public var isLocked: Bool {
        if let fallbackIsLocked = fallback?.isLocked { // make sure we always access this, so that it's properly observed
            isAvailable ? !didUnlockFaceId : fallbackIsLocked
        } else {
            !didUnlockFaceId
        }
    }
    
    var isAvailable: Bool {
        (try? context.canEvaluate(.deviceOwnerAuthenticationWithBiometrics)) == true
    }
    
    public init(config: BiometricAccessGuard, context: AccessGuard) {
        self.config = config
        self.fallback = config.fallback.flatMap { fallbackKind in
            do {
                try context.register(CodeAccessGuard(
                    id: config.id.passcodeFallback,
                    timeout: config.timeout,
                    isOptional: true, // TOOD this really should be false?!
                    kind: fallbackKind
                ))
            } catch {
                fatalError("Error registering biometric access guard fallback: \(error)")
            }
            return context.model(for: config.id.passcodeFallback)
        }
    }
    
    public func lock() {
        didUnlockFaceId = false
        fallback?.lock()
    }
    
    public func unlock(_ input: Void) async throws -> Bool {
        guard (try? context.canEvaluate(.deviceOwnerAuthenticationWithBiometrics)) == true else {
            throw AccessGuardError.biometricsNotAvailable
        }
        let success = try await context.evaluatePolicy(
            .deviceOwnerAuthenticationWithBiometrics,
            localizedReason: String(localized: "ACCESS_GUARD_BIOMETRICS_REASON", bundle: .module)
        )
        didUnlockFaceId = success
        return success
    }
}


extension AccessGuardIdentifier where AccessGuard == BiometricAccessGuard {
    /// The identifier of the biometric access guard's passcode fallback.
    ///
    /// - Important: Only use this property if you wish to reset the fallback passcode associated with a Biometric Access Guard.
    ///     Do not use it for anything else; the behaviour in that case is undefined.
    public var passcodeFallback: AccessGuardIdentifier<CodeAccessGuard> {
        AccessGuardIdentifier<CodeAccessGuard>(value: self.value + "~codeFallback")
    }
}


extension LAContext {
    func canEvaluate(_ policy: LAPolicy) throws(LAError) -> Bool {
        var error: NSError?
        let result = self.canEvaluatePolicy(policy, error: &error)
        if let error {
            throw LAError(_nsError: error)
        } else {
            return result
        }
    }
}
