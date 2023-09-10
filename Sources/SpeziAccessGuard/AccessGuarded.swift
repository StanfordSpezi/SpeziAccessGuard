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
/// AccessGuarded(identifier: "MyAccessGuardIdentifier") {
///     Text("Secured View")
/// }
/// ```
public struct AccessGuarded<GuardedView: View>: View {
    @EnvironmentObject private var accessGuard: AccessGuard
    
    private let identifier: AccessGuardConfiguration.Identifier
    private let guardedView: GuardedView
    
    
    public var body: some View {
        AccessGuardView(
            viewModel: accessGuard.viewModel(for: identifier),
            guardedView: guardedView
        )
    }
    
    
    /// - Parameters:
    ///   - identifier: The identifier of the access guard configuration that should be used to guard this view.
    ///   - guarded: The guarded view.
    public init(
        _ identifier: AccessGuardConfiguration.Identifier,
        @ViewBuilder guarded guardedView: () -> GuardedView
    ) {
        self.identifier = identifier
        self.guardedView = guardedView()
    }
}


struct AccessCodeGuard_Previews: PreviewProvider {
    static var previews: some View {
        AccessGuarded("MyGuardedView") {
            Text("Guarded View")
        }
    }
}
