//
//  MicroAppPrepareAssembly.swift
//  LarkOpenPlatform
//
//  Created by 刘洋 on 2021/4/9.
//

import Foundation
import Swinject
import LarkMicroApp
import Heimdallr
import LarkAppLinkSDK
import LKCommonsLogging
import EENavigator
import EEMicroAppSDK
import OPSDK
import LarkOPInterface
import TTMicroApp
import LarkAssembler
import ECOInfra
import SpaceInterface
#if MessengerMod
import LarkOpenFeed
#endif

public final class MicroAppPrepareAssembly: LarkAssemblyInterface {
    static let logger = Logger.log(MicroAppPrepareAssembly.self, category: "Ecosystem")

    public init() {}

    public func registContainer(container: Container) {
        container.register(OPNetStatusHelper.self) { _ in
            return OPNetStatusHelper()
        }.inObjectScope(.container)

        container.register(MicroAppService.self) { _ in
            let larkMicroApp = LarkMicroApp(resolver: container) {
                app, resolver in
            }
            // 创建对象后就立即添加自己的代理
            larkMicroApp.addLifeCycleListener(listener: larkMicroApp)
            return larkMicroApp
        }.inObjectScope(.container)

        let userContainer = container.inObjectScope(OPUserScope.userScope)
        userContainer.register(SNSShareHelper.self) { (r) -> SNSShareHelper in
            return try SNSShareHelperImpl(resolver: r)
        }

        userContainer.register(OPApiLogin.self) { _ in
            return OPLoginHelper()
        }

        #if MessengerMod
        let graphContainer = container.inObjectScope(OPUserScope.userGraph)
        // microApp feed card dependency
        graphContainer.register(MicroAppFeedCardDependency.self) { r -> MicroAppFeedCardDependency in
            return try MicroAppFeedCardDependencyImpl(resolver: r)
        }
        #endif
    }

    public func registLarkAppLink(container: Container){
        //  注册小程序 AppLink 协议
        LarkAppLinkSDK.registerHandler(path: "/client/mini_program/open", handler: { [weak container] (applink: AppLink) in
            OPMonitor("applink_handler_start").setAppLink(applink).flush()
            MiniProgramHandler().handle(appLink: applink, container: container)
        })
    }
#if MessengerMod
    @_silgen_name("Lark.Feed.FeedCard.MicroApp")
    static public func registOpenFeed() {
        FeedCardModuleManager.register(moduleType: MicroAppFeedCardModule.self)
        FeedActionFactoryManager.register(factory: { MicroAppFeedActionMuteFactory() })
        FeedActionFactoryManager.register(factory: { MicroAppFeedActionJumpFactory() })
    }
#endif
}
