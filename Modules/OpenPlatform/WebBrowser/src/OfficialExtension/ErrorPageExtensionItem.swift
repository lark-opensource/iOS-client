import Foundation
import LarkSetting
import LarkWebViewContainer
import LKCommonsLogging
import WebKit
import ECOProbe

private let ErrorPageExtensionItemErrorDomain =  "com.larksuite.openplatform.ErrorPageExtensionItem"

public let BrowserInternalScheme = "lkweb"
let BrowserInternalLocalDomain = "local"
let BrowserInternalErrorPagePath = "/errorpage"
let BrowserInternalDetectPagePath = "/netdetect"
let BrowserFailedUrlQueryName = "failedUrl"
let BrowserErrorCodeQueryName = "errorCode"
let BrowserErrorDescQueryName = "errorDesc"
let BrowserErrorShowDetectQueryName = "showDetectBtn"
let BrowserErrorBusinessTypeName = "businessType"
let BrowserCustomPageConfigQueryName = "customPageConfig"
private let OPBrowserErrorPendingTime = UserSettingKey.make(userKeyLiteral: "restart_dialog_pending_time")

public var browserNewErrorTimedOutNoResponse: Bool = { !FeatureGatingManager.shared.featureGatingValue(with: FeatureGatingManager.Key(stringLiteral: "openplatform.web.timed_out_no_response.disable")) }()// user:global
let errorpageLogger = Logger.webBrowserLog(ErrorPageExtensionItem.self, category: "ErrorPage")

// MARK: ErrorPageExtensionItem
final public class ErrorPageExtensionItem: WebBrowserExtensionItemProtocol {
    public var itemName: String? = "ErrorPage"
    public lazy var navigationDelegate: WebBrowserNavigationProtocol? = ErrorPageWebBrowserNavigation(item: self)
    public lazy var lifeCycleDelegate: WebBrowserLifeCycleProtocol? = OPWErrorLifeCycleImplementation(item: self)
    public lazy var browserDelegate: WebBrowserProtocol? = OPWErrorLoadImplementation(item: self)
    
    public init() {
    }
}

// MARK: ErrorPageWebBrowserNavigation
final public class ErrorPageWebBrowserNavigation: WebBrowserNavigationProtocol {
    private weak var item: ErrorPageExtensionItem?
    /// 开始加载阶段超时无响应计时器
    private var timer: Timer?
    static var pendingTime: TimeInterval? = {
        if let settings = try? SettingManager.shared.setting(with: OPBrowserErrorPendingTime),// user:global
           let time = settings[OPBrowserErrorPendingTime.stringValue] as? Int,
           time > 0 {
            return TimeInterval(time) / 1000.0
        }
        return nil
    }()
    
    private static let browserErrorPageTxzEnable: Bool = !FeatureGatingManager.shared.featureGatingValue(with: FeatureGatingManager.Key(stringLiteral: "openplatform.webapp.inner_bundle_txz.disable"))// user:global
    private var nativeFailView: NativeFailViewExtensionItem?
    
    deinit {
        cancelTimer()
    }
    
    init(item: ErrorPageExtensionItem) {
        self.item = item
        setupNotifications()
    }
    
    public func browser(_ browser: WebBrowser, didStartProvisionalNavigation navigation: WKNavigation!) {
        if let nativeFailView = nativeFailView {
            errorpageLogger.info("web_bundle_size_compress errorpage.html is nil, remove nativeFailView")
            nativeFailView.removeFailView()
        }
        guard browserNewErrorTimedOutNoResponse else {
            return
        }
        guard let delay = Self.pendingTime else {
            return
        }
        errorpageLogger.info("didStart: no response timer delay:\(delay), url:\(browser.browserURL?.safeURLString ?? "")")
        cancelTimer()
        let timer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { [weak self, weak browser] _ in
            guard let self = self, let browser = browser else {
                return
            }
            if browser.processStage == .HasStartedURL {
                errorpageLogger.info("web show error page due to \(delay)s from did start to no response timeout")
                browser.webview.stopLoading()
                let errorInfo = [NSLocalizedDescriptionKey: "The request timed out.", NSURLErrorFailingURLErrorKey: browser.browserURL as Any, NSURLErrorFailingURLStringErrorKey: browser.browserURL?.absoluteString as Any]
                self.handlerWebError(browser: browser, error: NSError(domain: ErrorPageExtensionItemErrorDomain, code: NSURLErrorTimedOut, userInfo: errorInfo))
            } else {
                errorpageLogger.info("web \(browser.processStage) stage not show error page even if no response timeout")
            }
        }
        self.timer = timer
    }
    
    public func browser(_ browser: WebBrowser, decidePolicyFor navigationResponse: WKNavigationResponse) -> WKNavigationResponsePolicy {
        if browserNewErrorTimedOutNoResponse && timer != nil {
            errorpageLogger.info("web did response cancel no response timer")
            cancelTimer()
            return .allow
        }
        return .allow
    }
    
    public func browser(_ browser: WebBrowser, didFail navigation: WKNavigation!, withError error: Error) {
        let browserSettings = LarkWebSettings.shared.settings?["browser"] as? [String: Any]
        let value = browserSettings?["didFailNavigationShowErrorPage"] as? Bool
        if value == true {
            handlerWebError(browser: browser, error: error)
        }
    }
    public func browser(_ browser: WebBrowser, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        if browserNewErrorTimedOutNoResponse && timer != nil {
            errorpageLogger.info("web did start fail cancel no response timer")
            cancelTimer()
        }
        handlerWebError(browser: browser, error: error)
    }
    
    public func browserWebContentProcessDidTerminate(_ browser: WebBrowser) {
        if browserNewErrorTimedOutNoResponse && timer != nil {
            errorpageLogger.info("web process did terminate cancel no response timer")
            cancelTimer()
        }
    }
    
    private func handlerWebError(browser: WebBrowser, error: Error) {
        let urlString = browser.browserURL?.safeURLString ?? ""
        errorpageLogger.error("load page error", additionalData: ["url": urlString], error: error)
        
        guard WKNavigationDelegateFailFix.isFatalWebError(error: error) else {
            errorpageLogger.warn("not fatal web error.")
            return
        }
        if checkIfWebContentProcessHasCrashed(browser.webview, error: error as NSError) {
            errorpageLogger.info("checkIfWebContentProcessHasCrashed true, not show error page")
            return
        }
        let error = error as NSError
        guard let url = error.userInfo[NSURLErrorFailingURLErrorKey] as? URL else {
            errorpageLogger.error("has no NSURLErrorFailingURLErrorKey'url")
            return
        }
        
        // 若不解压错误页资源包 或 不能获取错误页, 则降级使用兜底native错误页
        let showNativeError = !Self.browserErrorPageTxzEnable || webBrowserDependency.errorpageHTML() == nil
        if showNativeError {
            errorpageLogger.error("web_bundle_size_compress errorpage.html is nil, show nativeFailView")
            let nativeFailView = NativeFailViewExtensionItem(browser: browser)
            nativeFailView.showFailView(browser: browser, error: error)
            self.nativeFailView = nativeFailView
        } else {
            loadPage(error, forUrl: url, browser: browser)
        }
        //错误页展示
        OPMonitor("wb_container_show_error_view")
            .tracing(browser.webview.trace)
            .addCategoryValue("url", url.safeURLString)
            .addCategoryValue("is_native", showNativeError)
            .setError(error)
            .flush()
    }
    
    /// 展示定制错误页
    public func handleWebCustomError(browser: WebBrowser, errorCode: Int? = nil, errorDesc: String? = nil, forCustom configStr: String? = nil) {
        guard let url = browser.browserURL else {
            errorpageLogger.error("load custom error page url is nil")
            return
        }
        errorpageLogger.info("load custom error page code: \(errorCode ?? -1), desc: \(errorDesc ?? "")")
        
        var code: Int?
        if let errorCode = errorCode {
            code = errorCode
        } else if let configStr = configStr,
                  let data = configStr.data(using: .utf8),
                  let configDict = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                  let customErrorCode = configDict["customErrorCode"] as? String {
            code = Int(customErrorCode)
        }
        
        let errorInfo = [NSLocalizedDescriptionKey: errorDesc ?? "Show Custom Error Page",
                      NSURLErrorFailingURLErrorKey: browser.browserURL as Any,
                NSURLErrorFailingURLStringErrorKey: browser.browserURL?.absoluteString as Any]
        let error = NSError(domain: ErrorPageExtensionItemErrorDomain, code: code ?? NSURLErrorTimedOut, userInfo: errorInfo)
        let isNativeErrorPage = !Self.browserErrorPageTxzEnable || webBrowserDependency.errorpageHTML() == nil
        if isNativeErrorPage {
            errorpageLogger.error("load custom error page settings html is nil, show native error page")
            let nativeFailView = NativeFailViewExtensionItem(browser: browser)
            nativeFailView.showFailView(browser: browser, error: error)
            self.nativeFailView = nativeFailView
        } else {
            loadPage(error, forUrl: url, browser: browser, forCustom: configStr)
        }
        
        OPMonitor("wb_container_show_error_view")
            .tracing(browser.webview.trace)
            .addCategoryValue("url", url.safeURLString)
            .addCategoryValue("is_native", isNativeErrorPage)
            .setError(error)
            .flush()
    }
    
    private func loadPage(_ error: NSError, forUrl url: URL, browser: WebBrowser, forCustom configStr: String? = nil) {
        var components = URLComponents()
        components.scheme = BrowserInternalScheme
        components.host = BrowserInternalLocalDomain
        components.path = BrowserInternalErrorPagePath
        var queryItems = [
            URLQueryItem(name: BrowserFailedUrlQueryName, value: url.absoluteString),
            URLQueryItem(name: BrowserErrorCodeQueryName, value: String(error.code)),
            URLQueryItem(name: BrowserErrorDescQueryName, value: error.localizedDescription)
        ]
        if let detectPage = webBrowserDependency.webDetectPageHTML(), !detectPage.isEmpty {
            queryItems.append(URLQueryItem(name: BrowserErrorShowDetectQueryName, value: "1"))
            queryItems.append(URLQueryItem(name: BrowserErrorBusinessTypeName, value: browser.bizType?.rawValue))
        }
        // 原生定制错误页
        if isCustomErrorPageEnabled() {
            if let targetConfigStr = configStr, !targetConfigStr.isEmpty {
                errorpageLogger.info("append custom error page query item succeed")
                queryItems.append(URLQueryItem(name: BrowserCustomPageConfigQueryName, value: targetConfigStr))
            } else {
                errorpageLogger.error("append custom error page query item failed")
            }
        }
        components.queryItems = queryItems
        guard let urlWithQuery = components.url else {
            errorpageLogger.error("loadErrorPage error, components.url is nil")
            return
        }
        let request = URLRequest(url: urlWithQuery)
        browser.webView.load(request)
    }
        
    private func checkIfWebContentProcessHasCrashed(_ webView: WKWebView, error: NSError) -> Bool {
        if error.code == WKError.webContentProcessTerminated.rawValue && error.domain == "WebKitErrorDomain" {
            return true
        }
        return false
    }
    
    fileprivate func cancelTimer() {
        guard timer != nil else {
            return
        }
        errorpageLogger.debug("timer did cancel")
        timer?.invalidate()
        timer = nil
    }
    
    private func setupNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(didEnterBackgroundNotification), name: UIApplication.didEnterBackgroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(didBecomeActiveNotification), name: UIApplication.didBecomeActiveNotification, object: nil)
    }
    
    @objc private func didEnterBackgroundNotification() {
        guard let timer = timer else {
            return
        }
        errorpageLogger.debug("did enter background timer pause")
        timer.fireDate = Date.distantFuture
    }
    
    @objc private func didBecomeActiveNotification() {
        guard let timer = timer else {
            return
        }
        guard let delay = Self.pendingTime else {
            return
        }
        errorpageLogger.debug("did become active timer restart")
        timer.fireDate = Date(timeIntervalSinceNow: delay)
    }
    
    private func isCustomErrorPageEnabled() -> Bool {
        return FeatureGatingManager.realTimeManager.featureGatingValue(with: FeatureGatingManager.Key(stringLiteral: "openplatform.web.errorpage.custom_ui_config_enable"))// user:global
    }
}

// MARK: OPWErrorLifeCycleImplementation
final class OPWErrorLifeCycleImplementation: WebBrowserLifeCycleProtocol {
    private weak var item: ErrorPageExtensionItem?
    
    init(item: ErrorPageExtensionItem) {
        self.item = item
    }
    
    func webBrowserDeinit(browser: WebBrowser) {
        guard let item = item else {
            return
        }
        guard let navigationDelegate = item.navigationDelegate as? ErrorPageWebBrowserNavigation else {
            return
        }
        navigationDelegate.cancelTimer()
    }
}

// MARK: OPWErrorLoadImplementation
final class OPWErrorLoadImplementation: WebBrowserProtocol {
    private static let browserDetectStatusEnable: Bool = !FeatureGatingManager.shared.featureGatingValue(with: FeatureGatingManager.Key(stringLiteral: "openplatform.ecosystemweb.detectnetstatus.disable"))// user:global
    private weak var item: ErrorPageExtensionItem?
    var rightBarBtnItems: [UIBarButtonItem]?
    
    init(item: ErrorPageExtensionItem) {
        self.item = item
    }
    
    func browser(_ browser: WebBrowser, didURLChanged url: URL?) {
        guard Self.browserDetectStatusEnable else {
            return
        }
        guard let url = browser.webview.url else {
            return
        }
        // 回调的url参数是browserURL包含错误页等场景, 需要使用当前的webview.url
        if WebDetectHelper.isValid(url: url) {
            if browser.isNavigationRightBarExtensionDisable {
                // 7.6之前线上逻辑, else 什么都不做，在NavigationBarRightExtensionItem中会自动处理
                if let items = browser.navigationItem.rightBarButtonItems {
                    rightBarBtnItems = items
                    browser.navigationItem.setRightBarButtonItems(nil, animated: false)
                }
            }
        } else if url.isErrorPageURL() {
            if browser.isNavigationRightBarExtensionDisable {
                // 7.6之前线上逻辑, else 什么都不做，在NavigationBarRightExtensionItem中会自动处理
                if rightBarBtnItems != nil {
                    browser.navigationItem.setRightBarButtonItems(rightBarBtnItems, animated: false)
                    rightBarBtnItems = nil
                }
            }
            
        }
    }
}

// MARK: - InternalSchemeHandler
enum InternalPageSchemeHandlerError: Error {
    case badURL
    case noResponder
    case responderUnableToHandle
}
protocol InternalSchemeResponse {
    func response(forRequest: URLRequest) -> (URLResponse, Data)?
}
class InternalSchemeHandler: NSObject, WKURLSchemeHandler {
    static func response(forUrl url: URL) -> URLResponse {
        URLResponse(url: url, mimeType: "text/html", expectedContentLength: -1, textEncodingName: "utf-8")
    }
    static var responders: [String: InternalSchemeResponse] = [
        BrowserInternalErrorPagePath: ErrorPageHandler(),
        BrowserInternalDetectPagePath: DetectPageHandler()
    ]
    func webView(_ webView: WKWebView, start urlSchemeTask: WKURLSchemeTask) {
        guard let url = urlSchemeTask.request.url else {
            errorpageLogger.error("InternalSchemeHandler start urlSchemeTask url is nil")
            urlSchemeTask.didFailWithError(InternalPageSchemeHandlerError.badURL)
            return
        }
        let path = url.path
        guard let responder = InternalSchemeHandler.responders[path] else {
            errorpageLogger.error("nternalSchemeHandler.responders[\(path)] is nil")
            urlSchemeTask.didFailWithError(InternalPageSchemeHandlerError.noResponder)
            return
        }
        guard let (urlResponse, data) = responder.response(forRequest: urlSchemeTask.request) else {
            urlSchemeTask.didFailWithError(InternalPageSchemeHandlerError.responderUnableToHandle)
            return
        }
        urlSchemeTask.didReceive(urlResponse)
        urlSchemeTask.didReceive(data)
        urlSchemeTask.didFinish()
    }
    func webView(_ webView: WKWebView, stop urlSchemeTask: WKURLSchemeTask) {
    }
}
class ErrorPageHandler: InternalSchemeResponse {
    func response(forRequest request: URLRequest) -> (URLResponse, Data)? {
        guard let url = request.url else {
            errorpageLogger.error("error page request url is nil")
            return nil
        }
        guard let component = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            errorpageLogger.error("error page URLComponents init is nil, url: \(url.safeURLString)")
            return nil
        }
        guard let failedUrlValue = component.queryItems?.first(where: { item in
            item.name == BrowserFailedUrlQueryName
        })?.value else {
            errorpageLogger.error("error page no failedUrl value, url: \(url.safeURLString)")
            return nil
        }
        guard let originalUrl = URL(string: failedUrlValue) else {
            errorpageLogger.error("error page failedUrlValue is vaild, value: \(failedUrlValue.safeURLString)")
            return nil
        }
        let response = InternalSchemeHandler.response(forUrl: originalUrl)
        guard let html = webBrowserDependency.errorpageHTML() else {
            errorpageLogger.error("errorpageHTML is nil")
            return nil
        }
        if html.isEmpty {
            errorpageLogger.error("errorpageHTML is empty")
            return nil
        }
        guard let data = html.data(using: .utf8) else {
            errorpageLogger.error("error page html.data(using: .utf8) is nil")
            return nil
        }
        return (response, data)
    }
}

// MARK: - URL Extension
extension URL {
    func isErrorPageURL() -> Bool {
        scheme == BrowserInternalScheme && host == BrowserInternalLocalDomain && path == BrowserInternalErrorPagePath
    }
}

