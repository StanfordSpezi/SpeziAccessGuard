//
// This source file is part of the Spezi open source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import SpeziViews
import SwiftUI


struct CodeView: View {
    @Binding private var codeOption: CodeOptions
    private let action: (String) async throws -> Void
    @State private var code: String = ""
    @FocusState private var focused: Bool
    @State private var viewState: ViewState = .idle
    @State private var wrongCodeCounter: Int = 0
    @State private var oldKeyBoardType: UIKeyboardType?
    
    
    var body: some View {
        SecureField("", text: $code)
            .textContentType(.password)
            .keyboardType(codeOption.keyBoardType)
            .textFieldStyle(.roundedBorder)
            .focused($focused)
            .disabled(viewState == .processing)
            .accessibilityLabel(Text("PASSCODE_FIELD", bundle: .module))
            .overlay {
                ZStack {
                    if codeOption.maxLength == 4 {
                        Color(UIColor.systemBackground)
                        HStack(spacing: 32) {
                            ForEach(0..<4) { index in
                                if code.count <= index {
                                    Image(systemName: "circle")
                                } else {
                                    Image(systemName: "circle.fill")
                                }
                            }
                        }
                    } else if codeOption.maxLength == 6 {
                        Color(UIColor.systemBackground)
                        HStack(spacing: 24) {
                            ForEach(0..<6) { index in
                                if code.count <= index {
                                    Image(systemName: "circle")
                                } else {
                                    Image(systemName: "circle.fill")
                                }
                            }
                        }
                    }
                }
                .onTapGesture {
                    focused = true
                }
            }
            .task {
                focused = true
                oldKeyBoardType = codeOption.keyBoardType
            }
            .onChange(of: code) { _ in
                if code.count >= codeOption.maxLength {
                    Task { @MainActor in
                        await checkCode()
                    }
                }
            }
            .onChange(of: codeOption) { newCodeOption in
                guard oldKeyBoardType != newCodeOption.keyBoardType else {
                    return
                }
                
                focused = false
                oldKeyBoardType = newCodeOption.keyBoardType
                
                Task { @MainActor in
                    try await Task.sleep(for: .seconds(0.05))
                    focused = true
                }
            }
    }
    
    
    init(codeOption: CodeOptions, action: @escaping (String) async throws -> Void) {
        self._codeOption = .constant(codeOption)
        self.action = action
    }
    
    init(codeOption: Binding<CodeOptions>, action: @escaping (String) async throws -> Void) {
        self._codeOption = codeOption
        self.action = action
    }
    
    
    private func checkCode() async {
        focused = false
        viewState = .processing
        
        do {
            try await action(code)
        } catch {
            wrongCodeCounter += 1
            code = ""
        }
        
        viewState = .idle
        try? await Task.sleep(for: .seconds(0.05))
        focused = true
    }
}


struct AuthenticationView_Previews: PreviewProvider {
    static var previews: some View {
        CodeView(codeOption: .fourDigitNumeric) { _ in
            try await Task.sleep(for: .seconds(1))
        }
        .padding(.horizontal)
    }
}
