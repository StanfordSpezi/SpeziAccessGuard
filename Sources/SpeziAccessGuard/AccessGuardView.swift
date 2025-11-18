//
// This source file is part of the Spezi open source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Spezi
import SwiftUI


struct AccessGuardView<Guarded: View, Config: _AccessGuardConfig>: View {
    let config: Config
    var model: Config._Model
    let guarded: @MainActor () -> Guarded
    
    var body: some View {
        if model.isLocked {
            config._makeUnlockView(model: model)
                .ignoresSafeArea(.container)
        } else {
            guarded()
        }
    }
}
