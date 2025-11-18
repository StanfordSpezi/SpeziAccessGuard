//
// This source file is part of the Spezi open source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

public import SwiftUI


/// Allows a user to set a code for an Access Guard.
public struct SetAccessGuard: View {
    @AccessGuard<CodeAccessGuard> private var accessGuard: CodeAccessGuard._Model
    private let onSuccess: @MainActor () -> Void
    
    public var body: some View {
        SetupPasscodeFlow(model: accessGuard) {
            onSuccess()
        }
    }
    
    /// - Parameters:
    ///   - identifier: The identifier of the access guard configuration that should be used to guard this view.
    ///   - onSuccess: An action that should be performed once the password has been set.
    public init(
        _ identifier: AccessGuardIdentifier<CodeAccessGuard>,
        onSuccess: @escaping @MainActor () -> Void = {}
    ) {
        _accessGuard = .init(identifier)
        self.onSuccess = onSuccess
    }
}
