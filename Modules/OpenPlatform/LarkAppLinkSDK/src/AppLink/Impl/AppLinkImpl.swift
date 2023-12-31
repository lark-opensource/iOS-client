//
//  AppLinkImpl.swift
//  LarkAppLinkSDK
//
//  Created by yinyuan on 2021/3/30.
//

import Foundation
import EENavigator
import Swinject
import RxSwift
import LKCommonsLogging
import LKCommonsTracker
import LarkFoundation
import SwiftyJSON
import LarkFeatureGating
import ECOProbe
import SwiftProtobuf
import UniverseDesignToast
import LarkAccountInterface
import LarkSetting
import LarkLocalizations
import LarkContainer

private let logger = Logger.oplog(AppLinkImpl.self, category: "AppLink")

enum AppLinkDowngradeType: String {
    case noInWhiteList
    case versionUnavailable
    case noHandler
}

var applinkHandlers: [String: AppLinkHandler] = [:]

public func registerHandler(path: String, handler: @escaping AppLinkHandler) {
    logger.info("AppLink register path:\(path)")
    applinkHandlers[path] = handler
}

// swiftlint:disable identifier_name
/// 新版本的 支持动态化的 AppLink 实现，灰度通过后将会全量替换掉 AppLinkSDK
public final class AppLinkImpl: AppLinkService {
    
    @LazyRawSetting(key: .make(userKeyLiteral: "open_app_link_config_v3"))
    private var appLinkConfigV3Dic: [String: Any]?

    public static let applink_ex = "applink_ex"
    private let resolver: UserResolver
        
    /// AppLink 解析器
    private let appLinkParser: AppLinkParser

    init(resolver: UserResolver) {
        self.resolver = resolver
        self.appLinkParser = AppLinkParser(resolver: resolver)
    }
    
    /// 即将删除的代码
    public func open(url: URL, from: AppLinkFrom, callback: @escaping AppLinkOpenCallback) {
        open(url: url, from: from, fromControler: nil, callback: callback)
    }

    //Applink路由协议方法实现，先走短链逻辑，如果不是锻炼，走正常applink逻辑
    public func open(url: URL, from: AppLinkFrom, fromControler: UIViewController?, callback: @escaping AppLinkOpenCallback) {
        logger.info("AppLink assemble applink")
        let appLink = AppLink(url: url, from: from, fromControler: fromControler)
        open(appLink: appLink, callback: callback)
    }

    //Applink路由协议方法实现，先走短链逻辑，如果不是锻炼，走正常applink逻辑
    public func open(appLink: AppLink, callback: @escaping AppLinkOpenCallback) {
        logger.info("AppLink open applink: \(appLink.url.applinkEncyptString()), from: \(appLink.from.rawValue)")
        var changedAppLink = appLink
        changedAppLink.traceId = OPTraceService.default().generateTrace().traceId
        if appLinkParser.isShortApplink(url: changedAppLink.url) {
            logger.info("AppLink will parser short applink")
            appLinkParser.parseShortLink(appLink: changedAppLink) { (parsedAppLink) in
                // 旧逻辑未 weak，暂时保持此逻辑
                self.internalOpen(appLink: parsedAppLink, shortLink: changedAppLink, callback: callback)
            }
            return
        }
        internalOpen(appLink: changedAppLink, shortLink: nil, callback: callback)
    }
    
    // AppLink URL格式检查
    public func isAppLink(_ url: URL) -> Bool {
        logger.info("AppLink check isapplink: \(url.applinkEncyptString())")
        return appLinkParser.isAppLinkSync(url: url)
    }
}

extension AppLinkImpl {
    //正常的AppLink处理逻辑
    private func internalOpen(appLink: AppLink, shortLink: AppLink?, callback: @escaping AppLinkOpenCallback) {
        logger.info("AppLink internalOpen applink: \(appLink.url.applinkEncyptString())")
        appLinkParser.checkURLSupportedAsync(url: appLink.url) { [weak self] (isSupportedAppLink) in
            guard let `self` = self else {
                logger.warn("self is nil")
                callback(false)
                return
            }
            logger.info("AppLink check applink async result:\(isSupportedAppLink)")
            self.handleCheckAppLinkResult(isValidAppLink: isSupportedAppLink,
                                          appLink: appLink,
                                          shortLink: shortLink,
                                          callback: callback)
        }
    }
    
    /// 处理检查applink是否合法的返回
    private func handleCheckAppLinkResult(isValidAppLink: Bool, appLink: AppLink, shortLink: AppLink?, callback: @escaping AppLinkOpenCallback) {
        var monitorEventParams: [String: Any] = [
            "scheme": appLink.url.scheme ?? "",
            "host": appLink.url.host ?? "",
            "path": appLink.url.path,
            "from": appLink.from.rawValue,
            "appId": appLink.url.queryParameters["appId"] ?? "",
            "op_tracking": appLink.url.queryParameters["op_tracking"] ?? ""
        ]
        monitorEventParams["path"] = shortLink?.url.path ?? appLink.url.path
        monitorEventParams["long_path"] = (shortLink != nil && shortLink?.url.path != appLink.url.path) ? appLink.url.path : nil
        
        //检查是否通过身份校验
        guard appLinkParser.checkCurrentUserAvailable(appLink) else {
            logger.info("AppLink handle check currentUser is false")
            if let window = appLink.context?.from()?.fromViewController?.view.window ?? Navigator.shared.mainSceneWindow {
                logger.error("AppLink handle check currentUser taost show")
                var text = BundleI18n.LarkAppLinkSDK.OpenPlatform_AppLink_Check_UserID_FeatureToast()
                UDToast.showFailure(with: text, on: window)
            }
            callback(false)
            return
        }

        /// 检查是否是applink
        guard isValidAppLink else {
            // 统计A ppLink不在白名单的调用次数
            logger.error("AppLink handle check isValidAppLink is false")
            OPMonitor(AppLinkMonitorCode.pathNotSupport).setAppLink(appLink).flush();
            let result = self.downgrade(appLink, shortLink: shortLink, downgradeType: .noInWhiteList, monitorEventParams: monitorEventParams)
            callback(result)
            return
        }
        // 兼容版本检查
        guard appLinkParser.checkVersionAvailable(appLink) else {
            logger.error("AppLink handle check version available is false")
            // 不满足版本要求的调用次数
            OPMonitor(AppLinkMonitorCode.versionNotSupport).setAppLink(appLink).flush();
            let result = self.downgrade(appLink, shortLink: shortLink, downgradeType: .versionUnavailable, monitorEventParams: monitorEventParams)
            callback(result)
            return
        }
        var convertersApplink = appLink
        //判断是不是新的applink
        if appLinkParser.isV3AppLinkSync(url: appLink.url) {
            guard var urlComponents = URLComponents(url: appLink.url, resolvingAgainstBaseURL: false) else {
                logger.warn("AppLink invalid url:urlConponents nil")
                OPMonitor(AppLinkMonitorCode.invalidApplink).setAppLink(appLink).flush()
                return
            }
            let originPathArr: [String: [String: String]] = self.appLinkConfigV3Dic?["converters"] as? [String: [String: String]] ?? [:]
            var pathArr: [String: [String: String]] = [:]
            for path in originPathArr {
                pathArr[path.key.applink_trimed_path()] = path.value
            }
            guard let converters = pathArr[appLinkParser.firstPathComponent(url: appLink.url)] else {
                logger.warn("AppLink converters path is nil")
                return
            }
            if let targetQueryKey = converters["targetQueryKey"] {
                var queryItems: [URLQueryItem] = []
                if let originqueryItems = urlComponents.queryItems {
                    queryItems = originqueryItems
                }
                queryItems.append(URLQueryItem(name: targetQueryKey, value: appLink.url.lastPathComponent))
                urlComponents.queryItems = queryItems
            }
            if let path = converters["targetPath"] {
                urlComponents.path = path
            }
            if let url = urlComponents.url {
                convertersApplink.url = url
            }
        }
        let path = convertersApplink.url.path
        if let handler = applinkHandlers.first(where: { (_path, handler) -> Bool in
            _path.applink_trimed_path() == path.applink_trimed_path()
        })?.value {
            OPMonitor("applink_start_handle").setAppLink(convertersApplink).flush()
            handler(convertersApplink)
            logger.info("AppLink invoke handler \(convertersApplink.url.applinkEncyptString())")
            // 统计AppLink在白名单的调用次数
            let duration = Int((Date().timeIntervalSince1970 - (shortLink?.timestamp ?? convertersApplink.timestamp)) * 1000)
            monitorEventParams["duration"] = duration
            Tracker.post(TeaEvent("applink_click", params: monitorEventParams))
            callback(true)
            return
        } else {
            // 没有注册处理
            OPMonitor(AppLinkMonitorCode.noHandler).setAppLink(convertersApplink).flush()
            let result = self.downgrade(convertersApplink, shortLink: shortLink, downgradeType: .noHandler, monitorEventParams: monitorEventParams)
            callback(result)
            return
        }
    }

    /// 降级处理，打开兼容页面
    private func downgrade(_ appLink: AppLink, shortLink: AppLink?, downgradeType: AppLinkDowngradeType, monitorEventParams: [String: Any]) -> Bool {
        logger.info("AppLink downgrade type: \(downgradeType)")
        var monitorEventParams = monitorEventParams
        monitorEventParams["type"] = downgradeType.rawValue
        let duration = Int((Date().timeIntervalSince1970 - (shortLink?.timestamp ?? appLink.timestamp)) * 1000)
        monitorEventParams["duration"] = duration
        Tracker.post(TeaEvent("applink_invalid_click", params: monitorEventParams))
        guard let from = appLink.context?.from() ?? Navigator.shared.mainSceneWindow else {
            logger.warn("AppLink downgrade from scene is null")
            OPMonitor(AppLinkMonitorCode.from_scene_is_null).setAppLink(appLink).flush();
            return false
        }
        if appLink.url.host == unifiedDomain {
            // 这种情况下的降级逻辑，只用 Toast 即可
            if let window = from.fromViewController?.view.window ?? Navigator.shared.mainSceneWindow {
                logger.info("AppLink downgrade show toast")
                let text = BundleI18n.LarkAppLinkSDK.OpenPlatform_AppLink_NullFeatureToast
                UDToast.showFailure(with: text, on: window)
            }
            logger.info("AppLink downgrade return true")
            return true
        }
        guard var urlConponents = URLComponents(url: appLink.url, resolvingAgainstBaseURL: false) else {
            logger.warn("AppLink downgrade invalid url:urlConponents nil")
            OPMonitor(AppLinkMonitorCode.invalidApplink).setAppLink(appLink).flush();
            return false
        }
        urlConponents.scheme = "https"
        guard var url = urlConponents.url else {
            logger.warn("AppLink invalid url:url nil")
            OPMonitor(AppLinkMonitorCode.invalidApplink).setAppLink(appLink).flush();
            return false
        }
        let applink_ex: JSON = ["lk_ver": LarkFoundation.Utils.appVersion,
                                "from_pf": "iOS"]
        url = url.append(name: AppLinkParser.applink_ex, value: applink_ex.rawString(options: .sortedKeys) ?? "")
        // 使用网页打开
        resolver.navigator.push(url, from: from)
        logger.info("AppLink downgrade return true,push url:\(url.applinkEncyptString())")
        return true
    }
}

// swiftlint:enable identifier_name
