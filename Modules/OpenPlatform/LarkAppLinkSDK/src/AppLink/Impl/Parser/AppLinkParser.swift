//
//  AppLinkParser.swift
//  LarkAppLinkSDK
//
//  Created by yinyuan on 2021/3/29.
//

import Foundation
import Swinject
import RxSwift
import ECOProbe
import LKCommonsLogging
import LarkFeatureGating
import LarkSetting
import LarkContainer

/// AppLink 格式解析器，用于对 AppLink 执行一些解析和校验逻辑
class AppLinkParser {

    static let logger = Logger.oplog(AppLinkParser.self, category: "AppLink")
    
    // swiftlint:disable identifier_name
    static let applink_ex = "applink_ex"
    // swiftlint:enable identifier_name

    typealias CheckURLSupportedCallback = ((_ supported: Bool) -> Void)

    @LazyRawSetting(key: .make(userKeyLiteral: "open_app_link_config_v3"))
    private var appLinkConfigV3Dic: [String: Any]?

    let resolver: UserResolver
    let disposeBag = DisposeBag()
    
    /// settings 配置
    let settingsProvider: AppLinkSettingsProvider
    
    /// 用于 http 请求
    lazy var httpClient: AppLinkHttp = {
        let c = AppLinkHttp(resolver: self.resolver)
        return c
    }()
    
    init(resolver: UserResolver) {
        self.resolver = resolver
        self.settingsProvider = AppLinkSettingsProvider(resolver: resolver)
    }
 
    /// 异步检查 AppLink URL 是否支持
    func checkURLSupportedAsync(url: URL, callback: @escaping CheckURLSupportedCallback) {
        Self.logger.info("AppLink check applink async: \(url.applinkEncyptString())")
        guard let host = url.host else {
            // 没有 host 直接认为不支持
            Self.logger.error("AppLink check applink async: host is nil")
            callback(false)
            return
        }
        if FeatureGatingManager.shared.featureGatingValue(with: "openplatform.applink.v3") {
            let checkResult = isV3AppLinkSync(url: url) || checkOldAppLink(host: host, url: url)
            callback(checkResult)
        } else {
            let checkResult = isOldAppLinkSync(url: url)
            callback(checkResult)
        }
    }
    
    func firstPathComponent(url: URL) -> String {
        let path = url.path.applink_trimed_path()
        return path.components(separatedBy: "/")[0]
    }
    
    //判断是否是有效的、可跳转的AppLink结构
    func checkOldAppLink(host: String, url: URL) -> Bool {
        // 校验 host
        let settings = settingsProvider.fetchAppLinkSettings()
        guard Self.checkHostAppLink(host: host, settings: settings) else {
            Self.logger.error("AppLink check applink async: host invalid")
            return false
        }
        // 校验 Path
        guard Self.checkPathSupported(path: url.path, settings: settings) else {
            Self.logger.error("AppLink check applink async: path invalid. \(url.path) \(settings.supportedPathsRemote)")
            return false
        }
        return true
    }
    
    // 同步判断是否是 AppLink结构
    func isAppLinkSync(url: URL) -> Bool {
        if FeatureGatingManager.shared.featureGatingValue(with: "openplatform.applink.v3") {
            return isV3AppLinkSync(url: url) || isOldAppLinkSync(url: url)
        } else {
            return isOldAppLinkSync(url: url)
        }
    }
    
    func isV3AppLinkSync(url: URL) -> Bool {
        let hostArr: [String] = self.appLinkConfigV3Dic?["hosts"] as? [String] ?? []
        guard let host = url.host, hostArr.contains(host) else {
            Self.logger.error("AppLink check applink v3 sync,no supported host: \(url.host)")
            return false
        }
        let originPathArr: [String] = self.appLinkConfigV3Dic?["paths"] as? [String] ?? []
        var pathArr: [String] = []
        for path in originPathArr {
            pathArr.append(path.applink_trimed_path())
        }
        guard pathArr.contains(self.firstPathComponent(url: url)) else {
            Self.logger.error("AppLink check applink v3 sync,no supported path: \(url.path)")
            return false
        }
        Self.logger.info("AppLink check applink v3 true")
        return true
    }
    
    func isOldAppLinkSync(url: URL) -> Bool {
        var settings: AppLinkSettings = settingsProvider.fetchAppLinkSettings()
        
        guard Self.checkSchemeSupported(scheme: url.scheme, settings: settings) else {
            Self.logger.error("AppLink check applink sync,scheme\(String(describing: url.scheme)),no supported scheme")
            return false
        }
        
        guard Self.checkHostAppLink(host: url.host, settings: settings) else {
            Self.logger.error("AppLink check applink sync,host\(String(describing: url.host)),no supported host")
            return false
        }
        if url.scheme == "https" && url.host == unifiedDomain {
            Self.logger.error("AppLink check applink sync: invalid for https://applink/ format. \(url.applinkEncyptString())")
            return false
        }
        // 包含 applink_ex 保留字段的 URL(https) 是兼容页面，不处理
        if url.scheme == "https" && url.queryParameters.keys.contains(Self.applink_ex) {
            Self.logger.error("AppLink check applink sync: invalid for applink_ex. \(url.applinkEncyptString())")
            return false
        }
        Self.logger.info("AppLink check applink true")
        return true
    }
}

extension AppLinkParser {
    /// 校验 scheme 是否是 AppLink 支持
    private static func checkSchemeSupported(scheme: String?, settings: AppLinkSettings) -> Bool {
        guard let scheme = scheme else {
            return false
        }
        let supportedSchemes = supportedSchemes
        Self.logger.info("AppLink supportedSchemes :\(supportedSchemes)")
        return supportedSchemes.contains(scheme)
    }
    
    /// 校验 host 是否是 AppLink Host
    private static func checkHostAppLink(host: String?, settings: AppLinkSettings) -> Bool {
        guard let host = host else {
            Self.logger.error("AppLink check host fail,host is nil")
            return false
        }
        if host == unifiedDomain {
            // 无域名 AppLink
            Self.logger.info("AppLink check host pass,host is unifiedDomain")
            return true
        }
        return settings.supportedRegDomainsRemote.contains(where: { reg_doamin in
            do {
                let re = try NSRegularExpression(pattern: reg_doamin)
                let result = re.matches(host)
                return !result.isEmpty
            } catch {
                Self.logger.error("AppLink check host fail,host match reg fail")
                return false
            }
        })
    }
    
    /// 校验 Path 是否是支持的 path
    private static func checkPathSupported(path: String?, settings: AppLinkSettings) -> Bool {
        guard let path = path else {
            return false
        }
        if settings.supportedPathsRemote.isEmpty {
            // settings 配置未加载完成，直接走兜底逻辑
            // 乐观策略：默认通过
            return true
        } else {
            // 配置加载成功
            // 悲观策略: 严格校验

            // 移除首尾的斜线，然后进行对比 /A/B/ = /A/B = A/B/ = A/B
            let trimPath = path.applink_trimed_path()
            
            guard settings.supportedPathsRemote.contains(where: { (path) -> Bool in
                path.applink_trimed_path() == trimPath
            }) else {
                return false
            }

            // 校验通过
            return true
        }
    }
}
