//
//  File.swift
//  MessengerMod
//
//  Created by aslan on 2023/10/18.
//

import Foundation
import CTADialog
import LarkMessengerInterface
import LarkContainer

open class CTADialogDependencyImpl: CTADialogDependency {
    private let resolver: UserResolver

    public init(resolver: UserResolver) {
        self.resolver = resolver
    }

    public func navigateToProfile(userId: String, from: UIViewController) {
        /// todo: fix fromWhere
        let body = PersonCardBody(chatterId: userId, fromWhere: .none)
        self.resolver.navigator.push(body: body, from: from)
    }
}
