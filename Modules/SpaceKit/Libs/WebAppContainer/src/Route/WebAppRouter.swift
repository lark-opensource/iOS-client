//
//  WebAppRouter.swift
//  WebAppContainer
//
//  Created by majie.7 on 2023/11/20.
//

import SKFoundation
import EENavigator
import LarkSetting
import LKCommonsLogging
import LarkContainer
import RxSwift
import ThreadSafeDataStructure


public class WebAppRouter {
    private static let logger = Logger.log(WAPlugin.self, category: WALogger.TAG)
    
    private(set) var webContainerConfig: WebContainerConfig?
    
    // key:appId, value: config
    public private(set) var appConfigDict: SafeDictionary<String, WebAppConfig> = [:] + .readWriteLock
    private let disposeBag = DisposeBag()
    
    private var webAppEnable: Bool {
        let fgKey = FeatureGatingManager.Key(stringLiteral: "ccm.mobile.webapp_enable")
        return FeatureGatingManager.shared.featureGatingValue(with: fgKey)
    }
    
    private let userResolver: UserResolver
    
    public init(userResolver: UserResolver) {
        self.userResolver = userResolver
        Self.logger.info("init webapp router")
        self.resetConfig()
        userResolver.settings.observe(key: WebContainerConfig.settingKey, current: false)
            .observeOn(MainScheduler.instance)
            .throttle(DispatchQueueConst.MilliSeconds_5000, scheduler: MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in
                guard let self else { return }
                Self.logger.info("on setting change")
                self.resetConfig()
            }).disposed(by: disposeBag)
    }
    
    private func resetConfig() {
        Self.logger.info("reset webapp config")
        self.webContainerConfig = try? userResolver.settings.setting(with: WebContainerConfig.self,
                                                                     key: WebContainerConfig.settingKey)
        appConfigDict.replaceInnerData(by: buildAppConfig())
    }
    
    private func buildAppConfig() -> [String: WebAppConfig] {
        var dic: [String: WebAppConfig] = [:]
        guard let setting = self.webContainerConfig else {
            Self.logger.info("web app router: can not get setting config", tag: LogTag.router.rawValue)
            return dic
        }
        setting.webAppConfig.forEach { keyValue in
            let config = keyValue.value
            config.router.microAppInterceptConfig.forEach { (appId, _) in
                dic[appId] = config
            }
        }
        return dic
    }
    
    public func redirectOpenMiniProgram(url: URL) -> URL? {
        guard webAppEnable else { return nil }
        // 检查是否是applink 或 sslocal链接
        guard checkUrlIsApplinkOrSslocal(url: url) else {
            // 非applink和sslocal的统一规范链接，直接检查黑白名单是否拦截
            if checkStandardWebAppUrl(url: url) {
                // 走容器拦截
                Self.logger.info("web app router: open expected mini app url, need not convert", tag: LogTag.router.rawValue)
                return url
            }
            Self.logger.info("web app router: the link is a illegal url, can not redirect", tag: LogTag.router.rawValue)
            return nil
        }
        
        guard let appId = getAppIdFromUrl(url: url) else {
            Self.logger.info("web app router: can not get app id from url", tag: LogTag.router.rawValue)
            return nil
        }
        
        guard let config = self.webContainerConfig else {
            Self.logger.info("web app router: can not get setting config", tag: LogTag.router.rawValue)
            return nil
        }
        
        var microAppInterceptConfig: MicroAppInterceptConfig?
        var appConfig: WebAppConfig?
        for (_, value) in config.webAppConfig {
            appConfig = value
            let _router = value.router
            guard let _microAppInterceptConfig = _router.microAppInterceptConfig[appId] else {
                continue
            }
            microAppInterceptConfig = _microAppInterceptConfig
            break
        }
        
        guard let appConfig, let microAppInterceptConfig else {
            Self.logger.info("web app router: no matching micro app router config info in Setting config", tag: LogTag.router.rawValue)
            return nil
        }
        
        guard let fgKey = FeatureGatingManager.Key(rawValue: appConfig.fgKey),
              FeatureGatingManager.shared.featureGatingValue(with: fgKey) else {
            Self.logger.warn("web app router: current web app \(appConfig.appName) fg closed", tag: LogTag.router.rawValue)
            return nil
        }
        
        guard checkUrlSchema(url: url, config: microAppInterceptConfig) else {
            // urlSchema不匹配则不拦截处理
            Self.logger.warn("web app router: original app link or sslocal can not match url schema", tag: LogTag.router.rawValue)
            return nil
        }
        
        return convertURL(originUrl: url,
                          appConfig: appConfig,
                          microAppInterceptConfig: microAppInterceptConfig)
    }
    
    public func canOpenWebAppWithURL(url: URL) -> Bool {
        guard webAppEnable else { return false }
        // 检查是否是applink 或 sslocal链接
        guard checkUrlIsApplinkOrSslocal(url: url) else {
            // 非applink和sslocal的统一规范链接，直接检查黑白名单是否拦截
            if checkStandardWebAppUrl(url: url) {
                // 走容器拦截
                return true
            }
            return false
        }
        // applink 或 sslocal链接 判断是否能取到appId, fg是否开启
        guard let appId = getAppIdFromUrl(url: url) else {
            return false
        }
        return canOpenWebAppWithAppId(appId: appId)
    }
    
    public func canOpenWebAppWithAppId(appId: String) -> Bool {
        guard webAppEnable else { return false }
        guard let config = appConfigDict[appId] else {
            return false
        }
        guard let fgKey = FeatureGatingManager.Key(rawValue: config.fgKey),
              FeatureGatingManager.shared.featureGatingValue(with: fgKey) else {
            Self.logger.warn("web app router: not support open, current web app \(config.appName) fg closed", tag: LogTag.router.rawValue)
            return false
        }
        return true
    }
    
    // 检查是否是纯链接，非applink 和 sslocal
    public func checkStandardWebAppUrl(url: URL) -> Bool {
        guard webAppEnable else { return false }
        guard !checkUrlIsApplinkOrSslocal(url: url) else {
            return false
        }
        guard let config = getConfigFromWebAppUrl(url: url) else {
            return false
        }
        guard let fgKey = FeatureGatingManager.Key(rawValue: config.fgKey),
              FeatureGatingManager.shared.featureGatingValue(with: fgKey) else {
            Self.logger.warn("web app router: not support route redirect, current web app \(config.appName) fg closed", tag: LogTag.router.rawValue)
            return false
        }
        return true
    }
    
    // 获取所有业务的白名单url
    private func getLarkAppLinkInterceptedList(config: WebAppConfig) -> [String] {
        // const类型需要考虑旧版本兼容，将旧版本的所有用过的域名拼接path全部注册一遍路由
        if config.router.hostConfig.hostType == "const",
           let constHosts = config.router.hostConfig.constHosts {
            var result: [String] = []
            
            constHosts.forEach { domain in
                result.append(contentsOf: appendDomainForPath(domain: domain, list: config.router.urlInterceptPaths))
            }
            return result
        }
        
        if let domain = config.getUrlDomain() {
            return appendDomainForPath(domain: domain, list: config.router.urlInterceptPaths)
        } else {
            return config.router.urlInterceptPaths
        }
    }
    
    public func getConfigWithUrl(urlString: String) -> WebAppConfig? {
        guard let settingConfig = self.webContainerConfig else {
            Self.logger.error("webContainerConfig is nil")
            return nil
        }
        guard let url = URL(string: urlString) else {
            return nil
        }
        if checkUrlIsApplinkOrSslocal(url: url), let appId = getAppIdFromUrl(url: url) {
            for (_, config) in settingConfig.webAppConfig {
                if config.router.microAppInterceptConfig[appId] != nil {
                    return config
                }
            }
            return nil
        } else {
            let config = getConfigFromWebAppUrl(url: url)
            return config
        }
    }
    
    private func appendDomainForPath(domain: String, list: [String]) -> [String] {
        var result: [String] = []
        for var path in list {
            // 判断path是否有带“/”字符
            if path.first != "/" {
                path = "/" + path
            }
            path = "(http|https)://.*\(domain)\(path)"
            result.append(path)
        }
        return result
    }
    
    private func getUrlQueryItem(url: URL, configQuery: [String]) -> URLQueryItem? {
        for query in configQuery {
            guard let params = url.getQuery()?[query] else {
                continue
            }

            let quertItem = URLQueryItem(name: query, value: params)
            return quertItem
        }
        return nil
    }
}

extension WebAppRouter {
    // ---- 转化生成新的统一小程序链接 -------
    private func convertURL(originUrl: URL, 
                            appConfig: WebAppConfig,
                            microAppInterceptConfig: MicroAppInterceptConfig) -> URL? {
        guard let queryType = microAppInterceptConfig.queryType else {
            print("web app router: can not get query type")
            return originUrl
        }
        
        var appLinkComponents = URLComponents()
        appLinkComponents.scheme = "https"
        appLinkComponents.host = appConfig.getUrlDomain()
        if microAppInterceptConfig.urlPath.first != "/" {
            appLinkComponents.path = "/" + microAppInterceptConfig.urlPath
        } else {
            appLinkComponents.path = microAppInterceptConfig.urlPath
        }
        
        //拼接query
        guard let queryItem = getUrlQueryItem(url: originUrl, configQuery: microAppInterceptConfig.urlQuery.queryKey) else {
            return appLinkComponents.url
        }
        
        
        switch queryType {
        case .append:
            if let parmas = queryItem.value {
                appLinkComponents.path = appLinkComponents.path + "/" + parmas
            }
        case .parameter:
            guard let queryValue = queryItem.value else {
                break
            }
            let parameterComponents = URLComponents(string: queryValue)
            let queryItems = parameterComponents?.queryItems
            appLinkComponents.queryItems = queryItems
        }
        
        Self.logger.info("web app router: conver app link or sslocak successs, result url is \(String(describing: appLinkComponents.url?.urlForLog))", tag: LogTag.router.rawValue)
        return appLinkComponents.url
    }
    
    // ---- 检查当前URL是否在 某个名单中 ----
    private func urlInInterceptedSchemeList(url: URL, list: [String], domain: String? = nil) -> Bool {
        guard let urlString = url.absoluteString.removingPercentEncoding else {
            return false
        }
        for var path in list {
            
            if let domain {
                // 判断path是否有带“/”字符
                if path.first != "/" {
                    path = "/" + path
                }
                path = "(http|https)://.*\(domain)\(path)"
            }
            if urlString.isMatch(for: path) {
                return true
            }
        }
        return false
    }
    
    // ---- 检查当前小程序url是否在黑白名单中 -----
    private func getConfigFromWebAppUrl(url: URL) -> WebAppConfig? {
        guard let containerConfig = self.webContainerConfig else {
            return nil
        }
        
        for (_, appConfig) in containerConfig.webAppConfig {
            let router = appConfig.router
            // 在当前业务的黑名单中时，跳到下一个业务中去检查
            if urlInInterceptedSchemeList(url: url, list: router.urlInterceptBlackListSchemes) {
                continue
            } else {
                // 不在当前业务黑名单，检查是否在白名单
                let whiteList = getLarkAppLinkInterceptedList(config: appConfig)
                for regexString in whiteList {
                    if url.absoluteString.isMatch(for: regexString) {
                        return appConfig
                    } else {
                        // 不在当前业务白名单，去下一个业务检查黑白名单
                        continue
                    }
                }
            }
        }
        // 所有业务检查完没有命中白名单
        return nil
    }
    
    // ----- 检查是否是applink 和 sslocal链接 ------
    private func checkUrlIsApplinkOrSslocal(url: URL) -> Bool {
        let patterns: [String] = ["(http|https)://applink.*",
                                  "sslocal://microapp.*"]
        guard let urlString = url.absoluteString.removingPercentEncoding else {
            return false
        }
        for pattern in patterns {
            if urlString.isMatch(for: pattern) {
                return true
            }
            continue
        }
        return false
    }
    
    // ----- 检查当前url是否符合Schema -------
    private func checkUrlSchema(url: URL, config: MicroAppInterceptConfig) -> Bool {
        guard let urlString = url.absoluteString.removingPercentEncoding else {
            return false
        }
        guard let urlSchemas = config.urlSchema else {
            // 找不到urlSchema 直接认为需要拦截
            return true
        }
        guard !urlSchemas.isEmpty else {
            // 空数组也默认认为需要拦截
            return true
        }
        for schema in urlSchemas {
            if urlString.isMatch(for: schema) {
                return true
            }
        }
        return false
    }
    
    // ----- 获取当前url中的appId -------
    private func getAppIdFromUrl(url: URL) -> String? {
        // 解析URL参数
        var queryParameters: [String: String] = [:]
        if let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
            let queryItems = components.queryItems {
            for queryItem in queryItems {
                queryParameters[queryItem.name] = queryItem.value
            }
        }
        // 获取appID
        let linkAppId = queryParameters["appId"]
        let ssLocalAppId = queryParameters["app_id"]
        return linkAppId ?? ssLocalAppId
    }
    
}

