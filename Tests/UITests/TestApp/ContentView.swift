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
    @EnvironmentObject private var accessGuard: AccessGuard
    
    
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
                NavigationLink("Set Code") {
                    SetAccessGuard(identifier: "TestIdentifier")
                }
            }
                .toolbar {
                    ToolbarItem {
                        Button("Reset Access Guard") {
                            try? accessGuard.resetAccessCode(for: "TestIdentifier")
                        }
                    }
                }
        }
    }
}
