//
// This source file is part of the Spezi open source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

@testable import SpeziAccessCode
import XCTest


final class SpeziAccessCodeTests: XCTestCase {
    func testSpeziAccessCode() throws {
        let templatePackage = SpeziAccessCode()
        XCTAssertEqual(templatePackage.stanford, "Stanford University")
    }
}
