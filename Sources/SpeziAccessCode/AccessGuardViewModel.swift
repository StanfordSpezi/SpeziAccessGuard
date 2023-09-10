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
    private var identifier: String
    private var fixedCode: String?
    private var accessCode: AccessCode?
    private weak var accessGuard: AccessGuard?
    private let secureStorage: SecureStorage
    private var cancellables: Set<AnyCancellable> = []
    
    
    var codeOption: CodeOptions? {
        if fixedCode != nil {
            return configuration.codeOptions
        } else {
            return accessCode?.codeOption
        }
    }
    
    
    init(_ identifier: String, fixedCode: String? = nil, accessGuard: AccessGuard, secureStorage: SecureStorage, configuration: AccessGuardConfiguration) {
        self.configuration = configuration
        self.accessGuard = accessGuard
        self.secureStorage = secureStorage
        self.identifier = identifier
        self.fixedCode = fixedCode
        
        if let credentials = try? secureStorage.retrieveCredentials(identifier),
           let accessCode = try? JSONDecoder().decode(AccessCode.self, from: Data(credentials.password.utf8)),
           accessCode.codeOption.verifyStructore(ofCode: accessCode.code) {
            self.accessCode = accessCode
        } else {
            self.accessCode = nil
        }
        
        accessGuard.objectWillChange
            .sink {
                self.updateState()
                self.objectWillChange.send()
            }
            .store(in: &cancellables)
    }
    
    
    private func updateState() {
        Task { @MainActor in
            if let lastEnteredBackground = accessGuard?.lastEnteredBackground, lastEnteredBackground.addingTimeInterval(configuration.timeout) >= .now {
                locked = false
            } else {
                locked = true
            }
        }
    }
    
    
    func checkAccessCode(_ code: String) async throws {
        try await MainActor.run {
            if let fixedCode, code == fixedCode {
                locked = false
                return
            }
            
            guard code == accessCode?.code else {
                throw AccessGuardError.wrongPasscode
            }
            
            locked = false
        }
    }
    
    func setAccessCode(_ code: String, codeOption: CodeOptions) async throws {
        guard fixedCode == nil else {
            throw AccessGuardError.storeCodeError
        }
        
        accessCode = AccessCode(codeOption: codeOption, code: code)
        
        guard let accessCodeData = try? String(data: JSONEncoder().encode(accessCode), encoding: .utf8) else {
            throw AccessGuardError.storeCodeError
        }
        
        try secureStorage.store(credentials: Credentials(username: identifier, password: accessCodeData))
        
        await MainActor.run {
            locked = true
        }
    }
}
