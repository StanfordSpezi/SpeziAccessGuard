//
// This source file is part of the Stanford Spezi open-source project
//
// SPDX-FileCopyrightText: 2025 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import SpeziAccessGuard
import SpeziViews
import SwiftUI


struct ConsumableCodesView: View {
    @Environment(ConsumableCodesModule.self) private var consumableCodes
    @Environment(AccessGuard.self) private var accessGuard
    
    @State private var isShowingSheet = false
    
    var body: some View {
        Form {
            Section("Codes") {
                makeRow("Available", codes: consumableCodes.remainingCodes)
                makeRow("Consumed", codes: consumableCodes.consumedCodes)
            }
            Section {
                Button("Open Secret View") {
                    accessGuard.lock(.testConsumable)
                    isShowingSheet = true
                }
            }
        }
        .sheet(isPresented: $isShowingSheet) {
            NavigationStack {
                AccessGuarded(.testConsumable) {
                    Text("Congrats! You made it!!")
                }
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        DismissButton()
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private func makeRow(_ title: String, codes: [String]) -> some View {
        LabeledContent(title, value: codes.isEmpty ? "[]" : codes.sorted().joined(separator: ", "))
    }
}
