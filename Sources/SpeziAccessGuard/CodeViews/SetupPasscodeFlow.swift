//
// This source file is part of the Spezi open source project
//
// SPDX-FileCopyrightText: 2025 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import SwiftUI


struct SetupPasscodeFlow: View {
    private enum Step: Hashable {
        case setCode
        case repeatCode(expectedCode: String)
        case done
    }
    
    private var model: _PasscodeAccessGuardModel
    private let onSuccess: @MainActor () -> Void
    @State private var step: Step = .setCode
    
    var body: some View {
        switch step {
        case .setCode, .repeatCode:
            EnterCodeView(
                format: model.config.format,
                title: { () -> LocalizedStringResource? in
                    switch step {
                    case .setCode:
                        LocalizedStringResource("Set Code", bundle: .module)
                    case .repeatCode:
                        LocalizedStringResource("Repeat Code", bundle: .module)
                    case .done:
                        nil
                    }
                }()
            ) { code in
                switch step {
                case .setCode:
                    // if we're setting the code we always accept it
                    withAnimation {
                        step = .repeatCode(expectedCode: code)
                    }
                    return .valid
                case .repeatCode(let expectedCode):
                    guard code == expectedCode else {
                        return .invalid(
                            message: LocalizedStringResource("SET_PASSCODE_REPEAT_NOT_EQUAL", bundle: .module)
                        )
                    }
                    try? model.resetCode(newCode: code)
                    step = .done
                    onSuccess()
                    return .valid
                case .done:
                    return .valid // unreachable
                }
            }
            switch step {
            case .repeatCode:
                Button {
                    step = .setCode
                } label: {
                    Text("SET_PASSCODE_BACK_BUTTON", bundle: .module)
                }
            case .setCode, .done:
                EmptyView()
            }
        case .done:
            Image(systemName: "checkmark.circle.fill")
                .resizable()
                .aspectRatio(1.0, contentMode: .fit)
                .frame(height: 100)
                .foregroundStyle(.green)
                .transition(.slide)
                .accessibilityLabel(Text("PASSCODE_SET_SUCCESS", bundle: .module))
        }
    }
    
    init(model: _PasscodeAccessGuardModel, onSuccess: @escaping @MainActor () -> Void = {}) {
        self.model = model
        self.onSuccess = onSuccess
    }
}
