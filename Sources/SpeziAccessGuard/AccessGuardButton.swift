//
// This source file is part of the Spezi open source project
//
// SPDX-FileCopyrightText: 2025 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import SwiftUI

public struct AccessGuardButton<Locked: View, Unlocked: View>: View {
    @Environment(AccessGuard.self) private var accessGuard
    private let identifier: AccessGuardIdentifier
    private let locked: () -> Locked
    private let unlocked: () -> Unlocked
    @State private var isShowingUnlockSheet = false
    
    init(
        _ identifier: AccessGuardIdentifier,
        @ViewBuilder locked: @escaping () -> Locked,
        @ViewBuilder unlocked: @escaping () -> Unlocked
    ) {
        self.identifier = identifier
        self.locked = locked
        self.unlocked = unlocked
    }
    
    public var body: some View {
        if accessGuard.isLocked(identifier: identifier) {
            Button {
                isShowingUnlockSheet = true
            } label: {
                locked()
            }
            .sheet(isPresented: $isShowingUnlockSheet) {
                AccessGuarded(identifier) {
                    VStack { }
                        .onAppear {
                            isShowingUnlockSheet = false
                        }
                }
            }
        } else {
            unlocked()
        }
    }
}

#if DEBUG
#Preview {
    let identifier = AccessGuardIdentifier("edu.stanford.spezi.myView")
    AccessGuardButton(identifier) {
        Text("Unlock")
    } unlocked: {
        Text("Super secret stuff 🤫")
    }
    .previewWith {
        AccessGuardModule {
            FixedAccessGuard(identifier, code: "1234")
        }
    }
}
#endif
