//
//  WebInspectorExtensionItem.swift
//  EcosystemWeb
//
//  Created by ByteDance on 2022/9/13.
//

import ECOInfra
import LarkContainer
import LarkWebViewContainer
import LarkSetting
import LKCommonsLogging
import WebBrowser
import WebKit
import OPWebApp
import OPSDK
import TTMicroApp
import EENavigator
import UniverseDesignDialog

private let logger = Logger.ecosystemWebLog(WebInspectorExtensionItem.self, category: "WebInspectorExtensionItem")

final public class WebInspectorExtensionItem: WebBrowserExtensionItemProtocol, WebInspectorPanelDelegate {
    
    public var itemName: String? = "WebInspector"
    
    weak var webBrowser: WebBrowser?
    
    public init(browser: WebBrowser) {
        self.webBrowser = browser
    }
    
    public lazy var lifecycleDelegate: WebBrowserLifeCycleProtocol? = WebInspectorWebBrowserLifeCycle(item: self)
    
    public lazy var navigationDelegate: WebBrowserNavigationProtocol? = WebInspectorWebBrowserNavigation(item: self)
    
    public lazy var browserDelegate: WebBrowserProtocol? = WebInspectorWebBrowser(item: self)
    
    // 调试工具悬浮窗
    private lazy var debugPanel: WebInspectorPanel = {
        let panel = WebInspectorPanel(frame: .zero)
        panel.actionDelegate = self
        return panel
    }()

    deinit {
    }
    
    // 添加调试工具悬浮窗
    func setupPanel() {
        guard let browser = self.webBrowser else {
            logger.error("browser is nil")
            return
        }
        browser.view.addSubview(debugPanel)
        debugPanel.snp.makeConstraints { make in
            make.right.equalToSuperview()
            make.top.equalToSuperview().offset(5 + (Navigator.shared.mainSceneWindow?.safeAreaInsets.top ?? 0))
            make.width.equalTo(WebInspectorPanel.Const.panelWidth)
            make.height.equalTo(WebInspectorPanel.Const.panelHeight)
        }
    }
    
    // 去除调试工具悬浮窗
    func destroyPanel() {
        debugPanel.removeFromSuperview()
    }
    
    // 用户点击关闭后，展示确认弹窗
    func showDestroyDialog() {
        guard let browser = self.webBrowser else {
            logger.error("browser is nil")
            return
        }
        
        var dialog = UDDialog()
        dialog.setTitle(text: BundleI18n.EcosystemWeb.OpenPlatform_WebView_OnlineDebug_Tip)
        dialog.setContent(text: BundleI18n.EcosystemWeb.OpenPlatform_WebView_OnlineDebug_Close_Info)
        dialog.addSecondaryButton(
            text: BundleI18n.EcosystemWeb.OpenPlatform_WebView_OnlineDebug_Cancel,
            dismissCompletion: {
                logger.info("user canceled closing the web debug tool")
            }
        )
        dialog.addPrimaryButton(
            text: BundleI18n.EcosystemWeb.OpenPlatform_WebView_OnlineDebug_Confirm,
            dismissCompletion: {
                logger.info("user checked closing the web debug tool")
                // 用户确认关闭调试能力后，清除调试面板
                browser.webview.evaluateJavaScript("window._destroyLarkDebugTool();", completionHandler: { result, error in
                    if let error = error {
                        logger.error("eval destroy error", error: error)
                    }
                })
                // 清除本地的悬浮窗标记
                WebInspectorValidator.clear()
                // 清除悬浮窗
                logger.info("remove panel")
                self.destroyPanel()
            }
        )
        
        browser.present(dialog, animated: true)
    }
}

extension WebInspectorExtensionItem {
    // 点击悬浮窗显示调试面板
    func didClickPanel() {
        guard let browser = self.webBrowser else {
            logger.error("browser is nil")
            return
        }
        
        let action = {
            browser.webview.evaluateJavaScript("window._openLarkDebugTool();", completionHandler: { result, error in
                if let error = error {
                    logger.error("eval open error", error: error)
                }
            })
        }
        
        // 检查目前 URL 的域名是否在白名单内
        guard let currentHost = browser.browserURL?.host else {
            logger.info("current host is nil")
            return
        }
        guard WebInspectorValidator.checkWebHost(for: currentHost) else {
            logger.info("current host does not hit the host white list")
            return
        }
        
        action()
        return
    }
    
    func didClickClose() {
        self.showDestroyDialog()
    }
}

final public class WebInspectorWebBrowserLifeCycle: WebBrowserLifeCycleProtocol {
    
    weak var item: WebInspectorExtensionItem?
    
    private var debugToolJS: String = CommonComponentResourceManager().fetchJSWithSepcificKey(componentName: "js_for_web_inspector") ?? ""
    let webViewInspectorFixDisable: Bool = FeatureGatingManager.realTimeManager.featureGatingValue(with: FeatureGatingManager.Key(stringLiteral: "openplatform.web.inspector.didcreatefix.disable"))
    init(item: WebInspectorExtensionItem) {
        self.item = item
    }
    
    public func viewDidLoad(browser: WebBrowser) {
        if !webViewInspectorFixDisable {
            configInspectTool(browser: browser)
        }
        
        // 获取调试工具 extension item
        guard let item = self.item else {
            logger.error("item is nil")
            return
        }
        
        // 注入js监听console日志
        if WebConsoleHelper.devToolConsoleOptEnabled() {
            injectConsoleHandler(for: browser)
        }
        
        // 检查本地悬浮窗标记
        guard WebInspectorValidator.checkMark() else {
            logger.info("debug mark is false")
            return
        }

        // 检查 settings 域名白名单
        guard WebInspectorValidator.hostWhiteList != nil else {
            logger.info("settings: web_onlineDebug is nil")
            return
        }
        
        // 显示悬浮窗
        item.setupPanel()

    }
    
    func configInspectTool(browser: WebBrowser) {
        // 检查本地悬浮窗标记
        guard WebInspectorValidator.checkMark() else {
            logger.info("debug mark is false")
            return
        }
        
        // 检查 settings 域名白名单
        guard WebInspectorValidator.hostWhiteList != nil else {
            logger.info("settings: web_onlineDebug is nil")
            return
        }
        
        // 将调试工具 JS 脚本添加为 userScript
        // 因此之后每个网页加载前均会注入调试工具 JS 脚本
        guard !debugToolJS.isEmpty else {
            logger.error("debug tool js is empty")
            return
        }
        let userScript = WKUserScript(source: debugToolJS, injectionTime: .atDocumentStart, forMainFrameOnly: false)
        browser.webview.configuration.userContentController.addUserScript(userScript)
    }
    
    
    // 不可靠的通知，如果插件注册晚于webview创建会收不到这个通知，不推荐使用
    public func webviewDidCreated(_ browser: WebBrowser, webview: LarkWebView) {
        if webViewInspectorFixDisable {
            configInspectTool(browser: browser)
        }
    }

    public func webBrowserDeinit(browser: WebBrowser) {
        logger.info("browser deinit")
    }
    
    private func injectConsoleHandler(for browser: WebBrowser) {
        browser.webview.registerConsoleBridge(handler:WebConsoleHelper())
        let script = WKUserScript(source: WebUserScript.consoleLoggerSource, injectionTime: .atDocumentStart, forMainFrameOnly: false)
        browser.configuration.webviewConfiguration.userContentController.addUserScript(script)
    }
}

final public class WebInspectorWebBrowserNavigation: WebBrowserNavigationProtocol {

    weak var item: WebInspectorExtensionItem?
    var httpResponseList: [HTTPURLResponse]?
    
    init(item: WebInspectorExtensionItem?) {
        self.item = item
    }
    
    public func browser(_ browser: WebBrowser, decidePolicyFor navigationResponse: WKNavigationResponse) -> WKNavigationResponsePolicy {
        guard let response = navigationResponse.response as? HTTPURLResponse else {
            return .allow
        }
        guard WebConsoleHelper.logToVConsoleEnabled(url: response.url) else {
            return .allow
        }
        if navigationResponse.isForMainFrame && response.statusCode >= 400 {
            if httpResponseList == nil {
                httpResponseList = []
            }
            httpResponseList?.append(response)
        }
        return .allow
    }
    
    public func browser(_ browser: WebBrowser, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        reportStatusCodeLog(browser)
    }
    
    public func browser(_ browser: WebBrowser, didFail navigation: WKNavigation!, withError error: Error) {
        reportStatusCodeLog(browser)
    }
    
    public func browser(_ browser: WebBrowser, didFinish navigation: WKNavigation!) {
        reportStatusCodeLog(browser)
    }
    
    private func reportStatusCodeLog(_ browser: WebBrowser) {
        guard let list = httpResponseList, !list.isEmpty else {
            return
        }
        for httpResponse in list {
            let code = httpResponse.statusCode
            let url = httpResponse.url?.safeURLString ?? ""
            let msg = "status_code:\(code) status_desc:\(HTTPURLResponse.localizedString(forStatusCode: code)) url:\(url)"
            WebConsoleHelper.sendLogToVConsole(level: .warn, msg, webview: browser.webview)
        }
        httpResponseList = nil
    }
}

final public class WebInspectorWebBrowser: WebBrowserProtocol {
    
    weak var item: WebInspectorExtensionItem?
    
    init(item: WebInspectorExtensionItem?) {
        self.item = item
    }
    
    public func browser(_ browser: WebBrowser, didURLChanged url: URL?) {
        
    }
}

