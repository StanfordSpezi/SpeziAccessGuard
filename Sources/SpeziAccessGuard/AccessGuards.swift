//
// This source file is part of the Spezi open source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Foundation
public import Observation
public import Spezi
public import SpeziFoundation
import SpeziKeychainStorage
public import class UIKit.UIScene


/// Enforce code or biometrics-guarded access to SwiftUI views.
///
/// ## Usage
///
/// The `AccessGuards` type is used for two purposes:
/// 1. defining the access guards used by your app
/// 2. (optional) manually managing, locking, and resetting access guards from within your custom SwiftUI views
///
/// ### Defining and Using Access Guards
///
/// The module needs to be registered in a Spezi-based application using the [`configuration`](https://swiftpackageindex.com/stanfordspezi/spezi/documentation/spezi/speziappdelegate/configuration)
/// in a [`SpeziAppDelegate`](https://swiftpackageindex.com/stanfordspezi/spezi/documentation/spezi/speziappdelegate):
/// ```swift
/// class ExampleAppDelegate: SpeziAppDelegate {
///     override var configuration: Configuration {
///         Configuration {
///             AccessGuards {
///                 CodeAccessGuard(.transactionsList)
///             }
///         }
///     }
/// }
///
/// extension AccessGuardIdentifier where AccessGuard == CodeAccessGuard {
///     static let transactionsList: Self = .passcode("com.example.MyApp.transactionsList")
/// }
/// ```
///
/// > Tip: You can learn more about a [`Module` in the Spezi documentation](https://swiftpackageindex.com/stanfordspezi/spezi/documentation/spezi/module).
///
/// You can now use ``AccessGuarded`` to protect individual views within your app with this access guard,
/// enforcing that the user enter a passcode or perform a biometrics-based check (depending on the access guard's configuration)
/// before being able to view and interact with the guarded view:
/// ```swift
/// struct MyView: View {
///     var body: some View {
///         TabView {
///             // ...
///             Tab("Transactions", systemImage: "list.bullet.rectangle.portrait") {
///                 AccessGuarded(.transactionsList) {
///                     TransactionsList()
///                 }
///             }
///         }
///     }
/// }
/// ```
///
///
/// ### Managing Access Guards
///
/// You can also use the `AccessGuards` module to manually manage access guards within your application.
///
/// For example, even though access guards automatically lock after their specified timeout time interval has passed,
/// you might need to manually lock some specific access guard directly.
/// The example below uses a toolbar item to allow the user to lock the access guard:
/// ```swift
/// struct ProtectedContent: View {
///     @Environment(AccessGuard.self) private var accessGuards
///
///     var body: some View {
///         AccessGuarded(.transactionsList) {
///             TransactionsList()
///         }
///         .toolbar {
///             ToolbarItem {
///                 Button("Lock") {
///                     try? accessGuards.lock(.transactionsList)
///                 }
///             }
///         }
///     }
/// }
/// ```
///
/// In addition to manually locking access guards, you can also reset access guards; this will remove any information associated with the guard (e.g., the passcode the user selected).
///
/// - Important: In order to use biometric (Face ID) access guards, you need to add the `NSFaceIDUsageDescription` key to your app's Info.plist.
///
///
/// ## Topics
///
/// ### Initializers
/// - ``init(_:)``
///
/// ### Access Guard Operations
/// - ``lock(_:)-(AccessGuardIdentifier<Any>)``
/// - ``lock(_:)-(_AnyAccessGuardIdentifier<Any>)``
/// - ``isLocked(_:)``
/// - ``resetAccessCode(for:)``
/// - ``setupComplete(for:)``
@Observable
public final class AccessGuards: Module, EnvironmentAccessible, LifecycleHandler {
    private struct ModelKey: Hashable {
        private let rawIdentifier: String
        private let identifierType: ObjectIdentifier
        
        init<I: _AnyAccessGuardIdentifier>(_ identifier: I) {
            rawIdentifier = identifier.value
            identifierType = ObjectIdentifier(I.self)
        }
    }
    
    @ObservationIgnored @Dependency(KeychainStorage.self) var keychain
    private(set) var lastEnteredBackground: Date = .now
    private var configs: [any _AccessGuardConfig]
    private var models: [ModelKey: any _AnyAccessGuardModel] = [:]
    
    
    public init(@ArrayBuilder<any _AccessGuardConfig> _ configurations: () -> [any _AccessGuardConfig]) {
        self.configs = configurations()
        Self.assertUniqueness(configs.map(\.typeErasedId))
    }
    
    private static func assertUniqueness(_ identifiers: [any _AnyAccessGuardIdentifier]) {
        let duplicateIdentifiers = identifiers
            .grouped(by: \.value)
            .filter { $1.count > 1 }
        guard !duplicateIdentifiers.isEmpty else {
            return // it's fine
        }
        var errorMsg = "Invalid Input: Found duplicate identifiers in Access Guard configuration:"
        for (id, entries) in duplicateIdentifiers {
            errorMsg.append("\n- '\(id)': \(entries)")
        }
        preconditionFailure(errorMsg)
    }
}


// MARK: Lifecycle

extension AccessGuards {
    @_documentation(visibility: internal)
    @MainActor
    public func sceneDidEnterBackground(_ scene: UIScene) { // swiftlint:disable:this missing_docs
        lastEnteredBackground = .now
        for model in models.values {
            model.didEnterBackground()
        }
    }
    
    @_documentation(visibility: internal)
    @MainActor
    public func sceneWillEnterForeground(_ scene: UIScene) { // swiftlint:disable:this missing_docs
        for model in models.values {
            model.willEnterForeground(lastEnteredBackground: lastEnteredBackground)
        }
    }
}


// MARK: Operations

extension AccessGuards {
    func register(_ config: some _AccessGuardConfig) throws {
        guard !configs.contains(where: { ModelKey($0.typeErasedId) == ModelKey(config.typeErasedId) }) else {
            throw NSError(domain: "edu.stanford.SpeziAccessGuard", code: 0)
        }
        configs.append(config)
    }
    
    /// Resets the access guard for an identifier.
    ///
    /// The function removes the code and all stored information.
    /// - Parameter id: The identifier of the access guard.
    @MainActor
    public func resetAccessCode(for id: some _AnyAccessGuardIdentifier<some Any>) throws {
        switch id {
        case let id as AccessGuardIdentifier<CodeAccessGuard>:
            try model(for: id).resetCode()
        case let id as AccessGuardIdentifier<BiometricAccessGuard>:
            try model(for: id).fallback?.resetCode()
        default:
            break
        }
    }
    
    /// Determine the setup state of an access lock.
    ///
    /// Use the ``SetAccessGuard`` view to setup an access guard.
    /// - Parameter id: The identifier of the access guard.
    /// - Returns: Returns `true` of the access guard is successfully setup. False if no access guard is setup.
    @MainActor
    public func setupComplete(for id: AccessGuardIdentifier<CodeAccessGuard>) -> Bool {
        !model(for: id).needsSetup
    }
    
    /// Locks an access guard.
    /// - Parameter id: The identifier of the access guard that should be locked.
    @MainActor
    public func lock(_ id: AccessGuardIdentifier<some Any>) {
        model(for: id).lock()
    }
    
    /// Locks an access guard.
    /// - Parameter id: The identifier of the access guard that should be locked.
    @MainActor
    @_disfavoredOverload
    public func lock(_ id: some _AnyAccessGuardIdentifier<some Any>) {
        model(for: id).lock()
    }
    
    /// Checks is the `AccessGuard` associated with the given identifier is currently locked.
    @MainActor
    public func isLocked(_ id: AccessGuardIdentifier<some Any>) -> Bool {
        model(for: id).isLocked
    }
    
    func config<Config>(for id: some _AnyAccessGuardIdentifier<Config>) -> Config {
        guard let config = configs.first(where: { $0.typeErasedId.value == id.value }) else {
            preconditionFailure(
                "Unable to find Access Guard Configuration for identifier '\(id.value)'. Make sure to include a corresponding definition when initializing the AccessGuard module."
            )
        }
        guard let config = config as? Config else {
            preconditionFailure("Invalid State: configuration for id '\(id.value)' has type '\(type(of: config))'; expected '\(Config.self)'")
        }
        return config
    }
    
    @MainActor
    func model<Config>(for id: some _AnyAccessGuardIdentifier<Config>) -> Config._Model {
        let config = config(for: id)
        if let model = models[.init(id)] {
            guard let model = model as? Config._Model else {
                preconditionFailure("Invalid State: model for id '\(id.value)' has type '\(type(of: model))'; expected '\(Config._Model.self)'")
            }
            return model
        } else {
            let model = Config._Model(config: config, context: self)
            models[.init(id)] = model
            return model
        }
    }
}
