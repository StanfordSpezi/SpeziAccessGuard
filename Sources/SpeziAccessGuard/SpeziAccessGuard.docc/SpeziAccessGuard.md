# ``SpeziAccessGuard``

<!--
                  
This source file is part of the Stanford Spezi open-source project

SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)

SPDX-License-Identifier: MIT
             
-->

Enforce code or biometrics-guarded access to SwiftUI views.

## Overview

The Access Guard module allows developers to guard a SwiftUI view with an access code or biometrics and allows users to set or reset their access codes.

@Row {
    @Column {
        @Image(source: "AccessGuarded", alt: "Screenshot showing access guarded to a SwiftUI view by an access code.") {
            An ``AccessGuarded`` view guarding access to a SwiftUI view by an access code.
        }
    }
    @Column {
        @Image(source: "AccessGuarded-Biometrics", alt: "Screenshot showing access guarded to a SwiftUI view by Face ID with an access code fallback.") {
            An ``AccessGuarded`` view guarding access to a SwiftUI view by Face ID with an access code fallback.
        }
    }
}

### Setup

You need to add the SpeziAccessGuard Swift package to
[your app in Xcode](https://developer.apple.com/documentation/xcode/adding-package-dependencies-to-your-app) or
[Swift package](https://developer.apple.com/documentation/xcode/creating-a-standalone-swift-package-with-xcode#Add-a-dependency-on-another-Swift-package).

- Important: If your application is not yet configured to use Spezi, follow the [Spezi setup article](https://swiftpackageindex.com/stanfordspezi/spezi/documentation/spezi/initial-setup) to set up the core Spezi infrastructure.

## Usage

You use the ``AccessGuards`` module to define your app's access guards, as part of the overall Spezi configuration:
```swift
import Spezi
import SpeziAccessGuard

class ExampleDelegate: SpeziAppDelegate {
    override var configuration: Configuration {
        Configuration {
            AccessGuards {
                CodeAccessGuard(.transactions)
                BiometricAccessGuard(.accountInfo)
                CodeAccessGuard(.hiddenFeature, fixed: "7184")
            }
        }
    }
}

extension AccessGuardIdentifier where AccessGuard == CodeAccessGuard {
    static let transactions: Self = .passcode("com.myApp.transactions")
    static let hiddenFeature: Self = .passcode("com.myApp.hiddenFeature")
}

extension AccessGuardIdentifier where AccessGuard == BiometricAccessGuard {
    static let accountInfo: Self = .passcode("com.myApp.accountInfo")
}
```

You then can use these Access Guards in your app, e.g. via the ``AccessGuarded`` view, which automatically manages the presentation and unlocking of the access guard for you:
```swift
var body: some View {
    TabView {
        // ...
        Tab("Account", systemImage: "person.circle") {
            AccessGuarded(.accountInfo) {
                AccountTab()
            }
        }
    }
}
```
- Tip: If you need more/custom control over the guard, e.g. to build a custom unlock experience, use the ``AccessGuard`` property wrapper to inspect and interact with the guard's underlying state within a View.


There are different types of access guards:
- code-based access guards, which require the user to enter a passcode in order to unlock the guard and access the guarded UI
- biometric-based access guards, which use Face ID or Touch ID to unlock the guard

Each guard must be defined in the ``AccessGuards`` module configuration (see above), and must be uniquely identified by an ``AccessGuardIdentifier``.
SpeziAccessGuard will automatically manage and persist each guard's state; for ``CodeAccessGuard``s, the passcodes are securely stored in the system keychain.


All access guards have a timeout, which governs how long the guard should stay unlocked after the user closes the app.
Additionally, all guards can either be required (the default), or optional.
If a guard is non-optional (i.e., required), it's default state is locked, even if no passcode is set; if the guard is optional, and no code is set, its default state is to be unlocked.

You can use the ``AccessGuard`` property wrapper and the ``AccessGuards`` environment object to work with individual guards within your application, e.g. to manually lock them or to reset their codes.


### Biometric Access Guards

``BiometricAccessGuard``s are unlocked via Face ID or Touch ID; the user simply is prompted to perform the biometric authentication in order to unlock the guard.

> Note: If neither Face ID nor Touch ID is available, biometric access guards use a 6-digit code-based access guard as a fallback.

```swift
import Spezi
import SpeziAccessGuard

class ExampleDelegate: SpeziAppDelegate {
    override var configuration: Configuration {
        Configuration {
            AccessGuards {
                BiometricAccessGuard(.transactionsList)
            }
        }
    }
}

extension AccessGuardIdentifier where AccessGuard == BiometricAccessGuard {
    static let transactionsList: Self = .biometric("com.MyApp.transactionsList")
}
```

The API for using biometric access guards is identical to the one for using code-based access guards.

- Important: In order to use biometric access guards, you need to add the `NSFaceIDUsageDescription` key to your app's Info.plist.


### Code-Based Access Guards

The ``CodeAccessGuard`` takes three forms:
1. Regular: the user is prompted to define a passcode for the guard, which is then used to unlock the view. (See ``CodeAccessGuard/init(_:codeFormat:isOptional:timeout:)``.)
2. Fixed-code: the guard's passcode is hardcoded by the app. (See ``CodeAccessGuard/init(_:fixed:timeout:)``.)
3. Dynamic: closure-based API that allows the app to validate the guard's code entry. (See ``CodeAccessGuard/init(_:timeout:message:format:validate:)``.)

In the example below, we configure the ``AccessGuards`` module with one access guard that uses an access code and is identified by `exampleAccessGuard`.
The `codeFormat` parameter defines the type of code used, which in this case is a 4-digit numeric code.
The `timeout` property defines when the view should be locked based on the time the app is not in the foreground.

```swift
import Spezi
import SpeziAccessGuard

class ExampleDelegate: SpeziAppDelegate {
    override var configuration: Configuration {
        Configuration {
            AccessGuards {
                CodeAccessGuard(
                    .exampleAccessGuard,
                    codeFormat: .numeric(4),
                    isOptional: true,
                    timeout: .hours(1)
                )
            }
        }
    }
}

extension AccessGuardIdentifier where AccessGuard == CodeAccessGuard {
    static let exampleAccessGuard: Self = .passcode("edu.stanford.spezi.exampleAccessGuard")
}
```


## Topics

### Access Guard Types
- ``AccessGuards``
- ``AccessGuardIdentifier``
- ``CodeAccessGuard``
- ``BiometricAccessGuard``

### UI Components
- ``AccessGuarded``
- ``AccessGuard``
- ``SetAccessGuard``
- ``AccessGuardButton``
