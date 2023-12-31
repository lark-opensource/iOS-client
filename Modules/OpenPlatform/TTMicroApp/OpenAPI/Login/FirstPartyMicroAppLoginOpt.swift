//
//  FirstPartyMicroAppLoginOpt.swift
//  TTMicroApp
//
//  Created by zhaojingxin on 2022/9/2.
//

import Foundation
import LarkSetting
import LKCommonsLogging

public final class FirstPartyMicroAppLoginOpt: NSObject {
    
    @objc
    public static let shared = FirstPartyMicroAppLoginOpt()
    
    private static let logger = Logger.oplog(FirstPartyMicroAppLoginOpt.self, category: "FirstPartyMicroAppLoginOpt")
    
    private let config: [String: Any]
    override init() {
        do {
            config = try SettingManager.shared.setting(with: UserSettingKey.make(userKeyLiteral: "firstPartyLoginOpt"))
        } catch {
            config = [
                "containers": [],
                "apps": [],
                "block_apps": [],
                "domains": [],
                "keys": []
            ]
        }
    }
    
    @objc
    public func cookieValidForUniqueID(_ uniqueID: OPAppUniqueID) -> Bool {
        guard enabledForUniqueID(uniqueID) else {
            return false
        }
        
        let domains = config["domains"] as? [String] ?? []
        let keys = config["keys"] as? [String] ?? []
        
        guard let cookies = HTTPCookieStorage.shared.cookies, !cookies.isEmpty else {
            Self.logger.info("[\(uniqueID)] no cookies in cookie storage")
            return false
        }
        
        let (logStr, result) = filterCookies(cookies, by: domains, keys: keys)
        Self.logger.info("[\(uniqueID)]found cookies in cookie storage > \(logStr)")
        
        return !result.isEmpty
    }
    
    @objc
    public func cookiesForURL(_ url: URL, uniqueID: OPAppUniqueID) -> [HTTPCookie] {
        guard enabledForUniqueID(uniqueID) else {
            return []
        }
        
        let domains = config["domains"] as? [String] ?? []
        let keys = config["keys"] as? [String] ?? []
        
        guard let cookies = HTTPCookieStorage.shared.cookies(for: url), !cookies.isEmpty else {
            Self.logger.info("[\(uniqueID)] no cookies for \(url)")
            return []
        }
        
        let (logStr, result) = filterCookies(cookies, by: domains, keys: keys)
        Self.logger.info("[\(uniqueID)] found cookies for \(url) > \(logStr)")
        
        return result
    }
    
    private func enabledForUniqueID(_ uniqueID: OPAppUniqueID) -> Bool {
        let containersMap: [OPAppType: String] = [
            .gadget: "gadget",
            .webApp: "WebAPP",
            .block: "BlockitApp"
        ]
        
        guard let containers = config["containers"] as? [String],
              let container = containersMap[uniqueID.appType],
                containers.contains(container) else {
            Self.logger.info("[\(uniqueID)] container check invalid, support containers: \(config["containers"] ?? "nil"), current container:\(containersMap[uniqueID.appType] ?? "nil")")
            return false
        }
        
        let whiteList = uniqueID.appType == .block ? config["block_apps"] : config["apps"]
        guard let apps = whiteList as? [String], apps.contains(uniqueID.appID) else {
            Self.logger.info("[\(uniqueID)] app check invalid, support apps: \(config["apps"] ?? "nil"), current app:\(uniqueID.appID)")
            return false
        }
        
        return true
    }
    
    private func filterCookies(_ origin: [HTTPCookie], by domains: [String], keys: [String]) -> (String, [HTTPCookie]) {
        var logStr = ""
        var result = [HTTPCookie]()
        for cookie in origin {
            logStr += "domain:\(cookie.domain), name:\(cookie.name), value:\(cookie.value.reuseCacheMask());"
            if domains.contains(cookie.domain), keys.contains(cookie.name) {
                result.append(cookie)
            }
        }
        
        return (logStr, result)
    }
}
