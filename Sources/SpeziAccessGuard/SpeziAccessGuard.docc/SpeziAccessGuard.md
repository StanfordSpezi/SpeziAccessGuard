# ``SpeziAccessGuard``

<!--
                  
This source file is part of the Stanford Spezi open-source project

SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)

SPDX-License-Identifier: MIT
             
-->

Allows developers to guard a SwiftUI view with an access code.

## Overview

The Access Guard module allows developers to guard a SwiftUI view with an access code view and allows users to set or reset their access codes.

@Row {
    @Column {
        @Image(source: "AccessGuarded", alt: "Screenshot showing access guarded to a SwiftUI view by an access code.") {
            An ``AccessGuarded`` view guarding access to a SwiftUI view by an access code.
        }
    }
}

## Setup

### Add SpeziAccessGuard as a Dependency

First, you will need to add the SpeziAccessGuard Swift package to
[your app in Xcode](https://developer.apple.com/documentation/xcode/adding-package-dependencies-to-your-app#) or
[Swift package](https://developer.apple.com/documentation/xcode/creating-a-standalone-swift-package-with-xcode#Add-a-dependency-on-another-Swift-package).

> If your application is not yet configured to use Spezi, follow the [Spezi setup article](https://swiftpackageindex.com/stanfordspezi/spezi/documentation/spezi/setup) to set up the core Spezi infrastructure.

### Configuring the SpeziAccessGuard Module

You can configure the ``SpeziAccessGuard`` module in the `SpeziAppDelegate`` as follows.

```swift
import Spezi
import SpeziAccessGuard


class ExampleDelegate: SpeziAppDelegate {
    override var configuration: Configuration {
        Configuration {
            AccessGuard(
                [
                    .code(identifier: "ExampleIdentifier", timeout: 15 * 60)
                ]
            )
        }
    }
}
```

In the example above, we configure the ``AccessGuard`` with one guard that uses a 4-digit numerical access code and is identified by `ExampleIdentifier`. The `timeout` property defines when the view should be locked based on the time the scene is not in the foreground, in seconds.

## Examples

### Setting an Access Code

Using ``SetAccessGuard``, we can create a view that allows the user to set their access code.

```swift
import SpeziAccessGuard

struct SetAccessCode: View {
    var body: some View {
        SetAccessGuard(identifier: "ExampleIdentifier")
    }
}
```

### Guarding Access to a SwiftUI View

Now, we can use the the ``AccessGuarded`` view to guard access to a SwiftUI view with an access code.

```swift
import SpeziAccessGuard

struct ProtectedContent: View {    
    var body: some View {
        AccessGuarded("ExampleIdentifier") {
            Text("Secured content...")
        }
    }
}
```

### Locking an Access Guard

The access guard will lock automatically when it times out. However, we can also lock an access guard directly using the ``AccessGuard/lock(identifier:)`` method. Here, we add a toolbar item with a button that will lock the access guard.

```swift
struct ProtectedContent: View {
    @EnvironmentObject private var accessGuard: AccessGuard
    
    var body: some View {
        AccessGuarded("ExampleIdentifier") {
            Text("Secured content...")
        }
        .toolbar {
            ToolbarItem {
                Button("Lock Access Guard") {
                    try? accessGuard.lock(identifier: "ExampleIdentifier")
                }
            }
        }
    }
}
```

### Resetting an Access Guard

To remove the access code and all information from an access guard, we can use the ``AccessGuard/resetAccessCode(for:)`` method. Here, we add a toolbar item with a button that will lock the access guard.

```swift
struct ProtectedContent: View {
    @EnvironmentObject private var accessGuard: AccessGuard
    
    var body: some View {
        AccessGuarded("ExampleIdentifier") {
            Text("Secured content...")
        }
        .toolbar {
            ToolbarItem {
                Button("Reset Access Guard") {
                    try? accessGuard.resetAccessCode(for: "ExampleIdentifier")
                }
            }
        }
    }
}
```