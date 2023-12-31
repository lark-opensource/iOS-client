//
//  LarkOthersAssembly.swift
//  LarkLiveDemo
//
//  Created by yangyao on 2021/6/8.
//

import Foundation
import Swinject
import EENavigator
import LarkAccountInterface
import LarkLive
import LarkLiveInterface
import LarkRustClient
import LarkLocalizations
import LarkFoundation
import BootManager
import LKCommonsLogging
import LarkReleaseConfig
import LarkAssembler

public final class LarkLiveAssembly: Assembly, LarkAssemblyInterface {

    private static let logger = Logger.urlTracker

    public init() { }

    public func assemble(container: Container) {
        registContainer(container: container)
        registLaunch(container: container)
        registRouter(container: container)
    }

    public func registContainer(container: Container) {
        container.register(LarkLiveDependency.self) { r in
            return LarkLiveDependencyImpl(resolver: r)
        }.inObjectScope(.user)

        container.register(LarkLiveService.self) { r in
            let accountService = r.resolve(LarkAccountInterface.AccountService.self)
            let service = LarkLiveServiceImpl(resolver: r)
            return service
        }.inObjectScope(.user)

        container.register(LiveConfig.self) { r in
            let deviceService = r.resolve(LarkAccountInterface.DeviceService.self)
            let accountService = r.resolve(LarkAccountInterface.AccountService.self)
            let config = LiveConfig(appID: ReleaseConfig.appId,
                                       deviceID: deviceService?.deviceId ?? "",
                                       session: accountService?.currentAccountInfo.accessToken ?? "",
                                       locale: LanguageManager.currentLanguage.localeIdentifier,
                                       userAgent: Utils.userAgent,
                                       larkVersion: Utils.appVersion)

            return config
        }

        container.register(LiveAPI.self) { (r, urlString: String) in
            let config = r.resolve(LiveConfig.self)!
            let rustService = r.resolve(RustService.self)!
            let baseURL = URL(string: urlString)
            return LarkLiveAPI(baseURL, config: config, rustService: rustService)
        }
    }

    public func registLaunch(container: Container) {
        NewBootManager.register(LarkLiveSetupTask.self) { () -> BootTask in
            return LarkLiveSetupTask(resolver: container)
        }
    }

    public func registRouter(container: Container) {
        //  注册 WebBrowserDemoAssembly 打开业务网页的路由
        Navigator.shared.registerRoute_(type: LarkLiveRouterBody.self) {
            LarkLiveRouterHandler(container: container)
        }

        //  注册业务网页打开路由，请保障路由规则只包含自己业务，不包含其他的
        Navigator.shared.registerRoute_(match: { url -> Bool in
            let service = container.resolve(LarkLiveService.self)!
            return service.isLiveURL(url: url)
        }, tester: { req -> Bool in
            if let scene = (req.context["scene"] as? String), scene == "messenger" {
                let linkSource = "live"
                LarkLiveAssembly.logger.info("click link of \(linkSource)")
                LiveTracker.tracker(name: .linkClicked, params: ["link_source": linkSource])
            }
            return true
        }) { req, res in
            res.redirect(
                body: LarkLiveRouterBody(url: req.url),
                context: req.context
            )
        }
    }
}



