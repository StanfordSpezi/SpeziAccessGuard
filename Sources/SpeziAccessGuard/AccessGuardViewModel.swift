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


final class AccessGuardViewModel: ObservableObject {
    private struct AccessCode: Codable {
        let codeOption: CodeOptions
        let code: String
    }
    
    
    @MainActor @Published private(set) var locked = true
    
    let configuration: AccessGuardConfiguration
    private var accessCode: AccessCode?
    private weak var accessGuard: AccessGuard?
    private let secureStorage: SecureStorage
    private var cancellables: Set<AnyCancellable> = []
    
    
    var setup: Bool {
        accessCode != nil || configuration.fixedCode != nil
    }
    
    var codeOption: CodeOptions? {
        if configuration.fixedCode != nil {
            return configuration.codeOptions
        } else {
            return accessCode?.codeOption
        }
    }
    
    
    @MainActor
    init(accessGuard: AccessGuard, secureStorage: SecureStorage, configuration: AccessGuardConfiguration) {
        self.configuration = configuration
        self.accessGuard = accessGuard
        self.secureStorage = secureStorage
        
        if let credentials = try? secureStorage.retrieveCredentials(configuration.identifier),
           let accessCode = try? JSONDecoder().decode(AccessCode.self, from: Data(credentials.password.utf8)),
           accessCode.codeOption.verifyStructore(ofCode: accessCode.code) {
            self.accessCode = accessCode
        } else {
            self.accessCode = nil
        }
        
        self.locked = setup
        
        accessGuard.objectWillChange
            .sink {
                self.lockAfterInactivity()
                self.objectWillChange.send()
            }
            .store(in: &cancellables)
    }
    
    
    private func lockAfterInactivity() {
        Task { @MainActor in
            if let lastEnteredBackground = accessGuard?.lastEnteredBackground,
               lastEnteredBackground.addingTimeInterval(configuration.timeout) < .now {
                locked = true
            }
        }
    }
    
    @MainActor
    func resetAccessCode() throws {
        guard configuration.fixedCode == nil else {
            return
        }
        
        do {
            try secureStorage.deleteCredentials(configuration.identifier)
            accessCode = nil
            self.locked = setup
        } catch {
            print("Error resetting access code: \(error)")
        }
    }
    
    func checkAccessCode(_ code: String) async throws {
        try await MainActor.run {
            if let fixedCode = configuration.fixedCode, code == fixedCode {
                locked = false
                return
            }
            
            guard code == accessCode?.code else {
                throw AccessGuardError.wrongPasscode
            }
            
            locked = false
        }
    }
    
    func lock() async {
        await MainActor.run {
            locked = true
        }
    }
    
    func setAccessCode(_ code: String, codeOption: CodeOptions) async throws {
        guard configuration.fixedCode == nil else {
            throw AccessGuardError.storeCodeError
        }
        
        accessCode = AccessCode(codeOption: codeOption, code: code)
        
        guard let accessCodeData = try? String(data: JSONEncoder().encode(accessCode), encoding: .utf8) else {
            throw AccessGuardError.storeCodeError
        }
        
        try secureStorage.store(credentials: Credentials(username: configuration.identifier, password: accessCodeData))
        
        // Ensure that the model is in a state as if the user has just entered the access code.
        try await checkAccessCode(code)
    }
}
