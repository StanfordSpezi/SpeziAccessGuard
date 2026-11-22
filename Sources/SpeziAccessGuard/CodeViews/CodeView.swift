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
    @State private var invalidCharacterMessage: LocalizedStringResource?
    @State private var dismissTask: Task<Void, Never>?
    
    var body: some View {
        VStack(spacing: 8) {
            SecureField(String(), text: $code)
                .textContentType(.password)
                .keyboardType(codeFormat.keyboardType)
                .textFieldStyle(.roundedBorder)
                .focused($focused)
                .disabled(viewState == .processing)
                .accessibilityLabel(Text("PASSCODE_FIELD", bundle: .module))
                .overlay {
                    codeIndicator
                        .onTapGesture {
                            focused = true
                        }
                }
                .onAppear {
                    focused = true
                }
                .onChange(of: code) {
                    codeDidChange()
                }
            if let invalidCharacterMessage {
                ErrorMessageCapsule(errorMessage: invalidCharacterMessage)
                    .accessibilityIdentifier("invalidCharacterMessage")
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut, value: invalidCharacterMessage)
        .onDisappear {
            dismissTask?.cancel()
            dismissTask = nil
        }
    }
    
    private var codeIndicator: some View {
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
    }
    
    init(codeFormat: PasscodeFormat, action: @escaping @MainActor (String) async throws -> Void) {
        self.codeFormat = codeFormat
        self.action = action
    }
    
    private func codeDidChange() {
        let filtered = codeFormat.filteringInvalidCharacters(from: code)
        if filtered != code {
            code = filtered
            invalidCharacterMessage = codeFormat.invalidCharacterMessage
            dismissTask?.cancel()
            dismissTask = Task { @MainActor in
                try? await Task.sleep(for: .seconds(2))
                guard !Task.isCancelled else {
                    return
                }
                invalidCharacterMessage = nil
            }
            return
        }
        if codeFormat.validate(code: filtered) {
            Task { @MainActor in
                await checkCode()
            }
        }
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
