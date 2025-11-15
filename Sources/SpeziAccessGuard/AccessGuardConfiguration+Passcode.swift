//
// This source file is part of the Spezi open source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Foundation
import SpeziFoundation
import SpeziViews
import SwiftUI


public struct CodeAccessGuard: _AccessGuardConfigurationProtocol {
    public enum ValidationResult: Sendable {
        case valid
        case invalid(message: LocalizedStringResource?)
        
        public static var invalid: Self {
            .invalid(message: nil)
        }
    }
    
    public enum Kind: Sendable {
        case regular(format: PasscodeFormat)
        case fixed(format: PasscodeFormat, code: String)
        case custom(
            message: LocalizedStringResource?,
            format: PasscodeFormat,
            validate: @Sendable (String) async -> ValidationResult
        )
    }
    
    public let id: AccessGuardIdentifier<Self>
    public let timeout: Duration
    let isOptional: Bool
    let kind: Kind
    var format: PasscodeFormat {
        switch kind {
        case .regular(let format), .fixed(let format, _), .custom(_, let format, _):
            format
        }
    }
    
    init(id: AccessGuardIdentifier<Self>, timeout: Duration, isOptional: Bool, kind: Kind) {
        self.id = id
        self.timeout = timeout
        self.isOptional = isOptional
        self.kind = kind
    }
    
    @_spi(Internal)
    public func _makeUnlockView(model: _PasscodeAccessGuardModel) -> some View { // swiftlint:disable:this identifier_name
        switch kind {
        case .regular:
            if model.needsSetup {
                SetupPasscodeFlow(model: model)
            } else {
                EnterCodeView(format: model.config.format) {
                    await model.unlock($0)
                }
            }
        case let .fixed(format, _):
            EnterCodeView(format: format) {
                await model.unlock($0)
            }

        case let .custom(message, format, validate: _):
            EnterCodeView(format: format, title: message) {
                await model.unlock($0)
            }
        }
    }
}


extension CodeAccessGuard {
    /// Creates a Passcode Access Guard
    public init(
        _ id: AccessGuardIdentifier<Self>,
        codeFormat: PasscodeFormat,
        isOptional: Bool = false,
        timeout: Duration = .minutes(5)
    ) {
        self.id = id
        self.timeout = timeout
        self.isOptional = isOptional
        self.kind = .regular(format: codeFormat)
    }
    
    /// Creates a Passcode Access Guard with a fixed code
    public init(
        _ id: AccessGuardIdentifier<Self>,
        fixed fixedCode: String,
        timeout: Duration = .minutes(5)
    ) {
        self.id = id
        self.timeout = timeout
        self.isOptional = false
        self.kind = .fixed(format: .automatic(forFixedCode: fixedCode), code: fixedCode)
    }
    
    /// Creates a Passcode Access Guard that uses a custom validation closure
    public init(
        _ id: AccessGuardIdentifier<Self>,
        timeout: Duration = .minutes(5),
        message: LocalizedStringResource? = nil, // swiftlint:disable:this function_default_parameter_at_end
        format: PasscodeFormat,
        validate: @escaping @Sendable (String) async -> ValidationResult
    ) {
        self.id = id
        self.timeout = timeout
        self.isOptional = false
        self.kind = .custom(message: message, format: format, validate: validate)
    }
}
