//
// This source file is part of the Spezi open source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import SpeziAccessGuard
import SwiftUI


struct ContentView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AccessGuard.self) private var accessGuard

    // swiftlint:disable closure_body_length
    var body: some View {
        NavigationStack {
            List {
                NavigationLink("Access Guarded") {
                    AccessGuarded("TestIdentifier") {
                        Color.green
                            .overlay {
                                Text("Secured ...")
                            }
                    }
                }
                NavigationLink("Access Guarded Fixed") {
                    AccessGuarded("TestFixedIdentifier") {
                        Color.green
                            .overlay {
                                Text("Secured with fixed code ...")
                            }
                    }
                }
                NavigationLink("Access Guarded Biometrics") {
                    AccessGuarded("TestBiometricsIdentifier") {
                        Color.green
                            .overlay {
                                Text("Secured with biometrics ...")
                            }
                    }
                }
                NavigationLink("Access Guarded If Unprotected") {
                    AccessGuarded("TestCodeIfUnprotectedIdentifier") {
                        Color.green
                            .overlay {
                                Text("Secured with code only if unprotected ...")
                            }
                    }
                }
                NavigationLink("Set Code") {
                    SetAccessGuard(identifier: "TestIdentifier")
                }
                NavigationLink("Set Code If Unprotected") {
                    SetAccessGuard(identifier: "TestCodeIfUnprotectedIdentifier")
                }
                NavigationLink("Set Biometric Backup Code") {
                    SetAccessGuard(identifier: "TestBiometricsIdentifier")
                }
            }
                .toolbar {
                    ToolbarItem {
                        Button("Lock Access Guards") {
                            Task {
                                let identifiers = [
                                    "TestIdentifier",
                                    "TestFixedIdentifier",
                                    "TestBiometricsIdentifier",
                                    "TestCodeIfUnprotectedIdentifier"
                                ]
                                for identifier in identifiers {
                                    await accessGuard.lock(identifier: identifier)
                                }
                            }
                        }
                    }
                    ToolbarItem {
                        Button("Reset Access Guards") {
                            let identifiers = ["TestIdentifier", "TestBiometricsIdentifier"]
                            for identifier in identifiers {
                                try? accessGuard.resetAccessCode(for: identifier)
                            }
                        }
                    }
                }
        }
    }
}
