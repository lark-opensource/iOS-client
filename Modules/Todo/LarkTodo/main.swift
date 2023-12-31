//
//  main.swift
//  LarkNavigationDemo
//
//  Created by Supeng on 2021/1/15.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import BootManager
import AppContainer
import Swinject
import LarkLocalizations
import LarkContainer
import RunloopTools
import LKLoadable
import LarkAssembler

class LarkMainAssembly: UserFlowBootTask, Identifiable {
    static var identify = "LarkMainAssembly"

    override var runOnlyOnce: Bool { return true }

    override func execute(_ context: BootContext) {
        let assemblies: [LarkAssemblyInterface] = [
            BaseAssembly(),
            DemoAssembly()
        ]
        _ = Assembler(assemblies: assemblies, container: BootLoader.container)
        BootLoader.assemblyLoaded = true
    }
}

func todoMain() {

    // 设置语言
    LanguageManager.setCurrent(language: .zh_CN, isSystem: false)

    NewBootManager.register(LarkMainAssembly.self)

    RunloopDispatcher.enable = true

    BootLoader.shared.start(delegate: AppDelegate.self, config: .default)

}

todoMain()
