//
// This source file is part of the Spezi open source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import SwiftUI


struct EnterCodeView: View {
    @ObservedObject var viewModel: AccessGuardViewModel
    @State private var wrongCodeCounter: Int = 0
    @State private var errorMessage: String?
    
    
    var body: some View {
        ZStack {
            Color(uiColor: .systemBackground)
            VStack(spacing: 32) {
                Text("ACCESS_CODE_PASSCODE_PROMPT", bundle: .module)
                    .font(.title2)
                    .frame(maxWidth: .infinity)
                if let codeOption = viewModel.codeOption {
                    CodeView(codeOption: codeOption) { code in
                        do {
                            try viewModel.checkAccessCode(code)
                        } catch {
                            wrongCodeCounter += 1
                            errorMessage = String(localized: "ACCESS_CODE_PASSCODE_ERROR \(wrongCodeCounter)", bundle: .module)
                            throw error
                        }
                    }
                }
                ErrorMessageCapsule(errorMessage: $errorMessage)
            }
                .padding(.horizontal)
        }
    }
}
