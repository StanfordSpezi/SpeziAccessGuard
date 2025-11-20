//
// This source file is part of the Spezi open source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

public import Foundation
import enum UIKit.UIKeyboardType


/// Passcode Format Rules
///
/// ## Topics
/// ### Formats
/// - ``numeric(_:)-(Int)``
/// - ``numeric(_:)-(PartialRangeFrom<Int>)``
/// - ``alphanumeric(_:)-(Int)``
/// - ``alphanumeric(_:)-(PartialRangeFrom<Int>)``
///
/// ### Enumeration Cases
/// - ``numeric(_:)-enum.case``
/// - ``alphanumeric(_:)-enum.case``
public enum PasscodeFormat: Hashable, Sendable, Codable {
    case numeric(Length)
    case alphanumeric(Length)
    
    public enum Length: Hashable, Codable, Sendable {
        case exact(Int)
        case atLeast(Int)
    }
    
    /// A numeric code of fixed length
    public static func numeric(_ length: Int) -> Self {
        .numeric(.exact(length))
    }
    
    /// A numeric code with a minimum length
    public static func numeric(_ length: PartialRangeFrom<Int>) -> Self {
        .numeric(.atLeast(length.lowerBound))
    }
    
    /// An alphanumeric code of fixed length
    public static func alphanumeric(_ length: Int) -> Self {
        .alphanumeric(.exact(length))
    }
    
    /// An alphanumeric code with a minimum length
    public static func alphanumeric(_ length: PartialRangeFrom<Int>) -> Self {
        .alphanumeric(.atLeast(length.lowerBound))
    }
}


extension PasscodeFormat {
    var length: Length {
        switch self {
        case .numeric(let length), .alphanumeric(let length):
            length
        }
    }
    
    var keyboardType: UIKeyboardType {
        switch self {
        case .numeric:
            .numberPad
        case .alphanumeric:
            .asciiCapable
        }
    }
    
    func validate(code: String) -> Bool {
        switch self {
        case .numeric(.exact(let length)):
            code.allSatisfy(\.isNumber) && code.count == length
        case .numeric(.atLeast(let minLength)):
            code.allSatisfy(\.isNumber) && code.count >= minLength
        case .alphanumeric(.exact(let length)):
            code.allSatisfy { $0.isNumber || $0.isLetter } && code.count == length
        case .alphanumeric(.atLeast(let minLength)):
            code.allSatisfy { $0.isNumber || $0.isLetter } && code.count >= minLength
        }
    }
}


extension PasscodeFormat: CustomLocalizedStringResourceConvertible {
    public var localizedStringResource: LocalizedStringResource {
        switch self {
        case .numeric(.exact(let length)):
            "\(length)-Digit Numeric Code"
        case .numeric(.atLeast(let minLength)):
            "\(minLength)+-Digit Numeric Code"
        case .alphanumeric(.exact(let length)):
            "\(length)-Digit Alphanumeric Code"
        case .alphanumeric(.atLeast(let minLength)):
            "\(minLength)+-Digit Alphanumeric Code"
        }
    }
}


extension PasscodeFormat {
    static func automatic(forFixedCode fixedCode: String) -> Self {
        if fixedCode.allSatisfy({ $0.isASCII && $0.isNumber }) {
            .numeric(fixedCode.count)
        } else {
            .alphanumeric(fixedCode.count)
        }
    }
}
