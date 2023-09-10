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
            NavigationStack {
                List {
                    NavigationLink("Access Guarded") {
                        AccessGuarded(identifier: "TestIdentifier") {
                            Color.green
                                .overlay {
                                    Text("Secured ...")
                                }
                        }
                    }
                    NavigationLink("Access Guarded Fixed") {
                        AccessGuarded(fixedCode: "1234") {
                            Color.green
                                .overlay {
                                    Text("Secured with fixed code ...")
                                }
                        }
                    }
                    NavigationLink("Set Code") {
                        SetAccessGuard(identifier: "TestIdentifier")
                    }
                }
            }
                .spezi(appDelegate)
        }
    }
}
