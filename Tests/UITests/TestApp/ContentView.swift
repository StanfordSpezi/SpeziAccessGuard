//
// This source file is part of the Spezi open source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

// swiftlint:disable closure_body_length

import SpeziAccessGuard
import SwiftUI


struct ContentView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AccessGuards.self) private var accessGuards
    
    private let allIdentifiers: [any _AnyAccessGuardIdentifier] = [
        AccessGuardIdentifier.test,
        AccessGuardIdentifier.testFixed,
        AccessGuardIdentifier.testBiometrics
    ]
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    actions
                }
                Section {
                    NavigationLink("Access Guarded") {
                        AccessGuarded(.test) {
                            Color.green.overlay {
                                Text("Secured ...")
                            }
                        }
                    }
                    NavigationLink("Access Guarded Fixed") {
                        AccessGuarded(.testFixed) {
                            Color.green.overlay {
                                Text("Secured with fixed code ...")
                            }
                        }
                    }
                    NavigationLink("Access Guarded Biometrics") {
                        AccessGuarded(.testBiometrics) {
                            Color.green.overlay {
                                Text("Secured with biometrics ...")
                            }
                        }
                    }
                    NavigationLink("Set Code") {
                        SetAccessGuard(.test)
                    }
                    NavigationLink("Set Biometric Backup Code") {
                        SetAccessGuard(AccessGuardIdentifier.testBiometrics.passcodeFallback)
                    }
                    NavigationLink("Access Guard Button") {
                        AccessGuardButton(.testFixed) {
                            Text("Unlock me")
                        } unlocked: {
                            Text("Success")
                        }
                    }
                    NavigationLink("Consumable Codes") {
                        ConsumableCodesView()
                    }
                }
            }
        }
    }
    
    @ViewBuilder private var actions: some View {
        Button("Lock Access Guards") {
            for identifier in allIdentifiers {
                accessGuards.lock(identifier)
            }
        }
        Button("Reset Access Guards") {
            for identifier in allIdentifiers {
                try? accessGuards.resetAccessCode(for: identifier)
            }
        }
    }
}
