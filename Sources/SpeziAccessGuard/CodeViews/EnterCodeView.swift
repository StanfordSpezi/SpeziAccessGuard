//
// This source file is part of the Spezi open source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import SwiftUI


struct EnterCodeView<Header: View>: View {
    typealias EvaluateCode = @MainActor (_ code: String) async -> CodeAccessGuard.ValidationResult
    
    private struct ErrorMessage {
        let numFailedAttempts: Int
        let explainer: LocalizedStringResource?
    }
    
    private let codeFormat: PasscodeFormat
    private let header: Header
    private let evaluateCode: EvaluateCode
//    private let onCompletion: @MainActor (String) async -> Void
    @State private var numFailedAttempts: Int = 0
    @State private var errorMessage: ErrorMessage?
    
    var body: some View {
        ZStack {
            Color(uiColor: .systemBackground)
            VStack(spacing: 32) {
                header
                    .frame(maxWidth: .infinity)
                CodeView(codeFormat: codeFormat) { code in
                    switch await evaluateCode(code) {
                    case .valid:
                        // entered correct code; the parent view will take it from here
                        break
                    case .invalid(let message):
                        numFailedAttempts += 1
                        errorMessage = .init(numFailedAttempts: numFailedAttempts, explainer: message)
                    }
                }
                if let errorMessage {
                    VStack {
                        ErrorMessageCapsule(
                            errorMessage: LocalizedStringResource("\(errorMessage.numFailedAttempts) Failed Attempts", bundle: .module)
                        )
                        if let explainer = errorMessage.explainer {
                            Text(explainer)
                                .font(.callout)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                        }
                    }
                }
            }
            .padding(.horizontal)
        }
    }
    
    init(
        format: PasscodeFormat,
        @ViewBuilder header: () -> Header,
        evaluateCode: @escaping EvaluateCode,
//        onCompletion: @escaping @MainActor (String) async -> Void
    ) {
        self.codeFormat = format
        self.header = header()
        self.evaluateCode = evaluateCode
//        self.onCompletion = onCompletion
    }
    
//    init(
//        format: PasscodeFormat,
//        evaluateCode: @escaping EvaluateCode,
////        onCompletion: @escaping @MainActor (String) async -> Void
//    ) where Header == Text {
//        self.init(
//            format: format,
//            title: LocalizedStringResource("ACCESS_CODE_PASSCODE_PROMPT", bundle: .module),
//            evaluateCode: evaluateCode,
////            onCompletion: onCompletion
//        )
//    }
    
    init(
        format: PasscodeFormat,
        title: LocalizedStringResource? = nil,
        evaluateCode: @escaping EvaluateCode,
//        onCompletion: @escaping @MainActor (String) async -> Void
    ) where Header == Text {
        self.init(
            format: format,
            header: {
                Text(title ?? LocalizedStringResource("Enter Passcode", bundle: .module))
                    .font(.title2)
            },
            evaluateCode: evaluateCode,
//            onCompletion: onCompletion
        )
    }
}


#Preview {
    EnterCodeView(format: .numeric(4), title: "Enter PIN") { code in
        if code == "1234" {
            return .valid
        } else {
            switch code.count {
            case ..<4:
                return .invalid(message: "too short")
            case 4:
                return .invalid(message: "WRONG")
            default:
                return .invalid(message: "too long")
            }
        }
    }
}
