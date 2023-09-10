//
// This source file is part of the Spezi open source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import SpeziSecureStorage
import SwiftUI


public struct SetAccessGuard: View {
    @EnvironmentObject private var accessGuard: AccessGuard
    
    private let identifier: AccessGuardConfiguration.Identifier
    private let action: @MainActor () async -> Void
    
    
    public var body: some View {
        SetCodeView(viewModel: accessGuard.viewModel(for: identifier), action: action)
    }
    
    
    /// - Parameters:
    ///   - identifier: The identifier of the access guard configuration that should be used to guard this view.
    ///   - action: An action that should be performed once the password has been set.
    public init(
        identifier: AccessGuardConfiguration.Identifier,
        action: (@MainActor () async -> Void)? = nil
    ) {
        self.identifier = identifier
        self.action = action ?? {}
    }
}
