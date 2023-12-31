//
//  SettingAssembly.swift
//  LarkSetting
//
//  Created by Supeng on 2021/6/24.
//

import Foundation
import Swinject
import BootManager
import LarkContainer
import LarkDebugExtensionPoint
import LarkAssembler
import AppContainer
import LarkAccountInterface

// swiftlint:disable missing_docs
public final class SettingAssembly: LarkAssemblyInterface {
    public init() {
        SettingStorage.settingDatasource = SettingDatasourceDefaultImpl()
        FeatureGatingStorage.featureGatingDatasource = FeatureGatingDatasourceDefaultImpl()
    }

    public func registLaunch(container: Container) {
        NewBootManager.register(CommonSettingLaunchTask.self)
        NewBootManager.register(SettingLaunchTask.self)
        NewBootManager.register(SettingIdleTask.self)
        NewBootManager.register(SaveRustLogKeyTask.self)
    }

    public func registContainer(container: Container) {
        container.register(GlobalFeatureGatingService.self) { resolver in
            GlobalFeatureGatingServiceImpl(resolver: resolver)
        }.inObjectScope(.container).userSafe()
        container.register(GlobalSettingService.self) { _ in
            return GlobalSettingServiceImpl()
        }.inObjectScope(.container).userSafe()
        let userContainer = container.inObjectScope(.user(type: .both))
        userContainer.register(FeatureGatingService.self) { resolver in
            FeatureGatingServiceImpl(id: resolver.userID, userResolver: resolver)
        }
        userContainer.register(SettingService.self) { resolver in
            SettingServiceImpl(id: resolver.userID, userResolver: resolver)
        }
        userContainer.register(UserDomainService.self) { resolver in
            UserDomainServiceImpl(resolver)
        }
    }

    public func registBootLoader(container: Container) {
        (SettingAppDelegate.self, DelegateLevel.low)
    }

    public func registRustPushHandlerInUserSpace(container: Container) {
        (.pushUserSettingsUpdated, SettingPushHandler.init(resolver:))
    }
    public func registRustPushHandlerInBackgroundUserSpace(container: Container) {
        (.pushUserSettingsUpdated, SettingPushHandler.init(resolver:))
    }

    public func registPassportDelegate(container: Container) {
        (PassportDelegateFactory(delegateProvider: {
            SettingAccountDelegate()
        }), PassportDelegatePriority.middle)
    }

    #if ALPHA
    public func registDebugItem(container: Container) {
        ({ FeatureGatingDebugItem() }, SectionType.debugTool)
        ({ LarkSettingDebugItem() }, SectionType.debugTool)
    }
    #endif
}

/// basic service shortHand, 如果登出需要兜底，由底层统一处理
extension UserResolver {
    public var fg: FeatureGatingService { FeatureGatingServiceImpl(id: userID, userResolver: self) }
    public var settings: SettingService { SettingServiceImpl(id: userID, userResolver: self) }
}
