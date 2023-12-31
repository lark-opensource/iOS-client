//
//  WebAppSDKImpl.swift
//  CCMMod
//
//  Created by lijuyou on 2023/11/17.
//

import SKFoundation
import SpaceInterface
import LarkContainer
import WebAppContainer

class WebAppSDKImpl: WebAppSDK {
    let resolver: Resolver
    let router: WebAppRouter
    let userResolver: UserResolver

    init(resolver: Resolver) {
        self.resolver = resolver
        self.userResolver = resolver.getCurrentUserResolver(compatibleMode: true)
        self.router = WebAppRouter(userResolver: userResolver)
    }
    
    func canOpen(url: String) -> Bool {
        guard let _url = URL(string: url) else {
            return false
        }
        return router.canOpenWebAppWithURL(url: _url)
    }
    
    func canOpen(appId: String) -> Bool {
        return router.canOpenWebAppWithAppId(appId: appId)
    }
    
    func convert(url: String) -> URL? {
        guard let _url = URL(string: url) else {
            return nil
        }
        return router.redirectOpenMiniProgram(url: _url)
    }
    
    func preload(appId: String) -> Bool {
        guard canOpen(appId: appId) else {
            return false
        }
        guard let config = router.appConfigDict[appId] else {
            return false
        }
        guard let preloader = try? userResolver.resolve(assert: WAContainerPreloader.self) else {
            spaceAssertionFailure("preloader is empty")
            return false
        }
        preloader.tryPreload(for: config, userResolver: userResolver)
        return true
    }
}
