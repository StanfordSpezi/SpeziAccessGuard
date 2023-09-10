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
    
    private let configuration: AccessGuardConfiguration
    private let identifier: String
    
    
    public var body: some View {
        SetCodeView(
            viewModel: accessGuard.viewModel(
                for: identifier,
                configuration: configuration
            )
        )
    }
    
    
    /// - Parameters:
    ///   - configuration: The access code configuration that defines the behaviour of the view. See ``AccessGuardConfiguration`` for more information.
    ///   - identifier: The identifier of the credentials that should be used to guard this view.
    public init(
        configuration: AccessGuardConfiguration = .code,
        identifier: String
    ) {
        self.configuration = configuration
        self.identifier = identifier
    }
}
