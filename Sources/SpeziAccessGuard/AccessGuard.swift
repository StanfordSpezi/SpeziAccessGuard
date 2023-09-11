//
// This source file is part of the Spezi open source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Combine
import Spezi
import SpeziSecureStorage
import SwiftUI


/// Enforces a code or biometrics-based access guard to SwiftUI views.
///
/// > Important: If your application is not yet configured to use Spezi, follow the [Spezi setup article](https://swiftpackageindex.com/stanfordspezi/spezi/documentation/spezi/setup) setup the core Spezi infrastructure.
///
/// The component needs to be registered in a Spezi-based application using the [`configuration`](https://swiftpackageindex.com/stanfordspezi/spezi/documentation/spezi/speziappdelegate/configuration)
/// in a [`SpeziAppDelegate`](https://swiftpackageindex.com/stanfordspezi/spezi/documentation/spezi/speziappdelegate):
/// ```swift
/// class ExampleAppDelegate: SpeziAppDelegate {
///     override var configuration: Configuration {
///         Configuration {
///             AccessGuard(
///                 [
///                     .code(identifier: "TestIdentifier")
///                 ]
///             )
///             // ...
///         }
///     }
/// }
/// ```
/// > Tip: You can learn more about a [`Component` in the Spezi documentation](https://swiftpackageindex.com/stanfordspezi/spezi/documentation/spezi/component).
///
///
/// ## Usage
///
/// You can use the ``AccessGuarded`` SwiftUI [`View`](https://developer.apple.com/documentation/swiftui/view) in your SwiftUI application to
/// enforce a code or biometrics-based access guard to SwiftUI views.
public final class AccessGuard: Module, DefaultInitializable {
    @Dependency private var secureStorage: SecureStorage
    @Published private(set) var inTheBackground = true
    @Published private(set) var lastEnteredBackground: Date = .now
    private let configurations: [AccessGuardConfiguration]
    private var viewModels: [String: AccessGuardViewModel] = [:]
    private var cancellables: Set<AnyCancellable> = []
    
    
    public convenience init() {
        self.init([])
    }
    
    public init(_ configurations: [AccessGuardConfiguration]) {
        self.configurations = configurations
    }
    
    
    @_documentation(visibility: internal)
    public func sceneDidEnterBackground(_ scene: UIScene) {
        Task { @MainActor in
            inTheBackground = true
            lastEnteredBackground = .now
        }
    }
    
    @_documentation(visibility: internal)
    public func sceneWillEnterForeground(_ scene: UIScene) {
        Task { @MainActor in
            inTheBackground = false
        }
    }
    
    
    /// Resets the access guard for an identifier.
    ///
    /// The function removes the code and all stored information.
    /// - Parameter identifier: The identifier of the access guard.
    @MainActor
    public func resetAccessCode(for identifier: AccessGuardConfiguration.Identifier) throws {
        try viewModel(for: identifier).resetAccessCode()
    }
    
    /// Determine the setup state of an access lock.
    ///
    /// Use the ``SetAccessGuard`` view to setup an access guard.
    /// - Parameter identifier: The identifier of the access guard.
    /// - Returns: Returns `true` of the access guard is successfully setup. False if no access guard is setup.
    @MainActor
    public func setupComplete(for identifier: AccessGuardConfiguration.Identifier) -> Bool {
        viewModel(for: identifier).setup
    }
    
    /// Locks an access guard.
    /// - Parameter identifier: The identifier of the access guard that should be locked.
    @MainActor
    public func lock(identifier: AccessGuardConfiguration.Identifier) async {
        await viewModel(for: identifier).lock()
    }
    
    @MainActor
    func viewModel(for identifier: AccessGuardConfiguration.Identifier) -> AccessGuardViewModel {
        guard let configuration = configurations.first(where: { $0.identifier == identifier }) else {
            preconditionFailure(
            """
           Did not find a AccessGuardConfiguration with the identifier `\(identifier)`.
           
           Please ensure that you have defined an AccessGuardConfiguration with the identifier in your `AccessGuard` configuration.
           """
            )
        }
        
        guard let viewModel = viewModels[identifier] else {
            let viewModel = AccessGuardViewModel(accessGuard: self, secureStorage: secureStorage, configuration: configuration)
            viewModels[identifier] = viewModel
            return viewModel
        }
        
        return viewModel
    }
}
