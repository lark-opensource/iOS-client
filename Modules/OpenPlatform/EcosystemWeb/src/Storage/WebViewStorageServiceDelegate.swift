//
//  WebViewStorageServiceDelegate.swift
//  EcosystemWeb
//
//  Created by yinyuan on 2022/4/7.
//

import ECOProbe
import LarkAccountInterface
import LarkSetting
import LKCommonsLogging
import Swinject
import WebKit

private let logger = Logger.oplog(WebViewStorageServiceDelegate.self, category: "WebViewStorageServiceDelegate")

public final class WebViewStorageServiceDelegate: LauncherDelegate {
    
    public var name: String = "WebStorage"
    
    private func clearLocalStorage() {
        WKWebsiteDataStore.default().removeData(ofTypes: [WKWebsiteDataTypeLocalStorage], modifiedSince: Date(timeIntervalSince1970: 0)) {
            logger.info("removeData(WKWebsiteDataTypeLocalStorage) finished")
        }
    }

    public func beforeLogout() {
        guard FeatureGatingManager.realTimeManager.featureGatingValue(with: FeatureGatingManager.Key(stringLiteral: "openplatform.web.clean.localstorage.ios")) else {// user:global
            logger.info("clearLocalStorage fg closed")
            return
        }
        logger.info("clearLocalStorage beforeLogout")
        clearLocalStorage()
    }

    public func beforeSwitchAccout() {
        guard FeatureGatingManager.realTimeManager.featureGatingValue(with: FeatureGatingManager.Key(stringLiteral: "openplatform.web.clean.localstorage.ios")) else {// user:global
            logger.info("clearLocalStorage fg closed")
            return
        }
        logger.info("clearLocalStorage beforeSwitchAccout")
        clearLocalStorage()
    }
}
