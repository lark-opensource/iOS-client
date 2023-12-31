//
//  main.swift
//
//  Created by lark-project
//  Copyright © 2022 Bytedance.Inc. All rights reserved.
//

import BootManager
import AppContainer
import Swinject
import LarkAssembler
import LarkLocalizations
import LarkContainer
import LKLoadable

class LarkMainAssembly: FlowBootTask, Identifiable {
    static var identify = "LarkMainAssembly"

    override var runOnlyOnce: Bool { true }

    override func execute(_ context: BootContext) {
        let assemblies: [LarkAssemblyInterface] = [BaseAssembly()]
        _ = Assembler(assemblies: assemblies, container: BootLoader.container)
        BootLoader.assemblyLoaded = true
        NewBootManager.register(SetupMainTabTask.self)
    }
}

class SetupMainTabTask: FlowBootTask, Identifiable {
    static var identify = "SetupMainTabTask"

    override func execute(_ context: BootContext) {
        let navi = UINavigationController(rootViewController: ViewController())
        context.window?.rootViewController = navi
    }
}

NewBootManager.register(LarkMainAssembly.self)
BootLoader.shared.start(delegate: AppContainer.AppDelegate.self, config: .default)
