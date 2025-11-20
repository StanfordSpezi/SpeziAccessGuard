//
// This source file is part of the Stanford Spezi open-source project
//
// SPDX-FileCopyrightText: 2025 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

@_documentation(visibility: internal)
public protocol _AnyAccessGuardIdentifier<AccessGuard>: Hashable, Sendable { // swiftlint:disable:this type_name
    associatedtype AccessGuard: _AccessGuardConfig
    @_spi(Internal) var value: String { get }
}

/// Unique identifier of an Access Guard.
///
/// The `AccessGuardIdentifier` type is used to uniquely identify individual access guards within your application.
///
/// It is recommended you use reverse DNS notation for these identifiers, in order to reduce the risk of collisions.
/// Furthermore, the underlying raw values used for these should be stable, since they will in some cases be persisted across app launches.
///
/// - Note: Access Guard Identifiers are defined based on their supported configuration types (``CodeAccessGuard`` or ``BiometricAccessGuard``),
///     but are not scoped on them. Do not use the same string value for identifiers with different types.
///
/// These identifiers should be defined via static properties on the `AccessGuardIdentifier` type:
/// ```swift
/// // Identifier that can be used with code-based Access Guards
/// extension AccessGuardIdentifier where AccessGuard == CodeAccessGuard {
///     static let accountView: Self = .passcode("com.myApp.accountView")
/// }
///
/// // Identifier that can be used with biometrics-based Access Guards
/// extension AccessGuardIdentifier where AccessGuard == BiometricAccessGuard {
///     static let transactionsList: Self = .biometric("com.myApp.transactionsList")
/// }
/// ```
///
/// ## Topics
///
/// ### Creating an Identifier
/// - ``passcode(_:)``
/// - ``biometric(_:)``
///
/// ### Instance Properties
/// - ``passcodeFallback``
public struct AccessGuardIdentifier<AccessGuard: _AccessGuardConfig>: _AnyAccessGuardIdentifier {
    @_spi(Internal) public let value: String
}


extension AccessGuardIdentifier {
    /// Creates a Passcode Access Guard Identifier
    public static func passcode(_ id: String) -> Self where AccessGuard == CodeAccessGuard {
        Self(value: id)
    }
    
    /// Creates a Biometric Access Guard Identifier
    public static func biometric(_ id: String) -> Self where AccessGuard == BiometricAccessGuard {
        Self(value: id)
    }
}
