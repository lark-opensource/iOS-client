//
//  AppDelegate.swift
//  LarkDemo
//
//  Created by CharlieSu on 10/11/19.
//  Copyright © 2019 Bytedance.Inc. All rights reserved.
//

import Foundation
import AppContainer
import Swinject
import LarkAccountInterface
import Logger
import LarkContainer
import LarkAppConfig
import LarkNavigation
import EENavigator
import LarkUIKit
import AnimatedTabBar
import LarkRustClient
import LarkTab

func larkMain() {
    BootLoader.shared.start(delegate: AppDelegate.self, config: .default)
    _ = Assembler(
        [DemoAssembly(),
//         AccountAssembly(),
         NavigationAssembly(),
         NavigationMockAssembly()
    ], container: BootLoader.container)
}

class TempAppender: Appender {
    static func identifier() -> String { "" }

    static func persistentStatus() -> Bool { false }

    func doAppend(_ event: LogEvent) { }

    func persistent(status: Bool) { }
}

class DemoApplicationDelegate: ApplicationDelegate {
    @Injected private var rustClient: RustService
    static let config = Config(name: "Demo", daemon: true)

    required init(context: AppContext) {
        let config = RustLogConfig(
            process: "larkdocs",
            logPath: FileManager.default
                .urls(for: .documentDirectory, in: .userDomainMask)[0]
                .appendingPathComponent("sdk_storage/log")
                .path,
            monitorEnable: true
        )

        RustLogAppender.setupRustLogSDK(config: config)
        Logger.add(appender: TempAppender())
    }
}

class DemoAssembly: Assembly {
    func assemble(container: Container) {
        BootLoader.shared.registerApplication(
            delegate: DemoApplicationDelegate.self,
            level: .default)

        TabRegistry.register(.feed) { _ in FakeTab() }
        Navigator.shared.registerRoute(plainPattern: Tab.feed.urlString) {
            return FakeControllerHandler()
        }
    }
}

larkMain()
