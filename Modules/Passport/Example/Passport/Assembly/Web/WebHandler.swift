//
//  LarkWeb+Component.swift
//  Lark
//
//  Created by K3 on 2018/5/17.
//  Copyright © 2018年 Bytedance.Inc. All rights reserved.
//
// swiftlint:disable all
import Homeric
import LKCommonsTracker
import RxCocoa
import RxSwift
import Swinject
import EENavigator
import LKCommonsLogging
import LarkTab
import LarkOPInterface
import LarkWebViewController
import CookieManager
import LarkAccountInterface
import LarkFeatureGating
import SuiteAppConfig
//未修改任何逻辑，只是移动了代码
class WebHandler: TypedRouterHandler<WebBody>, RouterHandler {
    private let resolver: Resolver
    static let log = Logger.log(WebHandler.self, category: "WebHandler")
    private let queryKey = "key"

    lazy var safeLinkEnable = LarkFeatureGating.shared.getFeatureBoolValue(for: "safe_link")

    init(resolver: Resolver) {
        self.resolver = resolver
        super.init()
    }

    //TODO 需要适配
    override func handle(_ body: WebBody, req: EENavigator.Request, res: Response) {
        Self.log.info("WebHandler recieve handle, body.url: \(body.url)")
        let vc = buildController(with: body, req: req, appID: nil)
        res.end(resource: vc)
    }
    func handle(req: EENavigator.Request, res: EENavigator.Response) {
        //  code from lizhong.limboy@bytedance.com
        if req.url.absoluteString.hasPrefix(Tab.webAppPrefix) {
            // tab h5 应用
            if let appIDKey = getQueryByKey(url: req.url, key: queryKey),
               let tab = Tab.getTab(appType: AppType.webapp, key: appIDKey),
               let url = URL(string: tab.mobileUrl ?? "") {
                let vc = buildController(with: WebBody(url: url), req: req, appID: tab.appid)
                vc.webappTab = tab
                res.end(resource: vc)
                WebHandler.log.info("Web: open tab successful, url: \(req.url), appid: \(tab.appid)")
            } else {
                WebHandler.log.error("Web: get tab webApp error, url: \(req.url)")
                res.end(resource: nil)
            }
        } else {
            //  非tab网页
            let vc = buildController(with: WebBody(url: req.url), req: req, appID: nil)
            res.end(resource: vc)
            WebHandler.log.info("Web: open web successful, from handle req: EENavigator.Request, url: \(req.url)")
        }
    }
    private func buildController(with body: WebBody, req: EENavigator.Request, appID: String?) -> WebBrowser {
        let url = body.url
        //  未修改任何逻辑，只是把方法实现转移到了这里
        CookieManager.shared.plantCookie(
            token: AccountServiceAdapter.shared.currentAccessToken
        )

        var originRefererURL: URL?
        if let from = req.context["from"] as? String, let fromURL = URL(string: from) {
            if let scheme = fromURL.scheme?.lowercased(), ["http", "https"].contains(scheme) {
                originRefererURL = fromURL
            }
        }
        let webBrowserID = req.context[webBrowserIDKey] as? String ?? UUID().uuidString
        let webViewConfig = WebBrowserConfiguration(
            customUserAgent: body.customUserAgent,              //  未修改逻辑
            allowShareToChat: body.allowShareToChat ?? true,    //  未修改逻辑
            showMore: !body.hideShowMore,
            customParams: req.parameters,
            /// 精简模式下sso为false，shouldNonPersistent应传true，需取反
            //未改动逻辑
            shouldNonPersistent: false,
            originRefererURL: originRefererURL,
            webBrowserID: webBrowserID
        )

        let controller = WebBrowserFactory.createWebVC(url: url, config: webViewConfig)

        WebBrowserFactory.configOpenURL(for: controller)

        return controller
    }
    private func getQueryByKey(url: URL, key: String) -> String? {
        if let urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false),
           let queryItems = urlComponents.queryItems {
            return queryItems.first { $0.name == key }?.value
        }
        return nil
    }
}

class UnloginWebHandler: TypedRouterHandler<UnloginWebBody> {
    private let resolver: Resolver

    init(resolver: Resolver) {
        self.resolver = resolver
        super.init()
    }

    override func handle(_ body: UnloginWebBody, req: EENavigator.Request, res: Response) {
        /// some config default vaule follows the init func default vaule
        let config = WebBrowserConfiguration(
            customUserAgent: body.customUserAgent,
            isInjectIgnorePageReady: body.isInjectIgnorePageReady,
            showMore: body.showMore,
            showLoadingFirstLoad: body.showLoadingFirstLoad,
            //未改动逻辑
            shouldNonPersistent: false,
            jsApiMethodScope: body.jsApiMethodScope,
            webBizType: body.webBizType
        )
        let controller = WebBrowserFactory.createWebVC(
            url: body.url,
            config: config
        )
        res.end(resource: controller)
    }
}

class SimpleWebHandler: TypedRouterHandler<SimpleWebBody> {
    override func handle(_ body: SimpleWebBody, req: EENavigator.Request, res: Response) {
        let unloginBody = UnloginWebBody(
            url: body.url,
            jsApiMethodScope: .none,
            showMore: body.showMore,
            isInjectIgnorePageReady: body.isInjectIgnorePageReady,
            showLoadingFirstLoad: body.showLoadingFirstLoad,
            customUserAgent: body.customUserAgent
        )
        res.redirect(body: unloginBody)
    }
}
// swiftlint:enable all
