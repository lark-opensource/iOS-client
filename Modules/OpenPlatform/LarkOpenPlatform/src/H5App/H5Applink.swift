//
//  H5Applink.swift
//  LarkOpenPlatform
//
//  Created by 李论 on 2020/1/19.
//

import EENavigator
import LKCommonsLogging
import LarkAccountInterface
import LarkAppLinkSDK
import LarkOPInterface
import LarkRustClient
import LarkSetting
import RxSwift
import SwiftyJSON
import Swinject
import UIKit
import LarkUIKit
import RoundedHUD
import LarkFeatureGating
import WebBrowser
import OPFoundation
import LarkFoundation
import EcosystemWeb
import OPSDK
import UniverseDesignToast
import OPWebApp
import ECOProbe
import LarkWebViewContainer
import LarkStorage
import EEMicroAppSDK
import LarkContainer
import LarkTab
import LarkTraitCollection


///
/// H5Applink：可以跳转H5App应用的link链接
/// H5AppLink测试用例：
/// case-1:
/// https://wd3.myworkday.com/bytedance/d/home.htmld?app_id=cli_9b50222c4ebbd102
/// case-2:
/// https://applink.feishu.cn/client/web_app/open?appId=cli_9b50222c4ebbd102
/// H5Applink测试路径：IM对话发送点击如上测试用例，即可跳转相应H5App。
///
public struct H5Applink {
    static let H5applinkKey = "/client/web_app/open"
    static let lkTargetUrl = "lk_target_url"
    static let customPathKey = "path"
    static let customFragmentKey = "lk_fragment"
    static let logger = Logger.log(H5Applink.self, category: "H5Applink")
    static func registerApplinkForH5App(container: Container) {
        //  注册网页应用 AppLink 协议
        LarkAppLinkSDK.registerHandler(path: H5applinkKey, handler: { (applink: AppLink) in
            let resolver = container.getCurrentUserResolver(compatibleMode: OPUserScope.compatibleModeEnabled)
            OPMonitor("applink_handler_start").setAppLink(applink).flush()
            H5ApplinkHandler.handle(applink: applink, resolver: resolver)
        })
    }

    public static func generateAppLink(targetUrl: String, appId: String) -> URL? {
        guard let applinkDomain = DomainSettingManager.shared.currentSetting["applink"]?.first else {
            // 理论上不会出现这个情况，这里是纯语法上的兜底写法，留下日志即可
            logger.error("invalid applink domain settings")
            assertionFailure("invalid applink domain settings")
            return nil
        }
        
        let applink = "https://\(applinkDomain)\(H5applinkKey)?appId=\(appId)"
        
        guard let url = URL(string: applink) else {
            logger.error("init url fail: \(applink)")
            return nil
        }
        
        guard var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            logger.error("init urlComponents fail: \(url)")
            return nil
        }
        
        let targetUrlQuery = URLQueryItem(name: lkTargetUrl, value: targetUrl)
        var queryItems = urlComponents.queryItems ?? []
        queryItems.append(targetUrlQuery)
        urlComponents.queryItems = queryItems
        
        return urlComponents.url
    }
    
    public static func generateCustomPathWebAppLink(targetUrl: String, appId: String) -> URL? {
        guard let applinkDomain = DomainSettingManager.shared.currentSetting["applink"]?.first else {
            // 理论上不会出现这个情况，这里是纯语法上的兜底写法，留下日志即可
            logger.error("invalid applink domain settings")
            assertionFailure("invalid applink domain settings")
            return nil
        }
        
        let applink = "https://\(applinkDomain)\(H5applinkKey)?appId=\(appId)"
        
        guard let url = URL(string: applink), let targetURL = URL(string: targetUrl) else {
            logger.error("init url fail: \(applink)")
            return nil
        }
        
        guard var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            logger.error("init urlComponents fail: \(url)")
            return nil
        }
        
        guard let targetUrlComponents = URLComponents(url: targetURL, resolvingAgainstBaseURL: false) else {
            logger.error("targetURL urlComponents fail: \(url)")
            return nil
        }
        
        var queryItems = urlComponents.queryItems ?? []
        // path
        let customPathQuery = URLQueryItem(name: customPathKey, value: targetUrlComponents.path)
        queryItems.append(customPathQuery)
        // fragment
        if !targetUrlComponents.fragment.isEmpty {
            let customFragmentQuery = URLQueryItem(name: customFragmentKey, value: targetUrlComponents.fragment)
            queryItems.append(customFragmentQuery)
        }
        
        // query items
        queryItems += targetUrlComponents.queryItems ?? []
        
        
        urlComponents.queryItems = queryItems
        return urlComponents.url
    }
}

/// H5Applink处理器：解析appLink参数，跳转相应的H5App
struct H5ApplinkHandler {
    static let H5appIdKey = "appId"
    static let urlParamAppIdKey = "app_id"
    static func handle(applink: AppLink, resolver: UserResolver) {
        H5Applink.logger.info("H5ApplinkHandler handle start url \(applink.url), from \(applink.from), context: \(applink.context)")
        var queryParameters: [String: String] = [:]
        if let components = URLComponents(url: applink.url, resolvingAgainstBaseURL: false),
            let queryItems = components.queryItems {
            for queryItem in queryItems.reversed() {
                queryParameters[queryItem.name] = queryItem.value
            }
        }
        guard let appId = queryParameters[H5appIdKey] else {
            H5Applink.logger.error("H5ApplinkHandler handle applink no appid \(queryParameters)")
            return
        }
        guard let tenantId = (try? resolver.resolve(assert: PassportUserService.self))?.user.tenant.tenantID else {
            H5Applink.logger.error("H5ApplinkHandler handle applink no tenantId")
            return
        }
        guard let from = applink.navigationFrom() else {
            H5Applink.logger.error("no from for AppLink")
            return
        }
        let cachekey = H5ApplinkCacheKeyPrefix(h5AppID: appId) + tenantId
        queryParameters[H5appIdKey] = nil
        
        let routerContext = applink.context as? [String:Any] ?? [:]
        if FeatureGatingManager.shared.featureGatingValue(with: FeatureGatingManager.Key(stringLiteral: "openplatform.applink.target.url.enable")),
           let targetUrl = queryParameters[H5Applink.lkTargetUrl] {
            // 如果有target_url，直接用这个url打开，不用单独去拉后台配置的链接
            queryParameters[H5Applink.lkTargetUrl] = nil
            H5App(resolver: resolver, appId: appId, urlParameters: queryParameters, cacheKey: cachekey, path: "/client/web_app/open", appLinkTraceId: applink.traceId, routerContext: routerContext).openTargetUrl(with: resolver, openType: applink.openType, from: from, targetUrl: targetUrl)
            return
        }
        
        // 组装H5App对象，执行open方法，跳转H5App
        H5App(resolver: resolver, appId: appId, urlParameters: queryParameters, cacheKey: cachekey, path: "/client/web_app/open", appLinkFrom: applink.from.rawValue, appLinkTraceId: applink.traceId, appLinkURLString: applink.url.absoluteString, routerContext: routerContext).open(with: resolver, openType: applink.openType, from: from, fromScene: .web_app_applink)
    }

    static func H5ApplinkCacheKeyPrefix(h5AppID: String) -> String {
        return "H5ApplinkCacheKeyPrefix" + h5AppID
    }
}
///
/// H5App：
///    （1）跳转URL预处理（获取对应真实链接，链接的path替换）
///    （2）实现H5App的跳转
///
class H5App {
    private let resolver: UserResolver
    private let appId: String                   // H5App的appId
    private var parameters: [String: String]    // url中的参数集合
    private let disposeBag = DisposeBag()       // 请求真实链接时使用disposeBag
    private let cacheKey: String                // 缓存URL的key
    private let path: String?
    private var appLinkTraceId: String?
    private static let H5PathKey = "path"
    private static let H5iOSPathKey = "path_ios"
    private static let H5FragmentKey = "lk_fragment"
    private static let H5iOSFragmentKey = "lk_fragment_ios"
    private static let urlCacheKey = "url"
    private static let nameCacheKey = "name"
    private static let iconKeyCacheKey = "iconKey"
    private static let iconURLCacheKey = "iconURL"
    private static let offlineEnableKey = "offlineEnable"
    private static let h5OfflineType = "h5OfflineType"
    private var appLinkFrom: String
    private var appLinkURLString: String
    var routerContext : [String:Any]

    // 是否禁用"用applink参数覆盖后台配置链接参数"
    private var disableOverrideParams: Bool  = {
        LarkFeatureGating.shared.getFeatureBoolValue(for: "openplatform.web_app.applink.override.params.disable")// user:global
    }()
    
    private lazy var uniteStorageReformEnable: Bool = {
        return FeatureGatingManager.shared.featureGatingValue(with: "openplatform.web.ios.unite.storage.reform")// user:global
    }()
    
    private let store : KVStore = {
        return KVStores.in(space: .global, domain: Domain.biz.microApp).udkv()
    }()
    
    static func fromSceneWithRouterContext(routerContext: [String:Any]) -> WebBrowserFromScene {
        
        if let lkWebFrom = routerContext["lk_web_from"] as? String {
            return WebBrowserFromScene(rawValue: lkWebFrom)
        } else if let from = routerContext["from"] as? String {
            return WebBrowserFromScene(rawValue: from)
        } else {
            return .normal
        }
    }

    init(resolver: UserResolver, appId: String, urlParameters: [String: String], cacheKey: String, path: String? = nil, appLinkFrom: String = "", appLinkTraceId: String? = "", appLinkURLString: String = "",routerContext: [String:Any] = [:]) {
        self.resolver = resolver
        self.appId = appId
        parameters = urlParameters
        self.cacheKey = cacheKey
        self.path = path
        self.appLinkFrom = appLinkFrom
        self.appLinkTraceId = appLinkTraceId
        self.appLinkURLString = appLinkURLString
        self.routerContext = routerContext
    }
    
    static func handlePushCommandIfNeeded(appId: String, latency: Int, extra: String, resolver: UserResolver){
        H5Applink.logger.info("appid:\(appId) ,latency: \(latency), extra \(extra)")
        let data = extra.data(using: String.Encoding.utf8, allowLossyConversion: false)
        guard let data = data else {
            H5Applink.logger.error("convert extra string to data failed")
            return
        }
        let json = try? JSONSerialization.jsonObject(with: data) as? [String:Any]
        if let json = json, let extensions = json["extensions"] as? Array<Any> {
            for appinfo in extensions {
                if let appinfo = appinfo as? [String:Any] ,let ext_type = appinfo["ext_type"] as? String, ext_type == "web_offline" {
                    DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + .seconds(latency > 0 ? latency : 0)) {
                        updateApplinkCache(appId: appId, resolver: resolver)
                    }
                    break;
                }
            }
        } else {
            H5Applink.logger.error("serialization extra failed")
        }
    }
    
    static func updateApplinkCache(appId: String, resolver: UserResolver){
        guard let tenantId = (try? resolver.resolve(assert: PassportUserService.self))?.user.tenant.tenantID else {
            H5Applink.logger.error("H5ApplinkHandler handle applink no tenantId")
            return
        }
        let cachekey = H5ApplinkHandler.H5ApplinkCacheKeyPrefix(h5AppID: appId) + tenantId
        let app = H5App(resolver: resolver, appId: appId, urlParameters: [:], cacheKey: cachekey, path: "/client/web_app/open", appLinkFrom: "", appLinkTraceId: "", appLinkURLString: "")
        app.retriveRealUrl(resolver: resolver) { (url, name, iconKey, iconURL, offlineEnable, h5OfflineType, error) in
            H5Applink.logger.info("retriveRealUrl cache url: \(app.appId)")
            if let err = error {
                H5Applink.logger.error("updateApplinkCache error \(err)")
                return
            }
            //如果url为空且不是离线包
            let responseH5Url = url
            H5Applink.logger.info("retriveRealUrl cache url: \(String(describing: responseH5Url)) key: \(cachekey), name:\(String(describing: name)), offlineEnable:\(offlineEnable), h5OfflineType\(h5OfflineType)")
            /*
            UserDefaults.standard.setValue(responseH5Url, forKey: self.cacheKey)
 */
            let defaultsMapWithoutNilValue:[String: Any?] = [
                H5App.urlCacheKey: responseH5Url,
                H5App.nameCacheKey: name,
                H5App.iconKeyCacheKey: iconKey,
                H5App.iconURLCacheKey: iconURL,
                H5App.offlineEnableKey: offlineEnable,
                H5App.h5OfflineType: h5OfflineType.rawValue
            ].filter({ $0.value != nil })
            if FeatureGatingManager.shared.featureGatingValue(with: "openplatform.web.ios.unite.storage.reform") {// user:global
                KVStores.in(space: .global, domain: Domain.biz.microApp).udkv().setDictionary(defaultsMapWithoutNilValue, forKey: cachekey)
            } else {
                UserDefaults.standard.setValue(defaultsMapWithoutNilValue, forKey: cachekey)
            }
        }
    }
    
    func openTargetUrl(with resolver: Resolver, openType: OpenType, from: NavigatorFrom, targetUrl: String) {
        var hasCache = false
        var cacheH5 : [String:Any]?
        if uniteStorageReformEnable {
//            cacheH5 = store.value(forKey: cacheKey) as? [String : Any]
            cacheH5 = store.dictionary(forKey: cacheKey)
        } else {
            cacheH5 = UserDefaults.standard.dictionary(forKey: cacheKey)
        }
        let disableCache =  FeatureGatingManager.realTimeManager.featureGatingValue(with: FeatureGatingManager.Key(stringLiteral: "openplatform.webapp.applink.metacache.disable"))
        if !disableCache, let cacheH5 = cacheH5, let cacheH5Url = cacheH5[H5App.urlCacheKey] as? String {
            hasCache = true
            if checkURLValid(lhs: targetUrl, rhs: cacheH5Url) {
                H5Applink.logger.info("openTargetUrl target url is valid")
                routerContext["lk_web_customurl"] = true
                openH5(url: targetUrl,
                       name: cacheH5[H5App.nameCacheKey] as? String,
                       iconKey: cacheH5[H5App.iconKeyCacheKey] as? String,
                       iconURL: cacheH5[H5App.iconURLCacheKey] as? String,
                       offlineEnable: false,
                       isCacheUrl: false,
                       openType: openType,
                       resolver: resolver,
                       from: from,
                       fromScene: .web_app_applink)
            } else {
                H5Applink.logger.error("openTargetUrl target url is invalid")
                open(with: self.resolver, openType: openType, from: from, fromScene: .web_app_applink)
            }
        }
        
        H5Applink.logger.info("openTargetUrl with cache \(hasCache)")
        
        // 请求最新URL并缓存
        retriveRealUrl(resolver: self.resolver) { (url, name, iconKey, iconURL, offlineEnable, h5OfflineType, error) in
            if let err = error {
                H5Applink.logger.error("openTargetUrl retriveRealUrl h5url error \(err)")
                if !FeatureGatingManager.realTimeManager.featureGatingValue(with: FeatureGatingManager.Key(stringLiteral: "lark.web.applink.supporttoast.disable")) {// user:global
                    if let nserror = error as? NSError, nserror.code == 0 {
                        // 进入到这个分支基本都是返回了数据，只是移动端h5地址没有配置，提示去PC使用
                        if !hasCache {
                            // 没有缓存时才进行错误提示
                            RoundedHUD.opShowFailure(with: BundleI18n.LarkOpenPlatform.Lark_Search_AppUnavailableInMobile)
                        }
                        if let cacheH5 = cacheH5 {
                            // 移动端未开启网页应用，且有缓存，需要把缓存删掉
                            H5Applink.logger.error("remove cache when not support mobile")
                            if self.uniteStorageReformEnable {
                                self.store.removeValue(forKey: self.cacheKey)
                            } else {
                                UserDefaults.standard.removeObject(forKey: self.cacheKey)
                            }
                        }
                    } else {
                        if !hasCache {
                            // 没有缓存时才进行错误提示
                            RoundedHUD.opShowFailure(with: BundleI18n.LarkOpenPlatform.OpenPlatform_VisitApp_UnavailableMsg)
                        }
                    }
                    return
                }
                if !hasCache {
                    // 没有缓存时才进行错误提示
                    RoundedHUD.opShowFailure(with: BundleI18n.LarkOpenPlatform.OpenPlatform_VisitApp_UnavailableMsg)
                }
                return
            }
            //如果url为空且不是离线包
            if url == nil && !offlineEnable {
                H5Applink.logger.warn("openTargetUrl retriveRealUrl url is empty \(String(describing: url))")
                if FeatureGatingManager.realTimeManager.featureGatingValue(with: FeatureGatingManager.Key(stringLiteral: "lark.web.applink.supporttoast.disable")) {// user:global
                    RoundedHUD.opShowFailure(with: BundleI18n.LarkOpenPlatform.OpenPlatform_VisitApp_UnavailableMsg)
                } else {
                    RoundedHUD.opShowFailure(with: BundleI18n.LarkOpenPlatform.Lark_Search_AppUnavailableInMobile)
                }
                return
            }
            
            let responseH5Url = url
            H5Applink.logger.info("openTargetUrl retriveRealUrl cache url: \(responseH5Url) key: \(self.cacheKey)")
            let defaultsMapWithoutNilValue:[String: Any?] = [
                H5App.urlCacheKey: responseH5Url,
                H5App.nameCacheKey: name,
                H5App.iconKeyCacheKey: iconKey,
                H5App.iconURLCacheKey: iconURL,
                H5App.offlineEnableKey: offlineEnable,
                H5App.h5OfflineType: h5OfflineType.rawValue
            ].filter({ $0.value != nil })
            if self.uniteStorageReformEnable {
                self.store.setDictionary(defaultsMapWithoutNilValue, forKey: self.cacheKey)
            } else {
                UserDefaults.standard.setValue(defaultsMapWithoutNilValue, forKey: self.cacheKey)
            }
            // 如果之前没有相应的缓存URL，在请求后打开H5
            guard hasCache else {
                if self.checkURLValid(lhs: targetUrl, rhs: url) {
                    self.routerContext["lk_web_customurl"] = true
                    self.openH5(url: targetUrl, name: name, iconKey: iconKey, iconURL: iconURL, offlineEnable: false, isCacheUrl: hasCache, openType: openType, resolver: resolver, from: from)
                } else {
                    self.openH5(url: url, name: name, iconKey: iconKey, iconURL: iconURL, offlineEnable: offlineEnable, isCacheUrl: hasCache, openType: openType, resolver: resolver, from: from)
                }
                return
            }
        }
    }
    
    // 判断两个url的scheme和host是否一致，用来检测 target_url的合法性
    private func checkURLValid(lhs: String?, rhs: String?) -> Bool {
        guard let lhs = lhs, let rhs = rhs else {
            H5Applink.logger.error("checkURLValid url string cannot be nil")
            return false
        }
        guard let lURL = URL(string: lhs), let rURL = URL(string: rhs) else {
            H5Applink.logger.error("checkURLValid init URL fail")
            return false
        }
        guard let lScheme = lURL.scheme?.lowercased(), let rScheme = rURL.scheme?.lowercased() else {
            H5Applink.logger.error("checkURLValid scheme is nil")
            return false
        }
        guard let lHost = lURL.host?.lowercased(), let rHost = rURL.host?.lowercased() else {
            H5Applink.logger.error("checkURLValid host is nil")
            return false
        }

        return lScheme == rScheme && lHost == rHost
    }

    func open(with resolver: UserResolver, openType: OpenType, from: NavigatorFrom, fromScene: H5AppFromScene? = nil) {
        var didOpenCache = false
        // UserDefaults存在相应的缓存URL，直接打开H5
        let disableCache =  FeatureGatingManager.realTimeManager.featureGatingValue(with: FeatureGatingManager.Key(stringLiteral: "openplatform.webapp.applink.metacache.disable"))// user:global
        var cacheH5 : [String:Any]?
        if uniteStorageReformEnable {
//            cacheH5 = store.value(forKey: cacheKey) as? [String : Any]
            cacheH5 = store.dictionary(forKey: cacheKey)
        } else {
            cacheH5 = UserDefaults.standard.dictionary(forKey: cacheKey)
        }
        if !disableCache, let cacheH5 = cacheH5 {
            let cacheH5Url = cacheH5[H5App.urlCacheKey] as? String
            let offlineEnable = cacheH5[H5App.offlineEnableKey] as? Bool ??  false
            
            let cacheh5OfflineType = H5OfflineType(rawValue: cacheH5[H5App.h5OfflineType] as? Int64 ?? 0) ?? .all
            if FeatureGatingManager.realTimeManager.featureGatingValue(with: FeatureGatingManager.Key(stringLiteral: "lark.developer_console.support_h5_offline_type")) {// user:global
                if offlineEnable && cacheh5OfflineType == H5OfflineType.pc {
                    H5Applink.logger.error("retriveRealUrl web offline webapp only support pc")
                    RoundedHUD.opShowFailure(with: BundleI18n.LarkOpenPlatform.Lark_Search_AppUnavailableInMobile)
                } else {
                    didOpenCache = cacheH5Url != nil || offlineEnable
                    openH5(url: cacheH5Url,
                           name: cacheH5[H5App.nameCacheKey] as? String,
                           iconKey: cacheH5[H5App.iconKeyCacheKey] as? String,
                           iconURL: cacheH5[H5App.iconURLCacheKey] as? String,
                           offlineEnable: offlineEnable,
                           isCacheUrl: didOpenCache,
                           openType: openType,
                           resolver: resolver,
                           from: from,
                           fromScene: fromScene)
                }
            } else {
                didOpenCache = cacheH5Url != nil || offlineEnable
                openH5(url: cacheH5Url,
                       name: cacheH5[H5App.nameCacheKey] as? String,
                       iconKey: cacheH5[H5App.iconKeyCacheKey] as? String,
                       iconURL: cacheH5[H5App.iconURLCacheKey] as? String,
                       offlineEnable: offlineEnable,
                       isCacheUrl: didOpenCache,
                       openType: openType,
                       resolver: resolver,
                       from: from,
                       fromScene: fromScene)
            }
        }
        // 请求最新URL并缓存
        retriveRealUrl(resolver: resolver) { (url, name, iconKey, iconURL, offlineEnable, h5OfflineType, error) in
            if let err = error {
                H5Applink.logger.error("retriveRealUrl h5url error \(err)")
                if !FeatureGatingManager.realTimeManager.featureGatingValue(with: FeatureGatingManager.Key(stringLiteral: "lark.web.applink.supporttoast.disable")) {// user:global
                    if let nserror = error as? NSError, nserror.code == 0 {
                        // 进入到这个分支基本都是返回了数据，只是移动端h5地址没有配置，提示去PC使用
                        if !didOpenCache {
                            // 没有缓存时才进行错误提示
                            RoundedHUD.opShowFailure(with: BundleI18n.LarkOpenPlatform.Lark_Search_AppUnavailableInMobile)
                        }
                        if let cacheH5 = cacheH5 {
                            // 移动端未开启网页应用，且有缓存，需要把缓存删掉
                            H5Applink.logger.error("remove cache when not support mobile")
                            if self.uniteStorageReformEnable {
                                self.store.removeValue(forKey: self.cacheKey)
                            } else {
                                UserDefaults.standard.removeObject(forKey: self.cacheKey)
                            }
                        }
                    } else {
                        if !didOpenCache {
                            // 没有缓存时才进行错误提示
                            RoundedHUD.opShowFailure(with: BundleI18n.LarkOpenPlatform.OpenPlatform_VisitApp_UnavailableMsg)
                        }
                    }
                    return
                }
                if !didOpenCache {
                    // 没有缓存时才进行错误提示
                    RoundedHUD.opShowFailure(with: BundleI18n.LarkOpenPlatform.OpenPlatform_VisitApp_UnavailableMsg)
                }
                return
            }
            //如果url为空且不是离线包
            if url == nil &&
                !offlineEnable {
                H5Applink.logger.warn("retriveRealUrl url is empty \(String(describing: url))")
                if FeatureGatingManager.realTimeManager.featureGatingValue(with: FeatureGatingManager.Key(stringLiteral: "lark.web.applink.supporttoast.disable")) {// user:global
                    RoundedHUD.opShowFailure(with: BundleI18n.LarkOpenPlatform.OpenPlatform_VisitApp_UnavailableMsg)
                } else {
                    RoundedHUD.opShowFailure(with: BundleI18n.LarkOpenPlatform.Lark_Search_AppUnavailableInMobile)
                }
                return
            }
            
            let responseH5Url = url
            H5Applink.logger.info("retriveRealUrl cache url: \(responseH5Url) key: \(self.cacheKey)")
            /*
            UserDefaults.standard.setValue(responseH5Url, forKey: self.cacheKey)
 */
            // 开启离线包但是仅配置了pc端
            if FeatureGatingManager.realTimeManager.featureGatingValue(with: FeatureGatingManager.Key(stringLiteral: "lark.developer_console.support_h5_offline_type")) {// user:global
                if offlineEnable && h5OfflineType == H5OfflineType.pc {
                    H5Applink.logger.error("retriveRealUrl web offline webapp only support pc")
                    RoundedHUD.opShowFailure(with: BundleI18n.LarkOpenPlatform.Lark_Search_AppUnavailableInMobile)
                    if let cacheH5 = cacheH5 {
                        // 移动端未开启网页应用，且有缓存，需要把缓存删掉
                        H5Applink.logger.error("remove cache when not support mobile")
                        if self.uniteStorageReformEnable {
                            self.store.removeValue(forKey: self.cacheKey)
                        } else {
                            UserDefaults.standard.removeObject(forKey: self.cacheKey)
                        }
                    }
                    return
                }
            }
            let defaultsMapWithoutNilValue:[String: Any?] = [
                H5App.urlCacheKey: responseH5Url,
                H5App.nameCacheKey: name,
                H5App.iconKeyCacheKey: iconKey,
                H5App.iconURLCacheKey: iconURL,
                H5App.offlineEnableKey: offlineEnable,
                H5App.h5OfflineType: h5OfflineType.rawValue
            ].filter({ $0.value != nil })
            if self.uniteStorageReformEnable {
                self.store.setDictionary(defaultsMapWithoutNilValue, forKey: self.cacheKey)
            } else {
                UserDefaults.standard.setValue(defaultsMapWithoutNilValue, forKey: self.cacheKey)
            }
            // 如果之前没有相应的缓存URL，在请求后打开H5
            guard didOpenCache else {
                self.openH5(url: url, name: name, iconKey: iconKey, iconURL: iconURL, offlineEnable: offlineEnable, isCacheUrl: didOpenCache, openType: openType, resolver: resolver, from: from, fromScene: fromScene)
                return
            }
        }
    }

    func openH5(url: String?, name: String?, iconKey: String?, iconURL: String?, offlineEnable: Bool, isCacheUrl: Bool, openType: OpenType, resolver: Resolver, from: NavigatorFrom, fromScene: H5AppFromScene? = nil) {
        if offlineEnable {
            H5Applink.logger.info("web offline openH5 with offlineEnable")
            let instanceID = UUID().uuidString
            let uniqueID = OPAppUniqueID(appID: appId, identifier: nil, versionType: .current, appType: .webApp, instanceID: instanceID)
            
            var topViewContainer: UIView?
            if let topView = Navigator.shared.mainSceneWindow {// user:global
                topViewContainer = topView
                DispatchQueue.main.async {
                    UDToast.showLoading(with: BundleI18n.LarkOpenPlatform.OpenPlatform_AppActions_LoadingDesc, on: topView, disableUserInteraction: true)
                }
            }
            OPWebAppManager.sharedInstance.prepareWebApp(uniqueId: uniqueID,
                                                         previewToken: nil,
                                                         supportOnline: false,
                                                         completeBlock: { (error, state, ext) in
                guard let topViewContainer = topViewContainer else {
                    //VC无法获取，会导致toast出不来
                    H5Applink.logger.error("web offline fail to openH5 in with desc: topVC is nil")
                    return
                }
                if let error = error {
                    var errorMessage = BundleI18n.LarkOpenPlatform.OpenPlatform_AppActions_NetworkErrToast
                    //如果是版本不兼容导致的错误，需要提示对应文案
                    if let error = error as? OPError,
                       let errorExTypeValue = error.userInfo["errorExType"] as? Int {
                        //提示版本太低需要更新
                        if errorExTypeValue == OPWebAppErrorType.verisonCompatible.rawValue {
                            errorMessage = BundleI18n.LarkOpenPlatform.OpenPlatform_H5Installer_ClientUpdate
                            //离线能力未开启，提示不可用
                        } else if errorExTypeValue == OPWebAppErrorType.offlineDisable.rawValue {
                            errorMessage = BundleI18n.LarkOpenPlatform.OpenPlatform_Worker_FeatureUnavailable
                        }
                    }
                    UDToast.removeToast(on: topViewContainer)
                    UDToast.showTips(with: errorMessage, on: topViewContainer)
                    return
                }
                if state == .meta {
                    H5Applink.logger.info("web offline openH5, webapp return on meta state")
                    return
                }
                DispatchQueue.main.async {
                    UDToast.removeToast(on: topViewContainer)
                }
                //拼接URL
                //如果本地存在数据且包已经下载完成，可以进行拦截
                if let (vhost, mainUrl) = OPWebAppManager.sharedInstance.webAppURLWithUniqueId(uniqueID),
                   let h5URL = URL(string: ((convert_https_to_http() ? vhost.replaceFirst(of: "https://", with: "http://") : vhost) + mainUrl)) {
                    let targetUrl = self.offlienTargetURLWithMainUrl(h5URL: h5URL, mainUrl: nil)
                    H5Applink.logger.info("web offline openH5 in webAppURLWithAppId:\(self.appId) targetUrl = \(targetUrl)")
                    if FeatureGatingManager.realTimeManager.featureGatingValue(with: FeatureGatingManager.Key(stringLiteral: "openplatform.offline.wkurlschemehandler")) {// user:global
                        //新代码开始
                        H5Applink.logger.info("web offline openH5 2.0")
                        var fallbackUrlsOptional: [URL]?
                        fallbackUrlsOptional = [URL]()
                        if let fallbackUrlStrings = ext?.fallbackUrls {
                            for urlString in fallbackUrlStrings {
                                var urlString = urlString
                                if var p = ext?.mainUrl {
                                    if !urlString.hasSuffix("/"), !p.starts(with: "/") {
                                        p = "/" + p
                                    }
                                    urlString = urlString + p
                                }
                                if let u = URL(string: urlString) {
                                    fallbackUrlsOptional?.append(u)
                                }
                            }
                        }
                        if #available(iOS 12.2, *), !offline_v2_useFallbackURLs(appID: self.appId) {
                            //  iOS12.2以上且不使用fallback，直接加载离线资源
                            let trace = OPTraceService.default().generateTrace()
                            let panelConfig = PanelBrowserConfig(params: targetUrl.lf.queryDictionary)
                            var fromAppOutSide = false //是否App外部唤起
                            if let applinkFromType = AppLinkFrom(rawValue: self.appLinkFrom) {
                                fromAppOutSide = (applinkFromType == .app)
                            }
                            let statusBarOrientation = UIApplication.shared.statusBarOrientation
                            let isLandscape = statusBarOrientation == .landscapeLeft || statusBarOrientation == .landscapeRight //是否横屏
                            let enablePanel = FeatureGatingManager.shared.featureGatingValue(with: FeatureGatingManager.Key(stringLiteral: "openplatform.applink.open_web_app_with_panel.enable"))// user:global
                            //非ipad && 非横屏 && 非外部唤起 && 开关开 && 参数合法，才可以使用半屏，否则全屏。
                            let useLarkWebPanel = !Display.pad &&
                                                  !isLandscape &&
                                                  !fromAppOutSide &&
                                                  enablePanel &&
                                                  panelConfig.usePanel()
                            
                            let bizType: LarkWebViewBizType = useLarkWebPanel == true ? .larkWebPanel : .larkWeb
                            var isCollapsed: Bool = false
                            if let trait = from.fromViewController?.rootWindow()?.traitCollection , let size = from.fromViewController?.rootWindow()?.bounds.size {
                                let newTrait =  TraitCollectionKit.customTraitCollection(trait, size)
                                isCollapsed = newTrait.horizontalSizeClass == .compact
                            }
                            let fromSceneInContext = H5App.fromSceneWithRouterContext(routerContext: self.routerContext)
                            let fromSceneInContextReport = WebBrowserFromSceneReport.build(context: self.routerContext)
                            let fromMode = self.routerContext["lk_web_mode"] as? String ?? ""
                            var scene: WebBrowserScene = .normal
                            if(useLarkWebPanel) {
                                //update
                                scene = .panel
                            } else if let myAIQuickLaunchbarService = try? resolver.resolve(assert: LarkOpenPlatformMyAIService.self), myAIQuickLaunchbarService.isTemporaryEnabled(), Display.pad, !isCollapsed {
                                let workplaceTemporaryTabEnable = FeatureGatingManager.shared.featureGatingValue(with: FeatureGatingManager.Key(stringLiteral: "openplatform.web.workplace.temporary.enable"))
                                let handleShowTemporaryEnable = !FeatureGatingManager.shared.featureGatingValue(with: FeatureGatingManager.Key(stringLiteral: "openplatform.web.handle.showtemporary.disable"))
                                if handleShowTemporaryEnable, let showTemporary = self.routerContext["showTemporary"] as? Bool {
                                    //context包含showTemporary有值的处理
                                    scene = showTemporary == true ? .temporaryTab : .normal
                                } else {
                                    //context包含showTemporary没有值 or disbale FG开启，走旧逻辑
                                    if fromSceneInContext == .web, fromMode == WebBrowserScene.normal.rawValue{
                                        scene = .normal
                                    } else if (fromSceneInContext == .workplace || fromSceneInContext == .workplacePortal) && !workplaceTemporaryTabEnable {
                                        scene = .normal
                                    } else {
                                        scene = .temporaryTab
                                    }
                                }
                                if let fromWebScene = self.routerContext["fromWebMultiScene"] as? Bool, fromWebScene == true {
                                    // 兼容ipad 多scene场景，不需要再标签页打开，直接返回browser即可.
                                    scene = .normal
                                }
                            }
                            H5Applink.logger.info("web offline openH5 2.0 and create browser, traceId is \(trace.traceId ?? ""), useLarkWebPanel:\(useLarkWebPanel), scene:\(scene)")
                            OPMonitor(WebContainerMonitorEvent.containerStartHandle)
                                .setWebAppID(self.appId)
                                .setWebURL(targetUrl)
                                .setWebBizType(bizType)
                                .addCategoryValue("from", fromScene?.rawValue)
                                .setWebBrowserScene(scene)
                                .addCategoryValue("applink_trace_id", self.appLinkTraceId)
                                .setWebBrowserOffline(true)
                                .tracing(trace)
                                .flush()
                            
                            var configuration = WebBrowserConfiguration(webBrowserID: instanceID)
                            configuration.resourceInterceptConfiguration = (offline_v2_schemes(), WebAppResourceIntercept())
                            configuration.acceptWebMeta = true
                            configuration.enableRedirectOptimization = true
                            configuration.initTrace = trace
                            configuration.startHandleTime = Date().timeIntervalSince1970
                            configuration.scene = scene
                            configuration.appId = self.appId
                            configuration.webBizType = bizType
                            configuration.offline = true
                            configuration.applinkURLString = self.appLinkURLString
                            configuration.fromScene = fromSceneInContext
                            configuration.fromSceneReport = fromSceneInContextReport
                            let browser = WebBrowser(url: targetUrl, configuration: configuration)
                            browser.resolver = resolver
                            browser.tabContainableIdentifier = self.routerContext[NavigationKeys.uniqueid] as? String ?? ""
                            self.registerExtensionItems(browser: browser, webAppInfo: WebAppInfo(id: self.appId, name: name, iconKey: iconKey, iconURL: iconURL), isWebPanel: useLarkWebPanel)
                            if useLarkWebPanel {
                                //半屏离线
                                let panelBrowserVC = PanelBrowserViewContainer(contentViewController: browser, style: panelConfig.panelStyle, appId: self.appId, resolver: resolver)
                                self.monitorApplinkHandlerSuccess()
                                panelBrowserVC.show(from: from.fromViewController)
                            } else {
                                //(默认)全屏离线
                                var finalOpenType = openType
                                //支持网页进Feed需求iPad场景处理
                                if Display.pad, let from = self.routerContext["from"] as? String, WebBrowserFromScene(rawValue: from) == .feed {
                                    finalOpenType = self.routerContext[ContextKeys.openType] as? EENavigator.OpenType ?? .push
                                    
                                }
                                switch finalOpenType {
                                case .showDetail:
                                    guard let from = from.fromViewController ?? Navigator.shared.mainSceneWindow?.fromViewController else {// user:global
                                        H5Applink.logger.warn("web offline openH5 cache:\(isCacheUrl) targetUrl = \(targetUrl) can not find host vc")
                                        return
                                    }
                                    self.monitorApplinkHandlerSuccess()
                                    if configuration.scene == .temporaryTab, let myAIQuickLaunchbarService = try? resolver.resolve(assert: LarkOpenPlatformMyAIService.self) {
                                        myAIQuickLaunchbarService.showTabVC(browser)
                                        H5Applink.logger.info("web offline openH5 2.0 and showTabVC")
                                    } else {
                                        Navigator.shared.showDetailOrPush(browser, context: self.routerContext, wrap: LkNavigationController.self, from: from)// user:global
                                        H5Applink.logger.info("web offline openH5 2.0 and showDetailOrPush")
                                    }
                                default:
                                    assert(openType == .push, "open h5 applink with wrong openType \(openType)")
                                    self.monitorApplinkHandlerSuccess()
                                    if configuration.scene == .temporaryTab, let myAIQuickLaunchbarService = try? resolver.resolve(assert: LarkOpenPlatformMyAIService.self) {
                                        myAIQuickLaunchbarService.showTabVC(browser)
                                        H5Applink.logger.info("web offline openH5 2.0 and showTabVC")
                                    } else {
                                        Navigator.shared.push(browser, from: from)// user:global
                                        H5Applink.logger.info("web offline openH5 2.0 and showDetailOrPush")
                                    }
                                }
                            }
                        } else {
                            //  此FG只用于URLProtocol下线前，URLProtocol删除的时候删掉这行if以及else内的代码
                            if FeatureGatingManager.shared.featureGatingValue(with: FeatureGatingManager.Key(stringLiteral: "openplatform.offline.usefallback")) {// user:global
                                H5Applink.logger.info("web offline openH5 2.0 and use fallback")
                                if var fallbackUrls = fallbackUrlsOptional, !fallbackUrls.isEmpty {
                                    let firstFallbackURL = fallbackUrls.removeFirst()
                                    
                                    let trace = OPTraceService.default().generateTrace()
                                    H5Applink.logger.info("H5AppLink, traceId is \(trace.traceId ?? "")")
                                    OPMonitor(WebContainerMonitorEvent.containerStartHandle)
                                        .setWebAppID(self.appId)
                                        .setWebURL(firstFallbackURL)
                                        .setWebBizType(.larkWeb)
                                        .addCategoryValue("from", fromScene?.rawValue)
                                        .addCategoryValue("applink_trace_id", self.appLinkTraceId)
                                        .setWebBrowserScene(WebBrowserScene.normal)
                                        .tracing(trace)
                                        .flush()
                                    var isCollapsed: Bool = false
                                    if let trait = from.fromViewController?.rootWindow()?.traitCollection , let size = from.fromViewController?.rootWindow()?.bounds.size {
                                        let newTrait =  TraitCollectionKit.customTraitCollection(trait, size)
                                        isCollapsed = newTrait.horizontalSizeClass == .compact
                                    }
                                    let fromSceneInContext = H5App.fromSceneWithRouterContext(routerContext: self.routerContext)
                                    let fromSceneInContextReport = WebBrowserFromSceneReport.build(context: self.routerContext)
                                    let fromMode = self.routerContext["lk_web_mode"] as? String ?? ""
                                    var configuration = WebBrowserConfiguration(webBrowserID: instanceID)
                                    configuration.acceptWebMeta = true
                                    configuration.enableRedirectOptimization = true
                                    configuration.initTrace = trace
                                    configuration.startHandleTime = Date().timeIntervalSince1970
                                    var scene = WebBrowserScene.normal
                                    if let myAIQuickLaunchbarService = try? resolver.resolve(assert: LarkOpenPlatformMyAIService.self), myAIQuickLaunchbarService.isTemporaryEnabled(), Display.pad, !isCollapsed {
                                        let workplaceTemporaryTabEnable = FeatureGatingManager.shared.featureGatingValue(with: FeatureGatingManager.Key(stringLiteral: "openplatform.web.workplace.temporary.enable"))
                                        let handleShowTemporaryEnable = !FeatureGatingManager.shared.featureGatingValue(with: FeatureGatingManager.Key(stringLiteral: "openplatform.web.handle.showtemporary.disable"))
                                        if handleShowTemporaryEnable, let showTemporary = self.routerContext["showTemporary"] as? Bool {
                                            //context包含showTemporary有值的处理
                                            scene = showTemporary == true ? .temporaryTab : .normal
                                        } else {
                                            //context包含showTemporary没有值 or disbale FG开启，走旧逻辑
                                            if fromSceneInContext == .web, fromMode == WebBrowserScene.normal.rawValue{
                                                scene = .normal
                                            } else if (fromSceneInContext == .workplace || fromSceneInContext == .workplacePortal) && !workplaceTemporaryTabEnable {
                                                scene = .normal
                                            } else {
                                                scene = .temporaryTab
                                            }
                                        }
                                    }
                                    configuration.scene = scene
                                    configuration.appId = self.appId
                                    configuration.fromScene = fromSceneInContext
                                    configuration.fromSceneReport = fromSceneInContextReport
                                    configuration.offline = true
                                    let targetUrl = self.offlienTargetURLWithMainUrl(h5URL: firstFallbackURL, mainUrl: nil)
                                    H5Applink.logger.info("web offline openH5 2.0 and create browser, traceId is \(trace.traceId), scene:\(scene)")
                                    let browser = WebBrowser(url: targetUrl, configuration: configuration)
                                    browser.tabContainableIdentifier = self.routerContext[NavigationKeys.uniqueid] as? String ?? ""
                                    browser.resolver = resolver
                                    if !fallbackUrls.isEmpty {
                                        try? browser.register(item: FallbackExtensionItem(fallbackUrls: fallbackUrls))
                                    }
                                    self.registerExtensionItems(browser: browser, webAppInfo: WebAppInfo(id: self.appId, name: name, iconKey: iconKey, iconURL: iconURL), isWebPanel: false)
                                    
                                    var finalOpenType = openType
                                    //支持网页进Feed需求iPad场景处理
                                    if Display.pad, let from = self.routerContext["from"] as? String, WebBrowserFromScene(rawValue: from) == .feed {
                                        finalOpenType = self.routerContext[ContextKeys.openType] as? EENavigator.OpenType ?? .push
                                    }
                                    switch finalOpenType {
                                    case .showDetail:
                                        guard let from = from.fromViewController ?? Navigator.shared.mainSceneWindow?.fromViewController else {// user:global
                                            H5Applink.logger.warn("web offline openH5 cache:\(isCacheUrl) targetUrl = \(targetUrl) can not find host vc")
                                            return
                                        }
                                        self.monitorApplinkHandlerSuccess()
                                        if configuration.scene == .temporaryTab, let myAIQuickLaunchbarService = try? resolver.resolve(assert: LarkOpenPlatformMyAIService.self) {
                                            H5Applink.logger.info("web offline showTabVC with fallback")
                                            myAIQuickLaunchbarService.showTabVC(browser)
                                        } else {
                                            H5Applink.logger.info("web offline showDetail with fallback")
                                            Navigator.shared.showDetailOrPush(browser, context: self.routerContext, wrap: LkNavigationController.self, from: from)// user:global
                                        }
                                    default:
                                        assert(openType == .push, "open h5 applink with wrong openType \(openType)")
                                        self.monitorApplinkHandlerSuccess()
                                        if configuration.scene == .temporaryTab, let myAIQuickLaunchbarService = try? resolver.resolve(assert: LarkOpenPlatformMyAIService.self) {
                                            H5Applink.logger.info("web offline showTabVC with fallback")
                                            myAIQuickLaunchbarService.showTabVC(browser)
                                        } else {
                                            H5Applink.logger.info("web offline push with fallback")
                                            Navigator.shared.push(browser, from: from)// user:global
                                        }
                                    }
                                } else {
                                    H5Applink.logger.info("web offline 2.0 use fallback but fallback url nil")
                                    UDToast.showTips(with: BundleI18n.LarkOpenPlatform.OpenPlatform_AppActions_NetworkErrToast, on: topViewContainer)
                                }
                            } else {
                                // URLProtocol删除的时候删掉这段代码
                                //  不开启fallback，则降级到urlprotocol
                                //  网页应用appLink仅用于打开网页应用或者网页应用跳转，要强制push新容器的
                                H5Applink.logger.info("web offline openH5 2.0 and disable fallback use web offline body")
                                let body = WebOfflineBody(url: targetUrl, webAppInfo: WebAppInfo(id: self.appId, name: name, iconKey: iconKey, iconURL: iconURL), webBrowserID: instanceID, fromScene: fromScene, appLinkTrackId: self.appLinkTraceId)
                                switch openType {
                                case .showDetail:
                                    guard let from = from.fromViewController ?? Navigator.shared.mainSceneWindow?.fromViewController else {
                                        H5Applink.logger.warn("web offline openH5 cache:\(isCacheUrl) targetUrl = \(targetUrl) can not find host vc")// user:global
                                        return
                                    }
                                    self.monitorApplinkHandlerSuccess()
                                    Navigator.shared.showDetailOrPush(body: body, context: self.routerContext, wrap: LkNavigationController.self, from: from)// user:global
                                default:
                                    assert(openType == .push, "open h5 applink with wrong openType \(openType)")
                                    self.monitorApplinkHandlerSuccess()
                                    Navigator.shared.push(body: body,context: self.routerContext, from: from)// user:global
                                }
                            }
                        }
                        //新代码结束
                    } else {
                    //  网页应用appLink仅用于打开网页应用或者网页应用跳转，要强制push新容器的
                        H5Applink.logger.info("web offline openH5 1.0")
                        let body = WebOfflineBody(url: targetUrl, webAppInfo: WebAppInfo(id: self.appId, name: name, iconKey: iconKey, iconURL: iconURL), webBrowserID: instanceID, fromScene: fromScene, appLinkTrackId: self.appLinkTraceId)
                    switch openType {
                    case .showDetail:
                        guard let from = from.fromViewController ?? Navigator.shared.mainSceneWindow?.fromViewController else {// user:global
                            H5Applink.logger.warn("web offline openH5 cache:\(isCacheUrl) targetUrl = \(targetUrl) can not find host vc")
                            return
                        }
                        self.monitorApplinkHandlerSuccess()
                        Navigator.shared.showDetailOrPush(body: body, context: self.routerContext, wrap: LkNavigationController.self, from: from)// user:global
                    default:
                        assert(openType == .push, "web offline  open h5 applink with wrong openType \(openType)")
                        self.monitorApplinkHandlerSuccess()
                        Navigator.shared.push(body: body, context: self.routerContext, from: from)// user:global
                    }
                    }
                } else {
                    H5Applink.logger.info("web offline  fail to openH5 in webAppURLWithAppId:\(self.appId)")
                    UDToast.showTips(with:  BundleI18n.LarkOpenPlatform.OpenPlatform_Worker_FeatureUnavailable, on: topViewContainer)
                }
            })
            return
        }
        guard let h5url = url, let h5URL = h5url.possibleURL() else {
            H5Applink.logger.error("openH5 cache:\(isCacheUrl) retriveRealUrl url is empty")
            return
        }
        H5Applink.logger.info("openH5 cache:\(isCacheUrl) h5url = \(h5url)")
        /// 判断是不是doc，长期需要使用doc的applink方案，已经提需求给到Doc这边
        /// 这里临时为了问题的结局，采取的兼容方案，方案已经和后端、Doc的同事沟通
        if let dependency = try? resolver.resolve(assert: OpenPlatformDependency.self), dependency.canOpenDocs(url: h5url) {
            let targetUrl = self.targetURLWithMainUrl(h5URL: h5URL, mainUrl: nil)
            self.monitorApplinkHandlerSuccess()
            Navigator.shared.push(targetUrl, context: self.routerContext, from: from)// user:global
            H5Applink.logger.info("retriveRealUrl Doc url: \(targetUrl)")
            return
        }
        // 添加参数生成最终要跳转的URL
        let targetUrl = self.targetURLWithMainUrl(h5URL: h5URL, mainUrl: nil)
        H5Applink.logger.info("openH5 cache:\(isCacheUrl) targetUrl = \(targetUrl)")
        //  网页应用appLink仅用于打开网页应用或者网页应用跳转，要强制push新容器的
        var body = WebBody(url: targetUrl, webAppInfo: WebAppInfo(id: appId, name: name, iconKey: iconKey, iconURL: iconURL))
        body.fromScene = fromScene
        body.appLinkFrom = self.appLinkFrom
        body.appLinkTrackId = self.appLinkTraceId
        
        var finalOpenType = openType
        //支持网页进Feed需求iPad场景处理
        if Display.pad, let from = self.routerContext["from"] as? String, WebBrowserFromScene(rawValue: from) == .feed {
            finalOpenType = self.routerContext[ContextKeys.openType] as? EENavigator.OpenType ?? .push
        }
    
        switch finalOpenType {
        case .showDetail:
            guard let from = from.fromViewController ?? Navigator.shared.mainSceneWindow?.fromViewController else {// user:global
                H5Applink.logger.warn("openH5 cache:\(isCacheUrl) targetUrl = \(targetUrl) can not find host vc")
                return
            }
            self.monitorApplinkHandlerSuccess()
            if !FeatureGatingManager.realTimeManager.featureGatingValue(with: FeatureGatingManager.Key(stringLiteral: "openplatform.applink.routeragain.disable")) {// user:global
                let applinkContext = ["fromScene" : fromScene, "appLinkFrom" : self.appLinkFrom, "appLinkTrackId" : self.appLinkTraceId , "webAppInfo": body.webAppInfo] as [String : Any]
                let finalContext = self.routerContext.merging(applinkContext) { first, _ in
                    return first
                }
                Navigator.shared.showDetailOrPush(targetUrl, context: finalContext, wrap: LkNavigationController.self, from: from)// user:global
            }else{
                Navigator.shared.showDetailOrPush(body: body, context: self.routerContext, wrap: LkNavigationController.self, from: from)// user:global
            }
            
        default:
            assert(openType == .push, "open h5 applink with wrong openType \(openType)")
            self.monitorApplinkHandlerSuccess()
            
            if !FeatureGatingManager.realTimeManager.featureGatingValue(with: FeatureGatingManager.Key(stringLiteral: "openplatform.applink.routeragain.disable")) {// user:global
                let applinkContext = ["fromScene" : fromScene, "appLinkFrom" : self.appLinkFrom, "appLinkTrackId" : self.appLinkTraceId , "webAppInfo": body.webAppInfo] as [String : Any]
                let finalContext = self.routerContext.merging(applinkContext) { first, _ in
                    return first
                }
                Navigator.shared.push(targetUrl, context:finalContext, from: from)// user:global
            }else{
                Navigator.shared.push(body: body, context: self.routerContext, from: from)// user:global
            }
        }
    }
    
    private func registerExtensionItems(browser: WebBrowser, webAppInfo: WebAppInfo, isWebPanel: Bool) {
        do {
            try registerWebMetaExtension(for: browser)
            try browser.register(item: MonitorExtensionItem())
            if !isWebPanel {
                try browser.register(item: NavigationBarStyleExtensionItem())
                try browser.register(item: NavigationBarMiddleExtensionItem())
                try browser.register(item: NavigationBarLeftExtensionItem(browser: browser))
            }
        
            try browser.register(item: MemoryLeakExtensionItem())
            try browser.register(item: TerminateReloadExtensionItem(browser: browser))
            if !isWebPanel {
                try browser.register(item: ProgressViewExtensionItem())
            }
            try browser.register(item: ErrorPageExtensionItem())
            try browser.register(item: WebInspectorExtensionItem(browser: browser))
            if OPUserScope.userResolver().fg.staticFeatureGatingValue(with: "openplatform.browser.remote.debug.client_enable") {
                try browser.register(item: WebOnlineInspectorExtensionItem(browser: browser))
            }
            try browser.register(item: UniteRouterExtensionItem())
            try browser.register(item: MediaExtensionItem())
            try browser.register(item: EcosystemAPIExtensionItem())
            try browser.register(singleItem: EcosystemWebSingleExtensionItem())
            try browser.register(item: WebMenuExtensionItem(browser: browser))
            try browser.register(item: NavigationBarRightExtensionItem(browser: browser))
            try browser.register(item: WebLaunchBarExtensionItem(browser: browser))
            try browser.register(item: WebInlineAIExtensionItem(browser: browser))
            try browser.register(item: NativeComponentExtensionItem())
            if Display.pad {
                try browser.register(item: PadExtensionItem(browser: browser))
            }
            try browser.register(item: WebMetaLegacyExtensionItem())
            try browser.register(item: WebAppExtensionItem(browser: browser, webAppInfo: webAppInfo))
            if !FeatureGatingManager.shared.featureGatingValue(with: .init(stringLiteral: "openplatform.web.leaveconfirm.disable")) {// user:global
            try browser.register(item: LeaveConfirmExtensionItem())
            }
            if WebBrowser.isDynamicNetStatusEnabled() {
                try browser.register(item: NetStatusExtenstionItem(browser: browser))
            }
            if WebTextSizeMenuPlugin.featureEnabled {
                try browser.register(item: WebTextSizeExtensionItem(browser: browser))
            }
            if let searchItem = WebSearchExtensionItem(browser: browser) {
                try browser.register(item: searchItem)
            }
        } catch {
            H5Applink.logger.error("registerExtensionItems error", error: error)
        }
    }
    
    private func registerWebMetaExtension(for browser: WebBrowser) throws {
        guard browser.configuration.acceptWebMeta else {
            H5Applink.logger.error("registerWebMetaExtension error because acceptWebMeta is false")
            return
        }
        try browser.register(item: WebMetaExtensionItem(browser: browser))
        let orientationExtensionItem = WebMetaOrientationExtensionItem(browser: browser)
        if Display.phone {
            try browser.register(item: orientationExtensionItem)
        }
        try browser.register(item: WebMetaSafeAreaExtensionItem(browser: browser))
        if FeatureGatingManager.shared.featureGatingValue(with: FeatureGatingManager.Key(stringLiteral: "openplatform.web.meta.meta_hidemenuitems"))// user:global
            || WebMetaMoreMenuConfigExtensionItem.isWebShareLinkEnabled() {
            try browser.register(item: WebMetaMoreMenuConfigExtensionItem(browser: browser))
        }
        if WebMetaSlideToCloseExtensionItem.isSlideToCloseEnabled() {
            try browser.register(item: WebMetaSlideToCloseExtensionItem(browser: browser))
        }
        if WebMetaBackForwardGesturesExtensionItem.allowBackForwardGesEnable() {
            try browser.register(item: WebMetaBackForwardGesturesExtensionItem(browser: browser))
        }
        if WebMetaNavigationBarExtensionItem.isShowNavigationBarEnabled() ||
            WebMetaNavigationBarExtensionItem.isNavBgAndFgColorEnabled() ||
            WebMetaNavigationBarExtensionItem.isHideNavBarItemsEnabled() {
            try browser.register(item: WebMetaNavigationBarExtensionItem(browser: browser))
        }
        if WebMetaLaunchBarExtensionItem.isShowLaunchBarEnabled() {
            try browser.register(item: WebMetaLaunchBarExtensionItem(browser: browser))
        }
    }
    
    private func targetURLWithMainUrl(h5URL: URL, mainUrl: String?) -> URL {
        var newH5URL: URL = h5URL
        // 优先使用iosPath进行替换，其次使用path，替换后去除path/iosPath参数
        // 若有path参数的不用处理app_id，否则需要处理
        if let iosPath = parameters[H5App.H5iOSPathKey] {
            newH5URL = updateUrlPath(url: h5URL, path: iosPath)
            parameters[H5App.H5iOSPathKey] = nil
            parameters[H5App.H5PathKey] = nil
            routerContext["lk_web_customurl"] = true // 自定义path
        } else if let path = parameters[H5App.H5PathKey] {
            newH5URL = updateUrlPath(url: h5URL, path: path)
            parameters[H5App.H5PathKey] = nil
            routerContext["lk_web_customurl"] = true // 自定义path
        } else {
            //最后使用 mainUrl 兜底
            if let mainUrl = mainUrl {
                newH5URL = updateUrlPath(url: h5URL, path: mainUrl)
            }
            if newH5URL.absoluteString.contains(H5ApplinkHandler.urlParamAppIdKey) {
                parameters[H5ApplinkHandler.urlParamAppIdKey] = nil
            }
        }
        
        if FeatureGatingManager.realTimeManager.featureGatingValue(with: FeatureGatingManager.Key(stringLiteral: "openplatform.web.applink.customfragment")) {// user:global
            if let iosFragment = parameters[H5App.H5iOSFragmentKey] {
                newH5URL = updateUrlFragment(url: newH5URL, fragment: iosFragment)
                parameters[H5App.H5iOSFragmentKey] = nil
                parameters[H5App.H5FragmentKey] = nil
            } else if let fragment = parameters[H5App.H5FragmentKey] {
                newH5URL = updateUrlFragment(url: newH5URL, fragment: fragment)
                parameters[H5App.H5FragmentKey] = nil
            }
        }
        
        // 添加参数生成最终要跳转的URL
        return newH5URL.append(parameters: parameters, forceNew: !disableOverrideParams)
    }
    
    private func offlienTargetURLWithMainUrl(h5URL: URL, mainUrl: String?) -> URL {
        if FeatureGatingManager.realTimeManager.featureGatingValue(with: FeatureGatingManager.Key(stringLiteral: "openplatform.web.applink.offline.target.url.disable")) {
            // 禁用新版targeturl后走之前的逻辑
            return targetURLWithMainUrl(h5URL: h5URL, mainUrl: mainUrl)
        }
        var newH5URL: URL = h5URL
        // 优先使用iosPath进行替换，其次使用path，替换后去除path/iosPath参数
        // 若有path参数的不用处理app_id，否则需要处理
        if let iosPath = parameters[H5App.H5iOSPathKey] {
            newH5URL = clearQueryAndFragment(url: h5URL)
            newH5URL = updateUrlPath(url: newH5URL, path: iosPath)
            parameters[H5App.H5iOSPathKey] = nil
            parameters[H5App.H5PathKey] = nil
        } else if let path = parameters[H5App.H5PathKey] {
            newH5URL = clearQueryAndFragment(url: h5URL)
            newH5URL = updateUrlPath(url: newH5URL, path: path)
            parameters[H5App.H5PathKey] = nil
        } else {
            //最后使用 mainUrl 兜底
            if let mainUrl = mainUrl {
                newH5URL = updateUrlPath(url: h5URL, path: mainUrl)
            }
            if newH5URL.absoluteString.contains(H5ApplinkHandler.urlParamAppIdKey) {
                parameters[H5ApplinkHandler.urlParamAppIdKey] = nil
            }
        }
        
        if FeatureGatingManager.realTimeManager.featureGatingValue(with: FeatureGatingManager.Key(stringLiteral: "openplatform.web.applink.customfragment")) {
            if let iosFragment = parameters[H5App.H5iOSFragmentKey] {
                newH5URL = updateUrlFragment(url: newH5URL, fragment: iosFragment)
                parameters[H5App.H5iOSFragmentKey] = nil
                parameters[H5App.H5FragmentKey] = nil
            } else if let fragment = parameters[H5App.H5FragmentKey] {
                newH5URL = updateUrlFragment(url: newH5URL, fragment: fragment)
                parameters[H5App.H5FragmentKey] = nil
            }
        }
        
        // 添加参数生成最终要跳转的URL
        return newH5URL.append(parameters: parameters, forceNew: !disableOverrideParams)
    }
    
    private func clearQueryAndFragment(url: URL)-> URL {
        if var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: true) {
            
            urlComponents.queryItems = nil
            urlComponents.fragment = nil
            
            if let url = urlComponents.url {
                return url
            }
        }
        return url
    }

    // 更新URL中的path
    private func updateUrlPath(url: URL, path: String) -> URL {
        if !disableOverrideParams {
            if var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: true) {
                
                // 保持现有的 path 兼容逻辑
                if path.starts(with: "/") {
                    urlComponents.path = path
                } else {
                    urlComponents.path = ("/" + path)
                }
                
                if let url = urlComponents.url {
                    return url
                }
            }
            return url;
        }
        // 下方逻辑丢失了 query 和 fragment，即将废弃
        
        /// 我们使用h5应用的appid换得的scheme、host、port 构造新的url
        guard let scheme = url.scheme, let domain = url.host else {
            H5Applink.logger.error("openH5: url is empty")
            return url
        }
        var newUrl = scheme + "://" + domain
        /// 如果给定的url存在端口号，那么将端口搬移过来
        if let port = url.port {
            newUrl += ":\(port)"
        }
        /// 将原来applink中指定的path，添加到新的url后面
        if path.starts(with: "/") {
            newUrl.append(path)
        } else {
            newUrl += "/" + path
        }
        return newUrl.possibleURL() ?? url
    }
    
    // 更新URL中的fragment
     private func updateUrlFragment(url: URL, fragment: String) -> URL {
         if var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: true) {
             // 保持现有的 path 兼容逻辑
             urlComponents.fragment = fragment
             if let url = urlComponents.url {
                 return url
             }
         }
         return url;
     }

    // 请求获取最新真实URL
    func retriveRealUrl(resolver: UserResolver, complete: @escaping ((String?, String?, String?, String?, Bool, H5OfflineType, Error?) -> Void)) {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
        let APIDowngrade = LarkFeatureGating.shared.getFeatureBoolValue(for: "openplatform.webapp.api.appinfo.downgrade")// user:global
        if OPUserScope.userResolver().fg.dynamicFeatureGatingValue(with: FeatureGatingManager.Key(stringLiteral: "openplatform.webbrowser.networkapi.update.enable")) {
            //V7.9 网页容器接口统一
            let trace = OPTraceService.default().generateTrace()
            WebAppAPINetworkInterface.getH5AppInfo(larkVer: version, appId: appId, downgrade: APIDowngrade, resolver: resolver, trace: trace, completionHandler: complete)
        } else {
            let api = OpenPlatformAPI.GetH5AppInfoAPI(larkVer: version, appId: appId, downgrade: APIDowngrade, resolver: resolver)
            let client = try? resolver.resolve(assert: OpenPlatformHttpClient.self)
            client?.request(api: api)
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { (result) in
                H5Applink.logger.debug("retriveRealUrl success \(result.code ?? -1) \(result.json)")
                //优先判断是否开启离线包能力
                if let resultCode = result.code, resultCode == 0,
                   result.json["data"]["appInfo"] != JSON.null,
                   AppInfo(json: result.json["data"]["appInfo"]).offlineEnable {
                    //开启离线包能力，先走离线包逻辑
                    let inf = AppInfo(json: result.json["data"]["appInfo"])
                    complete(inf.getH5AppUrl(), inf.getName(), inf.getIconKey(), inf.getIconURL(), inf.offlineEnable, inf.h5OfflineType, nil)
                }
                else if let resultCode = result.code, resultCode == 0,
                    result.json["data"]["appInfo"] != JSON.null,
                    let h5AppUrl = AppInfo(json: result.json["data"]["appInfo"]).getH5AppUrl() {
                    /*
                    complete(h5AppUrl, nil)
 */
                    let inf = AppInfo(json: result.json["data"]["appInfo"])
                    complete(h5AppUrl, inf.getName(), inf.getIconKey(), inf.getIconURL(), false, inf.h5OfflineType, nil)
                } else if let resultCode = result.code, resultCode == 0,
                    let guideUrl = result.json["data"]["guideUrl"].string {
                    /*
                    complete(guideUrl, nil)
 */
                    complete(guideUrl, nil, nil, nil, false, H5OfflineType.all, nil)
                } else {
                    let err = NSError(domain: OpenPlatform.errorDomain,
                                      code: result.code ?? OpenPlatform.errorUndefinedCode,
                                      userInfo: [NSLocalizedDescriptionKey: "retriveRealUrl.\(String(describing: result.msg))"])
                    complete(nil, nil, nil, nil, false, H5OfflineType.all, err)
                }
            }, onError: { (error) in
                    H5Applink.logger.error("retriveRealUrl error \(error)")
                    complete(nil, nil, nil, nil, false, H5OfflineType.all, error)
            }).disposed(by: disposeBag)
        }
    }
    
    private func monitorApplinkHandlerSuccess() {
        OPMonitor("applink_handler_success")
            .addCategoryValue("path", self.path)
            .addCategoryValue("app_id", self.appId)
            .addCategoryValue("applink_trace_id", self.appLinkTraceId)
            .flush()
    }
}

public enum H5OfflineType: Int64 {
    case all
    case mobile
    case pc
}

public struct AppInfo {
    private let stopByPlatform: Bool    // 判断是否是平台禁用
    private let botId: String           // H5App的botId
    private let imageUrl: String        // H5App图标的imgURL
    private let mobileH5Url: String     // H5App移动端H5链接
    private let pcMpUrl: String         // H5AppPC端应用URL
    private let description: String     // H5App的描述内容
    private let appId: String           // H5App的appId
    private let name: String            // H5App的名字
    private let mobileMpUrl: String     // H5App移动端应用URL
    let offlineEnable: Bool     // H5App是否启动了离线包能力
    private let iconKey: String
    let h5OfflineType : H5OfflineType // 离线开启端，仅PC，仅Mobile，双端
    init(json: JSON) {
        stopByPlatform = json["stopByPlatform"].boolValue
        botId = json["botId"].stringValue
        imageUrl = json["imageUrl"].stringValue
        mobileH5Url = json["mobileH5Url"].stringValue
        pcMpUrl = json["pcMpUrl"].stringValue
        description = json["description"].stringValue
        name = json["name"].stringValue
        mobileMpUrl = json["mobileMpUrl"].stringValue
        appId = json["appId"].stringValue
        iconKey = json["iconKey"].stringValue
        offlineEnable = json["offlineEnable"].boolValue
        h5OfflineType = H5OfflineType(rawValue: json["h5OfflineType"].int64Value) ?? .all
    }

    // 获取完整H5App对应的URL，需要携带Url
    func getH5AppUrl() -> String? {
        if mobileH5Url.isEmpty {
            return nil
        }
            return mobileH5Url
    }
    func getName() -> String? {
        if name.isEmpty {
            return nil
        }
        return name
    }
    func getIconKey() -> String? {
        if iconKey.isEmpty {
            return nil
        }
        return iconKey
    }
    func getIconURL() -> String? {
        if imageUrl.isEmpty {
            return nil
        }
        return imageUrl
    }
}

extension String {
    func replaceFirst(of p: String, with r: String) -> String {
        if let range = range(of: p) {
            return replacingCharacters(in: range, with: r)
        } else {
            return self
        }
    }
}
