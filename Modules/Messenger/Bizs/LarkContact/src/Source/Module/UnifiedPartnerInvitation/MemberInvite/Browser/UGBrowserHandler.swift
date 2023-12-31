//
//  UGBrowserHandler.swift
//  LarkContact
//
//  Created by aslan on 2021/12/22.
//

import Foundation
import WebKit
import WebBrowser
import EENavigator
import Swinject
import LKCommonsLogging
import AppContainer
import LarkOpenAPIModel
import LarkOpenPluginManager
import LarkWebViewContainer
import ECOProbe
import LarkNavigator
import LarkContainer
// swiftlint:disable all

final class UGBrowserHandler: UserTypedRouterHandler {
    private var fallback: LoadFailFallback?

    static let logger = Logger.log(UGBrowserHandler.self, category: "LarkContact.UGBrowserHandler")

    func handle(_ body: UGBrowserBody, req: EENavigator.Request, res: Response) throws {
        self.fallback = body.fallback
        let configuration = WebBrowserConfiguration(webBizType: .ug)
        let browser = WebBrowser(url: body.url, configuration: configuration)
        do {
            try? browser.register(item: NavigationBarStyleExtensionItem())
            try? browser.register(item: UGWebBrowserLoadItem(fallback: self.fallback))
            try? browser.register(item: UniteRouterExtensionItem())
            try? browser.register(item: ProgressViewExtensionItem())
            try? browser.register(item: ErrorPageExtensionItem())
            let it = UGSingleExtensionItem(browser: browser, stepInfo: body.stepInfo)
            try? browser.register(singleItem: it)
        } catch {
            Self.logger.info("browser register item failed.")
        }
        res.end(resource: browser)
    }
}

final class UGWebBrowserLoadItem: WebBrowserExtensionItemProtocol {

    public var fallback: LoadFailFallback?
    public var navigationDelegate: WebBrowserNavigationProtocol?
    public var lifecycleDelegate: WebBrowserLifeCycleProtocol?

    init(fallback: LoadFailFallback?) {
        self.fallback = fallback
        self.navigationDelegate = UGWebBrowserLoadNavigation(fallback: fallback)
        self.lifecycleDelegate = UGWebBrowserLifeCycle()
    }
}

final class UGWebBrowserLifeCycle: WebBrowserLifeCycleProtocol {
    public func viewDidAppear(browser: WebBrowser, animated: Bool) {
        // 延迟一段时间，防止执行过早被覆盖
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            browser.naviPopGestureRecognizerEnabled = false
        }
    }
}

final class UGWebBrowserLoadNavigation: WebBrowserNavigationProtocol {

    public var fallback: LoadFailFallback?

    init(fallback: LoadFailFallback?) {
        self.fallback = fallback
    }

    static let logger = Logger.log(UGWebBrowserLoadNavigation.self, category: "LarkContact.UGWebBrowserLoadNavigation")

    public func browser(_ browser: WebBrowser, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        if WKNavigationDelegateFailFix.isFatalWebError(error: error) {
            Self.logger.info("browser load occur fatal error: \(error.localizedDescription)")
            self.loadFailedFallback()
        }
    }

    public func browser(_ browser: WebBrowser, didFail navigation: WKNavigation!, withError error: Error) {
        if WKNavigationDelegateFailFix.isFatalWebError(error: error) {
            Self.logger.info("browser load occur fatal error: \(error.localizedDescription)")
            self.loadFailedFallback()
        }
    }

    func loadFailedFallback() {
        if let failedFallback = self.fallback {
            failedFallback()
        }
    }
}

final class UGSingleExtensionItem: WebBrowserExtensionSingleItemProtocol {
    weak var browser: WebBrowser?
    private var stepInfo: [String: Any]?

    public init(browser: WebBrowser?, stepInfo: [String: Any]?) {
        self.browser = browser
        self.stepInfo = stepInfo
    }

    public lazy var callAPIDelegate: WebBrowserCallAPIProtocol? = {
        let api = UGCallAPI(item: self, browser: browser, stepInfo: stepInfo)
        return api
    }()
}

final class UGCallAPI: WebBrowserCallAPIProtocol {
    weak var browser: WebBrowser?
    private var stepInfo: [String: Any]?
    private var pluginManager: OpenPluginManager?

    static let logger = Logger.log(UGCallAPI.self, category: "LarkContact.UGCallAPI")

    private weak var item: UGSingleExtensionItem?
    init(item: UGSingleExtensionItem, browser: WebBrowser?, stepInfo: [String: Any]?) {
        self.item = item
        self.browser = browser
        self.stepInfo = stepInfo
        let configPath = BundleConfig.LarkContactBundle.path(forResource: "UGBrowserOpenAPI", ofType: "plist")
        self.pluginManager = OpenPluginManager(defaultPluginConfig: configPath, bizDomain: .messenger, bizType: .all, bizScene: "ug")
    }

    public func recieveAPICall(webBrowser: WebBrowser, message: APIMessage, callback: APICallbackProtocol) {
        Self.logger.info("recieve api call: \(message.apiName), data: \(message.data)")
        var additionalInfo: [String: Any] = [:]
        if let stepInfo = self.stepInfo {
            additionalInfo["stepInfo"] = stepInfo
        }
        if let browser = self.browser {
            additionalInfo["controller"] = browser
        }
        additionalInfo["params"] = message.data
        let context = OpenAPIContext(trace: OPTrace(traceId: message.apiName),
                                     dispatcher: pluginManager,
                                     additionalInfo: additionalInfo)
        self.pluginManager?.asyncCall(apiName: message.apiName, params: message.data, canUseInternalAPI: false, context: context, callback: { res in
            switch res {
            case .success(let data):
                if let params = data?.toJSONDict() as? [String: Any] {
                    callback.callbackSuccess(param: params)
                }
            case .failure(let error):
                callback.callbackFailure(param: [:])
            case .continue(event: let event, data: let data):
                callback.callbackContinued()
            @unknown default:
                callback.callbackCancel()
            }
        })
    }
}

// swiftlint:enable all
