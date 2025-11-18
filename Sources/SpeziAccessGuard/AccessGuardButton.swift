//
// This source file is part of the Spezi open source project
//
// SPDX-FileCopyrightText: 2025 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

public import SwiftUI

/// A view that conditionally displays either a locked button or unlocked content based on an AccessGuard's state.
///
/// The `AccessGuardButton` uses an `AccessGuard` instance from the SwiftUI environment to determine whether to show a locked or unlocked view.
/// When the associated access guard is locked, the view displays a button built with the `locked` view builder.
/// Tapping this button presents a sheet containing an `AccessGuarded` view to handle the unlocking process.
/// Once unlocked, the view automatically shows the content provided by the `unlocked` view builder.
///
/// The access guard is injected into the SwiftUI environment using the [`@Environment`](https://developer.apple.com/documentation/swiftui/environment) property wrapper.
///
/// ### Parameters
/// - `identifier`: A unique identifier for the access guard. This is used to query the lock state and manage the unlocking process.
/// - `locked`: A closure that returns a view displayed when the access guard is locked.
/// - `unlocked`: A closure that returns a view displayed when the access guard is unlocked.
///
/// ### Behavior
/// - **Locked State:**
///   If `accessGuard.isLocked(identifier:)` returns `true`, the view renders a button with the content from the `locked` closure.
///   Tapping the button sets a state flag (`isShowingUnlockSheet`) to `true` and presents a sheet containing an `AccessGuarded` view.
///   The sheet includes an empty `VStack` that dismisses itself (by resetting `isShowingUnlockSheet`) once it appears.
///
/// - **Unlocked State:**
///   If the access guard is unlocked, the view directly displays the content from the `unlocked` closure.
///
/// ### Usage Example
/// ```swift
/// struct ContentView: View {
///     var body: some View {
///         AccessGuardButton(.myAccessGuard) {
///             // Locked view: display a lock icon or a message
///             Image(systemName: "lock.fill")
///         } unlocked: {
///             // Unlocked view: display the secured content
///             Text("Access Granted!")
///         }
///     }
/// }
///
/// extension AccessGuardIdentifier where AccessGuard == CodeAccessGuard {
///     static let myAccessGuard: Self = .passcode("edu.stanford.spezi.myAccessGuard")
/// }
/// ```
///
/// The `AccessGuardButton` offers a declarative and reusable way to control access to secure content in SwiftUI apps,
/// integrating seamlessly with the environment-based dependency injection of an `AccessGuard`.
public struct AccessGuardButton<Locked: View, Unlocked: View, Config: _AccessGuardConfig>: View {
    @AccessGuard<Config> private var accessGuard: Config._Model
    private let locked: @MainActor () -> Locked
    private let unlocked: @MainActor () -> Unlocked
    @State private var isShowingUnlockSheet = false
    
    public var body: some View {
        if accessGuard.isLocked {
            Button {
                isShowingUnlockSheet = true
            } label: {
                locked()
            }
            .sheet(isPresented: $isShowingUnlockSheet) {
                unlockSheetContent
            }
        } else {
            unlocked()
        }
    }
    
    @ViewBuilder private var unlockSheetContent: some View {
        NavigationStack {
            AccessGuarded(accessGuard.identifier) {
                VStack { }
                    .onAppear {
                        isShowingUnlockSheet = false
                    }
            }
            .navigationTitle(NSLocalizedString("UNLOCK_TITLE", bundle: .module, comment: ""))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(NSLocalizedString("CANCEL", bundle: .module, comment: ""), role: .cancel) {
                        isShowingUnlockSheet = false
                    }
                }
            }
        }
    }
    
    /// Creates a new `AccessGuardButton`.
    /// - Parameters:
    ///   - identifier: The unique identifier for the access guard.
    ///   - locked: The label of the button displayed when access is locked.
    ///   - unlocked: The content displayed when access is unlocked.
    public init(
        _ identifier: AccessGuardIdentifier<Config>,
        @ViewBuilder locked: @escaping @MainActor () -> Locked,
        @ViewBuilder unlocked: @escaping @MainActor () -> Unlocked
    ) {
        _accessGuard = .init(identifier)
        self.locked = locked
        self.unlocked = unlocked
    }
}


#if DEBUG
#Preview {
    let identifier = AccessGuardIdentifier.passcode("edu.stanford.spezi.myView")
    AccessGuardButton(identifier) {
        Text("Unlock")
    } unlocked: {
        Text("Super secret stuff 🤫")
    }
    .previewWith {
        AccessGuards {
            CodeAccessGuard(identifier, fixed: "1234")
        }
    }
}
#endif
