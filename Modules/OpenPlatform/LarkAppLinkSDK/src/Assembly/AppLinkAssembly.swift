//
//  AppLinkAssembly.swift
//  LarkAppLinkSDK
//
//  Created by yinyuan on 2019/8/21.
//
import Swinject
import EENavigator
import LarkRustClient
import BootManager
import LarkAssembler
import LKCommonsLogging
import LarkSetting
import ECOInfra

// swiftlint:disable identifier_name
public final class AppLinkAssembly: LarkAssemblyInterface {

    public static let KEY_CAN_OPEN_APP_LINK = "_canOpenAppLink"
    static let logger = Logger.oplog(AppLinkAssembly.self, category: "AppLink")

    public init() {}
    
    public func registContainer(container: Container) {
        let userContainer = container.inObjectScope(OPUserScope.userScope)
        userContainer.register(AppLinkService.self) { (r) -> AppLinkService in
            return AppLinkImpl(resolver: r)
        }
    }

    public func registRouter(container: Container) {
        // AppLink 调用
        Navigator.shared
            .registerRoute.type(AppLinkBody.self).tester({ (userResolver, req) -> Bool in
                guard let appLinkService = try? userResolver.resolve(assert: AppLinkService.self) else {
                                Self.logger.error("AppLink appLinkService is emply")
                                return false
                            }
                            let canOpen = appLinkService.isAppLink(AppLinkBodyHandler.fixedURLForRust(req.url))
                            if canOpen {
                                req.context[AppLinkAssembly.KEY_CAN_OPEN_APP_LINK] = true
                            }
                            Self.logger.info("AppLink register Router tester url:\(req.url)")
                            return canOpen
            }).priority(.high).factory(cache: true, AppLinkBodyHandler.init(resolver:))
    }

    public func registURLInterceptor(container: Container) {
        (AppLinkBody.patternConfig.pattern, { (url: URL, from: NavigatorFrom) in
            container.getCurrentUserResolver(compatibleMode: OPUserScope.compatibleModeEnabled).navigator.open(url, context: ["from": "app"], from: from)
        })
    }

    public func registLarkAppLink(container: Container) {
        // 对空 path 注册一个空实现，避免打开报错
        registerHandler(path: "/") { _ in }
    }
}
// swiftlint:enable identifier_name
