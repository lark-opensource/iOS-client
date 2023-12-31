//
//  WAContainerFactory.swift
//  WebAppContainer
//
//  Created by lijuyou on 2023/11/16.
//

import Foundation
import LarkUIKit
import LarkContainer

public final class WAContainerFactory {
    private static var isMenuRegister: Bool = false
    
    public class func createPage(for url: URL, config: WebAppConfig, userResolver: UserResolver) -> UIViewController {
        let routeStart = WAPerformanceTiming.getTimeStamp()
        registerMenuPluginIfNeed()
        WALogger.logger.info("start open webapp container,\(config.appName),\(url.urlForLog)", tag: LogTag.open.rawValue)
        let vc = WAContainerViewController(urlString: url.absoluteString, config: config, userResolver: userResolver)
        vc.viewModel.timing.routeState.update(start: routeStart, end: WAPerformanceTiming.getTimeStamp())
        return vc
    }
    
    private class func registerMenuPluginIfNeed() {
        guard !isMenuRegister else { return }
        WALogger.logger.info("registerMenuPlugin", tag: LogTag.open.rawValue)
        let refreshCtx = MenuPluginContext(plugin: RefreshMenuPlugin.self)
        let copyLinkCtx = MenuPluginContext(plugin: CopyLinkMenuPlugin.self)
        let forwardCtx = MenuPluginContext(plugin: ForwardMenuPlugin.self)
        MenuPluginPool.registerPlugin(pluginContext: refreshCtx)
        MenuPluginPool.registerPlugin(pluginContext: copyLinkCtx)
        MenuPluginPool.registerPlugin(pluginContext: forwardCtx)
        isMenuRegister = true
    }
}
