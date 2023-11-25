//
// This source file is part of the Spezi open source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Spezi
import SwiftUI


struct AccessGuardView<GuardedView: View>: View {
    private let guardedView: GuardedView
    private let viewModel: AccessGuardViewModel

    @MainActor
    private var shouldEnterCode: Bool {
        !(viewModel.configuration.guardType == .codeIfUnprotected && viewModel.deviceIsProtected)
    }

    @MainActor
    private var shouldAttemptBiometricAuthentication: Bool {
        viewModel.configuration.guardType == .biometrics && !shouldEnterCode
    }

    var body: some View {
        guardedView
            .overlay {
                if viewModel.locked && shouldEnterCode {
                    EnterCodeView(viewModel: viewModel)
                        .ignoresSafeArea(.container)
                }
            }
            .onAppear {
                if viewModel.locked && shouldAttemptBiometricAuthentication {
                    Task {
                        try? await viewModel.authenticateWithBiometrics()
                    }
                }
            }
    }
    
    
    init(
        viewModel: AccessGuardViewModel,
        guardedView: GuardedView
    ) {
        self.guardedView = guardedView
        self.viewModel = viewModel
    }
}
