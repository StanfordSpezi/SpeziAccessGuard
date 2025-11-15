//
// This source file is part of the Spezi open source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Foundation
import LocalAuthentication
import SpeziFoundation
import SwiftUI


public struct BiometricAccessGuard: _AccessGuardConfigurationProtocol {
    public let id: AccessGuardIdentifier<Self>
    public let timeout: Duration
    public let fallback: CodeAccessGuard.Kind?
    
    /// Creates a Biometric Access Guard
    public init(
        _ id: AccessGuardIdentifier<Self>,
        timeout: Duration = .minutes(5),
        fallback: CodeAccessGuard.Kind = .regular(format: .alphanumeric(6))
    ) {
        self.id = id
        self.timeout = timeout
        self.fallback = fallback
    }
    
    @_spi(Internal)
    public func _makeUnlockView(model: _BiometricAccessGuardModel) -> some View { // swiftlint:disable:this identifier_name
        if model.isAvailable {
            BiometricsUnlockView(model: model)
        } else if let fallback = model.fallback {
            fallback.config._makeUnlockView(model: fallback)
        } else {
            Text("Biometric")
        }
    }
}


private struct BiometricsUnlockView: View {
    //    let didUnlock: @MainActor () -> Void
    var model: _BiometricAccessGuardModel
    private let context = LAContext()
    
    @State private var state: Result<Bool, any Error>?
    
    var body: some View {
        VStack {
            switch state {
            case nil: // currently running
                Text("Unlock via Face ID")
                    .onAppear {
                        unlock()
                    }
            case .success(true):
                // won't actually be seen (for long) bc the unlock will be completed...
                Text("Successfully Unlocked")
            case .success(false):
                Text("Biometric Unlock Failed")
                Button("Retry") {
                    unlock()
                }
            case .failure(let error):
                Text("Error: \(String(describing: error))")
                Button("Retry") {
                    unlock()
                }
            }
        }
    }
    
    private func unlock() {
        state = nil
        Task {
            do {
                state = .success(try await model.unlock())
            } catch {
                state = .failure(error)
            }
        }
    }
}
