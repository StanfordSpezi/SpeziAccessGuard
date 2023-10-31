<!--

This source file is part of the Stanford Spezi open-source project.

SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)

SPDX-License-Identifier: MIT
  
-->

# Spezi Access Guard

[![Build and Test](https://github.com/StanfordSpezi/SpeziAccessGuard/actions/workflows/build-and-test.yml/badge.svg)](https://github.com/StanfordSpezi/SpeziAccessGuard/actions/workflows/build-and-test.yml)
[![codecov](https://codecov.io/gh/StanfordSpezi/SpeziAccessGuard/graph/badge.svg?token=8AFI6Q1WvM)](https://codecov.io/gh/StanfordSpezi/SpeziAccessGuard)
[![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.8332974.svg)](https://doi.org/10.5281/zenodo.8332974)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2FStanfordSpezi%2FSpeziAccessGuard%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/StanfordSpezi/SpeziAccessGuard)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2FStanfordSpezi%2FSpeziAccessGuard%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/StanfordSpezi/SpeziAccessGuard)

Allows developers to easily guard a SwiftUI view with an access code.

|![Screenshot showing access guarded to a SwiftUI view by an access code.](Sources/SpeziAccessGuard/SpeziAccessGuard.docc/Resources/AccessGuarded.png#gh-light-mode-only)![Screenshot showing access guarded to a SwiftUI view by an access code.](Sources/SpeziAccessGuard/SpeziAccessGuard.docc/Resources/AccessGuarded-dark.png#gh-dark-mode-only)|
|:--:|
|[`AccessGuarded`](https://swiftpackageindex.com/stanfordspezi/speziaccessguard/0.1.1/documentation/speziaccessguard/accessguarded)

## Overview

The Access Guard module allows developers to guard a SwiftUI view with an access code view and allows users to set or reset their access codes.

For more information, please refer to the [API documentation](https://swiftpackageindex.com/StanfordSpezi/SpeziAccessGuard/documentation).

## Setup

### 1. Add Spezi Access Guard as a Dependency

First, you will need to add the SpeziAccessGuard Swift package to
[your app in Xcode](https://developer.apple.com/documentation/xcode/adding-package-dependencies-to-your-app#) or
[Swift package](https://developer.apple.com/documentation/xcode/creating-a-standalone-swift-package-with-xcode#Add-a-dependency-on-another-Swift-package).

### 2. Register the Access Guard Component

> [!IMPORTANT]
> If your application is not yet configured to use Spezi, follow the [Spezi setup article](https://swiftpackageindex.com/stanfordspezi/spezi/documentation/spezi/initial-setup) to set up the core Spezi infrastructure.

You can configure the [`AccessGuard`](https://swiftpackageindex.com/stanfordspezi/speziaccessguard/0.1.1/documentation/speziaccessguard/accessguard) component in the [`SpeziAppDelegate`](https://swiftpackageindex.com/stanfordspezi/spezi/documentation/spezi/speziappdelegate) as follows.

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

In the example above, we configure the [`AccessGuard`](https://swiftpackageindex.com/stanfordspezi/speziaccessguardt/documentation/speziaccessguard/accessguard) component with one access guard that uses a 4-digit numerical access code and is identified by `ExampleIdentifier`. The `timeout` property defines when the view should be locked based on the time the scene is not in the foreground, in seconds.

> [!NOTE]  
> You can learn more about a [`Component` in the Spezi documentation](https://swiftpackageindex.com/stanfordspezi/spezi/documentation/spezi/component).

## Examples

### Setting an Access Code

Using [`SetAccessGuard`](https://swiftpackageindex.com/stanfordspezi/speziaccessguard/0.1.1/documentation/speziaccessguard/setaccessguard), we can create a view that allows the user to set their access code.

```swift
import SpeziAccessGuard

struct SetAccessCode: View {
    var body: some View {
        SetAccessGuard(identifier: "ExampleIdentifier")
    }
}
```

### Guarding Access to a SwiftUI View

Now, we can use the [`AccessGuarded`](https://swiftpackageindex.com/stanfordspezi/speziaccessguard/0.1.1/documentation/speziaccessguard/accessguarded) view to guard access to a SwiftUI view with an access code.

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

The access guard will lock automatically when it times out. However, we can also lock an access guard directly using the  [`lock(identifier:)`](https://swiftpackageindex.com/stanfordspezi/speziaccessguard/documentation/speziaccessguard/accessguard/lock(identifier:)) method. Here, we add a toolbar item with a button that will lock the access guard.

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

To remove the access code and all information from an access guard, we can use the [`resetAccessCode(for:)`](https://swiftpackageindex.com/stanfordspezi/speziaccessguard/documentation/speziaccessguard/accessguard/resetaccesscode(for:)) method. Here, we add a toolbar item with a button that will reset the access guard.

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

For more information, please refer to the [API documentation](https://swiftpackageindex.com/StanfordSpezi/SpeziAccessGuard/documentation/speziaccessguard).

## Contributing

Contributions to this project are welcome. Please make sure to read the [contribution guidelines](https://github.com/StanfordSpezi/.github/blob/main/CONTRIBUTING.md) and the [contributor covenant code of conduct](https://github.com/StanfordSpezi/.github/blob/main/CODE_OF_CONDUCT.md) first.


## License

This project is licensed under the MIT License. See [Licenses](https://github.com/StanfordSpezi/SpeziAccessGuard/tree/main/LICENSES) for more information.

![Spezi Footer](https://raw.githubusercontent.com/StanfordSpezi/.github/main/assets/FooterLight.png#gh-light-mode-only)
![Spezi Footer](https://raw.githubusercontent.com/StanfordSpezi/.github/main/assets/FooterDark.png#gh-dark-mode-only)
