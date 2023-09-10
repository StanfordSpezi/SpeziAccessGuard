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
    public enum Defaults {
        public static let codeOptions: CodeOptions = .fourDigitNumeric
        public static let timeout: TimeInterval = 5 * 60
    }
    
    
    let guardType: GuardType
    let codeOptions: CodeOptions
    let timeout: TimeInterval
    
    
    /// Enforce a code if the device is not protected with an access code.
    ///
    /// > Warning: Not yet implemented
    private static var codeIfUnprotected: AccessGuardConfiguration {
        codeIfUnprotected()
    }
    
    /// Enforce a code.
    public static var code: AccessGuardConfiguration {
        code()
    }
    
    /// Enforce a code & biometrics authentication if setup on the device.
    ///
    /// > Warning: Not yet implemented
    private static var biometrics: AccessGuardConfiguration {
        biometrics()
    }
    
    
    init(
        guardType: GuardType,
        codeOptions: CodeOptions,
        timeout: TimeInterval
    ) {
        self.guardType = guardType
        self.codeOptions = codeOptions
        self.timeout = timeout
    }
    
    
    /// Enforce a code if the device is not protected with an access code.
    /// - Parameters:
    ///   - codeOptions: The code options, see ``CodeOptions``.
    ///   - timeout: The timeout when the view should be locked based on the time the scene is not in the foreground.
    ///
    /// > Warning: Not yet implemented
    private static func codeIfUnprotected(
        codeOptions: CodeOptions = Defaults.codeOptions,
        timeout: TimeInterval = Defaults.timeout
    ) -> AccessGuardConfiguration {
        AccessGuardConfiguration(guardType: .codeIfUnprotected, codeOptions: codeOptions, timeout: timeout)
    }
    
    /// Enforce a code.
    /// - Parameters:
    ///   - codeOptions: The code options, see ``CodeOptions``.
    ///   - timeout: The timeout when the view should be locked based on the time the scene is not in the foreground.
    public static func  code(
        codeOptions: CodeOptions = .fourDigitNumeric,
        timeout: TimeInterval = Defaults.timeout
    ) -> AccessGuardConfiguration {
        AccessGuardConfiguration(guardType: .code, codeOptions: codeOptions, timeout: timeout)
    }
    
    /// Enforce a code & biometrics authentication if setup on the device.
    /// - Parameters:
    ///   - codeOptions: The code options, see ``CodeOptions``.
    ///   - timeout: The timeout when the view should be locked based on the time the scene is not in the foreground.
    ///
    /// > Warning: Not yet implemented
    private static func  biometrics(
        codeOptions: CodeOptions = .all,
        timeout: TimeInterval = Defaults.timeout
    ) -> AccessGuardConfiguration {
        AccessGuardConfiguration(guardType: .biometrics, codeOptions: codeOptions, timeout: timeout)
    }
}
