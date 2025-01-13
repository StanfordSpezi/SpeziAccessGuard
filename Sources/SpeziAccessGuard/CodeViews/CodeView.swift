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
    private let action: (String, ValidationResult, Bool) async throws -> Void
    private var toolbarButtonLabel: String = ""
    @State private var code: String = ""
    @State private var formerCode: String = ""
    @State private var upstreamError: String = ""
    @FocusState private var focused: Bool
    @State private var viewState: ViewState = .idle
    @State private var wrongCodeCounter: Int = 0
    @State private var oldKeyBoardType: UIKeyboardType?
    
    
    var body: some View {
        SecureField(String(), text: $code)
            .textContentType(.password)
            .keyboardType(codeOption.keyBoardType)
            .textFieldStyle(.roundedBorder)
            .focused($focused)
            .disabled(viewState == .processing)
            .accessibilityLabel(Text("PASSCODE_FIELD", bundle: .module))
            .overlay {
                ZStack {
                    if codeOption.maxLength == 4 { // to do: change to type instead of length
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
            .onChange(of: code) {
                // skip the validation, becuase the code was reset due to a failed validation.
                if formerCode == code {
                    print("Skipping validation")
                    return
                }
                
                let validationRes = codeOption.continousValidation(ofCode: code)
                let autoSubmit = codeOption.shouldAutoSubmit(code)
                
                print("CodeView: Validation result: \(validationRes) AutoSubmit: \(autoSubmit)")
                
                switch validationRes {
                case .success:
                    Task { @MainActor in
                        do {
                            try await action(code, validationRes, autoSubmit)
                        } catch {
                        }
                    }
                    formerCode = code
                case .failure(let error):
                    print("code failed with error: \(error)")
                    Task { @MainActor in
                        try await action(code, validationRes, false)
                    }
                    code = formerCode
                    
                    print("Reset code to: \(code)")
                default:
                    formerCode = code
                }
            }
            .onChange(of: codeOption) {
                guard oldKeyBoardType != codeOption.keyBoardType else {
                    return
                }
                
                focused = false
                oldKeyBoardType = codeOption.keyBoardType
                
                Task { @MainActor in
                    try await Task.sleep(for: .seconds(0.05))
                    focused = true
                }
            }
            .toolbar {
                if codeOption.willAutoSubmit() {
                    ToolbarItem(placement: .primaryAction) {
                        Button(toolbarButtonLabel) {
                            let validationRes = codeOption.submissionValidation(ofCode: code)
                            focused=false
                            Task {
                                @MainActor in
                                do {
                                    try await action(code, validationRes, true)
                                } catch {
                                    code = ""
                                }
                            }
                            focused = true
                        }
                    }
                }
            }
    }
    
    
    init(codeOption: CodeOptions, toolbarButtonLabel: String, action: @escaping (String, ValidationResult, Bool ) async throws -> Void) {
        self._codeOption = .constant(codeOption)
        self.toolbarButtonLabel = toolbarButtonLabel
        self.action = action
    }
    
    init(codeOption: Binding<CodeOptions>, toolbarButtonLabel: String, action: @escaping (String, ValidationResult, Bool) async throws -> Void) {
        self._codeOption = codeOption
        self.toolbarButtonLabel = toolbarButtonLabel
        self.action = action
    }
    
    
    private func checkCode() async {
        focused = false
        viewState = .processing
        
        do {
            try await action(code, .success, true)
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
        CodeView(codeOption: .fourDigitNumeric, toolbarButtonLabel: String("")) { _,_,_ in
            try await Task.sleep(for: .seconds(1))
        }
        .padding(.horizontal)
    }
}
