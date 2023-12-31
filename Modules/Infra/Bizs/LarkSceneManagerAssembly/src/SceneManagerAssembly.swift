//
//  SceneManagerAssembly.swift
//  LarkSceneManagerAssembly
//
//  Created by su on 2022/5/13.
//

import Foundation
import LarkAssembler
import Swinject
import BootManager

// MARK: - Assembly
public final class LarkSceneManagerAssembly: LarkAssemblyInterface {

    public init() {}

    public func registLaunch(container: Container) {
        NewBootManager.register(SceneSetupTask.self)
    }
}
