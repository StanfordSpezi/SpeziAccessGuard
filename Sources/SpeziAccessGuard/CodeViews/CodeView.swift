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
    private let action: (String, CodeOptions.ValidationResult) async throws -> Void
    private let toolbarButtonLabel: String
    @State private var code: String = ""
    @State private var lastValidCode: String = ""
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
            .frame(height: 44)
            .overlay {
                ZStack {
                    if codeOption.isSubset(of: .finiteNumeric) {
                        Color(UIColor.systemBackground)
                        HStack(spacing: 48 - (Double(codeOption.maxLength) * 4)) {
                            ForEach(Array(0..<codeOption.maxLength), id: \.self) { index in
                                if code.count > index {
                                    Image(systemName: "circle.fill")
                                } else {
                                    Image(systemName: "circle")
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
                // Validation is skipped, when code was reset or modified after an error
                if lastValidCode == code || code.isEmpty {
                    lastValidCode = code
                    return
                }
                    
                let validationRes = codeOption.continousValidation(ofCode: code)
                
                Task { @MainActor in
                    do {
                        try await action(code, validationRes)
                    } catch {
                        code = ""
                    }
                }
                
                switch validationRes {
                case .failure:
                    code = lastValidCode
                default:
                    lastValidCode = code
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
                if !codeOption.willAutoSubmit {
                    ToolbarItem(placement: .primaryAction) {
                        Button(toolbarButtonLabel) {
                            let validationRes = codeOption.submissionValidation(ofCode: code)
                            Task {
                                @MainActor in
                                do {
                                    try await action(code, validationRes)
                                } catch {
                                    code = ""
                                }
                            }
                        }
                    }
                }
            }
    }
    
    
    init(
        codeOption: CodeOptions,
        toolbarButtonLabel: String,
        action: @escaping (String, CodeOptions.ValidationResult) async throws -> Void
    ) {
        self._codeOption = .constant(codeOption)
        self.toolbarButtonLabel = toolbarButtonLabel
        self.action = action
    }
    
    init(
        codeOption: Binding<CodeOptions>,
        toolbarButtonLabel: String,
        action: @escaping (String, CodeOptions.ValidationResult) async throws -> Void
    ) {
        self._codeOption = codeOption
        self.toolbarButtonLabel = toolbarButtonLabel
        self.action = action
    }
}


struct AuthenticationView_Previews: PreviewProvider {
    static var previews: some View {
        CodeView(codeOption: .fourDigitNumeric, toolbarButtonLabel: String("")) { _, _ in
            try await Task.sleep(for: .seconds(1))
        }
        .padding(.horizontal)
    }
}
