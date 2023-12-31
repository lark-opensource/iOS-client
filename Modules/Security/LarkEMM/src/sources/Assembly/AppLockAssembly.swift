//
//  AppLockAssembly.swift
//  LarkSecurityCompliance
//
//  Created by ByteDance on 2022/11/9.
//

import LarkAssembler
import Swinject
import BootManager
import LarkContainer
import AppContainer
import EENavigator
import LarkNavigator
import LarkAppLinkSDK
import LarkAccountInterface
import LarkSecurityComplianceInfra
import LarkOpenSetting

final class AppLockAssembly: LarkAssemblyInterface {

    func registContainer(container: Container) {
        let userContainer = container.inObjectScope(SCContainerSettings.userScope)
        userContainer.register(AppLockSettingServiceImp.self) { resolver in
            try AppLockSettingServiceImp(resolver: resolver)
        }

        userContainer.register(AppLockSettingService.self) { resolver in
            try resolver.resolve(assert: AppLockSettingServiceImp.self)
        }

        userContainer.register(AppLockSettingModuleService.self) { resolver in
            AppLockSettingModuleServiceImp(resolver: resolver)
        }

        userContainer.register(AppLockSettingDependency.self) { resolver in
            try resolver.resolve(assert: AppLockSettingServiceImp.self)
        }
    }

    func registRouter(container: Container) {
        Navigator.shared.registerRoute.type(AppLockSettingBody.self)
            .factory(AppLockSettingControllerHandler.init(resolver:))
    }

    func registLarkAppLink(container: Container) {
        LarkAppLinkSDK.registerHandler(path: AppLockSettingBody.appLinkPattern) { (applink: AppLink) in
            guard let from = applink.context?.from() else {
                Logger.error("AppLockSetting page: Missing applink from")
                return
            }
            let body = AppLockSettingBody()
            Navigator.shared.push(body: body, from: from) // Global
        }
    }

    func registPassportDelegate(container: Container) {
        (PassportDelegateFactory(delegateProvider: {
            AppLockLauncherDelegate(resolver: container)
        }), PassportDelegatePriority.low)
    }
}

/// 应用锁设置
final class AppLockSettingControllerHandler: UserTypedRouterHandler {

    typealias B = AppLockSettingBody

    static func compatibleMode() -> Bool { SCContainerSettings.userScopeCompatibleMode }

    func handle(_ body: AppLockSettingBody, req: EENavigator.Request, res: EENavigator.Response) throws {
        let appLockSettingModuleService = try userResolver.resolve(assert: AppLockSettingModuleService.self)
        let viewController = appLockSettingModuleService.generateAppLockSettingVC()
        res.end(resource: viewController)
    }
}
