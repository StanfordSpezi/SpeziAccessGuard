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

    
    var body: some View {
        if viewModel.locked {
            EnterCodeView(viewModel: viewModel)
                .onAppear {
                    if viewModel.configuration.guardType == .biometrics {
                        Task {
                            try? await viewModel.authenticateWithBiometrics()
                        }
                    }
                }
                .ignoresSafeArea(.container)
        } else {
            guardedView
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
