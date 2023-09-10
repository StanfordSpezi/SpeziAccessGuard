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
///             AccessGuard()
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
public final class AccessGuard: Module {
    @Dependency var secureStorage: SecureStorage
    @Published var inTheBackground = true
    @Published var lastEnteredBackground: Date = .now
    private let configurations: [AccessGuardConfiguration]
    private var viewModels: [String: AccessGuardViewModel] = [:]
    private var cancellables: Set<AnyCancellable> = []
    
    
    public init(_ configurations: [AccessGuardConfiguration]) {
        self.configurations = configurations
    }
    
    
    public func sceneDidEnterBackground(_ scene: UIScene) {
        Task { @MainActor in
            inTheBackground = true
            lastEnteredBackground = .now
        }
    }
    
    public func sceneWillEnterForeground(_ scene: UIScene) {
        Task { @MainActor in
            inTheBackground = false
        }
    }
    
    
    @MainActor
    public func resetAccessCode(for identifier: AccessGuardConfiguration.Identifier) throws {
        try viewModel(for: identifier).resetAccessCode()
    }
    
    @MainActor
    public func setupComplete(for identifier: AccessGuardConfiguration.Identifier) -> Bool {
        viewModel(for: identifier).setup
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
