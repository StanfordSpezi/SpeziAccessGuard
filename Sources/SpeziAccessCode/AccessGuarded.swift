//
// This source file is part of the Spezi open source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import SpeziSecureStorage
import SwiftUI


/// A view that guards the access to a view.
///
/// ```swift
/// AccessGuarded {
///     Text("Secured View")
/// }
/// ```
///
/// The view can be configured using the ``AccessGuardConfiguration``, the default configuration enables a code or biometrics authentication.
/// ```swift
/// AccessGuarded(.code) {
///     Text("Secured View")
/// }
/// ```
public struct AccessGuarded<GuardedView: View>: View {
    @EnvironmentObject private var accessGuard: AccessGuard
    
    private let configuration: AccessGuardConfiguration
    private let identifier: String
    private let fixedCode: String?
    private let guardedView: GuardedView
    
    
    public var body: some View {
        AccessGuardView(
            viewModel: accessGuard.viewModel(
                for: identifier,
                fixedCode: fixedCode,
                configuration: configuration
            ),
            guardedView: guardedView
        )
    }
    
    
    /// - Parameters:
    ///   - configuration: The access code configuration that defines the behaviour of the view. See ``AccessGuardConfiguration`` for more information.
    ///   - identifier: The identifier of the credentials that should be used to guard this view.
    ///   - guarded: The guarded view.
    public init(
        configuration: AccessGuardConfiguration = .code,
        identifier: String? = nil,
        @ViewBuilder guarded guardedView: () -> GuardedView
    ) {
        self.configuration = configuration
        self.identifier = identifier ?? String(describing: GuardedView.self)
        self.fixedCode = nil
        self.guardedView = guardedView()
    }
    
    /// Create a ``AccessGuarded`` view that is protected by a fixed code.
    ///
    /// We generally advise not to use fixed codes, applications should use ``init(configuration:identifier:guarded:)``.
    /// - Parameters:
    ///   - codeOption: The code options, see ``CodeOptions``.
    ///   - timeout: The timeout when the view should be locked based on the time the scene is not in the foreground.
    ///   - fixedCode: The identifier of the credentials that should be used to guard this view.
    ///   - guarded: The guarded view.
    public init(
        codeOption: CodeOptions = AccessGuardConfiguration.Defaults.codeOptions,
        timeout: TimeInterval = AccessGuardConfiguration.Defaults.timeout,
        fixedCode: String,
        @ViewBuilder guarded guardedView: () -> GuardedView
    ) {
        precondition(
            codeOption.verifyStructore(ofCode: fixedCode),
            "The provided fixed code \"\(fixedCode)\" must conform to the \(codeOption.description) code option."
        )
        
        self.configuration = AccessGuardConfiguration(
            guardType: .code,
            codeOptions: codeOption,
            timeout: timeout
        )
        self.identifier = String(describing: GuardedView.self)
        self.fixedCode = fixedCode
        self.guardedView = guardedView()
    }
}


struct AccessCodeGuard_Previews: PreviewProvider {
    static var previews: some View {
        AccessGuarded {
            Text("Guarded View")
        }
    }
}
