//
// This source file is part of the Spezi open source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import SwiftUI


struct ErrorMessageCapsule: View {
    let errorMessage: LocalizedStringResource
    
    var body: some View {
        Text(errorMessage)
            .foregroundStyle(.white)
            .padding(.horizontal)
            .padding(.vertical, 4)
            .background {
                RoundedRectangle(cornerRadius: 25)
                    .foregroundStyle(.red)
            }
            .frame(height: 40)
    }
}
