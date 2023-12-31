//
//  DomainConfig.swift
//  SpaceKit
//
//  Created by litao_dev on 2020/1/2.
//  

//swiftlint:disable file_length
import Foundation
import SwiftyJSON
import LarkReleaseConfig
import SKFoundation
import RxSwift
import LarkAccountInterface
import ThreadSafeDataStructure
import SKInfra
/// 域名相关的配置
extension DomainConfig {

    /// 给RN注入的AppKey（appinfo）
    public static var appKey: String?
    
    /// 数据更新通知
    private static let dataUpdatePublish = PublishSubject<Bool>()

    public enum NewDomainHost {
        //国内域名
        public static var mainLandDomainRelease: String {
            return judge(ka: DomainConfig.ka.docsApiDomain,
                         old: "internal-api-space.feishu.cn")
        }
        public static var mainLandDomainStaging: String {
            return judge(ka: DomainConfig.ka.docsApiDomain,
                         old: "internal-api-space.feishu-staging.cn")
        }
        public static var mainLandDomainDev: String {
            return judge(ka: DomainConfig.ka.internalApiDomainTest,
                         old: "internal-api.feishu-test.cn")
        }
        public static var internalDomain: String {
            return judge(ka: DomainConfig.ka.internalApiDomain,
                         old: "internal-api.feishu.cn")
        }

        //国外域名
        public static var overSeaDomainRelease: String {
            return judge(ka: DomainConfig.ka.docsApiDomain,
                         old: "internal-api-space.larksuite.com")
        }
        public static var overSeaDomainStaging: String {
            return judge(ka: DomainConfig.ka.docsApiDomain,
                         old: "internal-api-space.larksuite-staging.com")
        }
        public static var overSeaDomainDev: String {
            return judge(ka: DomainConfig.ka.internalApiDomainOverSeaTest,
                         old: "internal-api.larksuite-test.com")
        }
        public static var overSeaInternalDomain: String {
            return judge(ka: DomainConfig.ka.internalApiDomain,
                         old: "internal-api.larksuite.com")
        }

        public static func judge(ka: String?, old defaultDomain: String) -> String {
            return DomainConfig.judgeToUse(ka: ka, or: defaultDomain)
        }
    }

    // MARK: - 后台下发配置
    private static var validUrlPatterns: [String] {

        var urls: [String] = CCMKeyValue.globalUserDefault.stringArray(forKey: UserDefaultKeys.validURLMatchKey) ?? []
        urls.forEach { spaceAssert(!$0.isEmpty) }
        urls = urls.filter { !$0.isEmpty }
        if urls.isEmpty {
            urls.append("\\.feishu\\.cn/space")
            urls.append("\\.internal-api\\.feishu\\.cn/space/api/explorer/create")
            urls.append("\\.feishu\\.cn/(doc|docs|sheet|sheets|mindnote|mindnotes|slide|slides|file|bitable|base|folder|wiki)/")
            urls.append("\\.feishu\\.cn/blank/")

            urls.append("\\.larksuite\\.com/space")
            urls.append("\\.internal-api\\.larksuite\\.com/space/api/explorer/create")
            urls.append("\\.larksuite\\.com/(doc|docs|sheet|sheets|mindnote|mindnotes|slide|slides|file|bitable|base|folder|wiki)/")
            urls.append("\\.larksuite\\.com/space/blank/")

            urls.append("\\.feishu\\.cn/drive")
            urls.append("\\.internal-api\\.feishu\\.cn/drive/api/explorer/create")

            urls.append("\\.larksuite\\.com/drive")
            urls.append("\\.internal-api\\.larksuite\\.com/drive/api/explorer/create")
            urls.append("\\.larksuite\\.com/drive/blank/")
        }
        return urls
    }

    public static var validPaths: [String] {
        func getValidPathsFromServer() -> [String] {
            let serverValue = CCMKeyValue.globalUserDefault.stringArray(forKey: UserDefaultKeys.validPathsKey) ?? []
            return serverValue.isEmpty ? ["space"] : serverValue
        }
        if enableAbandonOversea {
            return getValidPathsFromServer()
        } else if DomainConfig.envInfo.isChinaMainland == false {
            return ["space"]
        }
        return getValidPathsFromServer()
    }

    // 为取值做缓存，避免统一存储KV的频繁log
    private static var _userDomain = SafeAtomic<String?>(nil, with: .readWriteLock)
    /// 后台下发的当前用户的域名
    static var userDomain: String {
        if let value = _userDomain.value {
            return value
        } else {
            let newValue = CCMKeyValue.globalUserDefault.string(forKey: UserDefaultKeys.domainKey) ?? "www.feishu.cn"
            _userDomain.value = newValue
            return newValue
        }
    }

    // MARK: - 根据变量生成的信息
    static var localValidHosts: [String] {
        var urls = [String]()
        if OpenAPI.docs.isAgentToFrontEndActive, !OpenAPI.docs.frontendHost.isEmpty {
            urls.append(OpenAPI.docs.frontendHost)
        }
        urls.append(OpenAPI.DocsDebugEnv.legacyHost)
        urls.forEach { spaceAssert(!$0.isEmpty) }
        return urls
    }
    /// 是否启用了新的域名系统
    public static var isNewDomain: Bool {
        if ReleaseConfig.isPrivateKA || DocsSDK.isInLarkDocsApp { return true }
        if enableAbandonOversea {
            // UserDefaultKeys.isNewDomainSystemKey,这个FG，在3.3之前已经GA，项目内默认值也是true，此处逻辑添加于3.17，
            // 因此返回true
            return true
        }
        // 国外一定是新逻辑
        if !DomainConfig.envInfo.isChinaMainland { return true }
        // 总开关必须开启
        guard CCMKeyValue.globalUserDefault.bool(forKey: UserDefaultKeys.isNewDomainSystemKey) else {
            return false
        }
        // 合法的url匹配模式，必须有值
        if validUrlPatternsV2.isEmpty { return false }
        return true
    }

    /// 后台请求时，路径的前缀
    public static var pathPrefix: String {
        if isNewDomain, !NetConfig.shared.busness.isEmpty {
            return "/" + NetConfig.shared.busness
        } else {
            return ""
        }
    }

    /// 用户向后台请求时的域名
    public static var userDomainForRequest: String {
        if OpenAPI.docs.isAgentToFrontEndActive {
            return String(OpenAPI.docs.frontendHost.split(separator: ":").first!)
        }
        guard isNewDomain else {
            return OpenAPI.DocsDebugEnv.legacyHost
        }

        if enableAbandonOversea {
            return OpenAPI.DocsDebugEnv.hostForNewMainlandDomain
        }

        return DomainConfig.envInfo.isChinaMainland ? OpenAPI.DocsDebugEnv.hostForNewMainlandDomain : OpenAPI.DocsDebugEnv.hostForNewOverSeaDomain
    }

    public static var userDomainForDBDoc: String {
        guard isNewDomain else {
            return OpenAPI.DocsDebugEnv.legacyHost
        }
        if enableAbandonOversea {
            return OpenAPI.DocsDebugEnv.bdDocHostForNewMainlandDomain
        }
        return DomainConfig.envInfo.isChinaMainland ? OpenAPI.DocsDebugEnv.bdDocHostForNewMainlandDomain : OpenAPI.DocsDebugEnv.bdDocHostForNewOverSeaDomain
    }

    public static var userDomainForDocs: String {
        guard isNewDomain else {
            return OpenAPI.DocsDebugEnv.legacyHost
        }
        return userDomain
    }

    public static var geckoDomain: String {

        let geckoOfMainLand = judgeToUse(ka: DomainConfig.ka.docsFeResourceUrl, or: "gecko-bd.feishu.cn")

        guard isNewDomain else {
            return geckoOfMainLand
        }

        if enableAbandonOversea {
            return geckoOfMainLand
        }

        let geckoOfOversea = judgeToUse(ka: DomainConfig.ka.docsFeResourceUrl, or: "gecko-va.byteoversea.com")
        return DomainConfig.envInfo.isChinaMainland ?  geckoOfMainLand : geckoOfOversea
    }

    /// Drive上传下载文件流域名
    public static var driveDomain: String {
        DomainConfig.ka.docsDriveDomain ?? DomainConfig.userDomainForRequest
    }

    /// 飞书举报域名
    public static var tnsReportDomain: String {
        DomainConfig.ka.tnsReportDomain?.first ?? DomainConfig.userDomainForRequest
    }
    
    /// Lark举报域名
    public static var larkReportDomain: String {
        DomainConfig.ka.tnsLarkReportDomain?.first ?? DomainConfig.userDomainForRequest
    }
    
    /// feishu举报域名
    public static var suiteReportDomain: String {
        DomainConfig.ka.suiteReportDomain ?? DomainConfig.userDomainForRequest
    }
    
    ///帮助中心域名
    public static var helpCenterDomain: String {
        DomainConfig.ka.helpCenterDomain ?? DomainConfig.userDomainForRequest
    }
    
    /// 服务台域名
    public static var mpAppLinkDomain: String {
        DomainConfig.ka.mpAppLinkDomain ?? DomainConfig.userDomainForRequest
    }

    /// 黑名单的Path列表，名单内的Path不进入native兜底页，使用WebView兜底
    public static var blackPathPattern: String? = {
        if let blackPaths = H5UrlPathConfig.getBlackPathList(), !blackPaths.isEmpty {
            let pattern = blackPaths.joined(separator: "|")
            return pattern
        }
        return nil
    }()
    
    public static func updateUserDomain(_ value: String?) {
        _userDomain.value = value
        CCMKeyValue.globalUserDefault.set(value, forKey: UserDefaultKeys.domainKey)
    }
}

extension DomainConfig {

    static var enableKADomain: Bool {
        return true
    }

    public static var ka: KA = KA()

    // lark传入的值会赋值到这里
    public struct KA {

        public var docsHomeDomain: String?

        public var docsApiDomain: String?
        public var docsMainDomain: String?
        public var internalApiDomain: String?

        public var docsHelpDomain: String?
        public var docsDriveDomain: String?

        public var longConDomain: [String]?

        public var tnsReportDomain: [String]?

        public var tnsLarkReportDomain: [String]?
        
        public var helpCenterDomain: String?
        
        public var suiteReportDomain: String?
        
        public var mpAppLinkDomain: String?

        // 下面目前为空，debug时使用历史默认值
        public var internalApiDomainTest: String?
        public var internalApiDomainOverSeaTest: String?

        public var docsHelpDomainStaging: String?
        public var docsHelpDomainDev: String?
        public var docsHelpDomainOverSeaStaging: String?
        public var docsHelpDomainOverSeaDev: String?
        /**
         bytedance 国内：feichu.cn，国外：larksuite.com，KA用户这个值的一二级域名可能都会变
         */
        public var suiteMainDomain: String?
        /**
         gecko域名，因为KA用户可能要私有化部署，所有的域名都要换成他们自己的，所以统一到lark rust管理下发到DocsSDK
         */
        public var docsFeResourceUrl: String?
        
        //mg下对应的文档api
        public var docsMgApi: [String: [String: String]]?
        //mg下对应的长链域名
        public var docsMgFrontier: [String: [String: [String]]]?
        //mg下文档api匹配正则
        public var docsMgGeoRegex: String?
        //mg下文档长链匹配正则
        public var docsMgBrandRegex: String?

        public mutating func updateDomains(_ newDomains: DocsConfig.Domains) {

            DocsLogger.info("update DomainConfig.ka domains: \(newDomains)", component: LogComponents.domain)
            self.docsApiDomain = newDomains.docsApiDomain
            self.docsMainDomain = newDomains.docsMainDomain
            self.internalApiDomain = newDomains.internalApiDomain
            self.docsHelpDomain = newDomains.docsHelpDomain
            self.longConDomain = newDomains.docsLongConDomain
            self.suiteMainDomain = newDomains.suiteMainDomain
            self.docsFeResourceUrl = newDomains.docsFeResourceUrl
            self.docsHomeDomain = newDomains.docsHomeDomain
            self.docsMgApi = newDomains.docsMgApi
            self.docsMgFrontier = newDomains.docsMgFrontier
            self.docsMgGeoRegex = newDomains.docsMgGeoRegex
            self.docsMgBrandRegex = newDomains.docsMgBrandRegex
            self.docsDriveDomain = newDomains.docsDriveDomain
            self.tnsReportDomain = newDomains.tnsReportDomain
            self.tnsLarkReportDomain = newDomains.tnsLarkReportDomain
            self.helpCenterDomain = newDomains.helpCenterDomain
            self.mpAppLinkDomain = newDomains.mpAppLinkDomain
            self.suiteReportDomain = newDomains.suiteReportDomain
        }
        
    }

    /// 判断使用哪个域名
    ///
    /// - Parameters:
    ///   - kaDomain: lark 动态传入的域名
    ///   - defaultDomain: 默认域名，传入老版本定义在代码中的域名
    /// - Returns: 根据FG开关判断使用哪个域名，返回使用值
    static func judgeToUse(ka kaDomain: String?, or defaultDomain: String) -> String {
        guard
            enableKADomain,
            let domainLocal = kaDomain, !domainLocal.isEmpty else {
                return defaultDomain
        }
        return domainLocal
    }
}
// MARK: - 请求后台domain相关配置，目前主要用于文档链接识别，合法性校验
extension DomainConfig {
    private static let defualtValidatedDomains: [String] = ["feishu.cn",
                                                            "feishu.net",
                                                            "larkoffice.com",
                                                            "internal-api.feishu.cn",
                                                            "larksuite.com",
                                                            "internal-api.larksuite.com"]
    static var validatedDomains: [String] {
        // 先从本地取出来，然后判断是否为空，为空的话，使用lark注入给我们的值
        
        if let exDomainConfig = CCMKeyValue.globalUserDefault.stringArray(forKey: UserDefaultKeys.domainPoolKey), !exDomainConfig.isEmpty {
            return exDomainConfig
        }

        if DocsSDK.isInDocsApp {
            return defualtValidatedDomains
        }

        guard let suiteMainDomain = ka.suiteMainDomain else {
            // 不用这个方法OpenAPI.DocsDebugEnv.current.suiteMainDomain，是为了在异常情况下使用defualtValidatedDomains，兼容多个域名
            // 这里是最后的兜底
//            spaceAssertionFailure("不应该走到这里，lark 传入的套件域名丢了，请认真检查，不然KA用户打不开文档")
            return defualtValidatedDomains
        }

        return [suiteMainDomain]
    }

    /// 请求domain的额外配置，KA2开始从3.14开始
    /// api文档说明：https://yapi.bytedance.net/project/3843/interface/api/1114295
    public static func requestExDomainConfig() -> Observable<Bool> {
        let docsHomeDomain = OpenAPI.DocsDebugEnv.docsHomeDomain
        let path = OpenAPI.APIPath.getExtraDomainConfig
        let urlStr = OpenAPI.docs.currentNetScheme + "://" + docsHomeDomain + "/space" + path
        let request = DocsRequest<JSON>(url: urlStr, params: nil)
            .set(timeout: Double(ListConfig.requestTimeOut))
            .set(method: .GET)
            .set(retryCount: 3)
            .start(result: { (result, error) in
                DomainConfig.handleRemoteComputeDomain(result: result)
                let domainPoolStrArray = result?["data"]["common"]["domainPool"].arrayObject
                let domainPoolStrArrayLogStr = domainPoolStrArray != nil ? "\(domainPoolStrArray!)" : "nil"
                let errorLogStr = error != nil ? "\(error!)" : "nil"
                DocsLogger.info("---->get DocsSDK domainConfigs result：\(domainPoolStrArrayLogStr), error:\(errorLogStr)")
                if let data = result?["data"].rawString(), !data.isEmpty {
                    CCMKeyValue.globalUserDefault.set(data, forKey: UserDefaultKeys.exDomainConfigKey)
                } else {
                    self.dataUpdatePublish.onNext(false)
                    return
                }

                var domainsPool: [String] = []
                if let domainPool = result?["data"]["common"]["domainPool"].arrayObject as? [String] {
                    // 存到到userdefauts中
                    domainsPool.append(contentsOf: domainPool)
                }
                if !domainsPool.isEmpty {
                    CCMKeyValue.globalUserDefault.set(domainsPool, forKey: UserDefaultKeys.domainPoolV2Key)
                }

                if let createApi = result?["data"]["common"]["create_api"].arrayObject as? [String] {
                    // 存到到userdefauts中
                    domainsPool.append(contentsOf: createApi)
                }
                if !domainsPool.isEmpty {
                    CCMKeyValue.globalUserDefault.setStringArray(domainsPool, forKey: UserDefaultKeys.domainPoolKey)
                }
                DomainConfig.updateValidUrlPatternsV2()
                self.dataUpdatePublish.onNext(true)
            })
        request.makeSelfReferenced()
        return self.dataUpdatePublish.asObservable()
    }
    static func handleRemoteComputeDomain(result: JSON?) {
        if UserScopeNoChangeFG.WJS.bitableMobileSupportRemoteCompute, let overload_static_domain = result?["data"]["overload_static_domain"].arrayObject as? [String] {
            CCMKeyValue.globalUserDefault.setStringArray(overload_static_domain, forKey: UserDefaultKeys.adPermImageOverloadStaticDomainKey)
        }
        if UserScopeNoChangeFG.WJS.bitableMobileSupportRemoteCompute, let helpcenter = result?["data"]["common"]["domain"]["helpcenter"].string {
            CCMKeyValue.globalUserDefault.set(helpcenter, forKey: UserDefaultKeys.bitableShareNoticeLearnMoreDomain)
        }
    }

    static func clearLocalGlobalConfig() {
        CCMKeyValue.globalUserDefault.removeObject(forKey: UserDefaultKeys.exDomainConfigKey)
    }

    static var globalConfig: [String: Any]? {
        if let dataStr = CCMKeyValue.globalUserDefault.string(forKey: UserDefaultKeys.exDomainConfigKey) {
            let json = JSON(parseJSON: dataStr)
            return json.dictionaryObject
        }

        return nil
    }

    static var globalConfigStr: String? {
        return CCMKeyValue.globalUserDefault.string(forKey: UserDefaultKeys.exDomainConfigKey)
    }

    static var unitIDForBulletin: String {
        if let paramsConfig = globalConfig?["paramsConfig"] as? [String: Any], let unitID = paramsConfig["unitID"] as? String {
            return unitID
        }
        if DomainConfig.envInfo.isChinaMainland {
            return "cn"
        } else {
            return "va"
        }
    }

    static var getPermissionHelpDocumentUrl: String? {

        guard
            let common = globalConfig?["common"] as? [String: Any],
            let domains = common["domain"] as? [String: Any],
            let helpcenterDomain = domains["helpcenter"] as? String, !helpcenterDomain.isEmpty,
            let helpUrls = common["helpcenter_article"] as? [String: Any],
            let authorizedHelp = helpUrls["authorized_help"] as? Int else {

            return nil
        }
        /// isCn ? "https://getfeishu.cn/hc/zh-cn/articles/360025093793" : "https://getfeishu.cn/hc/en-us/articles/360025093793"

        var language = "/en-us"
        switch DocsSDK.currentLanguage {
        case .zh_CN:
            language = "/zh-cn"
        case .ja_JP:
            language = "/en-us" // "/ja-jp"
        default:
            language = "/en-us"
        }
        let url = OpenAPI.docs.currentNetScheme + "://" + helpcenterDomain + "/hc" + language + "/articles" + "/\(authorizedHelp)"
        return url
    }
    
    public static var helperCenterDomain: String? {
        guard let common = globalConfig?["common"] as? [String: Any],
              let domains = common["domain"] as? [String: Any],
              let domain = domains["helpcenter"] as? String
        else { return nil }
        return domain
    }
}

extension DomainConfig {

    private static let pathLock = NSLock()
    static var pathPatterns: [String] {
        let config = getValidatedPaths()
        if !config.isEmpty {
            return config
        }

        return ["/space",
                "/space/api/explorer/create",
                "/(doc|docs|docx|sheet|sheets|mindnote|mindnotes|slide|slides|file|folder|wiki)/",
                "/blank/",
                "/space/blank/",
                "/app/upgrade",
                "/(base|bitable)/(?!automation|feed)",
                "/drive",
                "/drive/api/explorer/create",
                "/drive/blank/"]
    }

    static func getValidatedPaths() -> [String] {
        if let paths = H5UrlPathConfig.getWhitePathList() {
            return paths
        }

        return []
    }

    private static var innerValidUrlPatternsV2: [String]?

    static var validUrlPatternsV2: [String] {
        pathLock.lock(); defer { pathLock.unlock() }

        if let urlPatterns = innerValidUrlPatternsV2 {
            return urlPatterns
        }

        return generateValidUrlPatternsV3()
    }

    /// 从FG返回后存在UserDefaults中取出来，第一次调用时，如果FG请求还没回来，就会使用上一次请求存在本的缓存
    @discardableResult
    public static func updateValidUrlPatternsV2() -> [String] {
        pathLock.lock(); defer { pathLock.unlock() }
        return generateValidUrlPatternsV3()
    }

    /// 调用此方法必须加锁：pathLock
    private static func generateValidUrlPatternsV3() -> [String] {
        let domains = validatedDomains
        let paths = pathPatterns
        guard !domains.isEmpty, !paths.isEmpty else {
            innerValidUrlPatternsV2 = validUrlPatterns //兜底逻辑
            return validUrlPatterns
        }
        //路由匹配性能优化，合成一个正则表达式 https://bytedance.feishu.cn/docs/doccnXTvjOPeYqlPLfvmNkg6ysd#WiMG4R
        let newDomains = domains.map { domain -> String in
            var curDomain = domain
            if curDomain.starts(with: ".") {
                curDomain.remove(at: curDomain.startIndex)
            }
            return curDomain.replacingOccurrences(of: ".", with: "\\.")
        }
        let domainString = newDomains.joined(separator: "|")
        let pathString = paths.joined(separator: "|")
        let newUrlPatterns = ["(\\.|//)(\(domainString))(\(pathString))"]
        innerValidUrlPatternsV2 = newUrlPatterns
        return newUrlPatterns
    }
}

extension DomainConfig {
    static var enableAbandonOversea: Bool {
        return CCMKeyValue.globalUserDefault.bool(forKey: UserDefaultKeys.docsAbandonOverseaEnable)
    }
}

final public class DomainConfigRNWatcher: RNMessageDelegate {
    private var dispose = DisposeBag()
    init() {}

    public func registerRNEvent() {
        if let rnManager = DocsContainer.shared.resolve(RNMangerAPI.self) {
            rnManager.registerRnEvent(eventNames: [.getDataFromRN], handler: self)
        }
    }

    public func didReceivedRNData(data outData: [String: Any], eventName: RNManager.RNEventName) {
        guard eventName == .getDataFromRN else {
            return
        }
        guard let action = outData["action"] as? String, action == "fetchDomainConfig" else {
            return
        }
        DocsLogger.info("收到RN消息, 准备去拉域名配置信息")
        DomainConfig.requestExDomainConfig().subscribe(onNext: { (_) in
            RNManager.manager.updateAPPInfoIfNeed()
        }).disposed(by: dispose)
    }
}
