//
//  ContainerCreator.swift
//  WebAppContainer
//
//  Created by lijuyou on 2023/11/23.
//

import Foundation
import WebKit
import LarkWebViewContainer
import LarkContainer

class ContainerCreator {
    
    class func getWebViewBizType(appName: String) -> LarkWebViewBizType {
        return LarkWebViewBizType("wa_\(appName)")
    }
    
    class func createWebView(config: WebAppConfig,
                             frame: CGRect = .zero) -> WAWebView {
        let webViewConfig = WKWebViewConfiguration()
        webViewConfig.websiteDataStore = WKWebsiteDataStore.default()
        webViewConfig.allowsInlineMediaPlayback = true
        let webview = WAWebView(frame: .zero,
                                configuration: webViewConfig,
                                interceptEnable: config.interceptEnable,
                                bizType: Self.getWebViewBizType(appName: config.appName))
        return webview
    }
    
    class func createContainerView(config: WebAppConfig,
                                   userResolver: UserResolver,
                                   frame: CGRect = .zero) -> WAContainerView {
        let mustPreload = config.needPreload
        if let preloader = try? userResolver.resolve(assert: WAContainerPreloader.self),
           let cacheView = preloader.getAvailableContainer(for: config,
                                                           userResolver: userResolver,
                                                           mustPreload: mustPreload) {
            WALogger.logger.info("get available container: \(cacheView.identifier), usecount:\(cacheView.usedCount)", tag: LogTag.open.rawValue)
            return cacheView
        }
        WALogger.logger.info("create new ContainerView", tag: LogTag.open.rawValue)
        let containerView = WAContainerView(frame: frame, config: config, userResolver: userResolver)
        return containerView
    }
}
