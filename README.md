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

Enforce code or biometrics-guarded access to SwiftUI views.

|<picture><source media="(prefers-color-scheme: dark)" srcset="Sources/SpeziAccessGuard/SpeziAccessGuard.docc/Resources/AccessGuarded-dark.png"><img src="Sources/SpeziAccessGuard/SpeziAccessGuard.docc/Resources/AccessGuarded.png" width="250" alt="Screenshot showing access guarded to a SwiftUI view by an access code." /></picture>|<picture><source media="(prefers-color-scheme: dark)" srcset="Sources/SpeziAccessGuard/SpeziAccessGuard.docc/Resources/AccessGuarded-Biometrics-dark.png"><img src="Sources/SpeziAccessGuard/SpeziAccessGuard.docc/Resources/AccessGuarded-Biometrics.png" width="250" alt="Screenshot showing access guarded to a SwiftUI view by Face ID with an access code fallback." /></picture>|
|:--:|:--:|
|4-digit Numeric Access Code|Face ID with Access Code Fallback|

## Overview

Enforce code or biometrics-guarded access to SwiftUI views.

For more information, please refer to the [API documentation](https://swiftpackageindex.com/StanfordSpezi/SpeziAccessGuard/documentation).

### Setup

You need to add the SpeziAccessGuard Swift package to
[your app in Xcode](https://developer.apple.com/documentation/xcode/adding-package-dependencies-to-your-app) or
[Swift package](https://developer.apple.com/documentation/xcode/creating-a-standalone-swift-package-with-xcode#Add-a-dependency-on-another-Swift-package).

> [!IMPORTANT]  
> If your application is not yet configured to use Spezi, follow the [Spezi setup article](https://swiftpackageindex.com/stanfordspezi/spezi/documentation/spezi/initial-setup) to set up the core Spezi infrastructure.


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

For more information, please refer to the [API documentation](https://swiftpackageindex.com/StanfordSpezi/SpeziAccessGuard/documentation/speziaccessguard).


## Contributing

Contributions to this project are welcome. Please make sure to read the [contribution guidelines](https://github.com/StanfordSpezi/.github/blob/main/CONTRIBUTING.md) and the [contributor covenant code of conduct](https://github.com/StanfordSpezi/.github/blob/main/CODE_OF_CONDUCT.md) first.


## License

This project is licensed under the MIT License. See [Licenses](https://github.com/StanfordSpezi/SpeziAccessGuard/tree/main/LICENSES) for more information.

![Spezi Footer](https://raw.githubusercontent.com/StanfordSpezi/.github/main/assets/FooterLight.png#gh-light-mode-only)
![Spezi Footer](https://raw.githubusercontent.com/StanfordSpezi/.github/main/assets/FooterDark.png#gh-dark-mode-only)
