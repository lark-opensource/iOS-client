//
//  ECOCookie+Config.swift
//  ECOInfra
//
//  Created by Meng on 2021/2/9.
//

import Foundation
import LarkContainer
import LarkSetting

/// ECOCookieConfig cookie 配置策略
struct ECOCookieConfig {
    
    private var syncWebViewCookieInWhiteList: Bool {
        return resolver.fg.dynamicFeatureGatingValue(with: "openplatform.api.syncwebviewcookie.usewhitelist")
    }

    static let cookieExceptMaskCharacters: [Character] = ["-", "_", "."]
    
    private let resolver: UserResolver
    
    init(resolver: UserResolver) {
        self.resolver = resolver
    }
    
    private lazy var gadgetWebViewCookieIsolationConfig: [String: Any] = {
        do {
            let config = try resolver.settings.setting(with: .make(userKeyLiteral: "gadgetWebViewCookieIsolationConfig"))
            return config
        } catch {
            return [
                "tenants": [:],
                "apps": [:],
                "apply_all": false
            ]
        }
    }()

    /// tt.request 请求里的 cookie 同步到小程序 webview 的白名单
    var requestCookieURLWhiteListForWebview: [String]? {
        if syncWebViewCookieInWhiteList {
            return try? resolver.settings.setting(with: [String].self, key: .make(userKeyLiteral: "cookieUrlWhiteList"))
        }
        
        return nil
    }
    
    var gadgetWebViewCookieIsolationAllApplied: Bool {
        var mutableSelf = self
        return mutableSelf.gadgetWebViewCookieIsolationConfig["apply_all"] as? Bool ?? false
    }
    
    func gadgetWebViewCookieIsolated(tenantID: String, appID: String) -> Bool {
        var mutableSelf = self
        let config = mutableSelf.gadgetWebViewCookieIsolationConfig
        let tenants = config["tenants"] as? [String: Any] ?? [:]
        let apps = config["apps"] as? [String: Any] ?? [:]
        if let tenantConfig = tenants[tenantID] as? [String: Any] {
            if tenantConfig.isEmpty { return true }
            
            if let whiteList = tenantConfig["white_list"] as? [String] {
                return whiteList.contains(appID)
            }
            
            if let blackList = tenantConfig["black_list"] as? [String] {
                return !blackList.contains(appID)
            }
            
            return false
        }
        
        return apps[appID] != nil
    }
}
