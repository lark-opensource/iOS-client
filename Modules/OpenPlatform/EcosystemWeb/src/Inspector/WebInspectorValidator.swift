//
//  WebInspectorValidator.swift
//  EcosystemWeb
//
//  Created by ByteDance on 2022/9/13.
//

import Foundation
import LKCommonsLogging
import LarkSetting
import LarkStorage

private let logger = Logger.ecosystemWebLog(WebInspectorValidator.self, category: "WebInspectorValidator")

class WebInspectorValidator {
    
    // 本地悬浮窗标记的 key
    private static let key = "openplatform.web.browser.inspector.mark"
    
    // 从 settings 拉取的域名白名单
    static var hostWhiteList: [String]? {
        do {
            let config = try SettingManager.shared.setting(with: UserSettingKey.make(userKeyLiteral: "web_onlineDebug"))["host_white_list"] as? [String]// user:global
            logger.info("get host white list from settings [web_onlineDebug] successfully")
            return config
        } catch {
            logger.info("get host white list from settings [web_onlineDebug] failed")
            return nil
        }
    }
    
    // 更新本地的悬浮窗标记
    public static func updateMark() {
        if FeatureGatingManager.shared.featureGatingValue(with: "openplatform.web.ios.unite.storage.reform") {// user:global
            let store = KVStores.in(space: .global, domain: Domain.biz.microApp).udkv()
            store.set(Self.key, forKey: Self.key)
        } else {
            UserDefaults.standard.set(Self.key, forKey: Self.key)
        }
    }
    
    // 清除本地的悬浮窗标记
    static func clear() {
        logger.info("clear: remove mark")
        if FeatureGatingManager.shared.featureGatingValue(with: "openplatform.web.ios.unite.storage.reform") {// user:global
            let store = KVStores.in(space: .global, domain: Domain.biz.microApp).udkv()
            store.removeValue(forKey: Self.key)
        } else {
            UserDefaults.standard.removeObject(forKey: Self.key)
        }
    }
    
    // 检查本地是否有悬浮窗标记
    static func checkMark() -> Bool {
        if FeatureGatingManager.shared.featureGatingValue(with: "openplatform.web.ios.unite.storage.reform") {// user:global
            let store = KVStores.in(space: .global, domain: Domain.biz.microApp).udkv()
            if store.string(forKey: Self.key) == nil {
                logger.info("mark is nil")
                return false
            }
        } else {
            if UserDefaults.standard.object(forKey: Self.key) == nil {
                logger.info("mark is nil")
                return false
            }
        }
        
        return true
    }
    
    // 检查当前域名是否命中域名白名单
    static func checkWebHost(for currentHost: String) -> Bool {
        guard let currentList = self.hostWhiteList else {
            // 从 settings 拉取的域名白名单为空
            logger.info("settings: web_onlineDebug is nil")
            return false
        }
        
        for whiteHost in currentList {
            if whiteHost.split(separator: ".").count < 2 {
                continue
            }
            var dotConfigHost = whiteHost
            if !whiteHost.starts(with: ".") {
                dotConfigHost = "." + whiteHost
            }
            if currentHost.hasSuffix(dotConfigHost) || currentHost == whiteHost{
                return true
            }
        }
        return false
    }    
}

