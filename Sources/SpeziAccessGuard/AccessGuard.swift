//
// This source file is part of the Spezi open source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Foundation
import Observation
import Spezi
import SpeziFoundation
import SpeziKeychainStorage
import SwiftUI


/// Provides access to manage, lock, and reset and access guard from Swift UI views.
///
/// The ``AccessGuard`` is injected in the SwiftUI environment and can be accessed using the [`@Environment`](https://developer.apple.com/documentation/swiftui/environment) property wrapper.
///
/// ### Locking an Access Guard
///
/// The access guard will lock automatically when it times out. However, we can also lock an access guard directly using the ``AccessGuard/lock(identifier:)`` method. Here, we add a toolbar item with a button that will lock the access guard.
/// 
/// ```swift
/// struct ProtectedContent: View {
///     @Environment(AccessGuard.self) private var accessGuard
///     
///     var body: some View {
///         AccessGuarded(.myAccessGuard) {
///             Text("Secured content...")
///         }
///         .toolbar {
///             ToolbarItem {
///                 Button("Lock Access Guard") {
///                     try? accessGuard.lock(identifier: .myAccessGuard)
///                 }
///             }
///         }
///     }
/// }
///
/// extension AccessGuardIdentifier where AccessGuard == CodeAccessGuard {
///     static let myAccessGuard: Self = .passcode("edu.stanford.spezi.myAccessGuard")
/// }
/// ```
/// 
/// ### Resetting an Access Guard
/// 
/// To remove the access code and all information from an access guard, we can use the ``AccessGuard/resetAccessCode(for:)`` method. Here, we add a toolbar item with a button that will lock the access guard.
/// 
/// ```swift
/// struct ProtectedContent: View {
///     @Environment(AccessGuard.self) private var accessGuard
///     
///     var body: some View {
///         AccessGuarded(.myAccessGuard) {
///             Text("Secured content...")
///         }
///         .toolbar {
///             ToolbarItem {
///                 Button("Reset Access Guard") {
///                     try? accessGuard.resetAccessCode(for: .myAccessGuard)
///                 }
///             }
///         }
///     }
/// }
/// ```
@Observable
public final class AccessGuard {
    private struct ModelKey: Hashable {
        private let rawIdentifier: String
        private let identifierType: ObjectIdentifier
        
        init<I: _AnyAccessGuardIdentifier>(_ identifier: I) {
            rawIdentifier = identifier.value
            identifierType = ObjectIdentifier(I.self)
        }
    }
    
    let keychain: KeychainStorage
    private(set) var lastEnteredBackground: Date = .now
    private var configs: [any _AccessGuardConfigurationProtocol]
    private var models: [ModelKey: any _AnyAccessGuardModel] = [:]
    
    
    init(keychain: KeychainStorage, configs: [any _AccessGuardConfigurationProtocol]) {
        Self.assertUniqueness(configs.map(\.typeErasedId))
        self.keychain = keychain
        self.configs = configs
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

extension AccessGuard {
    @MainActor
    func sceneDidEnterBackground(_ scene: UIScene) {
        lastEnteredBackground = .now
        for model in models.values {
            model.didEnterBackground()
        }
    }
    
    
    @MainActor
    func sceneWillEnterForeground(_ scene: UIScene) {
        for model in models.values {
            model.willEnterForeground(lastEnteredBackground: lastEnteredBackground)
        }
    }
}


// MARK: Operations

extension AccessGuard {
    func register(_ config: some _AccessGuardConfigurationProtocol) throws {
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
