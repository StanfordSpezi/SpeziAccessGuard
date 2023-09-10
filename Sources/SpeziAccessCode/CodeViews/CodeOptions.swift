//
// This source file is part of the Spezi open source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import UIKit


/// An [option set](https://developer.apple.com/documentation/swift/optionset) of access code options.
public struct CodeOptions: OptionSet, Codable, CaseIterable, Identifiable {
    public static var allCases: [CodeOptions] = [
        .fourDigitNumeric,
        .sixDigitNumeric,
        .customNumeric,
        .customAlphanumeric
    ]
    
    /// A four digit numeric code.
    public static let fourDigitNumeric = CodeOptions(rawValue: 1 << 0)
    /// A six digit numeric code.
    ///
    /// > Warning: Not yet implemented
    private static let sixDigitNumeric = CodeOptions(rawValue: 1 << 1)
    /// A numeric code with at least four digits in length.
    ///
    /// > Warning: Not yet implemented
    private static let customNumeric = CodeOptions(rawValue: 1 << 2)
    /// A alphanumeric code with at least four characters in length.
    ///
    /// > Warning: Not yet implemented
    private static let customAlphanumeric = CodeOptions(rawValue: 1 << 3)
    
    /// A finite numeric code.
    ///
    /// > Warning: Not yet implemented
    private static let finiteNumeric: CodeOptions = [.fourDigitNumeric, .sixDigitNumeric]
    /// A numeric code.
    ///
    /// > Warning: Not yet implemented
    private static let numeric: CodeOptions = [.fourDigitNumeric, .sixDigitNumeric, .customNumeric]
    /// A numeric or alphanumeric code.
    ///
    /// > Warning: Not yet implemented
    public static let all: CodeOptions = [.fourDigitNumeric, .sixDigitNumeric, .customNumeric, .customAlphanumeric]
    
    
    public var id: Int {
        rawValue
    }
    
    var maxLength: Int {
        if self.contains(CodeOptions.customNumeric) || self.contains(CodeOptions.customAlphanumeric) {
            return Int.max
        } else if self.contains(CodeOptions.sixDigitNumeric) {
            return 6
        } else if self.contains(CodeOptions.fourDigitNumeric) {
            return 4
        }
        
        return Int.max
    }
    
    public var description: LocalizedStringResource {
        switch self {
        case .fourDigitNumeric:
            return LocalizedStringResource("CODE_OPTIONS_FOUR_DIGIT", bundle: .atURL(from: .module))
        case .sixDigitNumeric:
            return LocalizedStringResource("CODE_OPTIONS_SIX_DIGIT", bundle: .atURL(from: .module))
        case .customNumeric:
            return LocalizedStringResource("CODE_OPTIONS_CUSTOM_NUMERIC_DIGIT", bundle: .atURL(from: .module))
        case .customAlphanumeric:
            return LocalizedStringResource("CODE_OPTIONS_CUSTOM_ALPHANUMERIC_DIGIT", bundle: .atURL(from: .module))
        default:
            return LocalizedStringResource("CODE_OPTIONS_DEFAULT_DIGIT", bundle: .atURL(from: .module))
        }
    }
    
    var keyBoardType: UIKeyboardType {
        if self.contains(.customAlphanumeric) {
            return .default
        } else {
            return .numberPad
        }
    }
    
    public let rawValue: Int
    
    
    /// Raw initializer for the ``CodeOptions`` option set. Do not use this initializer.
    /// - Parameter rawValue: The raw option set value.
    public init(rawValue: Int) {
        self.rawValue = rawValue
    }
    
    
    func verifyStructore(ofCode code: String) -> Bool {
        switch self {
        case .fourDigitNumeric, .sixDigitNumeric:
            return code.isEmpty && code.count == maxLength
        case .customNumeric:
            return code.isNumeric && code.count >= CodeOptions.fourDigitNumeric.maxLength
        case .customAlphanumeric:
            return code.count >= CodeOptions.fourDigitNumeric.maxLength
        default:
            return false
        }
    }
}
