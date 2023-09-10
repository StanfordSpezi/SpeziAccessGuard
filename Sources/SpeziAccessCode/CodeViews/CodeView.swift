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
    private let codeOption: CodeOptions
    private let action: (String) async throws -> ()
    @State private var code: String = ""
    @FocusState private var focused: Bool
    @State private var viewState: ViewState = .idle
    @State private var wrongCodeCounter: Int = 0
    
    
    
    
    var body: some View {
        SecureField("", text: $code)
            .textContentType(.password)
            .keyboardType(codeOption.keyBoardType)
            .textFieldStyle(.roundedBorder)
            .focused($focused)
            .disabled(viewState == .processing)
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
            .onAppear {
                focused = true
            }
            .onChange(of: code) { newCode in
                if code.count >= codeOption.maxLength {
                    Task { @MainActor in
                        await checkCode()
                    }
                }
            }
    }
    
    
    init(codeOption: CodeOptions, action: @escaping (String) async throws -> ()) {
        self.codeOption = codeOption
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
        
        try? await Task.sleep(for: .seconds(0.1))
        focused = true
    }
}


struct AuthenticationView_Previews: PreviewProvider {
    static var previews: some View {
        CodeView(codeOption: .fourDigitNumeric) { code in
            try await Task.sleep(for: .seconds(1))
        }
        .padding(.horizontal)
    }
}

