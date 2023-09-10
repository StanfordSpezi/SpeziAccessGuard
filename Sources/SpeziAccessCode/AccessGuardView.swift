//
// This source file is part of the Spezi open source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Spezi
import SwiftUI


public struct AccessGuardView<GuardedView: View>: View {
    private let guardedView: GuardedView
    @StateObject private var viewModel: AccessGuardViewModel
    
    
    public var body: some View {
        guardedView
            .overlay {
                if viewModel.locked {
                    EnterCodeView(viewModel: viewModel)
                        .ignoresSafeArea(.container)
                }
            }
    }
    
    
    init(
        viewModel: AccessGuardViewModel,
        guardedView: GuardedView
    ) {
        self.guardedView = guardedView
        self._viewModel = StateObject(wrappedValue: viewModel)
    }
}
