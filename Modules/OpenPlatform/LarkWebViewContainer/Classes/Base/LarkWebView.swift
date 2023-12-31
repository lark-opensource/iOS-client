//
//  LarkWebView.swift
//  LarkWebViewContainer
//
//  Created by houjihu on 2020/8/12.
//

import ECOInfra
import ECOProbe
import LarkContainer
import LarkSetting
import LKCommonsLogging
import LKLoadable
import WebKit

public var ajaxFetchHookFG = false

class LarkWebViewDpInternal {
    static let shared = LarkWebViewDpInternal()
    @Provider var dp: LarkWebViewProtocol
    private init() {}
}

public protocol LarkWebViewProtocol {
    func setupAjaxFetchHook(webView: LarkWebView)
    func ajaxFetchHookString() -> String?
}
var larkWebViewDependency: LarkWebViewProtocol! {
    LarkWebViewDpInternal.shared.dp
}

/// LarkWebView回调Delegate
@objc
public protocol LarkWebViewDelegate {
    /// load url前设置的http headers
    @objc
    optional func buildExtraHttpHeaders() -> [String: String]?

    /// load url前的自定义User-Agent，如无需在loadUrl时设置，可直接修改customUserAgent
    @objc
    optional func buildCustomUserAgent() -> String?

    /// 构造 APIMessage 不实现此方法或者返回nil将会走默认流程 无特殊需求谨慎使用
    /// - Parameter messageBody: The body of the message. Allowed types are NSNumber, NSString, NSDate, NSArray, NSDictionary, and NSNull.
    @objc
    optional func buildAPIMessage(with messageBody: Any) -> APIMessage?
}

let logger = Logger.lkwlog(LarkWebView.self, category: "LarkWebView")

// MARK: - private init & deinit
/// 该扩展均为私有方法，只允许在LarkWebView.m中由init和dealloc调用
@objc public extension LarkWebView {
    
    var isFirstPage : Bool{
        get {
            return (self.loadURLCount <= 1 || self.loadURLEndCount < 1)
        }
    }
    
    /// 只允许在OC的init调用该方法
    func initByOC(config: LarkWebViewConfig, parentTrace: OPTrace?, webviewDelegate: LarkWebViewDelegate?) {
        // 进行一些内核问题修复
        FixLarkWebView.tryFixLarkWebView(webView: self)
        //  属性初始化
        self.config = config
        self.webviewDelegate = webviewDelegate
        uiDelegateProxy = WKUIDelegateProxy()
        navigationDelegateProxy = WKNavigationDelegateProxy()
        uiDelegateProxy.changeDelegateBlock = { [weak self] in
            self?.updateUIDelegate()
        }
        navigationDelegateProxy.changeDelegateBlock = { [weak self] in
            self?.updateNavigationDelegate()
        }
        
        qualityService = InjectedOptional<LarkWebViewQualityServiceProtocol>().wrappedValue
        
        if qualityService == nil {
            logger.error("has not register LarkWebViewQualityServiceProtocol")
        }
        if config.secLinkEnable {
            secLinkService = InjectedOptional<LarkWebViewSecLinkServiceProtocol>().wrappedValue
            
            if secLinkService == nil {
                logger.error("has not register LarkWebViewSecLinkServiceProtocol")
            }
        }
        prepare(initTrace: config.initTrace, parent: parentTrace)
        addObserver()
        //  初始化ajax/fetch hook的能力
        larkWebViewDependency.setupAjaxFetchHook(webView: self)
        //  配置hybrid monitor
        if Self.enableHybridMonitor {
            monitorService = InjectedOptional<LarkWebViewMonitorServiceProtocol>().wrappedValue
            
            monitorService?.configWebView(webView: self)
        }
        setupUserScript()
        self.performancer = LarkWebViewPerformance()
        
        if (self.config.bizType == LarkWebViewBizType.larkWeb) {
            LarkWebViewPreLoadDetector.shared.startDetect(webview: self)
        }
        LarkWebViewPreLoadDetector.shared.webviewMaybePreloaded(webview:self)
    }
    
    /// 只允许在OC的dealloc调用该方法
    func deinitByOC() {
        self.monitorLoadURLEndIfNeeded()
        logger.lkwlog(level: .info, "LarkWebView deinit isloading: \(self.isLoading)", traceId: opTraceId())
        // prevent webview from crash on deinit WebKit 内部 Bug
        scrollView.delegate = nil
        // 如果是通过 window.open 打开的 WebView 由于和父 WebView 共享 WKWebViewConfiguration 不可以清除上下文，否则会导致父 WebView 无法调用 API
        if !config.disableClearBridgeContext {
            clearBridgeContext()
        }
        clearDelegates()
        deinitMonitor()
        if (self.config.bizType == LarkWebViewBizType.larkWeb) {
            LarkWebViewPreLoadDetector.shared.finishDetect()
        }
    }
    
    static var enableHybridMonitor: Bool = {
        FeatureGatingManager.shared.featureGatingValue(with: FeatureGatingManager.Key(stringLiteral: "openplatform.larkwebview.hybridmonitor.enable"))// user:global
    }()
}

extension LarkWebView {
    /// 使用前准备工作
    func prepare(initTrace: OPTrace?, parent: OPTrace? = nil) {
        if config.isAutoSyncCookie, config.webViewConfig.websiteDataStore.isPersistent {
            syncCookies()
        }
        self.refreshTrace(initTrace: initTrace, parent: parent)
        logger.lkwlog(level: .info, "webview init", traceId: opTraceId())
        OPMonitor(event: .createWebView, code: BaseMonitorCode.createWebView, webview: self).flush()
    }

    /// deinit时埋点
    private func deinitMonitor() {
        logger.lkwlog(level: .info, "webview dealloc", traceId: opTraceId())
        OPMonitor(event: .destroyWebView, code: BaseMonitorCode.destroyWebView, webview: self)
            .setVisibleCrashCount(visibleTerminateCount)
            .setInvisibleCrashCount(invisibleTerminateCount)
            .setIsTerminateState(isTerminateState)
            .setLoadURLCount(loadURLCount)
            .flush()
    }
    
    public func monitorLoadURLEndIfNeeded () {
        if self.isLoading {
            var duration: TimeInterval = 0
            if (self.disappearTime - self.createTime > 0) {
                duration = (self.disappearTime - self.createTime) * 1000
            }
            let monitor =  OPMonitor(event: .loadUrlEnd, code: BaseMonitorCode.loadUrlEnd, webview: self)
                .addCategoryValue(.appType, "webApp")
                .addCategoryValue(.resultCode, LoadUrlResult.closed.rawValue)
                .setWebViewURL(self, url)
                .addCategoryValue("failType", "didFail")
                .addCategoryValue("web_duration", duration)
                .setResultTypeFail()
                .setCustomEventInfo(self.customEventInfo())
                .setTimeConsumigInfo(self.fetchDifferentPhaseTimeConsumingInfo())
                .flush()
            self.monitorLoadUrlDuration(url: url, isSuccess: false, resutlCode: LoadUrlResult.closed, error: nil)
        }
    }
    
    func monitorLoadUrlDuration(url:URL?,isSuccess:Bool, resutlCode:LoadUrlResult, error: Error?) {
        if (self.config.bizType == .larkWeb && self.isFirstPage && !self.hasUploadURLDuration){
            var duration:TimeInterval = 0
            if let startTime = self.config.startHandleTime {
                duration = Date().timeIntervalSince1970 - startTime
            }
            
           let monitor = OPMonitor(event: .loadDuration, code:nil, webview: self)
                .addCategoryValue(.resultCode, resutlCode.rawValue)
                .setWebViewURL(self,url)
                .setDuration(duration)
        
            if (isSuccess) {
                monitor.setResultTypeSuccess()
                monitor.flush()
            }else{
                monitor.setResultTypeFail()
                .setError(error)
                monitor.flush()
            }
            self.hasUploadURLDuration = true
        }
    }
    
   public func recordTimeConsumingIn(phase:WebviewTimeConsumingPhase, duration:TimeInterval){
       if (self.isFirstPage && self.config.bizType == LarkWebViewBizType.larkWeb){
            self.performancer.recordTimeConsumingIn(phase: phase, duration: duration)
        }
    }
    
    public func recordExtensionItemTimeConsumingIn(phase:WebviewTimeConsumingPhase, duration:TimeInterval,itemName:String){
        if (!itemName.isEmpty && self.isFirstPage && self.config.bizType == LarkWebViewBizType.larkWeb){
             self.performancer.recordExtensionItemTimeConsumingIn(phase: phase, duration: duration, itemName: itemName)
         }
     }
    
    public func fetchDifferentPhaseTimeConsumingInfo () ->Array<Any>? {
        guard self.config.bizType == .larkWeb && self.isFirstPage else{
            return nil
        }
        return self.performancer.fetchTimeConsumingInfo()
    }
    
    public func monitorSeclinkService(url:URL?) {
        if let url = url, self.config.bizType == LarkWebViewBizType.larkWeb, self.isFirstPage {
            OPMonitor(.urlSeclinkCheck,webview:self)
                .addCategoryValue("url", url.absoluteString)
                .flush()
        }
    }
    
    public func preloadInfo() -> String? {
        guard self.config.bizType == LarkWebViewBizType.larkWeb, self.isFirstPage else {
            return nil
        }
      
        guard LarkWebViewPreLoadDetector.shared.webviewHasPreloaded == true else {
            return nil
        }
        return LarkWebViewPreLoadDetector.shared.preloadInfo
    }
    
    public func opTraceId() -> String? {
        guard let trace = trace else {
            return nil
        }
        guard let traceId = trace.traceId as? String else {
            return nil
        }
        return traceId
    }
}

// MARK: - App前后台切换监听 用于takeUploadAssertion()触发条件排查
extension LarkWebView {
    /// App前后台切换监听
    private func addObserver() {
        NotificationCenter.default.addObserver(self, selector: #selector(lkw_didEnterBackground), name: UIApplication.didEnterBackgroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(lkw_willEnterForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(lkw_didBecomeActive), name: UIApplication.didBecomeActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(lkw_willResignActive), name: UIApplication.willResignActiveNotification, object: nil)
    }

    @objc func lkw_didEnterBackground() {
        if LarkWebSettings.lkwEncryptLogEnabel {
            logger.lkwUrlEncryptLog(level: .info, "didEnterBackground, info: \(notificationInfo())", url: url, traceId: opTraceId())
        } else {
            logger.lkwlog(level: .info, "lkw_didEnterBackground, info: \(notificationInfo())", traceId: opTraceId())
        }
        self.recordWebviewCustomEvent(.didEnterBackground)
    }
    
    @objc func lkw_willEnterForeground() {
        if LarkWebSettings.lkwEncryptLogEnabel {
            logger.lkwUrlEncryptLog(level: .info, "willEnterForeground, info: \(notificationInfo())", url: url, traceId: opTraceId())
        } else {
            logger.lkwlog(level: .info, "lkw_willEnterForeground, info: \(notificationInfo())", traceId: opTraceId())
        }
    }
    
    @objc func lkw_didBecomeActive() {
        if LarkWebSettings.lkwEncryptLogEnabel {
            logger.lkwUrlEncryptLog(level: .info, "didBecomeActive, info: \(notificationInfo())", url: url, traceId: opTraceId())
        } else {
            logger.lkwlog(level: .info, "lkw_didBecomeActive, info: \(notificationInfo())", traceId: opTraceId())
        }
    }
    
    @objc func lkw_willResignActive() {
        if LarkWebSettings.lkwEncryptLogEnabel {
            logger.lkwUrlEncryptLog(level: .info, "willResignActive, info: \(notificationInfo())", url: url, traceId: opTraceId())
        } else {
            logger.lkwlog(level: .info, "lkw_willResignActive, info: \(notificationInfo())", traceId: opTraceId())
        }
        self.recordWebviewCustomEvent(.didEnterBackground)
    }
    
    /// 基础信息
    private func notificationInfo() -> String {
        "biz_type: \(config.bizType.rawValue), isLoading: \(isLoading), estimatedProgress: \(estimatedProgress)"
    }
}

// MARK: - seclink检测
extension LarkWebView {
    static var enableSeclinkPrecheck: Bool = {
        FeatureGatingManager.shared.featureGatingValue(with: FeatureGatingManager.Key(stringLiteral: "openplatform.web.seclinkprecheck.enable"))// user:global
    }()
    
    public func seclinkCheckCanBeAsync() -> Bool {
        let enablePrecheck = Self.enableSeclinkPrecheck
        guard enablePrecheck, self.loadURLEndCount < 1,self.config.bizType == LarkWebViewBizType.larkWeb else{
            return false
        }
        
        if self.config.seclinkPrecheckResult == .prechecking {
            return true
        }
        return false
    }
    
    public func exemptSecLinkCheck() -> Bool {
        let exemptSeclinkDisable = FeatureGatingManager.shared.featureGatingValue(with: FeatureGatingManager.Key(stringLiteral: "openplatform.larkwebview.exemptseclinkcheck.disable"))// user:global
        guard exemptSeclinkDisable == false, self.config.bizType == .larkWeb else {
            return false
        }
        
        let workplacePortalIdentifier = "workplacePortal"
        let mainTabIdentifier = "mainTab"
        let normalIdentifier  = "normal"
        let scene = self.config.scene
        
        if scene == workplacePortalIdentifier || scene == mainTabIdentifier {
            return true
        }
        
        if let _ = self.config.appId, scene == normalIdentifier {
            return true
        }
        
        let precheckEnable = Self.enableSeclinkPrecheck
        //如果是首页（只考虑loadURLEndCount小于1，没有使用isFirstPage）且seclink预检测结果是safe，可以豁免检测
        if precheckEnable && self.loadURLEndCount < 1 && self.config.seclinkPrecheckResult == .safe {
            return true
        }
        return false
    }
    
    public func seclinkPrecheckUrl(url:URL) {
        let precheckEnable = Self.enableSeclinkPrecheck
        guard precheckEnable else {
            return
        }
        guard self.config.secLinkEnable else {
            return
        }
        let canExempt = self.exemptSecLinkCheck()
        if !canExempt{
            self.config.seclinkPrecheckResult = .prechecking
            self.secLinkService?.seclinkPrecheck(url: url, checkReuslt: {[weak self] isSafe in
                if isSafe {
                    self?.config.seclinkPrecheckResult = .safe
                }else {
                    self?.config.seclinkPrecheckResult = .unsafe
                }
            })
        }
    }
}

// MARK: - override
extension LarkWebView {
    open override func evaluateJavaScript(_ javaScriptString: String, completionHandler: ((Any?, Error?) -> Void)? = nil) {
        executeOnMainQueueAsync {
            super.evaluateJavaScript(javaScriptString, completionHandler: completionHandler)
        }
    }
    
    open override func load(_ request: URLRequest) -> WKNavigation? {
        assert(Thread.isMainThread, "WKWebView.loadRequest must be used from main thread only")
        logger.lkwlog(level: .info, "load request start...", traceId: opTraceId())
        LKWSecurityLogUtils.webSafeAESURL(request.url?.absoluteString ?? "", msg: "loadURL")
        qualityService?.setCustomHeaderAndUserAgent(webView: self, request: request)
        return super.load(request)
    }
}

// MARK: - Tracing
@objc
extension LarkWebView: OPTraceContextProtocol {
    public func opTrace() -> OPTrace? {
        return self.trace
    }
    /// 刷新Trace
    /// initTrace 和 parent 只能二选一
    func refreshTrace(initTrace: OPTrace?, parent: OPTrace?) {
        if let initTrace = initTrace {
            self.trace = initTrace
            // 外部已经指定了初始化 trace，就不再需要再生成 trace 了
            assert(parent==nil, "parentTrace does not take effect when initTrace exists, please set only one of them.")
            return
        }
        if let parent = parent {
            self.trace = OPTraceService.default().generateTrace(withParent: parent)
        } else {
            self.trace = OPTraceService.default().generateTrace()
        }
    }
}

// MARK: 网页业务自定义 Text Selection Menu
extension LarkWebView {
    public func makeCustomMenu(menuItems: [LarkWebViewMenuItem]) {
        guard menuItems.count > 0 else {
            logger.lkwlog(level: .error, "no custom menuItems")
            return
        }
        var customItems: [UIMenuItem] = [UIMenuItem]()
        for menuItem in menuItems {
            switch menuItem.identifier {
            case .myAI:
                let myAiItem = UIMenuItem(title: menuItem.title, action: #selector(myAIAction(sender:)))
                customItems.append(myAiItem)
                logger.lkwlog(level: .info, "add myAiItem to customItems")
            case .explain:
                let explainItem = UIMenuItem(title: menuItem.title, action: #selector(explainAction(sender:)))
                customItems.append(explainItem)
                logger.lkwlog(level: .info, "add explainItem to customItems")
            default:
                break
            }
        }
        let menuControl = UIMenuController.shared
        menuControl.menuItems = customItems
    }
    
    @objc
    func myAIAction(sender: Any?) {
        self.webviewMenuDelegate?.myAIAction?(sender: sender)
    }

    @objc
    func explainAction(sender:Any?) {
        self.webviewMenuDelegate?.explainAction?(sender: sender)
    }
    
    override open var canBecomeFirstResponder: Bool {
        if let result = self.webviewMenuDelegate?.lk_canBecomeFirstResponder {
            logger.lkwlog(level: .info, "get canBecomeFirstResponder result from webviewMenuDelegate")
            return result
        }
        return super.canBecomeFirstResponder
    }
    
    override open func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        if let result = self.webviewMenuDelegate?.lk_canPerformAction?(action, withSender: sender, withDefault: super.canPerformAction(action, withSender: sender)) {
            logger.lkwlog(level: .info, "get canPerformAction result from webviewMenuDelegate")
            return result
        }
        return super.canPerformAction(action, withSender: sender)
    }
}

@available(iOS 13.0, *)
extension LarkWebView {
    // 适配 iOS16
    open override func buildMenu(with builder: UIMenuBuilder) {
        defer {
            super.buildMenu(with: builder)
        }
        if let menuItems = self.webviewMenuDelegate?.lk_buildMenu?(with: builder), menuItems.count > 0 {
            logger.lkwlog(level: .info, "get menuItems from webviewMenuDelegate")
            var menuElements: [UIMenuElement] = [UIMenuElement]()
            for menuItem in menuItems {
                switch menuItem.identifier {
                case .myAI:
                    //My AI 气泡菜单项
                    let myAiItem = UICommand(title: menuItem.title, action: #selector(myAIAction(sender:)))
                    menuElements.append(myAiItem)
                    logger.lkwlog(level: .info, "add myAiItem to menuElements")
                case .explain:
                    //My AI 解释指令的气泡菜单项
                    let explainItem = UICommand(title: menuItem.title, action: #selector(explainAction(sender:)))
                    menuElements.append(explainItem)
                    logger.lkwlog(level: .info, "add explainItem to menuElements")
                default:
                    break
                }
            }
            let customMenu = UIMenu(identifier: .init("webCustomMenu"), options: .displayInline, children: menuElements)
            builder.insertChild(customMenu, atStartOfMenu: .root)
        }
    }
}
