//
//  UGBrowserHandler.swift
//  LarkContact
//
//  Created by aslan on 2021/12/22.
//

import UIKit
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
import LarkUIKit
import LKCommonsTracker
import Homeric
import UniverseDesignProgressView
import LarkNavigator
import LarkContainer
import LarkAccountInterface
import OfflineResourceManager
import BDWebKit
import IESGeckoKit
// swiftlint:disable all

fileprivate enum FallbackType: String {
    case loadError = "network_err"
    case timeout = "timeout"
}

final class UGOverseaBrowserHandler: UserTypedRouterHandler {

    @Provider var UGService: AccountServiceUG

    private var fallback: UGOverseaLoadFailFallback?

    static let logger = Logger.log(UGBrowserHandler.self, category: "LarkContact.UGOverseaBrowserHandler")

    func handle(_ body: UGOverseaBrowserBody, req: EENavigator.Request, res: Response) throws {
        self.fallback = body.fallback
        let configuration = WebBrowserConfiguration(webBizType: .ug)
        let passportOfflineConfig = UGService.passportOfflineConfig()
        let enableOffline = UGService.enableLarkGlobalOffline()
        if #available(iOS 12.0, *), enableOffline, passportOfflineConfig.offlineConfig.count > 0 {
            configuration.webviewConfiguration.bdw_installURLSchemeHandler()
        }
        let browser = WebBrowser(url: body.url, configuration: configuration)
        do {
            try? browser.register(item: NavigationBarStyleExtensionItem())
            try? browser.register(item: UGOverseaWebBrowserLoadItem(fallback: self.fallback))
            try? browser.register(item: UniteRouterExtensionItem())
            let it = UGOverseaSingleExtensionItem(browser: browser, userResolver: self.userResolver, stepInfo: body.stepInfo)
            try? browser.register(singleItem: it)
            if #available(iOS 12.0, *), enableOffline, passportOfflineConfig.offlineConfig.count > 0 {
                let customInterceptor = PassportFalconInterceptor()
                let offlineConfigs = passportOfflineConfig.offlineConfig
                offlineConfigs.forEach { config in
                    let accesskey = config.accessKey
                    let pattterns = config.prefixes
                    pattterns.forEach { pattern in
                        customInterceptor.register(pattern: pattern, for: accesskey)
                    }
                }
                browser.webview.bdw_registerSchemeHandlerClass(BDWebFalconURLSchemaHandler.self)
                browser.webview.bdw_register(customInterceptor)
            }
        } catch {
            Self.logger.info("browser register item failed.")
        }
        res.end(resource: browser)
    }
}

final class UGOverseaWebBrowserLoadItem: WebBrowserExtensionItemProtocol {

    public var fallback: UGOverseaLoadFailFallback?

    fileprivate var timeoutTimer: Timer?

    private var beginning: CFAbsoluteTime?

    static let logger = Logger.log(UGBrowserHandler.self, category: "LarkContact.UGOverseaProgressViewExtensionItem")
    public lazy var lifecycleDelegate: WebBrowserLifeCycleProtocol? = UGOverseaBrowserLoadLifeCycle(item: self)
    public lazy var navigationDelegate: WebBrowserNavigationProtocol? = UGOverseaBrowserLoadNavigation(item: self)
    public init() {}

    //首屏加载loadingView
    fileprivate var firstSceenLoadingView: LoadingPlaceholderView?
    //进度条
    fileprivate let progressView = UDProgressView()

    @Provider var ugService: AccountServiceUG //Global

    fileprivate func setupFirstScreenLoading(browser: WebBrowser) {
        let loadingView = LoadingPlaceholderView()
        browser.view.addSubview(loadingView)
        loadingView.snp.makeConstraints { make in
            make.left.right.top.bottom.equalToSuperview()
        }
        loadingView.animationView.play()
        firstSceenLoadingView = loadingView
    }

    fileprivate func setupProgressView(browser: WebBrowser) {
        browser.view?.addSubview(progressView)
        progressView.snp.makeConstraints { make in
            make.left.right.top.equalToSuperview()
        }
        observeEstimatedProgress(browser: browser)
    }

    fileprivate func setupTimeoutTimer(browser: WebBrowser) {
        beginning = CFAbsoluteTimeGetCurrent()
        timeoutTimer = Timer.op_scheduledTimer(withInterval: TimeInterval(ugService.globalRegistTimeoutNum()), target: self, block: { [weak self] _ in
            Self.logger.info("ug oversea webView load timeout fallback to passport flow")
            self?.handleFallbackAction(browser: browser, type: .timeout)
            browser.webview.stopLoading()
        })
    }


    private var estimatedProgressObservation: NSKeyValueObservation?
    private func observeEstimatedProgress(browser: WebBrowser) {
        estimatedProgressObservation = browser
            .webview
            .observe(
                \.estimatedProgress,
                options: [.old, .new]
            ) { [weak self] (webView, change) in
                guard let self = self, let progress = change.newValue else { return }
                Self.logger.info("estimated progress changed from \(change.oldValue) to \(progress)")
                self.changeProgressView(with: CGFloat(progress))
            }
    }
    func changeProgressView(with value: CGFloat) {
        progressView.setProgress(value, animated: false)
        if value > 0 && value < 1 {
            if progressView.isHidden {
                progressView.isHidden = false
            }
            return
        }
        //  如果是0（刚开始加载）则需要展示出来 1（加载完毕）则需要隐藏
        let hidden = value >= 1
        progressView.isHidden = hidden
    }
    //处理加载完成；成功，失败会都执行
    func handleFinishLoad(succ: Bool) {
        firstSceenLoadingView?.animationView.stop()
        if succ { firstSceenLoadingView?.removeFromSuperview() }
        firstSceenLoadingView = nil

        if let beginning = beginning, timeoutTimer != nil {
            let duration = Int(1000 * (CFAbsoluteTimeGetCurrent() - beginning))
            let enableOffline = ugService.enableLarkGlobalOffline()
            Self.logger.info("lark global finish duration: \(duration), offline enable: \(enableOffline)")
            ugService.finishGlobalRegistProbe(enableOffline: enableOffline, duration: duration)
        }

        timeoutTimer?.invalidate()
        timeoutTimer = nil
    }

    fileprivate func handleFallbackAction(browser: WebBrowser, type: FallbackType) {
        if let failedFallback = self.fallback {
            browser.closeWith(animated: false)
            // 为了兼容passport的逻辑，此处需要延迟0.5s；场景：push到webview时马上触发failCallback，有页面堆栈的兼容性问题
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                failedFallback(type.rawValue)
            }
            self.fallback = nil //置空，避免被执行2次
            //埋点
            Tracker.post(TeaEvent(Homeric.UG_OVERSEA_FALLBACK_SERVER, params: ["fallback_type": type.rawValue, "os": "iOS"]))
        }
    }

    init(fallback: UGOverseaLoadFailFallback?) {
        self.fallback = fallback
    }
}


final class UGOverseaSingleExtensionItem: WebBrowserExtensionSingleItemProtocol {
    weak var browser: WebBrowser?
    private var userResolver: UserResolver
    private var stepInfo: [String: Any]?

    public init(browser: WebBrowser?, userResolver: UserResolver, stepInfo: [String: Any]?) {
        self.browser = browser
        self.userResolver = userResolver
        self.stepInfo = stepInfo
    }

    public lazy var callAPIDelegate: WebBrowserCallAPIProtocol? = {
        let api = UGOverseaCallAPI(item: self, browser: browser, userResolver: userResolver, stepInfo: stepInfo)
        return api
    }()
}

final class UGOverseaCallAPI: WebBrowserCallAPIProtocol, UserResolverWrapper {
    weak var browser: WebBrowser?
    let userResolver: UserResolver
    private var stepInfo: [String: Any]?
    private var pluginManager: OpenPluginManager?
    @ScopedInjectedLazy(name: "PassportCallAPI") private var passportCallAPIDependency: ExternalCallAPIDependencyProtocol?
    private var passportCallAPI: WebBrowserCallAPIProtocol?

    static let logger = Logger.log(UGCallAPI.self, category: "LarkContact.UGCallAPI")

    private weak var item: UGOverseaSingleExtensionItem?
    init(item: UGOverseaSingleExtensionItem, browser: WebBrowser?, userResolver: UserResolver, stepInfo: [String: Any]?) {
        self.item = item
        self.browser = browser
        self.userResolver = userResolver
        self.stepInfo = stepInfo
        let configPath = BundleConfig.LarkContactBundle.path(forResource: "UGOverseaBrowserOpenAPI", ofType: "plist")
        self.pluginManager = OpenPluginManager(defaultPluginConfig: configPath, bizDomain: .messenger, bizType: .all, bizScene: "ug")

        // 获取PassportAPI
        if let dependency = self.passportCallAPIDependency, let browser = self.browser {
            self.passportCallAPI = self.passportCallAPIDependency?.getCallAPI(webBrowser: browser)
        }
    }

    public func recieveAPICall(webBrowser: WebBrowser, message: APIMessage, callback: APICallbackProtocol) {
        Self.logger.info("recieve api call: \(message.apiName)")
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

        if let dependency = self.passportCallAPIDependency, dependency.supportHandlerList.contains(message.apiName) {
            //Passport API
            self.passportCallAPI?.recieveAPICall(webBrowser: webBrowser, message: message, callback: callback)
        } else {
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
}


final public class UGOverseaBrowserLoadLifeCycle: WebBrowserLifeCycleProtocol {
    private weak var item: UGOverseaWebBrowserLoadItem?
    init(item: UGOverseaWebBrowserLoadItem) {
        self.item = item
    }
    public func viewDidLoad(browser: WebBrowser) {
        item?.setupProgressView(browser: browser)
        item?.setupFirstScreenLoading(browser: browser)
        item?.setupTimeoutTimer(browser: browser)
    }
}

final public class UGOverseaBrowserLoadNavigation: WebBrowserNavigationProtocol {
    static let logger = Logger.log(UGWebBrowserLoadNavigation.self, category: "LarkContact.UGOverseaBrowserLoadNavigationDelegate")
    private weak var item: UGOverseaWebBrowserLoadItem?
    init(item: UGOverseaWebBrowserLoadItem) {
        self.item = item
    }

    public func browser(_ browser: WebBrowser, didFinish navigation: WKNavigation!) {
        item?.handleFinishLoad(succ: true)
        //上报耗时埋点
        browser.webview.fetchPerformanceTimingData { timing in
            guard let timing = timing else { return }
            let duration = timing.responseEnd - timing.navigationStart
            Tracker.post(TeaEvent(Homeric.UG_OVERSEA_WEB_LOAD_DURATION_SERVER, params: ["duration": duration, "os": "iOS"]))
        }
    }

    public func browser(_ browser: WebBrowser, didFail navigation: WKNavigation!, withError error: Error) {

        item?.handleFinishLoad(succ: false)
        if WKNavigationDelegateFailFix.isFatalWebError(error: error) {
            Self.logger.info("browser load occur fatal error: \(error.localizedDescription)")
            self.loadFailedFallback(browser: browser)
        }
    }

    public func browser(_ browser: WebBrowser, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {

        item?.handleFinishLoad(succ: false)
        if WKNavigationDelegateFailFix.isFatalWebError(error: error) {
            Self.logger.info("browser load occur fatal error: \(error.localizedDescription)")
            self.loadFailedFallback(browser: browser)
        }
    }

    func loadFailedFallback(browser: WebBrowser) {
        item?.handleFallbackAction(browser: browser, type: .loadError)
    }
}

public protocol ExternalCallAPIDependencyProtocol {
    var resolver: Resolver? { get set }
    var supportHandlerList: [String] { get set }
    func getCallAPI(webBrowser: WebBrowser) -> WebBrowserCallAPIProtocol
}
// swiftlint:enable all
