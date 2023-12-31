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
import LarkSetting
import LarkSecurityAudit
import LarkWebCache

class DemoAssembly: Assembly {

    var subAssembles: [Assembly] = [
        SettingAssembly(),
        SecurityAuditAssembly(),
        WebAssembly(),
        WebCacheAssembly()
    ]
    
    func assemble(container: Container) {

        #if SIMPLE
        LauncherDelegateRegistery.register(factory: LauncherDelegateFactory(delegateProvider: { () -> LauncherDelegate in
            DemoLauncherDelegate()
        }), priority: .middle)
        #else
        subAssembles.append(BootManagerAssembly())
        #endif

        subAssembles.forEach({ $0.assemble(container: container) })

        // 注册一键登录数据
        LoginService.shared.registerOneKeyLogin()

        URLProviderRegistry.register(value: NativeStaticURLProvider(), priority: .lowest)
        DomainProviderRegistry.register(value: NativeStaticDomainProvider(), priority: .lowest)

        // 不使用H5
//        AccountServiceAdapter.shared.conf.h5ReplaceFeatureList = []

        LarkLogger.setup()
    }
}

class DemoLauncherDelegate: LauncherDelegate {
    let name: String = "DemoLauncherDelegate"

    func switchAccountSucceed(context: LauncherContext) {
        Navigator.shared.navigation?.popToRootViewController(animated: true)
    }
}
