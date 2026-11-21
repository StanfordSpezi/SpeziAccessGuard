//
// This source file is part of the Spezi open source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

@testable import SpeziAccessGuard
import Testing


@Test
func numericFormatFiltersLetters() {
    let format = PasscodeFormat.numeric(4)
    #expect(format.filteringInvalidCharacters(from: "1a2b") == "12")
    #expect(format.filteringInvalidCharacters(from: "1234") == "1234")
    #expect(format.filteringInvalidCharacters(from: "abcd").isEmpty)
    #expect(format.filteringInvalidCharacters(from: "1 2-3.4") == "1234")
}

@Test
func alphanumericFormatFiltersSpecialChars() {
    let format = PasscodeFormat.alphanumeric(6)
    #expect(format.filteringInvalidCharacters(from: "abc!@#") == "abc")
    #expect(format.filteringInvalidCharacters(from: "ab12cd") == "ab12cd")
    #expect(format.filteringInvalidCharacters(from: "ab 12") == "ab12")
}

@Test
func invalidCharacterMessageIsPresent() {
    #expect(PasscodeFormat.numeric(4).invalidCharacterMessage != nil)
    #expect(PasscodeFormat.alphanumeric(6).invalidCharacterMessage != nil)
}
