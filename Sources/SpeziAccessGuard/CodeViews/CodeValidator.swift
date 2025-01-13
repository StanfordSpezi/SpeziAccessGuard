//
// This source file is part of the Spezi open source project
//
// SPDX-FileCopyrightText: 2024 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

//struct CodeValidator {
//    let codeOption: CodeOptions
//    
//    func validate(_ code: String) -> ValidationResult {
//        // First check format (numeric vs alphanumeric)
//        if !validateFormat(code) {
//            return .failure(.invalidFormat)
//        }
//        
//        // Then check length
//        if !validateLength(code) {
//            return .failure(.invalidLength)
//        }
//        
//        return .success
//    }
//    
//    private func validateFormat(_ code: String) -> Bool {
//        if codeOption == .customAlphanumeric {
//            return true // Allow any character
//        }
//        return code.isNumeric // For all numeric types
//    }
//    
//    private func validateLength(_ code: String) -> Bool {
//        switch codeOption {
//        case .fourDigitNumeric:
//            return code.count <= 4
//        case .sixDigitNumeric:
//            return code.count <= 6
//        case .customNumeric, .customAlphanumeric:
//            return code.count >= 4 // Minimum length
//        default:
//            return false
//        }
//    }
//    
//    func shouldAutoSubmit(_ code: String) -> Bool {
//        switch codeOption {
//        case .fourDigitNumeric:
//            return code.count == 4
//        case .sixDigitNumeric:
//            return code.count == 6
//        case .customNumeric, .customAlphanumeric:
//            return false // Always require manual submission
//        default:
//            return false
//        }
//    }
//}

//enum ValidationResult {
//    case success
//    case failure(ValidationError)
//}
//
//enum ValidationError: LocalizedError {
//    case invalidFormat
//    case invalidLength
//    
//    var errorDescription: String? {
//        switch self {
//        case .invalidFormat:
//            return String(localized: "ACCESS_GUARD_ERROR_INVALID_CODE_FORMAT_ONLY_NUMERIC_ALLOWED", bundle: .module)
//        case .invalidLength:
//            return String(localized: "PASSCODE_NOT_ACCORDING_TO_FORMAT", bundle: .module)
//        }
//    }
//} 
