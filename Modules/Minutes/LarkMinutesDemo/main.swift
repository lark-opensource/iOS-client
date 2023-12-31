//
//  AppDelegate.swift
//  LarkDemo
//
//  Created by CharlieSu on 10/11/19.
//  Copyright © 2019 Bytedance.Inc. All rights reserved.
//

import RxSwift
import Swinject
import LarkPerf
import BootManager
import AppContainer
import LarkContainer
import LarkLocalizations
import LarkNavigation
import LarkUIKit
import LarkLaunchGuide

final class NewLarkMainAssembly: FlowBootTask, Identifiable {
    static var identify = "LarkMainAssembly"

    override var runOnlyOnce: Bool { return true }

    override func execute(_ context: BootContext) {
        _ = Assembler(assemblies: [], assemblyInterfaces: [BaseAssembly()] + [MinutesMockAssembly()] + [LaunchGuideAssembly()], container: BootLoader.container)
        BootLoader.assemblyLoaded = true
        
        SideBarVCRegistry.registerSideBarVC { (_, _) -> UIViewController? in
            let vc = LkNavigationController(rootViewController: MineViewController())
            return vc
        }
    }
}

func larkMain() {
    // swiftlint:disable all
    LanguageManager.supportLanguages =
        (Bundle.main.infoDictionary!["SUPPORTED_LANGUAGES"] as! [String]).map { Lang(rawValue: $0) }
    // swiftlint:enable all

    ColdStartup.shared?.do(.main)
    AppStartupMonitor.shared.start(key: .startup)
    NewBootManager.register(NewLarkMainAssembly.self)

    BootLoader.shared.start(delegate: AppDelegate.self, config: .default)
}

larkMain()
