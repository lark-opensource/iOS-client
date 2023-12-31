//
//  LarkShareContainerAssembly.swift
//  LarkShareContainer
//
//  Created by shizhengyu on 2020/12/29.
//

import Foundation
import AppContainer
import LKCommonsLogging
import Swinject
import EENavigator
import LarkAssembler

// MARK: - Assembly
public final class LarkShareContainerAssembly: LarkAssemblyInterface {
    public init() {}

    public func registRouter(container: Container) {
        Navigator.shared.registerRoute.type(LarkShareContainterBody.self)
            .factory(LarkShareContainterHandler.init(resolver:))
    }
}
