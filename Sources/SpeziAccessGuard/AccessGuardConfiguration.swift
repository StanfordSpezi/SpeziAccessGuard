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


/// Configures the behaviour of the ``AccessGuard`` view.
public struct AccessGuardConfiguration: Sendable {
    let identifier: AccessGuardIdentifier
    let guardType: GuardType
    let codeOptions: CodeOptions
    let timeout: Duration
    let fixedCode: String?
}


/// Enforce an access code.
/// - Parameters:
///   - codeOptions: The code options, see ``CodeOptions``.
///   - timeout: The timeout when the view should be locked based on the time the scene is not in the foreground.
public func CodeAccessGuard( // swiftlint:disable:this identifier_name
    _ identifier: AccessGuardIdentifier,
    codeOptions: CodeOptions = .fourDigitNumeric,
    timeout: Duration = .minutes(5)
) -> AccessGuardConfiguration {
    AccessGuardConfiguration(identifier: identifier, guardType: .code, codeOptions: codeOptions, timeout: timeout, fixedCode: nil)
}


/// Enforce a fixed access code.
/// - Parameters:
///   - code: The fixed access code.
///   - codeOptions: The code options, see ``CodeOptions``.
///   - timeout: The timeout when the view should be locked based on the time the scene is not in the foreground.
public func FixedAccessGuard( // swiftlint:disable:this identifier_name
    _ identifier: AccessGuardIdentifier,
    code: String,
    codeOptions: CodeOptions = .fourDigitNumeric,
    timeout: Duration = .minutes(5)
) -> AccessGuardConfiguration {
    AccessGuardConfiguration(identifier: identifier, guardType: .code, codeOptions: codeOptions, timeout: timeout, fixedCode: code)
}

/// Enforce an access code & biometrics authentication if setup on the device.
/// - Parameters:
///   - codeOptions: The code options, see ``CodeOptions``.
///   - timeout: The timeout when the view should be locked based on the time the scene is not in the foreground.
///
public func BiometricsAccessGuard( // swiftlint:disable:this identifier_name
    _ identifier: AccessGuardIdentifier,
    codeOptions: CodeOptions = .fourDigitNumeric,
    timeout: Duration = .minutes(5)
) -> AccessGuardConfiguration {
    AccessGuardConfiguration(identifier: identifier, guardType: .biometrics, codeOptions: codeOptions, timeout: timeout, fixedCode: nil)
}
    
    
/// Enforce an access code if the device is not protected with an access code.
/// - Parameters:
///   - codeOptions: The code options, see ``CodeOptions``.
///   - timeout: The timeout when the view should be locked based on the time the scene is not in the foreground.
///
/// > Warning: Not yet implemented
@available(*, unavailable, message: "Not yet implemented")
public func CodeIfUnprotectedAccessGuard( // swiftlint:disable:this identifier_name
    _ identifier: AccessGuardIdentifier,
    codeOptions: CodeOptions = .fourDigitNumeric,
    timeout: Duration = .minutes(5)
) -> AccessGuardConfiguration {
    AccessGuardConfiguration(identifier: identifier, guardType: .codeIfUnprotected, codeOptions: codeOptions, timeout: timeout, fixedCode: nil)
}
