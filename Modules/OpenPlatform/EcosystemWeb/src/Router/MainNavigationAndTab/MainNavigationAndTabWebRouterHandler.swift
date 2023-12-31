//
//  MainNavigationAndTabWebRouterHandler.swift
//  EcosystemWeb
//
//  Created by 新竹路车神 on 2021/6/25.
//

import ECOProbe
import EENavigator
import LarkSetting
import LarkTab
import LarkUIKit
import LKCommonsLogging
import WebBrowser
import LarkNavigator
import LarkContainer

final class MainNavigationAndTabWebRouterHandler: UserRouterHandler {
    // 全局缓存当前最新的webapp的tab标题，用作创建网页主导航时显示在主导航顶部的文案,因为目前主端的tab再更新标题的时候仅更新了UI上的标题，网页主导航自己持有的tab是旧的，所以通过缓存的方式持有最新的标题。
    static var newestTabTitleMap : [String:String] = [:]
    
    static let logger = Logger.ecosystemWebLog(MainNavigationAndTabWebRouterHandler.self, category: "MainNavigationAndTabWebRouterHandler")
    private let queryKey = "key"
    func handle(req: EENavigator.Request, res: EENavigator.Response) {
        guard req.url.absoluteString.hasPrefix(Tab.webAppPrefix) else {
            res.end(resource: nil)
            Self.logger.error("MainNavigationAndTab open web failed, url:\(req.url) has no webApp prefix")
            return
        }
        guard let appIDKey = getQueryByKey(url: req.url, key: queryKey) else {
            res.end(resource: nil)
            Self.logger.error("MainNavigationAndTab open web failed, url:\(req.url) get no appid key")
            return
        }
        guard let tab = Tab.getTab(appType: AppType.webapp, key: appIDKey) ?? Tab.getTab(appType: AppType.appTypeOpenApp, key: appIDKey)  else {
            res.end(resource: nil)
            Self.logger.error("MainNavigationAndTab open web failed, get no tab from Tab.getTab appIDKey:\(appIDKey)")
            return
        }
        guard let appID = tab.appid, !appID.isEmpty else {
            Self.logger.error("MainNavigationAndTab open web failed, appid is nil or empty string \(tab.appid)")
            res.end(resource: nil)
            return
        }
        let trace = OPTraceService.default().generateTrace()
        Self.logger.info("MainNavigationAndTab open web, traceId is \(trace.traceId ?? "")")
        OPMonitor(WebContainerMonitorEvent.containerStartHandle)
            .setWebAppID(appID)
            .setWebBizType(.larkWeb)
            .setWebBrowserScene(WebBrowserScene.mainTab)
            .tracing(trace)
            .flush()
        // 通知需要保证登录（某些场景下默认的主动登录任务会延迟数秒才会执行，可能晚于用户操作） code from 主导航小程序
        let startHandleTime = Date().timeIntervalSince1970
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "OpenAppEngine.shared.notifyLoginIfNeeded"), object: nil)
        var vc: UIViewController
        // 主导航标题,判断缓存里是否有最新的标题，如果没有，就使用tabname
        var webappNaviTitle = tab.tabName
        if let appid = tab.appid, let newestTabTitle = Self.newestTabTitleMap[appid], !newestTabTitle.isEmpty {
            webappNaviTitle = newestTabTitle
            print("使用缓存最新的标题:\(newestTabTitle)")
        }
        if FeatureGatingManager.realTimeManager.featureGatingValue(with: FeatureGatingManager.Key(stringLiteral: "openplatform.offline.wkurlschemehandler")) {// user:global
            vc = MainNavigationAndTabWebBrowser(
                appID: appID,
                tab: tab,
                webappNaviTitle: webappNaviTitle,
                initTrace: trace,
                startHandleTime: startHandleTime,
                resolver: self.userResolver
            )
        } else {
            //  URLProtocol删除后删掉这里
            vc = OldMainNavigationAndTabWebBrowser(
                appID: appID,
                tab: tab,
                webappNaviTitle: webappNaviTitle,
                initTrace: trace,
                startHandleTime: startHandleTime,
                resolver: self.userResolver
            )
        }
        Self.logger.info("MainNavigationAndTab open web successful, from handle req: EENavigator.Request, url: \(req.url)")
        if Display.pad {
            //  主导航模式，打开新窗口要求保留左侧主导航条
            let nav = LkNavigationController(rootViewController: vc)
            res.end(resource: nav)
        } else {
            res.end(resource: vc)
        }
    }
    private func getQueryByKey(url: URL, key: String) -> String? {
        if let urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false),
           let queryItems = urlComponents.queryItems {
            return queryItems.first { $0.name == key }?.value
        }
        return nil
    }
}
