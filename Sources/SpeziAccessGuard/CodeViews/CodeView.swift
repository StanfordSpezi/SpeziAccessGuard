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
    let codeFormat: PasscodeFormat
    private let action: @MainActor (String) async throws -> Void
    @State private var code: String = ""
    @FocusState private var focused: Bool
    @State private var viewState: ViewState = .idle
    
    var body: some View {
        SecureField(String(), text: $code)
            .textContentType(.password)
            .keyboardType(codeFormat.keyboardType)
            .textFieldStyle(.roundedBorder)
            .focused($focused)
            .disabled(viewState == .processing)
            .accessibilityLabel(Text("PASSCODE_FIELD", bundle: .module))
            .overlay {
                ZStack {
                    switch codeFormat.length {
                    case .exact(let length), .atLeast(let length):
                        Color(UIColor.systemBackground)
                        HStack(spacing: 24) {
                            ForEach(0..<length, id: \.self) { index in
                                if code.count <= index {
                                    Image(systemName: "circle")
                                        .accessibilityHidden(true)
                                } else {
                                    Image(systemName: "circle.fill")
                                        .accessibilityHidden(true)
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
            }
            .onChange(of: code) {
                if codeFormat.validate(code: code) {
                    Task { @MainActor in
                        await checkCode()
                    }
                }
            }
    }
    
    init(codeFormat: PasscodeFormat, action: @escaping @MainActor (String) async throws -> Void) {
        self.codeFormat = codeFormat
        self.action = action
    }
    
    private func checkCode() async {
        focused = false
        viewState = .processing
        try? await action(code)
        code = ""
        viewState = .idle
        try? await Task.sleep(for: .seconds(0.05))
        focused = true
    }
}


#Preview {
    CodeView(codeFormat: .numeric(4)) { _ in
        try await Task.sleep(for: .seconds(1))
    }
    .padding(.horizontal)
}
