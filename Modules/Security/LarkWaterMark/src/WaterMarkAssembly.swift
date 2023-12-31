//
//  WaterMarkAssembly.swift
//  LarkWaterMark
//
//  Created by Xingjian Sun on 2022/11/14.
//

import UIKit
import Foundation
import LarkFoundation
import Swinject
import BootManager
import LarkRustClient
import LarkAccountInterface
import LarkAssembler
import LarkSetting
import LarkFeatureGating

public final class WaterMarkAssembly: LarkAssemblyInterface {
    public init() {}

    public func registContainer(container: Container) {
        
        container.register(WaterMarkService.self) { r -> WaterMarkService in
            return r.resolve(WaterMarkManagerProtocol.self)!
        }.inObjectScope(.user)
        
        // register new service
        container.register(WaterMarkCustomService.self) { r -> WaterMarkCustomService in
            return r.resolve(WaterMarkManagerProtocol.self)!
        }.inObjectScope(.user)
        
        container.register(WaterMarkManagerProtocol.self) { r -> WaterMarkManagerProtocol in
            let useSingleton = FeatureGatingManager.shared.featureGatingValue(with: "admin.security.watermark_shared_manager_enabled")
            let rustClient = r.resolve(RustService.self)
            if useSingleton {
                let userService = r.resolve(PassportUserService.self)
                let userStateDelegate = r.resolve(WaterMarkPassportDelegate.self)
                WaterMarkSharedManager.setupWaterMarkDependency(client: rustClient, userService: userService, userStateDelegate: userStateDelegate)
                WaterMarkSharedManager.shared.updateDependency()
                return WaterMarkSharedManager.shared
            } else {
                let accountService = AccountServiceAdapter.shared
                let textColor = UIColor.ud.N500
                let darkModeTextColor = UIColor.ud.textPlaceholder
                // swiftlint:disable superfluous_disable_command
                return WaterMarkManager(client: rustClient!,
                                        shouldShow: !accountService.currentAccountInfo.isGuestUser,
                                        userId: accountService.currentAccountInfo.userID,
                                        textColor: textColor,
                                        darkModeTextColor: darkModeTextColor)
                // swiftlint:enable superfluous_disable_command
            }
        }.inObjectScope(.user)
        
        container.register(WaterMarkPassportDelegate.self) { _ -> WaterMarkPassportDelegate in
            return WaterMarkUserStateDelegate()
        }.inObjectScope(.user)
    }

    func factories(container: Container) -> [Command: RustPushHandlerFactory] {
        [
            .pushWaterMarkConfig: { WaterMarkPushHandler() }
        ] as [Command: RustPushHandlerFactory]
    }

    public func registPushHandler(container: Container) {
        factories(container: container)
    }
    
    public func registPassportDelegate(container: Container) {
        (PassportDelegateFactory(delegateProvider: {
            let enableUserScope = container.resolve(PassportService.self)?.enableUserScope ?? false
            if enableUserScope {
                return container.resolve(WaterMarkPassportDelegate.self)!
            } else {
                return DummyPassportDelegate()
            }
        }), PassportDelegatePriority.middle)
    }
}
