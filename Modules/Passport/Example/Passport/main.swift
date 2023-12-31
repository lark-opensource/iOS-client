//
//  AppDelegate.swift
//  LarkDemo
//
//  Created by CharlieSu on 10/11/19.
//  Copyright © 2019 Bytedance.Inc. All rights reserved.
//

import LarkContainer
import LarkAssembler
import Swinject
import AppContainer
import LarkPerf
import BootManager
import LarkLocalizations

class LarkMainAssembly: FlowBootTask, Identifiable {
    static var identify = "LarkMainAssembly"

    override var runOnlyOnce: Bool { return true }

    override func execute(_ context: BootContext) {
        let assemblies: [LarkAssemblyInterface] = [BaseAssembly()]
        _ = Assembler(assemblies: assemblies, container: BootLoader.container)
        BootLoader.assemblyLoaded = true
    }
}

// swiftlint:disable all
LanguageManager.supportLanguages = (Bundle.main.infoDictionary!["SUPPORTED_LANGUAGES"] as! [String])
    .map { Lang(rawValue: $0) }
// swiftlint:enable all

ColdStartup.shared?.do(.main)
AppStartupMonitor.shared.start(key: .startup)
NewBootManager.register(LarkMainAssembly.self)
BootLoader.shared.start(delegate: AppDelegate.self, config: .default)
