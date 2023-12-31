//
//  WebMetaBackForwardGesturesExtensionItem.swift
//  WebBrowser
//
//  Created by jiangzhongping on 2023/12/12.
//

import Foundation
import LKCommonsLogging
import LarkSetting
import ECOInfra

private let logger = Logger.webBrowserLog(WebMetaBackForwardGesturesExtensionItem.self, category: "WebMetaBackForwardGesturesExtensionItem")

public class WebMetaBackForwardGesturesExtensionItem: WebBrowserExtensionItemProtocol {
    public var itemName: String? = "WebMetaBackForwardGestures"
    private weak var browser: WebBrowser?
    
    static public func allowBackForwardGesEnable() -> Bool {
        return OPUserScope.userResolver().fg.staticFeatureGatingValue(with: "openplatform.web.meta.allowbackforwardgestures")
    }
    
    public init(browser: WebBrowser) {
        self.browser = browser
    }
    
    public func applyMetaContent(metaContent: String?) {
        logger.info("apply meta content allowBackForwardGestures \(metaContent ?? "")")
        guard let browser = browser else {
            logger.error("browser is nil")
            return
        }
        guard browser.configuration.acceptWebMeta else {
            logger.info("browser do not accept webmeta")
            return
        }
        guard let metaContent = metaContent else {
            browser.setAllowsBackForwardGestures(true)
            logger.info("metaContent is nil")
            return
        }
        browser.setAllowsBackForwardGestures(metaContent.lowercased() == "true")
    }
}

