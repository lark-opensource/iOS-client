//
//  DemoAssembly.swift
//  LarkAccountDev
//
//  Created by Miaoqi Wang on 2021/4/7.
//

import Foundation
import Swinject
import LarkAccountInterface
import EENavigator
import Logger

class DemoAssembly: Assembly {
    func assemble(container: Container) {
        #if SIMPLE
        LauncherDelegateRegistery.register(factory: LauncherDelegateFactory(delegateProvider: { () -> LauncherDelegate in
            DemoLauncherDelegate()
        }), priority: .middle)
        #else
        BootManagerAssembly().assemble(container: container)
        #endif

        // 注册一键登录数据
        LoginService.shared.registerOneKeyLogin()

        Self.setupLogger()
        URLProviderRegistry.register(value: NativeStaticURLProvider(), priority: .lowest)
        DomainProviderRegistry.register(value: NativeStaticDomainProvider(), priority: .lowest)

        // 不使用H5
        AccountServiceAdapter.shared.conf.h5ReplaceFeatureList = []
    }

    static func setupLogger() {
        let config = XcodeConsoleConfig(logLevel: .debug)
        let appender = LoggerConstruct.createConsoleAppender(config: config)
        let appenders: [Appender] = [appender]
        Logger.setup(appenders: appenders)
    }
}

class DemoLauncherDelegate: LauncherDelegate {
    let name: String = "DemoLauncherDelegate"

    func switchAccountSucceed(context: LauncherContext) {
        Navigator.shared.navigation?.popToRootViewController(animated: true)
    }
}
