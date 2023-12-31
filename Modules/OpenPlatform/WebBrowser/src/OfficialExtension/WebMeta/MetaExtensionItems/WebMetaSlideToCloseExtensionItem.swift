//
//  WebMetaSlideToCloseExtensionItem.swift
//  WebBrowser
//
//  Created by ByteDance on 2022/12/29.
//

import Foundation
import LKCommonsLogging
import LarkSetting

private let logger = Logger.webBrowserLog(WebMetaSlideToCloseExtensionItem.self, category: "WebMetaSlideToCloseExtensionItem")

public class WebMetaSlideToCloseExtensionItem: WebBrowserExtensionItemProtocol {
    public var itemName: String? = "WebMetaSlideToClose"
    private weak var browser: WebBrowser?
    
    static public func isSlideToCloseEnabled() -> Bool {
        return FeatureGatingManager.shared.featureGatingValue(with: FeatureGatingManager.Key(stringLiteral: "openplatform.web.meta.meta_slidetoclose"))// user:global
    }
    
    public init(browser: WebBrowser) {
        self.browser = browser
    }
    
    public func applyMetaContent(metaContent: String?) {
        logger.info("apply meta content slideToCloseItems \(metaContent ?? "")")
        guard let browser = browser else {
            logger.error("browser is nil")
            return
        }
        guard browser.configuration.acceptWebMeta else {
            logger.info("browser do not accept webmeta")
            return
        }
        guard let metaContent = metaContent else {
            browser.setSlideToClose(false)
            logger.info("metaContent is nil")
            return
        }
        browser.setSlideToClose(metaContent.lowercased() == "true")
    }
}
