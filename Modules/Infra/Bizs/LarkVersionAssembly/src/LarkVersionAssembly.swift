//
//  LarkVersionAssembly.swift
//  LarkVersionAssembly
//
//  Created by 张威 on 2022/1/19.
//

import Foundation
import Swinject
import BootManager
import LarkVersion
import LarkAssembler

public final class LarkVersionAssembly: LarkAssemblyInterface {
    public init() {}

    public func registContainer(container: Container) {
        // register dependency
        let userGraph = container.inObjectScope(Version.userGraph)
        userGraph.register(LarkVersionDependency.self) { _ -> LarkVersionDependency in
            return LarkVersionDependencyImpl()
        }
    }

    public func registLaunch(container: Container) {
        // register boot task
        NewBootManager.register(LarkVersionCheckTask.self)
    }

    public func getSubAssemblies() -> [LarkAssemblyInterface]? {
        VersionAssembly()
    }
}
