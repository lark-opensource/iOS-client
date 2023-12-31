//
//  WebMetaLaunchBarExtensionItem.swift
//  WebBrowser
//
//  Created by ByteDance on 2023/11/15.
//

import Foundation
import LKCommonsLogging
import LarkSetting
import ECOInfra

private let logger = Logger.webBrowserLog(WebMetaLaunchBarExtensionItem.self, category: "WebMetaLaunchBarExtensionItem")

final public class WebMetaLaunchBarExtensionItem: WebBrowserExtensionItemProtocol {
    public var itemName: String? = "WebMetaLaunchBarExtensionItem"
    private weak var browser: WebBrowser?
    
    public var isShowBottomNavBar: Bool = true
    
    // 隐藏底部导航栏开放能力的FG开关
    public static func isShowLaunchBarEnabled() -> Bool {
        return OPUserScope.userResolver().fg.staticFeatureGatingValue(with: "openplatform.webmeta.hidelaunchbar")
    }
    
    public init(browser: WebBrowser) {
        self.browser = browser
    }
    
    public func applyWebMeta(_ meta: WebMeta?) {
        guard let browser = browser else {
            logger.error("applyWebMeta browser is nil")
            return
        }
        guard let url = browser.browserURL else {
            logger.info("applyWebMeta browser url is nil")
            return
        }
        guard browser.configuration.acceptWebMeta else {
            logger.info("applyWebMeta browser do not accept webmeta")
            return
        }
        guard let meta = meta else {
            logger.info("applyWebMeta meta is nil")
            return
        }
        
        if WebMetaLaunchBarExtensionItem.isShowLaunchBarEnabled() {
            isShowBottomNavBar = true
            if let showBottomNavBar = meta.showBottomNavBar, showBottomNavBar.lowercased() == "false" {
                isShowBottomNavBar = false
            }
            browser.updateWebViewConstraint()
        }
        
    }
}
