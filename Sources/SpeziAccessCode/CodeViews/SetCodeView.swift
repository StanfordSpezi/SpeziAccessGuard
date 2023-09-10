//
// This source file is part of the Spezi open source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import SwiftUI


struct SetCodeView: View {
    enum SetCodeState {
        case setCode
        case repeatCode
        case success
    }
    
    @ObservedObject var viewModel: AccessGuardViewModel
    @State private var selectedCode: CodeOptions = .fourDigitNumeric
    @State private var firstCode: String = ""
    @State private var state: SetCodeState = .setCode
    @State private var errorMessage: String?
    
    
    var body: some View {
        ZStack {
            Color(uiColor: .systemBackground)
            VStack(spacing: 32) {
                switch state {
                case .setCode:
                    Group {
                        Text("SET_PASSCODE_PROMPT", bundle: .module)
                            .font(.title2)
                            .frame(maxWidth: .infinity)
                        CodeView(codeOption: $selectedCode) { code in
                            firstCode = code
                            withAnimation {
                                state = .repeatCode
                            }
                        }
                        Menu(selectedCode.description.localizedString()) {
                            ForEach(CodeOptions.allCases) { codeOption in
                                Button(codeOption.description.localizedString()) {
                                    selectedCode = codeOption
                                }
                            }
                        }
                            .frame(height: 60)
                    }
                        .transition(.navigate)
                case .repeatCode:
                    Group {
                        Text("SET_PASSCODE_REPEAT_PROMPT", bundle: .module)
                            .font(.title2)
                            .frame(maxWidth: .infinity)
                        CodeView(codeOption: $selectedCode) { code in
                            if code == firstCode {
                                do {
                                    try viewModel.setAccessCode(code, codeOption: selectedCode)
                                    errorMessage = nil
                                    withAnimation {
                                        state = .success
                                    }
                                } catch let error as AccessGuardError {
                                    errorMessage = error.failureReason
                                }
                            } else {
                                errorMessage = String(localized: "SET_PASSCODE_REPEAT_NOT_EQUAL", bundle: .module)
                            }
                        }
                        ErrorMessageCapsule(errorMessage: $errorMessage)
                            .frame(height: 60)
                    }
                        .transition(.navigate)
                case .success:
                    Image(systemName: "checkmark.circle.fill")
                        .resizable()
                        .aspectRatio(1.0, contentMode: .fit)
                        .frame(height: 100)
                        .foregroundStyle(.green)
                        .transition(.navigate)
                }
            }
                .toolbar {
                    if state == .repeatCode {
                        ToolbarItem(placement: .cancellationAction) {
                            Button(
                                action: {
                                    withAnimation {
                                        state = .setCode
                                        firstCode = ""
                                        errorMessage = nil
                                    }
                                }, label: {
                                    Text("SET_PASSCODE_BACK_BUTTON", bundle: .module)
                                }
                            )
                        }
                    }
                }
                .navigationBarBackButtonHidden(state == .repeatCode)
                .padding(.horizontal)
        }
    }
}
