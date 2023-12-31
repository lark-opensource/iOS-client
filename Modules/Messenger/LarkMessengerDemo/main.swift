//
//  AppDelegate.swift
//  LarkDemo
//
//  Created by CharlieSu on 10/11/19.
//  Copyright © 2019 Bytedance.Inc. All rights reserved.
//

import Foundation
import RxSwift
import Swinject
import LarkPerf
import BootManager
import AppContainer
import LarkContainer
import LarkLocalizations
import LarkAssembler
import LKLoadable
import EENotification

var assemblies: [LarkAssemblyInterface] = [BaseAssembly()]

// LarkCalendarAssembly 还未完成 LarkAssembler 的适配，需额外加入，等适配完了后可删除
#if canImport(CalendarMod)
import CalendarMod
assemblies.append(LarkCalendarAssembly())
#endif

final class LarkMainAssembly: FlowBootTask, Identifiable {
    static var identify = "LarkMainAssembly"

    override var runOnlyOnce: Bool { return true }

    override func execute(_ context: BootContext) {
        _ = Assembler(assemblies: assemblies, container: BootLoader.container)
        BootLoader.assemblyLoaded = true
    }
}

func larkMain() {
    // swiftlint:disable all
    LanguageManager.supportLanguages =
        (Bundle.main.infoDictionary!["SUPPORTED_LANGUAGES"] as! [String]).map { Lang(rawValue: $0) }
    // swiftlint:enable all

    ColdStartup.shared?.do(.main)
    AppStartupMonitor.shared.start(key: .startup)

    LKLoadableManager.run(appMain)
    NewBootManager.register(LarkMainAssembly.self)

    BootLoader.shared.start(delegate: AppDelegate.self, config: .default)
}

larkMain()
