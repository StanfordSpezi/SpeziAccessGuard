//
// This source file is part of the Spezi open source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

private import Foundation
private import LocalAuthentication
public import SpeziFoundation
public import SwiftUI


/// An Access Guard that is unlocked by via biometrics (Face ID).
///
/// - Important: In order to use biometric (Face ID) access guards, you need to add the `NSFaceIDUsageDescription` key to your app's Info.plist.
///
/// ## Topics
///
/// ### Initializers
/// - ``init(_:timeout:fallback:)``
///
/// ### Instance Properties
/// - ``id``
/// - ``timeout``
/// - ``fallback``
public struct BiometricAccessGuard: _AccessGuardConfig {
    public let id: AccessGuardIdentifier<Self>
    public let timeout: Duration
    public let fallback: CodeAccessGuard.Kind?
    
    /// Creates a Biometric Access Guard
    ///
    /// - parameter id: The access guard's identifier. Don't use the same identifier for multiple access guards.
    /// - parameter timeout: How long the access guard should remain unlocked after the app moves to the background.
    /// - parameter fallback: The ``CodeAccessGuard`` to use in case biometrics are not available.
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
