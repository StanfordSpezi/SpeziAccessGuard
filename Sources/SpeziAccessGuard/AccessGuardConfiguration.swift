//
// This source file is part of the Spezi open source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Foundation
import SpeziViews


/// Configures the behaviour of the ``AccessGuard`` view.
public struct AccessGuardConfiguration {
   public typealias Identifier = String
    
    public enum Defaults {
        public static let codeOptions: CodeOptions = .fourDigitNumeric
        public static let timeout: TimeInterval = 5 * 60
    }
    
    
    let identifier: Identifier
    let guardType: GuardType
    let codeOptions: CodeOptions
    let timeout: TimeInterval
    let fixedCode: String?
    
    
    init(
        identifier: Identifier,
        guardType: GuardType,
        codeOptions: CodeOptions,
        timeout: TimeInterval,
        fixedCode: String? = nil
    ) {
        self.identifier = identifier
        self.guardType = guardType
        self.codeOptions = codeOptions
        self.timeout = timeout
        self.fixedCode = fixedCode
    }
    
    
    /// Enforce an access code if the device is not protected with an access code.
    /// - Parameters:
    ///   - codeOptions: The code options, see ``CodeOptions``.
    ///   - timeout: The timeout when the view should be locked based on the time the scene is not in the foreground.
    ///
    /// > Warning: Not yet implemented
    private static func codeIfUnprotected(
        identifier: Identifier,
        codeOptions: CodeOptions = Defaults.codeOptions,
        timeout: TimeInterval = Defaults.timeout
    ) -> AccessGuardConfiguration {
        AccessGuardConfiguration(identifier: identifier, guardType: .codeIfUnprotected, codeOptions: codeOptions, timeout: timeout)
    }
    
    /// Enforce an access code.
    /// - Parameters:
    ///   - codeOptions: The code options, see ``CodeOptions``.
    ///   - timeout: The timeout when the view should be locked based on the time the scene is not in the foreground.
    public static func  code(
        identifier: Identifier,
        codeOptions: CodeOptions = .fourDigitNumeric,
        timeout: TimeInterval = Defaults.timeout
    ) -> AccessGuardConfiguration {
        AccessGuardConfiguration(identifier: identifier, guardType: .code, codeOptions: codeOptions, timeout: timeout)
    }
    
    /// Enforce a fixed access code.
    /// - Parameters:
    ///   - code: The fixed access code.
    ///   - codeOptions: The code options, see ``CodeOptions``.
    ///   - timeout: The timeout when the view should be locked based on the time the scene is not in the foreground.
    public static func fixed(
        identifier: Identifier,
        code: String,
        codeOptions: CodeOptions = .fourDigitNumeric,
        timeout: TimeInterval = Defaults.timeout
    ) -> AccessGuardConfiguration {
        AccessGuardConfiguration(identifier: identifier, guardType: .code, codeOptions: codeOptions, timeout: timeout, fixedCode: code)
    }
    
    /// Enforce an access code & biometrics authentication if setup on the device.
    /// - Parameters:
    ///   - codeOptions: The code options, see ``CodeOptions``.
    ///   - timeout: The timeout when the view should be locked based on the time the scene is not in the foreground.
    ///
    /// > Warning: Not yet implemented
    private static func  biometrics(
        identifier: Identifier,
        codeOptions: CodeOptions = .all,
        timeout: TimeInterval = Defaults.timeout
    ) -> AccessGuardConfiguration {
        AccessGuardConfiguration(identifier: identifier, guardType: .biometrics, codeOptions: codeOptions, timeout: timeout)
    }
}
