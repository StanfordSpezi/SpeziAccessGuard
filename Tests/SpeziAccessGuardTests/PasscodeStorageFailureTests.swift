//
// This source file is part of the Spezi open source project
//
// SPDX-FileCopyrightText: 2026 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Foundation
@testable import SpeziAccessGuard
import Testing
import UIKit


/// In-memory ``PasscodeCredentialsStore`` that can be made to fail reads or to report stored entries as not found,
/// e.g. to simulate protected data being unavailable.
private final class MockPasscodeStore: PasscodeCredentialsStore, @unchecked Sendable {
    struct ReadFailure: Error {}

    private let lock = NSLock()
    private var entries: [String: String] = [:]
    private var _failReads = false
    private var _reportsNotFound = false

    var failReads: Bool {
        get { lock.withLock { _failReads } }
        set { lock.withLock { _failReads = newValue } }
    }

    /// Whether reads return `nil` (item not found) even if an entry is stored.
    var reportsNotFound: Bool {
        get { lock.withLock { _reportsNotFound } }
        set { lock.withLock { _reportsNotFound = newValue } }
    }

    init(entries: [String: String] = [:], failReads: Bool = false) {
        self.entries = entries
        self._failReads = failReads
    }

    func retrievePasscodeEntry(for accessGuardId: String) throws -> String? {
        try lock.withLock {
            if _failReads {
                throw ReadFailure()
            }
            return _reportsNotFound ? nil : entries[accessGuardId]
        }
    }

    func storePasscodeEntry(_ entry: String, for accessGuardId: String) throws {
        lock.withLock { entries[accessGuardId] = entry }
    }

    func deletePasscodeEntry(for accessGuardId: String) throws {
        lock.withLock { entries[accessGuardId] = nil }
    }
}


/// Simulates whether protected data (and therefore the keychain) is currently available.
@MainActor
private final class ProtectedDataAvailability {
    var isAvailable: Bool

    init(isAvailable: Bool) {
        self.isAvailable = isAvailable
    }
}


@Suite("Passcode Storage Failures")
@MainActor
struct PasscodeStorageFailureTests {
    private static let guardId = "test.accessguard.storage"

    private static func config(isOptional: Bool) -> CodeAccessGuard {
        CodeAccessGuard(.passcode(guardId), codeFormat: .numeric(4), isOptional: isOptional)
    }
    
    /// Creates a model with an injected protected data availability.
    ///
    /// Protected data is reported as available by default; the test host's `UIApplication` can't be relied on for this.
    private static func makeModel(
        config: CodeAccessGuard,
        store: MockPasscodeStore,
        notificationCenter: NotificationCenter = .default,
        isProtectedDataAvailable: @escaping @MainActor () -> Bool = { true }
    ) -> _PasscodeAccessGuardModel {
        _PasscodeAccessGuardModel(
            config: config,
            store: store,
            notificationCenter: notificationCenter,
            isProtectedDataAvailable: isProtectedDataAvailable
        )
    }
    
    /// Creates a store containing the passcode `1234`, persisted the same way the passcode setup flow does it.
    private static func storeWithPasscode() throws -> MockPasscodeStore {
        let store = MockPasscodeStore()
        let setupModel = Self.makeModel(config: config(isOptional: false), store: store)
        try setupModel.resetCode(newCode: "1234")
        return store
    }


    @Test("No stored passcode: optional guard starts unlocked, required guard offers setup", arguments: [true, false])
    func notFound(isOptional: Bool) {
        let model = Self.makeModel(config: Self.config(isOptional: isOptional), store: MockPasscodeStore())
        if isOptional {
            #expect(!model.isLocked)
            #expect(!model.needsSetup)
        } else {
            #expect(model.isLocked)
            #expect(model.needsSetup)
        }
    }

    @Test("Stored passcode: guard starts locked and unlocks with the stored code", arguments: [true, false])
    func storedPasscode(isOptional: Bool) async throws {
        let store = try Self.storeWithPasscode()
        let model = Self.makeModel(config: Self.config(isOptional: isOptional), store: store)
        #expect(model.isLocked)
        #expect(!model.needsSetup)
        #expect(await model.unlock("0000") == .invalid)
        #expect(model.isLocked)
        #expect(await model.unlock("1234") == .valid)
        #expect(!model.isLocked)
    }

    @Test("Keychain read failure keeps the guard locked and does not offer setup", arguments: [true, false])
    func readFailure(isOptional: Bool) async throws {
        let store = try Self.storeWithPasscode()
        store.failReads = true
        let model = Self.makeModel(config: Self.config(isOptional: isOptional), store: store)
        #expect(model.isLocked)
        #expect(!model.needsSetup)
        // while the passcode can't be read, no code unlocks the guard
        #expect(await model.unlock("1234") == .invalid)
        #expect(model.isLocked)
        #expect(!model.needsSetup)
    }

    @Test("Corrupt stored passcode keeps the guard locked and does not offer setup", arguments: [true, false])
    func corruptEntry(isOptional: Bool) async {
        let store = MockPasscodeStore(entries: [Self.guardId: "not a passcode"])
        let model = Self.makeModel(config: Self.config(isOptional: isOptional), store: store)
        #expect(model.isLocked)
        #expect(!model.needsSetup)
        #expect(await model.unlock("1234") == .invalid)
        #expect(model.isLocked)
    }

    @Test("Unlock attempt re-reads the passcode once it becomes readable", arguments: [true, false])
    func unlockAfterRecovery(isOptional: Bool) async throws {
        let store = try Self.storeWithPasscode()
        store.failReads = true
        let model = Self.makeModel(config: Self.config(isOptional: isOptional), store: store)
        #expect(model.isLocked)
        store.failReads = false
        #expect(await model.unlock("1234") == .valid)
        #expect(!model.isLocked)
        #expect(!model.needsSetup)
    }
    
    @Test("Passcode is re-read once protected data becomes available")
    func protectedDataBecomesAvailable() async throws {
        let notificationCenter = NotificationCenter()
        let store = try Self.storeWithPasscode()
        store.failReads = true
        let model = Self.makeModel(config: Self.config(isOptional: true), store: store, notificationCenter: notificationCenter)
        #expect(model.isLocked)
        #expect(model.isPersistedPasscodeUnreadable)
        
        store.failReads = false
        notificationCenter.post(name: UIApplication.protectedDataDidBecomeAvailableNotification, object: nil)
        for _ in 0..<100 where model.isPersistedPasscodeUnreadable {
            try await Task.sleep(for: .milliseconds(10))
        }
        #expect(!model.isPersistedPasscodeUnreadable)
        #expect(model.isLocked)
        #expect(!model.needsSetup)
        #expect(await model.unlock("1234") == .valid)
    }
    
    @Test("Optional guard without passcode unlocks once the keychain becomes readable")
    func optionalGuardWithoutPasscodeRecovers() async throws {
        let notificationCenter = NotificationCenter()
        let store = MockPasscodeStore(failReads: true)
        let model = Self.makeModel(config: Self.config(isOptional: true), store: store, notificationCenter: notificationCenter)
        #expect(model.isLocked)
        #expect(!model.needsSetup)
        
        // still unreadable: notification and foregrounding don't change anything
        notificationCenter.post(name: UIApplication.protectedDataDidBecomeAvailableNotification, object: nil)
        model.willEnterForeground(lastEnteredBackground: .now)
        try await Task.sleep(for: .milliseconds(50))
        #expect(model.isLocked)
        #expect(model.isPersistedPasscodeUnreadable)
        
        store.failReads = false
        model.willEnterForeground(lastEnteredBackground: .now)
        #expect(!model.isLocked)
        #expect(!model.needsSetup)
        #expect(!model.isPersistedPasscodeUnreadable)
    }
    
    @Test("Required guard without passcode offers setup once the keychain becomes readable")
    func requiredGuardWithoutPasscodeRecovers() async {
        let store = MockPasscodeStore(failReads: true)
        let model = Self.makeModel(config: Self.config(isOptional: false), store: store)
        #expect(model.isLocked)
        #expect(!model.needsSetup)
        store.failReads = false
        #expect(await model.unlock("1234") == .invalid)
        #expect(model.isLocked)
        #expect(model.needsSetup)
    }

    @Test(
        "Not-found read while protected data is unavailable keeps the guard locked until protected data becomes available",
        arguments: [true, false], [true, false]
    )
    func notFoundWhileProtectedDataUnavailable(isOptional: Bool, hasStoredPasscode: Bool) async throws {
        let notificationCenter = NotificationCenter()
        let availability = ProtectedDataAvailability(isAvailable: false)
        let store = hasStoredPasscode ? try Self.storeWithPasscode() : MockPasscodeStore()
        // while protected data is unavailable, a keychain query for a "when unlocked" item can report the item as not found instead of failing
        store.reportsNotFound = true
        let model = Self.makeModel(
            config: Self.config(isOptional: isOptional),
            store: store,
            notificationCenter: notificationCenter,
            isProtectedDataAvailable: { availability.isAvailable }
        )
        #expect(model.isLocked)
        #expect(!model.needsSetup)
        #expect(model.isPersistedPasscodeUnreadable)
        // still unavailable: neither an unlock attempt nor foregrounding trusts the not-found result
        #expect(await model.unlock("1234") == .invalid)
        model.willEnterForeground(lastEnteredBackground: .now)
        #expect(model.isLocked)
        #expect(!model.needsSetup)
        #expect(model.isPersistedPasscodeUnreadable)

        availability.isAvailable = true
        store.reportsNotFound = false
        notificationCenter.post(name: UIApplication.protectedDataDidBecomeAvailableNotification, object: nil)
        for _ in 0..<100 where model.isPersistedPasscodeUnreadable {
            try await Task.sleep(for: .milliseconds(10))
        }
        #expect(!model.isPersistedPasscodeUnreadable)
        switch (hasStoredPasscode, isOptional) {
        case (true, _):
            #expect(model.isLocked)
            #expect(!model.needsSetup)
            #expect(await model.unlock("0000") == .invalid)
            #expect(await model.unlock("1234") == .valid)
            #expect(!model.isLocked)
        case (false, true):
            #expect(!model.isLocked)
            #expect(!model.needsSetup)
        case (false, false):
            #expect(model.isLocked)
            #expect(model.needsSetup)
        }
    }
}


extension CodeAccessGuard.ValidationResult: Equatable {
    public static func == (lhs: Self, rhs: Self) -> Bool {
        switch (lhs, rhs) {
        case (.valid, .valid), (.invalid, .invalid):
            true
        default:
            false
        }
    }
}
