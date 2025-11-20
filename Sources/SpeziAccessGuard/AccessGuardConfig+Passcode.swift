//
// This source file is part of the Spezi open source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

public import Foundation
public import SpeziFoundation
public import SwiftUI


/// An Access Guard that is unlocked by the user entering a passcode.
///
/// ## Topics
///
/// ### Regular Access Guards
/// - ``init(_:codeFormat:isOptional:timeout:)``
///
/// ### Fixed-Code Access Guards
/// - ``init(_:fixed:timeout:)``
/// - ``PasscodeFormat``
///
/// ### Custom-Validation Code Access Guards
/// - ``init(_:timeout:message:format:validate:)``
/// - ``ValidationResult``
///
/// ### Instance Properties
/// - ``id``
/// - ``timeout``
public struct CodeAccessGuard: _AccessGuardConfig {
    /// The result of evaluating a dynamic access guard against a user-entered passcode.
    ///
    /// ## Topics
    /// ### Results
    /// - ``valid``
    /// - ``invalid``
    /// - ``invalid(message:)``
    public enum ValidationResult: Sendable {
        /// The user-entered passcode was correct, and the access guard should be unlocked in response.
        case valid
        
        /// The user-entered passcode was incorrect, and the access guard should remain locked.
        ///
        /// - parameter message: An optional error message that should be displayed to the user.
        case invalid(message: LocalizedStringResource?)
        
        /// The user-entered passcode was incorrect, and the access guard should remain locked.
        public static var invalid: Self {
            .invalid(message: nil)
        }
    }
    
    public enum Kind: Sendable {
        case regular(format: PasscodeFormat)
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
        case .regular(let format), .custom(_, let format, _):
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
        case let .custom(message, format, validate: _):
            EnterCodeView(format: format, title: message) {
                await model.unlock($0)
            }
        }
    }
}


extension CodeAccessGuard {
    /// Creates a passcode-based Access Guard
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
    
    /// Creates a passcode-based Access Guard that uses a fixed code
    public init(
        _ id: AccessGuardIdentifier<Self>,
        fixed fixedCode: String,
        timeout: Duration = .minutes(5)
    ) {
        self.init(id, timeout: timeout, message: nil, format: .automatic(forFixedCode: fixedCode)) { code in
            code == fixedCode ? .valid : .invalid
        }
    }
    
    /// Creates a dynamic passcode-based Access Guard with custom code validation.
    ///
    /// This allows the app to fully control the unlock behaviour of a passcode-protected access guard.
    ///
    /// Example: using ``CodeAccessGuard`` with a custom validation closure to implement consumable access codes, where each code can only be used once:
    ///
    /// ```swift
    /// @MainActor
    /// final class ConsumableCodes: Sendable {
    ///     private(set) var consumedCodes: [String] = []
    ///     private(set) var remainingCodes = [
    ///         "1111", "2222", "3333", "4444"
    ///     ]
    ///
    ///     func validate(_ code: String) -> CodeAccessGuard.ValidationResult {
    ///         if let idx = remainingCodes.firstIndex(of: code) {
    ///             remainingCodes.remove(at: idx)
    ///             consumedCodes.append(code)
    ///             return .valid
    ///         } else {
    ///             return consumedCodes.contains(code) ? .invalid(message: "Code Already Used") : .invalid
    ///         }
    ///     }
    /// }
    ///
    /// // in the Spezi App Delegate
    /// override var configuration: Configuration {
    ///     let consumableCodes = ConsumableCodes()
    ///     AccessGuards {
    ///         CodeAccessGuard(.accessGuard, format: .numeric(4)) { code in
    ///             await consumableCodes.validate(code)
    ///         }
    ///     }
    /// }
    /// ```
    ///
    /// - Tip: In the example above, if `ConsumableCodes` were changed to conform to Spezi's `Module` protocol and added to the configuration,
    ///     it'd be able to access (via the [`@Dependency`](https://swiftpackageindex.com/stanfordspezi/spezi/documentation/spezi/module/dependency) API) other Spezi modules,
    ///     thereby giving the access guard validation logic full access to the entire Spezi environment
    ///     and it could use e.g. [SpeziStorage](https://swiftpackageindex.com/StanfordSpezi/SpeziStorage/documentation/) to keep track of the consumed/available codes.
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
