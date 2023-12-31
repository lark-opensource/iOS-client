//
//  WebAppAssemble.swift
//  CCMMod
//
//  Created by lijuyou on 2023/11/16.
//
import LarkContainer
import Swinject
import EENavigator
import LKCommonsLogging
import LarkFoundation
import LarkCustomerService
import LarkAccountInterface

#if MessengerMod
import LarkMessengerInterface
#endif

import LarkUIKit
import LarkNavigator
import LarkNavigation
import AppContainer
import AnimatedTabBar
import LarkAppLinkSDK
import LarkAppConfig
import BootManager
import LarkTab
import LarkSceneManager
import LarkRustClient
import LarkAssembler
import LarkSplitViewController
import LarkModel
import WebAppContainer
import SpaceInterface
import SKFoundation
import SKCommon

public final class WebAppAssemble: LarkAssemblyInterface {
    static let log = Logger.log(WebAppAssemble.self, category: "WebAppAssemble")

    public init() {}

// MARK: - LarkAssemblyInterface
    public func registContainer(container: Swinject.Container) {
        let resolver = container
        let userContainer = container.inObjectScope(CCMUserScope.userScope)
        
        container.register(WebAppSDK.self) { (_) in
            return WebAppSDKImpl(resolver: resolver)
        }.inObjectScope(.container)
        
        userContainer.register(WAUserInfoProtocol.self) { userResolver in
            let user = userResolver.docs.user
            return WAUserInfo(userId: user?.basicInfo?.userID ?? "",
                              tenantId: user?.basicInfo?.tenantID ?? "",
                              avatarUrl: user?.info?.avatarURL ?? "",
                              avatarKey: "",
                              gender: "")
        }
        
        userContainer.register(WABaseInfoProtocol.self) { _ in
            return WABaseInfo(lang: DocsSDK.currentLanguage.languageIdentifier,
                              timeZone: TimeZone.current.docs.gmtAbbreviation())
        }
        
        userContainer.register(WAContainerPreloader.self) { _ in
            let userResolver = container.getCurrentUserResolver(compatibleMode: true)
            return WAContainerPreloader(userResolver: userResolver)
        }
    }

    public func registRouter(container: Swinject.Container) {
        //let resolver = container
    }

    public func registLaunch(container: Swinject.Container) {
        NewBootManager.register(RegistWebAppLinkTask.self)
    }

    public func registPassportDelegate(container: Container) {

    }

    public func registLarkAppLink(container: Swinject.Container) {
        let userResolver = container.getCurrentUserResolver(compatibleMode: true)
        
        LarkAppLinkSDK.registerHandler(path: "/client/webapp/open", handler: { applink in
            guard let from = applink.context?.from(), let fromVC = from.fromViewController else { return }
            guard let urlString = applink.url.queryParameters["url"],
                  let url = URL(string: urlString) else {
                return
            }
            let vc = WAContainerFactory.createPage(for: url, config: WebAppConfig.default, userResolver: userResolver)
            Navigator.shared.showDetailOrPush(vc,
                                           wrap: LkNavigationController.self,
                                           from: fromVC)
        })
    }
}
