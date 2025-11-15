//
// This source file is part of the Spezi open source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import SpeziKeychainStorage
import SwiftUI


/// Allows a user to set a code for an Access Guard.
public struct SetAccessGuard: View {
    @Environment(AccessGuard.self) private var accessGuard
    
    private let identifier: AccessGuardIdentifier<CodeAccessGuard>
    private let onSuccess: @MainActor () -> Void
    
    public var body: some View {
        SetupPasscodeFlow(model: accessGuard.model(for: identifier)) {
            onSuccess()
        }
    }
    
    /// - Parameters:
    ///   - identifier: The identifier of the access guard configuration that should be used to guard this view.
    ///   - action: An action that should be performed once the password has been set.
    public init(
        identifier: AccessGuardIdentifier<CodeAccessGuard>,
        onSuccess: @escaping @MainActor () -> Void = {}
    ) {
        self.identifier = identifier
        self.onSuccess = onSuccess
    }
}
