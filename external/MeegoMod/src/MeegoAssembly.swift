//
//  MeegoAssembly.swift
//  Lark
//
//  Created by shizhengyu on 2021/9/7.
//  Copyright © 2021 shizhengyu All rights reserved.
//

import Foundation
import Swinject
import LarkMeego
import LarkFlutterContainer
import LarkAssembler
import LarkContainer
import LarkMeegoStrategy

public final class MeegoAssembly: LarkAssemblyInterface {
    public init() {}

    public func registContainer(container: Container) {
        let userGraph = container.inObjectScope(Meego.userGraphScope)

        userGraph.register(MeegoFlutterDependency.self) { resolver -> MeegoFlutterDependency in
            return try MeegoDependencyImpl(resolver: resolver)
        }

        userGraph.register(MeegoNativeDependency.self) { resolver -> MeegoNativeDependency in
            return try MeegoDependencyImpl(resolver: resolver)
        }

        userGraph.register(FlutterDockDependency.self) { resolver -> FlutterDockDependency in
            return try MeegoDependencyImpl(resolver: resolver)
        }

        userGraph.register(MeegoStrategyServiceDependency.self) { resolver -> MeegoStrategyServiceDependency in
            return try MeegoDependencyImpl(resolver: resolver)
        }
    }

    public func getSubAssemblies() -> [LarkAssemblyInterface]? {
        LarkMeegoAssembly()
    }
}
