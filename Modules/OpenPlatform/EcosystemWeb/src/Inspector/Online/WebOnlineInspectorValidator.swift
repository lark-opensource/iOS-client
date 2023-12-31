//
//  WebOnlineInspectorValidator.swift
//  EcosystemWeb
//
//  Created by jiangzhongping on 2023/9/7.
//

import LKCommonsLogging
import LarkSetting

private let logger = Logger.ecosystemWebLog(WebOnlineInspectorValidator.self, category: "WebOnlineInspect")

class WebOnlineInspectorValidator: NSObject {
    
    // 禁止调试域名列表
    static var forbiddenDebugDomains: [String]? {
        do {
            let config = try SettingManager.shared.setting(with: UserSettingKey.make(userKeyLiteral: "web_settings"))["forbidden_debug_domains"] as? [String]
            if config != nil {
                logger.info("get forbidden_debug_domains from settings [web_settings] successfully")
                return config
            }
            logger.info("get forbidden_debug_domains default")
            return []
        } catch {
            logger.info("get forbidden_debug_domains from settings [web_settings] failed")
            return []
        }
    }
    
    // 是否允许host调试
    static func allowDebugHost(for currentHost: String) -> Bool {
        guard let currentList = self.forbiddenDebugDomains else {
            logger.info("settings: forbiddenDebugDomains is nil")
            return false
        }

        for forbiddenHost in currentList {
            if forbiddenHost.split(separator: ".").count < 2 {
                continue
            }
            var dotConfigHost = forbiddenHost
            if !forbiddenHost.starts(with: ".") {
                dotConfigHost = "." + forbiddenHost
            }
            if currentHost.hasSuffix(dotConfigHost) || currentHost == forbiddenHost {
                return false
            }
        }
        return true
    }
}
