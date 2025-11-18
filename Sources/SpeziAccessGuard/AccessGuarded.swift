//
// This source file is part of the Spezi open source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

public import SwiftUI


/// A view that guards the access to a view.
///
/// > Important: You will need to register the ``AccessGuard`` module in your Spezi using the [`configuration`](https://swiftpackageindex.com/stanfordspezi/spezi/documentation/spezi/speziappdelegate/configuration)
/// in a [`SpeziAppDelegate`](https://swiftpackageindex.com/stanfordspezi/spezi/documentation/spezi/speziappdelegate) as detailed in the ``AccessGuard`` documentation.
///
/// ```swift
/// AccessGuarded(identifier: .accessGuardIdentifier) {
///     Text("Secured View")
/// }
/// ```
///
/// > Tip: You can allow a user to set the passcode using the ``SetAccessGuard`` view.
public struct AccessGuarded<GuardedView: View, Config: _AccessGuardConfig>: View {
    @AccessGuard<Config> private var accessGuard: Config._Model
    private let guarded: @MainActor () -> GuardedView
    
    public var body: some View {
        AccessGuardView(
            config: accessGuard.config,
            model: accessGuard,
            guarded: guarded
        )
    }
    
    
    /// - Parameters:
    ///   - identifier: The identifier of the access guard configuration that should be used to guard this view.
    ///   - guarded: The guarded view.
    public init(
        _ identifier: AccessGuardIdentifier<Config>,
        @ViewBuilder guarded: @escaping @MainActor () -> GuardedView
    ) {
//        self.identifier = identifier
        _accessGuard = .init(identifier)
        self.guarded = guarded
    }
}


#if DEBUG
#Preview {
    let identifier = AccessGuardIdentifier.passcode("edu.stanford.spezi.myView")
    AccessGuarded(identifier) {
        Text("Super secret stuff 🤫")
    }
}
#endif
