//
// This source file is part of the Spezi open source project
//
// SPDX-FileCopyrightText: 2026 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import SpeziKeychainStorage


/// Persistent storage for the passcodes of ``CodeAccessGuard``s.
///
/// The model talks to the keychain through this protocol so that its handling of storage failures can be tested.
protocol PasscodeCredentialsStore: Sendable {
    /// Retrieves the stored passcode entry for the access guard with the specified identifier.
    ///
    /// - returns: The stored entry, or `nil` if no entry exists.
    /// - throws: If the entry could not be read, e.g. because protected data is currently unavailable.
    ///     Implementations must not throw if the entry simply doesn't exist.
    func retrievePasscodeEntry(for accessGuardId: String) throws -> String?
    /// Stores the passcode entry for the access guard with the specified identifier, replacing any existing entry.
    func storePasscodeEntry(_ entry: String, for accessGuardId: String) throws
    /// Deletes the passcode entry for the access guard with the specified identifier, if it exists.
    func deletePasscodeEntry(for accessGuardId: String) throws
}


extension KeychainStorage: PasscodeCredentialsStore {
    func retrievePasscodeEntry(for accessGuardId: String) throws -> String? {
        // `retrieveCredentials` returns `nil` for `errSecItemNotFound` and throws for every other keychain error.
        try retrieveCredentials(withUsername: accessGuardId, for: .accessGuard)?.password
    }
    
    func storePasscodeEntry(_ entry: String, for accessGuardId: String) throws {
        try store(Credentials(username: accessGuardId, password: entry), for: .accessGuard)
    }
    
    func deletePasscodeEntry(for accessGuardId: String) throws {
        try deleteCredentials(withUsername: accessGuardId, for: .accessGuard)
    }
}
