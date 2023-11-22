//
// This source file is part of the Spezi open source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import XCTest


class TestAppUITests: XCTestCase {
    override func setUpWithError() throws {
        try super.setUpWithError()
        
        continueAfterFailure = false
    }
    
    func testFixedCode() throws {
        let app = XCUIApplication()
        app.launch()
        
        app.buttons["Access Guarded Fixed"].tap()
        app.secureTextFields["Passcode Field"].tap()
        app.secureTextFields["Passcode Field"].typeText("1234")
        
        XCTAssert(app.staticTexts["Secured with fixed code ..."].waitForExistence(timeout: 2.0))
        XCTAssert(app.staticTexts["Secured with fixed code ..."].isHittable)
    }
    
    
    func testAccessCode() throws { // swiftlint:disable:this function_body_length
        let app = XCUIApplication()
        app.launch()
        
        app.buttons["Reset Access Guards"].tap()
        
        app.buttons["Access Guarded"].tap()
        
        XCTAssert(app.staticTexts["Secured ..."].waitForExistence(timeout: 2.0))
        XCTAssert(app.staticTexts["Secured ..."].isHittable)
        
        app.buttons["Back"].tap()
        
        
        XCTAssert(app.buttons["Set Code"].waitForExistence(timeout: 2.0))
        app.buttons["Set Code"].tap()
        
        // Set first passcode
        XCTAssert(app.staticTexts["Please enter your new passcode"].waitForExistence(timeout: 2.0))
        XCTAssert(app.secureTextFields["Passcode Field"].waitForExistence(timeout: 2.0))
        app.secureTextFields["Passcode Field"].tap()
        app.secureTextFields["Passcode Field"].typeText("1111")
        
        // Go back once
        XCTAssert(app.staticTexts["Please repeat your new passcode"].waitForExistence(timeout: 2.0))
        XCTAssert(app.buttons["Reset"].waitForExistence(timeout: 2.0))
        app.buttons["Reset"].tap()
        
        // Enter new first passcode
        XCTAssert(app.staticTexts["Please enter your new passcode"].waitForExistence(timeout: 2.0))
        XCTAssert(app.secureTextFields["Passcode Field"].waitForExistence(timeout: 2.0))
        app.secureTextFields["Passcode Field"].tap()
        app.secureTextFields["Passcode Field"].typeText("1112")
        
        // Enter a wrong repeat passcode
        XCTAssert(app.staticTexts["Please repeat your new passcode"].waitForExistence(timeout: 2.0))
        XCTAssert(app.secureTextFields["Passcode Field"].waitForExistence(timeout: 2.0))
        app.secureTextFields["Passcode Field"].tap()
        app.secureTextFields["Passcode Field"].typeText("1113")
        
        // Enter correct repeat passcode
        XCTAssert(app.staticTexts["Passcodes not equal"].waitForExistence(timeout: 2.0))
        XCTAssert(app.secureTextFields["Passcode Field"].waitForExistence(timeout: 2.0))
        app.secureTextFields["Passcode Field"].tap()
        app.secureTextFields["Passcode Field"].typeText("1112")
        
        // Success
        XCTAssert(app.images["Passcode set was successful"].waitForExistence(timeout: 2.0))
        app.buttons["Back"].tap()
        
        // View should be unlocked as we just set the passcode ...
        XCTAssert(app.buttons["Access Guarded"].waitForExistence(timeout: 2.0))
        app.buttons["Access Guarded"].tap()
        XCTAssert(app.staticTexts["Secured ..."].waitForExistence(timeout: 2.0))
        XCTAssert(app.staticTexts["Secured ..."].isHittable)
        
        // Try the new passcode
        app.terminate()
        app.launch()
        XCTAssert(app.buttons["Access Guarded"].waitForExistence(timeout: 2.0))
        app.buttons["Access Guarded"].tap()
        
        XCTAssert(app.secureTextFields["Passcode Field"].waitForExistence(timeout: 2.0))
        app.secureTextFields["Passcode Field"].tap()
        app.secureTextFields["Passcode Field"].typeText("1112")
        
        XCTAssert(app.staticTexts["Secured ..."].waitForExistence(timeout: 2.0))
        XCTAssert(app.staticTexts["Secured ..."].isHittable)
        
        // Go to the home screen and see if the view is still visable in less than 10 seconds.
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        springboard.activate()
        XCTAssert(springboard.wait(for: .runningForeground, timeout: 2))
        app.activate()
        
        XCTAssert(app.staticTexts["Secured ..."].waitForExistence(timeout: 2.0))
        XCTAssert(app.staticTexts["Secured ..."].isHittable)
        
        // Try with a time longer than the timeout:
        springboard.activate()
        XCTAssert(springboard.wait(for: .runningForeground, timeout: 2))
        
        sleep(11)
        
        app.activate()
        XCTAssert(app.secureTextFields["Passcode Field"].waitForExistence(timeout: 2.0))
        app.secureTextFields["Passcode Field"].tap()
        app.secureTextFields["Passcode Field"].typeText("1112")
        
        XCTAssert(app.staticTexts["Secured ..."].waitForExistence(timeout: 2.0))
        XCTAssert(app.staticTexts["Secured ..."].isHittable)
        
        // Go Back to the main view:
        app.buttons["Back"].tap()
        
        // Check that the passcode is removed if it is no longer set.
        app.buttons["Reset Access Guards"].tap()
        
        app.buttons["Access Guarded"].tap()
        
        XCTAssert(app.staticTexts["Secured ..."].waitForExistence(timeout: 2.0))
        XCTAssert(app.staticTexts["Secured ..."].isHittable)
    }
    
    func testAccessCodeWithBiometrics() throws {
        // We cannot directly test FaceID or TouchID in a UI test
        // so we will test that the access code works
        // as a fallback to the biometrics
        let app = XCUIApplication()
        app.launch()
        
        // Reset all passcodes
        app.buttons["Reset Access Guards"].tap()
        
        // Test biometrics guard without a passcode
        app.buttons["Access Guarded Biometrics"].tap()
        
        XCTAssert(app.staticTexts["Secured with biometrics ..."].waitForExistence(timeout: 2))
        XCTAssert(app.staticTexts["Secured with biometrics ..."].isHittable)
        
        app.buttons["Back"].tap()
        
        // Set the passcode
        XCTAssert(app.buttons["Set Biometric Backup Code"].waitForExistence(timeout: 2))
        app.buttons["Set Biometric Backup Code"].tap()
        
        XCTAssert(app.staticTexts["Please enter your new passcode"].waitForExistence(timeout: 2))
        XCTAssert(app.secureTextFields["Passcode Field"].waitForExistence(timeout: 2))
        app.secureTextFields["Passcode Field"].tap()
        app.secureTextFields["Passcode Field"].typeText("1111")
        
        XCTAssert(app.staticTexts["Please repeat your new passcode"].waitForExistence(timeout: 2.0))
        app.secureTextFields["Passcode Field"].typeText("1111")
        
        XCTAssert(app.images["Passcode set was successful"].waitForExistence(timeout: 2.0))
        app.buttons["Back"].tap()
        
        // Try the passcode
        app.terminate()
        app.launch()
        XCTAssert(app.buttons["Access Guarded Biometrics"].waitForExistence(timeout: 2.0))
        app.buttons["Access Guarded Biometrics"].tap()
        
        XCTAssert(app.secureTextFields["Passcode Field"].waitForExistence(timeout: 2.0))
        app.secureTextFields["Passcode Field"].tap()
        app.secureTextFields["Passcode Field"].typeText("1111")
        
        XCTAssert(app.staticTexts["Secured with biometrics ..."].waitForExistence(timeout: 2.0))
        XCTAssert(app.staticTexts["Secured with biometrics ..."].isHittable)
    }
}
