//
//  CacheAssembly.swift
//  LarkCacheAssembly
//
//  Created by su on 2022/5/13.
//

import Foundation
import LarkAssembler
import Swinject
import BootManager
import LarkCache
import LarkStorage

// MARK: - Assembly
public final class CacheManagerAssembly: LarkAssemblyInterface {

    public init() {}

    public func registLaunch(container: Container) {
        NewBootManager.register(SetupCacheTask.self)
    }
}
