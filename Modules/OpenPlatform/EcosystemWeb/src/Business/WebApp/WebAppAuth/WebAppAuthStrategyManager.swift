//
//  WebAppAuthStrategyManager.swift
//  EcosystemWeb
//
//  Created by xiangyuanyuan on 2021/11/2.
//

import ECOProbe
import ECOInfra
import WebBrowser
import LarkSetting
import LKCommonsLogging

var webAppObjcKey: UInt8 = 0

// 鉴权方案
public enum WebAppAuthStrategyType: String {
    // 染色级别鉴权
    case prefix
    // url级别鉴权
    case url
    // 容器级别鉴权
    case container
}

public final class WebAppAuthStrategyManager {
    
    static let logger = Logger.ecosystemWebLog(WebAppAuthStrategyManager.self, category: "WebAppAuthStrategyManager")
    
    public static func getWebAppAuthStrategyType()-> WebAppAuthStrategyType {
        let configService: ECOConfigService = ECOConfig.service()
        let webAppAuthStrategyConfig = configService.getDictionaryValue(for: "webapp_auth_strategy")?["type"] as? String ?? ""
        let webAppAuthStrategy = WebAppAuthStrategyType(rawValue: webAppAuthStrategyConfig)
        switch webAppAuthStrategy {
        case .url:
            return .url
        case .prefix:
            return .prefix
        default:
            return .container
        }
    }
    
    public static func getWebAppAuthStrategy() -> WebAppAuthStrategyProtocol {
        // 从Settings获取当前的鉴权策略
        let configService: ECOConfigService = ECOConfig.service()
        let webAppAuthStrategyConfig = configService.getDictionaryValue(for: "webapp_auth_strategy")?["type"] as? String ?? ""
        
        let webAppAuthStrategy = WebAppAuthStrategyType(rawValue: webAppAuthStrategyConfig)
        switch webAppAuthStrategy {
        case .url:
            return WebAppWebPageAuthStrategy()
        case .prefix:
            return WebAppPrefixAuthStrategy()
        default:
            return WebAppContainerAuthStrategy()
            
        }
    }
    
    static var innerDomainPrivateAPIList : Array<String> = getInnerDomainPrivateAPIList()
    
    private static func getInnerDomainPrivateAPIList() -> Array<String> {
        if let defaultPath = BundleConfig.EcosystemWebBundle.path(forResource: "InnerDoaminPrivateAPIList", ofType: "plist"),
           let privateAPIData = try? Data(contentsOf: URL(fileURLWithPath: defaultPath)),
           let apiList = try? PropertyListSerialization.propertyList(from: privateAPIData, options: [], format: nil) as? Array<String> {
            Self.logger.info("get api count:\(apiList.count)")
            return apiList
        } else {
            Self.logger.info("get api failed")
            return []
        }
    }
    
    public static func canEscapeeInnerDomainPrivateAPIAuth(apiName: String , url: URL) -> Bool {
        var config = [String : Any]()
        let innerDomainPrivateAPIList = innerDomainPrivateAPIList
        do {
            config = try SettingManager.shared.setting(with: UserSettingKey.make(userKeyLiteral: "op_private_api_host_config"))
        } catch {
        }
        if innerDomainPrivateAPIList.contains(apiName) {
            if let hostConfig = (config[apiName] as? Dictionary<String, Any>), let allowList = hostConfig["allow_list"] as? Array<String> {
                if let denyList = hostConfig["deny_list"] as? [String: Any], isUrlDeny(url, denyList: denyList) {
                    Self.logger.info("deny by isUrlDeny")
                    return false
                }
                if isUrlEqualsIgnoreQueryItem(url, allowList: allowList) {
                    Self.logger.info("pass by isUrlEqualsIgnoreQueryItem")
                    return true
                }
                if isHostAllow(url, allowList: allowList) {
                    Self.logger.info("pass by isHostAllow")
                    return true
                }
            }
        }
        return false
    }
    
    private static func isUrlDeny(_ url: URL, denyList: [String: Any]) -> Bool {
        let urlStr = url.absoluteString
        guard !BDPIsEmptyString(urlStr) else {
            return false
        }
        // 默认为http/https url, 使用host
        var queryStr: String? = url.host
        // 若scheme存在且不为http前缀, 则为uri
        if let scheme = url.scheme, !scheme.hasPrefix("http") {
            queryStr = urlStr
        }
        if let key = queryStr, let denyPathList = denyList[key] as? [String] {
            return isPathInDenyList(currentPath: url.path, denyList: denyPathList)
        }
        return false
    }
    
    static func isPathInDenyList(currentPath:String, denyList: Array<String>) -> Bool {
        var isInDenyList : Bool = false
        for configPath in denyList {
            if currentPath.contains(configPath) {
                isInDenyList = true
                break
            }
        }
        return isInDenyList
    }
    
    private static func isUrlEqualsIgnoreQueryItem(_ url: URL, allowList: [String]) -> Bool {
        let urlStr = url.absoluteString
        guard !BDPIsEmptyString(urlStr) else {
            return false
        }
        return allowList.contains(urlStr)
    }
    
    private static func isHostAllow(_ url: URL, allowList: [String]) -> Bool {
        let urlStr = url.absoluteString
        guard !BDPIsEmptyString(urlStr) else {
            return false
        }
        guard let host = url.host else {
            return false
        }
        if let hitHost = hithostInWhiteList(currentHost: host, allowList: allowList), !BDPIsEmptyString(hitHost) {
            return true
        }
        return false
    }
    
    /// 判断域名是否在白名单中
    /// - Parameters:
    ///   - currentHost: 当前页面域名
    ///   - allowList: 配置的域名白名单
    /// - Returns: 命中的域名白名单host,如果没有命中返回空
    static func hithostInWhiteList(currentHost:String, allowList: Array<String>)->String? {
        var hitHost : String?
        for configHost in allowList {
            if configHost.split(separator: ".").count < 2 {
                continue
            }
            var dotConfigHost = configHost
            if !configHost.starts(with: ".") {
                dotConfigHost = "." + configHost
            }
            if currentHost.hasSuffix(dotConfigHost) || currentHost == configHost{
                hitHost = configHost
                break
            }
        }
        return hitHost
    }
}
