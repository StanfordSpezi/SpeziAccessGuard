# ``SpeziAccessGuard``

<!--
                  
This source file is part of the Stanford Spezi open-source project

SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)

SPDX-License-Identifier: MIT
             
-->

Allows developers to guard a SwiftUI view with an access code.

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

## Setup

### 1. Add Spezi Access Guard as a Dependency

First, you will need to add the SpeziAccessGuard Swift package to
[your app in Xcode](https://developer.apple.com/documentation/xcode/adding-package-dependencies-to-your-app#) or
[Swift package](https://developer.apple.com/documentation/xcode/creating-a-standalone-swift-package-with-xcode#Add-a-dependency-on-another-Swift-package).

> If your application is not yet configured to use Spezi, follow the [Spezi setup article](https://swiftpackageindex.com/stanfordspezi/spezi/documentation/spezi/initial-setup) to set up the core Spezi infrastructure.

### 2. Register the Access Guard Module

#### Code-Based Access Guards

In the example below, we configure the ``AccessGuards`` module with one access guard that uses an access code and is identified by `exampleAccessGuard`.
The `codeFormat` parameter defines the type of code used, which in this case is a 4-digit numeric code.
The `timeout` property defines when the view should be locked based on the time the scene is not in the foreground.


```swift
import Spezi
import SpeziAccessGuard

class ExampleDelegate: SpeziAppDelegate {
    override var configuration: Configuration {
        Configuration {
            AccessGuards {
                CodeAccessGuard(.exampleAccessGuard, codeFormat: .numeric(4), isOptional: true, timeout: .seconds(10))
            }
        }
    }
}

extension AccessGuardIdentifier where AccessGuard == CodeAccessGuard {
    static let accessGuard1: Self = .passcode("edu.stanford.spezi.exampleAccessGuard1")
}
```

#### Biometric Access Guards

SpeziAccessGuard also supports biometric-based access guards, which are unlocked via Face ID or Touch ID.

> Note: If no biometric authentication method is available, biometric access guards use a 6-digit code-based access guard as a fallback.

```swift
import Spezi
import SpeziAccessGuard

class ExampleDelegate: SpeziAppDelegate {
    override var configuration: Configuration {
        Configuration {
            AccessGuardModule {
                BiometricAccessGuard(.accessGuard2)
            }
        }
    }
}

extension AccessGuardIdentifier where AccessGuard == BiometricAccessGuard {
    static let accessGuard2: Self = .biometric("edu.stanford.spezi.exampleAccessGuard2")
}
```

#### Alternative Code-based Access Guards

In addition to their "regular" behaviour, where the user is asked to set a passcode the first time an access guard is used (unless the app already prompted the user to set the code), ``CodeAccessGuard``s have two additional modes:
- Fixed-code access guard, which use an unchangeable code that is set by the app when defining the access guard in the module configuration
- Custom-validation access guards, which delegate the validation of the user-entered code to the app, allowing custom handling and additional patterns which cannot be represented using the regular and fixed-code access guards


Example: using ``CodeAccessGuard`` with a custom validation closure to implement consumable access codes, where each code can only be used once:

```swift
@MainActor
final class ConsumableCodes: Sendable {
    private(set) var consumedCodes: [String] = []
    private(set) var remainingCodes = [
        "1111", "2222", "3333", "4444"
    ]
    
    func validate(_ code: String) -> CodeAccessGuard.ValidationResult {
        if let idx = remainingCodes.firstIndex(of: code) {
            remainingCodes.remove(at: idx)
            consumedCodes.append(code)
            return .valid
        } else {
            return consumedCodes.contains(code) ? .invalid(message: "Already Consumed") : .invalid
        }
    }
}


// in the Spezi App Delegate
override var configuration: Configuration {
    let consumableCodes = ConsumableCodes()
    AccessGuardModule {
        CodeAccessGuard(.exampleAccessGuard1, fixed: "1234")
        CodeAccessGuard(.exampleAccessGuard3, format: .numeric(4)) { code in
            await consumableCodes.validate(code)
        }
    }
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
