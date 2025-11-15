//
// This source file is part of the Spezi open source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Foundation
import Observation
import SpeziKeychainStorage


@Observable
@MainActor
public final class _PasscodeAccessGuardModel: _AnyAccessGuardModel { // swiftlint:disable:this type_name
    enum UnlockError: Error {
        case failed(LocalizedStringResource?)
    }
    
    private struct PersistedPasscode: Codable {
        /// The passcode
        let code: String
        /// The format that was required/enforced at the time the passcode was set
        ///
        /// - Note: This is stored here, instead of simply being fetched from the current configuration, in order to allow this being changed in a way that keeps old codes working.
        let format: PasscodeFormat
    }
    
    private let keychain: KeychainStorage
    public let config: CodeAccessGuard
    private(set) var needsSetup = true
    public private(set) var isLocked: Bool = true
    
    private var persistedCode: PersistedPasscode? {
        if let credentials = try? keychain.retrieveCredentials(withUsername: config.id.value, for: .accessGuard) {
            try? JSONDecoder().decode(PersistedPasscode.self, from: Data(credentials.password.utf8))
        } else {
            nil
        }
    }
    
    public init(config: CodeAccessGuard, context: AccessGuard) {
        self.config = config
        self.keychain = context.keychain
        setInitialLockedState()
    }
    
    private func setInitialLockedState() {
        switch (persistedCode, config.isOptional) {
        case (.some, _):
            // we have a code set
            needsSetup = false
            isLocked = true
        case (.none, true):
            // we don't have a code set currently, and the Access Guard is optional
            needsSetup = false
            isLocked = false
        case (.none, false):
            // we don't have a code set currently, and the Access Guard is NOT optional
            needsSetup = true
            isLocked = true // technically is isn't (yet) but we treat it as such as to not immediately show the guarded view
        }
    }
    
    public func lock() {
        isLocked = true
    }
    
    public func unlock(_ input: String) async -> CodeAccessGuard.ValidationResult {
        let result = await evaluate(input)
        switch result {
        case .valid:
            isLocked = false
        case .invalid:
            isLocked = true
        }
        return result
    }
    
    func evaluate(_ code: String) async -> CodeAccessGuard.ValidationResult {
        switch config.kind {
        case .fixed(_, let fixedCode):
            code == fixedCode ? .valid : .invalid
        case .regular:
            if let persistedCode {
                persistedCode.code == code ? .valid : .invalid
            } else {
                .invalid
            }
        case .custom(_, _, let validate):
            validate(code)
        }
    }
    
    func resetCode(newCode: String? = nil) throws {
        switch config.kind {
        case .fixed, .custom:
            throw AccessGuardError.storeCodeError // TOOD better error!!!
        case .regular(let format):
            try keychain.deleteCredentials(withUsername: config.id.value, for: .accessGuard)
            isLocked = true
            needsSetup = true
            setInitialLockedState()
            guard let newCode else {
                return
            }
            let persistedCode = PersistedPasscode(code: newCode, format: format)
            guard let accessCodeData = try? String(data: JSONEncoder().encode(persistedCode), encoding: .utf8) else {
                throw AccessGuardError.storeCodeError
            }
            try keychain.store(
                Credentials(username: config.id.value, password: accessCodeData),
                for: .accessGuard
            )
            needsSetup = false
            isLocked = false
        }
    }
}
