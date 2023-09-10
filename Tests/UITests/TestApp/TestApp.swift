//
// This source file is part of the SpeziAccessCode open-source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import SpeziAccessCode
import SwiftUI


@main
struct UITestsApp: App {
    @UIApplicationDelegateAdaptor(TestAppDelegate.self) var appDelegate
    
    
    var body: some Scene {
        WindowGroup {
            AccessGuarded {
                Color.green
                    .overlay {
                        Text("Secured ...")
                    }
            }
                .spezi(appDelegate)
        }
    }
}
