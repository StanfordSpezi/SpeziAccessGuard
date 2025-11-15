//
// This source file is part of the Spezi open source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Foundation
import LocalAuthentication
import Observation
import SpeziKeychainStorage


@MainActor
public protocol _AnyAccessGuardModel: Observable, Sendable { // swiftlint:disable:this type_name
    associatedtype UnlockInput
    associatedtype UnlockResult
    
    associatedtype Config: _AccessGuardConfigurationProtocol /* where Config._Model.Configuration == Self */
    var isLocked: Bool { get }
    var config: Config { get }
    init(config: Config, context: AccessGuard)
    
    @_spi(Internal)
    func lock()
    
    @_spi(Internal)
    func unlock(_ input: UnlockInput) async throws -> UnlockResult
    
    /// Informs the model that the app moved to the background
    @_spi(Internal)
    func didEnterBackground()
    
    /// Informs the model that the app is about to move to the foreground
    @_spi(Internal)
    func willEnterForeground(lastEnteredBackground: Date)
}


extension _AnyAccessGuardModel {
    func unlock() async throws -> UnlockResult where UnlockInput == Void {
        try await unlock(())
    }
    
    public func didEnterBackground() {} // swiftlint:disable:this missing_docs
    
    public func willEnterForeground(lastEnteredBackground: Date) { // swiftlint:disable:this missing_docs
        if lastEnteredBackground.addingTimeInterval(config.timeout.timeInterval) < .now {
            lock()
        }
    }
}


extension CredentialsTag {
    static let accessGuard = Self.genericPassword(forService: "edu.stanford.spezi.accessGuard")
}
