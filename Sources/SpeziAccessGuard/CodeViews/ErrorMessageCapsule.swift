//
// This source file is part of the Spezi open source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import SwiftUI


struct ErrorMessageCapsule: View {
    @Binding private var errorMessage: String?
    
    
    var body: some View {
        Group {
            if let errorMessage {
                Text(errorMessage)
                    .foregroundStyle(.white)
                    .padding(.horizontal)
                    .padding(.vertical, 4)
                    .background {
                        RoundedRectangle(cornerRadius: 25)
                            .foregroundStyle(.red)
                    }
            } else {
                Rectangle()
                    .foregroundStyle(.clear)
            }
        }
            .frame(height: 40)
    }
    
    
    init(errorMessage: Binding<String?>) {
        self._errorMessage = errorMessage
    }
}
