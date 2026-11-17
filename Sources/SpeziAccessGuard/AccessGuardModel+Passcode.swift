//
// This source file is part of the Spezi open source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

public import Foundation
public import Observation
import SpeziKeychainStorage
import UIKit


@Observable
@MainActor
public final class _PasscodeAccessGuardModel: _AnyAccessGuardModel { // swiftlint:disable:this type_name
    enum UnlockError: Error {
        case failed(LocalizedStringResource?)
    }
    
    private struct PersistedPasscode: Codable {
        /// The passcode
        let code: String
        /// The format that was required/enforced at the time the passcode was set
        ///
        /// - Note: This is stored here, instead of simply being fetched from the current configuration, in order to allow this being changed in a way that keeps old codes working.
        let format: PasscodeFormat
    }
    
    /// The result of reading the persisted passcode.
    private enum PersistedPasscodeState {
        /// There is no passcode stored for this access guard.
        case notSet
        /// There is a valid passcode stored for this access guard.
        case set(PersistedPasscode)
        /// It is unknown whether a passcode is stored for this access guard.
        ///
        /// This is the case if protected data is currently unavailable (e.g., before the device's first unlock after a reboot, or while the app is being prewarmed),
        /// if reading the stored passcode failed for a reason other than it not existing, or if the stored entry exists but could not be decoded.
        case unreadable
    }
    
    private let store: any PasscodeCredentialsStore
    private let notificationCenter: NotificationCenter
    private let isProtectedDataAvailable: @MainActor () -> Bool
    @ObservationIgnored private var protectedDataObserver: (any NSObjectProtocol)?
    public let config: CodeAccessGuard
    private(set) var needsSetup = true
    public private(set) var isLocked: Bool = true
    /// Whether the persisted passcode could not be read the last time the model attempted to do so.
    ///
    /// While this is `true`, the access guard stays locked and does not offer to set up a new passcode.
    /// The model re-reads the passcode once protected data becomes available, when the app returns to the foreground, and when the user attempts to unlock the access guard.
    private(set) var isPersistedPasscodeUnreadable = false
    
    private var persistedPasscodeState: PersistedPasscodeState {
        guard isProtectedDataAvailable() else {
            // While protected data is unavailable (e.g., before the device's first unlock after a reboot, or while the app is being prewarmed),
            // a keychain query can report the passcode as not found instead of failing, so the result of the read can't be trusted.
            return .unreadable
        }
        let entry: String?
        do {
            entry = try store.retrievePasscodeEntry(for: config.id.value)
        } catch {
            return .unreadable
        }
        guard let entry else {
            return .notSet
        }
        guard let persistedCode = try? JSONDecoder().decode(PersistedPasscode.self, from: Data(entry.utf8)) else {
            // A corrupt entry must not be treated as "no passcode set", since that would unlock optional access guards.
            return .unreadable
        }
        return .set(persistedCode)
    }
    
    public convenience init(config: CodeAccessGuard, context: AccessGuards) {
        self.init(config: config, store: context.keychain)
    }
    
    /// - parameter isProtectedDataAvailable: Whether protected data, and therefore the stored passcode, is currently available.
    ///     While this returns `false`, the stored passcode is treated as unreadable, regardless of what the store returns.
    init(
        config: CodeAccessGuard,
        store: any PasscodeCredentialsStore,
        notificationCenter: NotificationCenter = .default,
        isProtectedDataAvailable: @escaping @MainActor () -> Bool = { UIApplication.shared.isProtectedDataAvailable }
    ) {
        self.config = config
        self.store = store
        self.notificationCenter = notificationCenter
        self.isProtectedDataAvailable = isProtectedDataAvailable
        setInitialLockedState()
    }
    
    private func setInitialLockedState() {
        switch (persistedPasscodeState, config.isOptional) {
        case (.set, _):
            // we have a code set
            needsSetup = false
            isLocked = true
            isPersistedPasscodeUnreadable = false
        case (.unreadable, _):
            // we don't know whether a code is set; stay locked and don't offer setting a new code until we can read it
            needsSetup = false
            isLocked = true
            isPersistedPasscodeUnreadable = true
        case (.notSet, true):
            // we don't have a code set currently, and the Access Guard is optional
            needsSetup = false
            isLocked = false
            isPersistedPasscodeUnreadable = false
        case (.notSet, false):
            // we don't have a code set currently, and the Access Guard is NOT optional
            needsSetup = true
            isLocked = true // technically is isn't (yet) but we treat it as such as to not immediately show the guarded view
            isPersistedPasscodeUnreadable = false
        }
        updateProtectedDataObservation()
    }
    
    /// Re-reads the persisted passcode if it previously couldn't be read, and the access guard is still locked.
    ///
    /// - returns: Whether the access guard was unlocked as a result of the reload, i.e., because it turned out to be an optional access guard without a passcode.
    @discardableResult
    private func reloadPersistedPasscodeIfUnreadable() -> Bool {
        guard isPersistedPasscodeUnreadable, isLocked else {
            return false
        }
        setInitialLockedState()
        return !isLocked
    }
    
    private func updateProtectedDataObservation() {
        if isPersistedPasscodeUnreadable {
            guard protectedDataObserver == nil else {
                return
            }
            protectedDataObserver = notificationCenter.addObserver(
                forName: UIApplication.protectedDataDidBecomeAvailableNotification,
                object: nil,
                queue: nil
            ) { [weak self] _ in
                Task { @MainActor in
                    self?.reloadPersistedPasscodeIfUnreadable()
                }
            }
        } else if let protectedDataObserver {
            notificationCenter.removeObserver(protectedDataObserver)
            self.protectedDataObserver = nil
        }
    }
    
    public func lock() {
        isLocked = true
    }
    
    public func unlock(_ input: String) async -> CodeAccessGuard.ValidationResult {
        if reloadPersistedPasscodeIfUnreadable() {
            // reloading the passcode found that this is an optional access guard without a passcode
            return .valid
        }
        let result = await evaluate(input)
        switch result {
        case .valid:
            isLocked = false
        case .invalid:
            isLocked = true
        }
        return result
    }
    
    /// Informs the model that the app is about to move to the foreground
    public func willEnterForeground(lastEnteredBackground: Date) {
        lockIfTimedOut(lastEnteredBackground: lastEnteredBackground)
        reloadPersistedPasscodeIfUnreadable()
    }
    
    func evaluate(_ code: String) async -> CodeAccessGuard.ValidationResult {
        switch config.kind {
        case .regular:
            if case .set(let persistedCode) = persistedPasscodeState {
                persistedCode.code == code ? .valid : .invalid
            } else {
                .invalid
            }
        case .custom(_, _, let validate):
            await validate(code)
        }
    }
    
    func resetCode(newCode: String? = nil) throws {
        switch config.kind {
        case .custom:
            throw AccessGuardError.storeCodeError // TOOD better error!!!
        case .regular(let format):
            try store.deletePasscodeEntry(for: config.id.value)
            isLocked = true
            needsSetup = true
            setInitialLockedState()
            guard let newCode else {
                return
            }
            let persistedCode = PersistedPasscode(code: newCode, format: format)
            guard let accessCodeData = try? String(data: JSONEncoder().encode(persistedCode), encoding: .utf8) else {
                throw AccessGuardError.storeCodeError
            }
            try store.storePasscodeEntry(accessCodeData, for: config.id.value)
            needsSetup = false
            isLocked = false
        }
    }
}
