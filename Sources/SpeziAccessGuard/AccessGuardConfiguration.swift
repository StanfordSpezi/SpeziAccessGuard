//
// This source file is part of the Spezi open source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import SwiftUI


/// Access Guard Configuration
@_documentation(visibility: internal)
public protocol _AccessGuardConfigurationProtocol: Sendable, Identifiable { // swiftlint:disable:this type_name
    /// The view used to unlock the access guard
    associatedtype _UnlockView: View // swiftlint:disable:this type_name
    /// This access guard's associated model type
    associatedtype _Model: _AnyAccessGuardModel where _Model.Config == Self // swiftlint:disable:this type_name
    
    /// The access guard's identifier
    var id: AccessGuardIdentifier<Self> { get }
    /// The access guard's timeout
    var timeout: Duration { get }
    
    /// The access guard's unlock view
    @_spi(Internal)
    @MainActor
    @ViewBuilder
    func _makeUnlockView(model: _Model) -> _UnlockView // swiftlint:disable:this identifier_name
}


extension _AccessGuardConfigurationProtocol {
    var typeErasedId: any _AnyAccessGuardIdentifier {
        id
    }
}
