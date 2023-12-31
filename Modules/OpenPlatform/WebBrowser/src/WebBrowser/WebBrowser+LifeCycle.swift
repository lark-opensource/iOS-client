import CookieManager
import ECOInfra
import ECOProbe
import LarkAccountInterface
import LarkFoundation
import LarkLocalizations
import LarkSetting
import LarkSplitViewController
import LarkSuspendable
import LarkUIKit
import LarkWebViewContainer
import SnapKit
import UniverseDesignColor
import UIKit
import LarkMonitor
import UniverseDesignTheme
import LarkTraitCollection
import LarkOPInterface
import WebKit
import LarkQuickLaunchBar

import OPFoundation

public let LKBrowserIdentifier = "LKBrowserIdentifier"
/// ViewController LifeCycle
public extension WebBrowser {
    func createWebView() -> LarkWebView {
        let createStartTime = Date().timeIntervalSince1970
        configuration.webviewConfiguration.allowsInlineMediaPlayback = true
        // websiteDataStore需要在processPool前初始化，否则cookie不会sync成功
        configuration.webviewConfiguration.websiteDataStore = configuration.shouldNonPersistent ? WKWebsiteDataStore.nonPersistent() : WKWebsiteDataStore.default()
        configuration.webviewConfiguration.processPool = Self.defaultWKProcessPool
        
        // 注入User JS
        configuration.webviewConfiguration.userContentController.addUserScript(WKUserScript(
            source: JSInjection.viewActive(active: true) + JSInjection.currentPlayer,
            injectionTime: .atDocumentStart,
            forMainFrameOnly: true
        ))
        //移动端文件加密，禁止长按链接或图片时显示默认的弹出菜单（禁止保存图片）
        if FSCrypto.isCryptoInterceptEnable(type: .webTouchCallout) {
            let injectJS = "document.documentElement.style.webkitTouchCallout='none';"
            configuration.webviewConfiguration.userContentController.addUserScript(WKUserScript(
                source: injectJS,
                injectionTime: .atDocumentEnd,
                forMainFrameOnly: true
            ))
            Self.logger.info("WebBrowser disable webview long press while disk encrypted")
        }
        LKWebViewHelper.setConfiguration(configuration, withQueryApi: firstLoadURL)
        
        // 无痕模式下，也不能同步cookie
        configuration.isAutoSyncCookie = configuration.isAutoSyncCookie && !configuration.shouldNonPersistent
        let config: LarkWebViewConfig
        if Self.enableHybridMonitor {
            let builder = LarkWebViewConfigBuilder()
            if let initTrace = configuration.initTrace {
                builder.setInitTrace(initTrace: initTrace)
            }
            config = builder
                .setWebViewConfig(configuration.webviewConfiguration)
                .setMonitorConfig(fetchMonitorConfig())
                .build(
                    bizType: configuration.webBizType,
                    isAutoSyncCookie: configuration.isAutoSyncCookie,
                    secLinkEnable: configuration.secLinkEnable,
                    performanceTimingEnable: true,
                    advancedMonitorInfoEnable: true //  已经和Ecosystem- infra同学确认，网页场景可以使用advancedMonitorInfo
                )
        } else {
        let builder = LarkWebViewConfigBuilder()
        if let initTrace = configuration.initTrace {
            builder.setInitTrace(initTrace: initTrace)
        }
        config = builder
            .setWebViewConfig(configuration.webviewConfiguration)
            .build(
                bizType: configuration.webBizType,
                isAutoSyncCookie: configuration.isAutoSyncCookie,
                secLinkEnable: configuration.secLinkEnable,
                performanceTimingEnable: true,
                advancedMonitorInfoEnable: true //  已经和Ecosystem- infra同学确认，网页场景可以使用advancedMonitorInfo
            )
        }
        if let resourceInterceptConfiguration = configuration.resourceInterceptConfiguration {
            config.webViewConfig.registerIntercept(schemes: resourceInterceptConfiguration.0, delegate: resourceInterceptConfiguration.1)
        }
        config.webViewConfig.setURLSchemeHandler(InternalSchemeHandler(), forURLScheme: BrowserInternalScheme)
        config.startHandleTime = configuration.startHandleTime
        config.appId = configuration.appId
        config.scene = configuration.scene.rawValue
        #if DEBUG || BETA || ALPHA
        WebBrowserDebugItem.enbaleVConsoleIfInDebugEnvironment(userController:configuration.webviewConfiguration.userContentController )
        #endif
        
        let webView = LarkWebView(frame: .zero, config: config)

        if FeatureGatingManager.realTimeManager.featureGatingValue(with: FeatureGatingManager.Key(stringLiteral: "openplatform.offline.wkurlschemehandler")) {// user:global
            // 绑定 WebView 和 WebBrowser 之间的关系（用于在WK事件回调到Browser中时找回上下文）
            webView.wkWeakBindWebBrowser = self;
        }
        
        // webView 刚刚创建完成，但还没有进行其他初始化或添加到view中
        extensionManager.items.forEach { $0.lifecycleDelegate?.webviewDidCreated(self, webview: webView) }
        
        // 取消自动设置内边距， 在WebMetaExtensionItem.orientationDidChange中根据设备方向动态调整
        webView.scrollView.contentInsetAdjustmentBehavior = .never
        webView.uiDelegate = self
        webView.navigationDelegate = self
        // 支持手势前进/后退
        webView.allowsBackForwardNavigationGestures = true
        
        // 设置滚动事件代理
        webView.scrollView.delegate = self

        if configuration.isAutoSyncCookie, let passportService = try? resolver?.resolve(assert: PassportUserService.self), let session = passportService.user.sessionKey, !session.isEmpty {
            if LarkWebSettings.lkwEncryptLogEnabel {
                let httpCookies = LarkCookieManager.shared.buildLarkCookies(session: session, domains: nil)
                    .map { $1 }
                    .flatMap { $0 }
                var count = 0
                var startCookies = [Any]()
                var endCookies = [Any]()
                for cookie in httpCookies {
                    if startCookies.count == LarkWebView.cookieBatchCount {
                        let startCookiesString = String(describing: startCookies)
                        Self.logger.info("build cookie start sync Cookies to webview, infos:\(startCookiesString)")
                        startCookies.removeAll()
                    }
                    let maskedValue = cookie.value.lkw_cookie_mask()
                    let cookieInfo = [
                        "domain" : cookie.domain,
                        "path" : cookie.path,
                        "name" : cookie.name,
                        "value" : maskedValue,
                        "valuelength": String(describing: cookie.value.count),
                        "secure" : cookie.isSecure ? "true":"false",
                        "httpOnly" : cookie.isHTTPOnly ? "true":"false",
                        ]
                    startCookies.append(cookieInfo)
                    webView.configuration.websiteDataStore.httpCookieStore.setCookie(cookie) {
                        if endCookies.count == LarkWebView.cookieBatchCount {
                            let endCookiesString = String(describing: endCookies)
                            Self.logger.info("build cookie end sync Cookies to webview, infos:\(endCookiesString)")
                            endCookies.removeAll()
                        }
                        endCookies.append(cookieInfo)
                        count += 1
                        if count == httpCookies.count {
                            if !endCookies.isEmpty {
                                let endCookiesString = String(describing: endCookies)
                                Self.logger.info("build cookie end sync Cookies to webview, infos:\(endCookiesString)")
                            }
                            Self.logger.info("build cookie end sync Cookies to webview, count:\(count)")
                        }
                    }
                }
                if !startCookies.isEmpty {
                    let startCookiesString = String(describing: startCookies)
                    Self.logger.info("build cookie start sync Cookies to webview, infos:\(startCookiesString)")
                }
            } else {
                LarkCookieManager
                    .shared
                    .buildLarkCookies(
                        session: session,
                        domains: nil
                    )
                    .map { $1 }
                    .flatMap { $0 }
                    .forEach { cookie in
                        let maskedValue = cookie.value.lkw_cookie_mask()
                        Self.logger.info("start sync Cookies to webview, domain:\(cookie.domain), path:\(cookie.path), name:\(cookie.name), value:\(maskedValue), value length:\(cookie.value.count), isSecure:\(cookie.isSecure ? "true":"false")", additionalData: [:])
                        webView.configuration.websiteDataStore.httpCookieStore.setCookie(cookie) {
                            Self.logger.info("end sync Cookies to webview, domain:\(cookie.domain), path:\(cookie.path), name:\(cookie.name)", additionalData: [:])
                        }
                    }
            }
        }
        if enableDarkModeOptimization {
            webView.scrollView.backgroundColor = UDColor.bgBody
        }
        
        let createDuration = Date().timeIntervalSince1970 - createStartTime
        webView.recordTimeConsumingIn(phase: .webCreate, duration: createDuration)
        
            observeURLChange(webview: webView)
            setupUserAgent(webView: webView)
            setupBridge(webview: webView)
        
        if #available(iOS 16.4, *) {
            // 支持 套件统一浏览器 业务方配置 inspect
            if configuration.isInspectable {
                webView.isInspectable = true
            }
        }
        
        return webView
    }

    // 请注意，后边 Browser 就不会假设 viewDidLoad 才加载 URL 了，可能之前就加载了
    override func viewDidLoad() {
        super.viewDidLoad()
        extensionManager.viewDidLoadedFlag = true
        let startTime = NSDate().timeIntervalSince1970
        view.backgroundColor = UDColor.bgBody
        if let bar = self.launchBar {
            //深色模式优化，缩短commit之前背景显示为白色的时间
            if enableDarkModeOptimization {
                webView.isHidden = Self.isDarkMode()
            }
            view.addSubview(webview)
            var isCollapsed: Bool = false
            if let trait = self.rootWindow()?.traitCollection, let size = self.rootWindow()?.bounds.size {
                let newTrait = TraitCollectionKit.customTraitCollection(trait, size)
                isCollapsed = newTrait.horizontalSizeClass == .compact
            }
            if (Display.pad && isCollapsed) || Display.phone {
                Self.logger.info("display on iphone or split view on pad")
                view.addSubview(bar)
                bar.snp.makeConstraints() { make in
                    make.bottom.leading.trailing.equalToSuperview()
                }
                webview.snp.makeConstraints { make in
                    make.top.leading.trailing.equalToSuperview()
                    make.bottom.equalTo(bar.snp.top)
                }
            } else {
                Self.logger.info("display in full screen on pad")
                webview.snp.makeConstraints { make in
                    make.top.bottom.leading.trailing.equalToSuperview()
                }
            }
            self.updateWebViewConstraint()
        } else {
            // 不开launchBar的旧逻辑
            if enableDarkModeOptimization {
                let canOptimizeCommit = FeatureGatingManager.shared.featureGatingValue(with: FeatureGatingManager.Key(stringLiteral: "openplatform.web.optimizecommit.enable"))
                let isDarkMode = Self.isDarkMode()
                if (canOptimizeCommit) {
                    webView.isHidden = isDarkMode
                    view.addSubview(webview)
                    webview.frame = view.bounds
                }else{
                    webview.frame = view.bounds
                }
            } else {
                view.addSubview(webview)
                webview.snp.makeConstraints { make in
                    make.edges.equalToSuperview()
                }
            }
        }
        
        // TODO: luogantong, seclink 建议抽 extension item，一方业务不需要走这个
        safetyPrecheckIfNeeded()
        
        // 所有的 webview 相关的初始化工作都应当在这一行之前完成，这一行之后只能开始进行 laodURL
        extensionManager.items.forEach { $0.lifecycleDelegate?.viewDidLoad(browser: self) }

        // 需要注意 ，loadURL 需要在 viewDidLoad 插件通知发出去之后执行
        // 再次注意，viewDidLoad时，当且仅当设置了默认 URL 时才可以默认加载，不然假设有业务为了提高性能提前 load，这里就重复加载啦！
        // TODO: luogantong，同时也建议吧 SDP 抽一个 extension item，
        if configuration.autoLoadRequest {
            if let url = firstLoadURL {
                if self.handleMultiExternalOnOpen(url: url) {
                    Self.logger.info("exec handleMultiExternalOnOpen")
                } else {
                    //默认线上逻辑
                    Self.logger.info("exec loadURL")
                    loadURL(url, originRefererURL: originRefererURL)
                }
            } else {
                Self.logger.info("init browser with not url, don't load in viewdidload")
            }
        } else {
            Self.logger.info("configuration.autoLoadRequest is false")
        }
        let webContainerDidLoadDuration = Date().timeIntervalSince1970 - startTime
        webview.recordTimeConsumingIn(phase: .webContainerDidLoad, duration: webContainerDidLoadDuration)
    }

    private func safetyPrecheckIfNeeded(){
        if let url = self.firstLoadURL {
            self.webview.seclinkPrecheckUrl(url:url)
        }
    }
    
    static func isDarkMode() -> Bool {
        if #available(iOS 13.0, *), UDThemeManager.getRealUserInterfaceStyle() == .dark {
            return true
        } else {
            return false
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        /// iPad上RC视图切换时机通知
        if Display.pad {
            var isCollapsedNow = false
            if let trait = self.rootWindow()?.traitCollection, let size = self.rootWindow()?.bounds.size {
                let newTrait = TraitCollectionKit.customTraitCollection(trait, size)
                isCollapsedNow = newTrait.horizontalSizeClass == .compact
            }
            if isCollapsedNow != isCollapsed {
                self.notifyCollapseStateChanged(to: isCollapsedNow)
                Self.logger.info("on ipad, isCollapsed changed to \(isCollapsedNow).")
                isCollapsed = isCollapsedNow
            }
        }
        
        if let _ = self.launchBar {
            self.updateWebViewConstraint()
        } else {
            ///  不开launchBar的旧逻辑
            ///  避免有约束布局的时候还走下边的frame设置
            /// 横屏safearea适配开关，默认不开，开启后走5.14.0之前逻辑
            if FeatureGatingManager.shared.featureGatingValue(with: FeatureGatingManager.Key(stringLiteral: "openplatform.web.landscape.safearea.inset.disable")) {
                // 5.14.0之前老逻辑，稳定后可删除
                if enableDarkModeOptimization, webview.constraints.isEmpty {
                    webview.frame = view.bounds
                }
            } else {
                // @see updateWebViewConstraint()
                if enableDarkModeOptimization, webview.constraints.isEmpty {
                    if Display.phone {
                        switch UIApplication.shared.statusBarOrientation {
                        case .unknown, .portrait, .portraitUpsideDown:
                            let isEqual = CGRectEqualToRect(webView.frame, view.bounds)
                            if (!isEqual) {
                                webview.frame = view.bounds
                            }
                        case .landscapeLeft, .landscapeRight:
                            var leftOffSet = 0.0
                            var rightOffSet = 0.0
                            if let keyWindow = self.view.window {
                                leftOffSet = keyWindow.safeAreaInsets.left > 0 ? keyWindow.safeAreaInsets.left + 2 : 0
                                rightOffSet = keyWindow.safeAreaInsets.right > 0 ? keyWindow.safeAreaInsets.right + 2 : 0
                            }
                            let adjustFrame = CGRect(x:view.bounds.origin.x + leftOffSet, y:view.bounds.origin.y, width: view.bounds.size.width - leftOffSet-rightOffSet, height: view.bounds.size.height)
                            let isEqual = CGRectEqualToRect(webView.frame, adjustFrame)
                            if (!isEqual) {
                                webview.frame = adjustFrame
                            }
                        }
                    } else {
                        webview.frame = view.bounds
                    }
                }
            }
        }
        
        // 适配Pad应用内分栏时端内下载和预览视图大小
        if webDriveDownloadPreviewEnable() {
        updateDownloadViewConstraintsIfNeed()
        }
        
        extensionManager.items.forEach { $0.lifecycleDelegate?.viewDidLayoutSubviews() }
    }

    /// 设置webview customUserAgent
    private func setupUserAgent(webView: WKWebView) {
        //  Tips：目前此处存在历史债务，请设计套件统一UA逻辑，进行纠正
        //  参考文档：https://bytedance.feishu.cn/wiki/wikcneJ7z2DsmpLZ2fBiDNNDeUg
        // 如果上层设置了UA，则直接赋值
        // 否则对iPad设置默认UA
        // 历史诉求对接人： @quyiming
        if let customUserAgent = configuration.customUserAgent {
            webView.customUserAgent = customUserAgent
        } else {
            //LKBrowserIdentifier 和 configuration 中 webBrowwserID存在关联，随意修改会导致缓存匹配错误（离线包版本不一致）
            var customUserAgent = Utils.userAgent + " \(LKBrowserIdentifier)/\(configuration.webBrowserID)"
            if FeatureGatingManager.shared.featureGatingValue(with: FeatureGatingManager.Key(stringLiteral: "openplatform.web.custom.ua.downgrade")) {// user:global
                customUserAgent = Utils.userAgent
            }
            webView.customUserAgent = customUserAgent
        }
        Self.logger.info("customUserAgent: \(webView.customUserAgent)")
        
        // 如果有需要 append 的 UA，则补充在末尾
        if let appendUA = WebBrowser.nativeAppendUA {
            Self.logger.info("WebBrowser read appendUserAgent string at present: \(appendUA)")
            if let originUA = webView.customUserAgent {
                webView.customUserAgent = originUA + " " + appendUA
                Self.logger.info("append custom UserAgent: \(appendUA)")
            } else {
                webView.customUserAgent = appendUA
                Self.logger.info("set custom UserAgent: \(appendUA)")
            }
        } else {
            Self.logger.info("WebBrowser read appendUserAgent string at present: nil")
        }

    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        extensionManager.items.forEach { $0.lifecycleDelegate?.viewWillAppear(browser: self, animated: animated) }
        self.handlePopGestureRecognizer()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        extensionManager.items.forEach { $0.lifecycleDelegate?.viewDidAppear(browser: self, animated: animated) }
        if !FeatureGatingManager.shared.featureGatingValue(with: FeatureGatingManager.Key(stringLiteral: "openplatform.web.browser.larkappmonitor.disable")) {// user:global
            BDPowerLogManager.beginEvent(WebBrowser.powerLoggerEventName, params: [
                webBrowserIDKey : self.configuration.webBrowserID ?? "",
                traceIDKey : self.configuration.initTrace?.traceId ?? ""
            ])
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        extensionManager.items.forEach { $0.lifecycleDelegate?.viewWillDisappear(browser: self, animated: animated) }
        self.restorePopGestureRecognizer()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        extensionManager.items.forEach { $0.lifecycleDelegate?.viewDidDisappear(browser: self, animated: animated) }
    }
    
    ///处理横竖屏切换手势
    public override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        self.handlePopGestureRecognizer()
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        Self.logger.info("traitCollectionDidChange")
        extensionManager.items.forEach { $0.lifecycleDelegate?.traitCollectionDidChange(browser: self, previousTraitCollection: previousTraitCollection) }
    }

    private func handlePopGestureRecognizer() {
        if #available(iOS 16.0, *), self.iOS16LeftSlideFixEnable() {
            //横屏下禁止左侧手势滑动
            let statusBarStyle = UIApplication.shared.statusBarOrientation
            let isForbidden = statusBarStyle == .landscapeLeft || statusBarStyle == .landscapeRight
            Self.logger.info("iOS 16.0 & fix enable, handle popGesture, isForbidden: \(isForbidden)")
            self.navigationController?.interactivePopGestureRecognizer?.isEnabled = !isForbidden
        } else {
            Self.logger.info("Less than iOS 16.0 or fix disable, don't handle popGesture")
        }
    }
    
    private func restorePopGestureRecognizer() {
        if #available(iOS 16.0, *), self.iOS16LeftSlideFixEnable() {
            Self.logger.info("iOS 16.0 & fix enable, restore popGesture")
            self.navigationController?.interactivePopGestureRecognizer?.isEnabled = true
        } else {
            Self.logger.info("Less than iOS 16.0 or fix disable, don't restore popGesture")
        }
    }
    
    private func iOS16LeftSlideFixEnable() -> Bool {
        let fixEnable = !FeatureGatingManager.shared.featureGatingValue(with: FeatureGatingManager.Key(stringLiteral: "openplatform.webbrowser.ios16leftslide.fix.disable"))// user:global
        return fixEnable
    }
    
    override var prefersHomeIndicatorAutoHidden: Bool {
        return true
    }
}

extension WebBrowser {
    
    private static var _urlObservationKey: Void?
    
    /// 注意：本方法调用了 webview，务必在 viewDidLoad 之后再调用，否则可能导致异常
    private func observeURLChange(webview: LarkWebView) {
        // 监听 webview.url 变化，并更新 displayURL
        let observation = webview.observe(
            \.url,
            options: [.old, .new]
        ) { [weak self] (object, change) in
            guard let self = self,
                  let newValue = change.newValue,
                  let newURL = newValue else {
                return
            }
            if change.oldValue??.absoluteString == nil, self.firstLoadURL == nil {
                self.firstLoadURL = newURL
            }
            if LarkWebSettings.lkwEncryptLogEnabel {
                let traceId = self.configuration.initTrace?.traceId
                DispatchQueue.global().async {
                    let oldURLEncryptString = (change.oldValue != nil) ? OPEncryptUtils.webURLAES256Encrypt(content: String(describing: change.oldValue)) : "nil"
                    let newURLEncryptString = (change.newValue != nil) ? OPEncryptUtils.webURLAES256Encrypt(content: String(describing: change.newValue)) : "nil"
                    Self.logger.lkwlog(level: .info, "encrypt url changed from: \(oldURLEncryptString) to \(newURLEncryptString)", traceId: traceId)
                }
            } else {
                Self.logger.lkwlog(level: .info, "urlecoSafeURL changed from \(change.oldValue??.safeURLString ?? "") to \(newURL.safeURLString)")
            }
            //udpate lastest url
            self.browserLastestURL = newURL
            
            if self.isBusinessPluginsEnable, self.launchBar != nil {
                self.updateBusinessPlugins(for: newURL)
            }
            self.notifyURLChanged()
        }
            // 不需要强行和webview对齐，和browser对齐生命周期，参考导航栏item等
            urlObservation = observation
    }
    
    func updateBusinessPlugins(for newURL: URL) {
        self.imPluginForWebService?.destroyBarItems()
        self.docPluginForWebService?.destroyBarItems()
        
        self.imBarItemsMap = nil
        self.docBarItemsMap = nil
        
        self.imPluginForWebService = try? self.resolver?.resolve(type: ImPluginForWebProtocol.self) ?? nil
        self.docPluginForWebService = try? self.resolver?.resolve(type: DocPluginForWebProtocol.self) ?? nil
        
        if let imService = self.imPluginForWebService {
            imService.createBarItems(for: newURL, on: self) { [weak self](imBarItems) in
                guard self?.webview.url == newURL else {
                    Self.logger.info("im plugin cannot match latest url")
                    return
                }
                
                self?.imBarItemsMap = imBarItems
                self?.notifyBusinessPluginChanged()
            }
        }
        
        if let docService = self.docPluginForWebService {
            docService.createBarItems(for: newURL, on: self) { [weak self](docBarItems) in
                guard self?.webview.url == newURL else {
                    Self.logger.info("doc plugin cannot match latest url")
                    return
                }
                
                self?.docBarItemsMap = docBarItems
                self?.notifyBusinessPluginChanged()
            }
        }
    }
    
    func notifyBusinessPluginChanged() {
        extensionManager.items.forEach { $0.browserDelegate?.browser(self, didImBusinessPluginChanged: self.imBarItemsMap, didDocBusinessPluginChanged: self.docBarItemsMap) }
    }
    
    func notifyURLChanged() {
        extensionManager.items.forEach { $0.browserDelegate?.browser(self, didURLChanged: self.browserURL) }
    }
    
    func notifyHideMenuItemsChanged(hideMenuItems: Array<String>?) {
        extensionManager.items.forEach { $0.browserDelegate?.browser(self, didHideMenuItemsChanged: hideMenuItems) }
    }
    
    // @see viewDidLayoutSubviews
    func updateWebViewConstraint() {
        if Display.phone {
            if let bar = self.launchBar {
                guard WebMetaLaunchBarExtensionItem.isShowLaunchBarEnabled() else {
                    // TODO: 7.6 GA 稳定后删除
                    Self.logger.info("WebMetaLaunchBarExtensionItem.isShowLaunchBarEnabled() is false, use old method to update constraint.")
                    oldUpdateWebViewConstraint(bar: bar)
                    return
                }
                /// 适配横屏下 safearea
                var webviewLeftOffset = 0.0
                var webviewRightOffset = 0.0
                switch UIApplication.shared.statusBarOrientation {
                case .unknown, .portrait, .portraitUpsideDown:
                    Self.logger.info("iphone is in portrait direction, need to set webview width to superview.")
                case .landscapeLeft,.landscapeRight:
                    if let keyWindow = self.view.window {
                        webviewLeftOffset = keyWindow.safeAreaInsets.left > 0 ? keyWindow.safeAreaInsets.left + 2 : 0
                        webviewRightOffset = keyWindow.safeAreaInsets.right > 0 ? keyWindow.safeAreaInsets.right + 2 : 0
                    }
                    Self.logger.info("iphone is in landscape left or right, need to set webview width according to safearea.")
                }
                
                /// 适配开放能力配置的底部导航栏launchbar显隐
                let isShowBottomNavBar = resolve(WebMetaLaunchBarExtensionItem.self)?.isShowBottomNavBar ?? true
                let isLaunchBarNeedShow = (isShowBottomNavBar) &&  (!bar.isDescendant(of: view))
                let isLaunchBarNeedHide = (!isShowBottomNavBar) &&  (bar.isDescendant(of: view))
                Self.logger.info("in updateWebViewConstraint, WebMetaLaunchBarExtensionItem.isShowBottomNavBar is \(isShowBottomNavBar), bar is subview of browser.view is \(bar.isDescendant(of: view))")
                
                
                if isLaunchBarNeedShow {
                    view.addSubview(bar)
                    bar.snp.makeConstraints() { make in
                        make.bottom.leading.trailing.equalToSuperview()
                    }
                    webview.snp.remakeConstraints { make in
                        make.top.equalToSuperview()
                        make.leading.equalToSuperview().offset(webviewLeftOffset)
                        make.trailing.equalToSuperview().offset(-webviewRightOffset)
                        make.bottom.equalTo(bar.snp.top)
                    }
                    self.isWebLaunchBarEnable = true
                    Self.logger.info("(iphone, meta) showBottomNavBar changed to true, show web launch bar, set isWebLaunchBarEnable true.")
                    return
                }
                
                if isLaunchBarNeedHide {
                    bar.removeFromSuperview()
                    webview.snp.remakeConstraints { make in
                        make.top.bottom.equalToSuperview()
                        make.leading.equalToSuperview().offset(webviewLeftOffset)
                        make.trailing.equalToSuperview().offset(-webviewRightOffset)
                    }
                    self.isWebLaunchBarEnable = false
                    Self.logger.info("(iphone, meta) showBottomNavBar changed to false, remove web launch bar, set isWebLaunchBarEnable false")
                    return
                }
                
                if webview.frame.width != view.frame.width - webviewLeftOffset - webviewRightOffset {
                    Self.logger.info("iphone direction changed, need to reset webview width.")
                    webview.snp.updateConstraints() { make in
                        make.leading.equalToSuperview().offset(webviewLeftOffset)
                        make.trailing.equalToSuperview().offset(-webviewRightOffset)
                    }
                }
            } else {
                // 不开 LaunchBar 的旧逻辑
                switch UIApplication.shared.statusBarOrientation {
                case .unknown, .portrait, .portraitUpsideDown:
                    webview.snp.remakeConstraints { make in
                        make.edges.equalToSuperview()
                    }
                case .landscapeLeft,.landscapeRight:
                    var leftOffSet = 0.0
                    var rightOffSet = 0.0
                    if let keyWindow = self.view.window {
                        leftOffSet = keyWindow.safeAreaInsets.left > 0 ? keyWindow.safeAreaInsets.left + 2 : 0
                        rightOffSet = keyWindow.safeAreaInsets.right > 0 ? keyWindow.safeAreaInsets.right + 2 : 0
                    }
                    webview.snp.remakeConstraints { make in
                        make.top.bottom.equalToSuperview()
                        make.leading.equalToSuperview().offset(leftOffSet)
                        make.trailing.equalToSuperview().offset(-rightOffSet)
                    }
                }
            }
        } else {
            if let bar = self.launchBar {
                guard WebMetaLaunchBarExtensionItem.isShowLaunchBarEnabled() else {
                    // TODO: 7.6 GA 稳定后删除
                    Self.logger.info("WebMetaLaunchBarExtensionItem.isShowLaunchBarEnabled() is false, use old method to update constraint.")
                    oldUpdateWebViewConstraint(bar: bar)
                    return
                }
                /// pad 切换分屏模式(C视图)时才有底部Launchbar，全屏(R视图)时没有
                /// 适配开放能力配置的底部导航栏launchbar显隐
                let isShowBottomNavBar = resolve(WebMetaLaunchBarExtensionItem.self)?.isShowBottomNavBar ?? true
                let isLaunchBarNeedShow = isCollapsed && (isShowBottomNavBar) &&  (!bar.isDescendant(of: view))
                let isLaunchBarNeedHide = (!isCollapsed || !isShowBottomNavBar) &&  (bar.isDescendant(of: view))
                Self.logger.info("in updateWebViewConstraint, isCollapsed is \(isCollapsed), WebMetaLaunchBarExtensionItem.isShowBottomNavBar is \(isShowBottomNavBar), bar is subview of browser.view is \(bar.isDescendant(of: view))")
                
                if isLaunchBarNeedShow {
                    view.addSubview(bar)
                    bar.snp.makeConstraints() { make in
                        make.bottom.leading.trailing.equalToSuperview()
                    }
                    webview.snp.remakeConstraints { make in
                        make.top.leading.trailing.equalToSuperview()
                        make.bottom.equalTo(bar.snp.top)
                    }
                    self.isWebLaunchBarEnable = true
                    Self.logger.info("ipad changed to split view and showBottomNavBar is true, show web launch bar, set isWebLaunchBarEnable true.")
                    return
                }
                
                if isLaunchBarNeedHide {
                    bar.removeFromSuperview()
                    webview.snp.remakeConstraints { make in
                        make.top.bottom.leading.trailing.equalToSuperview()
                    }
                    self.isWebLaunchBarEnable = false
                    Self.logger.info("ipad changed to full screen or showBottomNavBar is false, remove web launch bar, set isWebLaunchBarEnable false")
                }
            } else {
                // 不开 LaunchBar 的旧逻辑
                webview.snp.remakeConstraints { make in
                    make.edges.equalToSuperview()
                }
            }
        }
    }
    
    func notifyCollapseStateChanged(to state: Bool) {
        extensionManager.items.forEach { $0.browserDelegate?.browser(self, didCollapseStateChangedTo: state) }
    }
    // TODO: 7.6 GA 稳定后删除
    // 7.0之后，开启 LaunchBar 但还没有支持开放能力配置显隐的旧逻辑
    func oldUpdateWebViewConstraint(bar: QuickLaunchBar) {
        if Display.phone {
            switch UIApplication.shared.statusBarOrientation {
            case .unknown, .portrait, .portraitUpsideDown:
                //前置避免不必要的 webview 约束布局计算
                if self.webview.frame.width != self.view.frame.width {
                    self.webview.snp.updateConstraints { make in
                        make.leading.trailing.equalToSuperview()
                    }
                    Self.logger.info("iphone changed to portrait direction, set webview width to superview.")
                }
            case .landscapeLeft,.landscapeRight:
                var leftOffSet = 0.0
                var rightOffSet = 0.0
                if let keyWindow = self.view.window {
                    leftOffSet = keyWindow.safeAreaInsets.left > 0 ? keyWindow.safeAreaInsets.left + 2 : 0
                    rightOffSet = keyWindow.safeAreaInsets.right > 0 ? keyWindow.safeAreaInsets.right + 2 : 0
                }
                //前置避免不必要的 webview 约束布局计算
                if self.webview.frame.width != self.view.frame.width - leftOffSet - rightOffSet {
                    self.webview.snp.updateConstraints() { make in
                        make.leading.equalToSuperview().offset(leftOffSet)
                        make.trailing.equalToSuperview().offset(-rightOffSet)
                    }
                    Self.logger.info("iphone changed to landscape left or right, set webview width according to safearea.")
                }
            }
        } else {
            var isCollapsed: Bool = false
            if let trait = self.rootWindow()?.traitCollection, let size = self.rootWindow()?.bounds.size {
               let newTrait = TraitCollectionKit.customTraitCollection(trait, size)
               isCollapsed = newTrait.horizontalSizeClass == .compact
            }
            if isCollapsed, !bar.isDescendant(of: view) {
               view.addSubview(bar)
               bar.snp.makeConstraints() { make in
                   make.bottom.leading.trailing.equalToSuperview()
               }
               webview.snp.remakeConstraints { make in
                   make.top.leading.trailing.equalToSuperview()
                   make.bottom.equalTo(bar.snp.top)
               }
               self.isWebLaunchBarEnable = true
               Self.logger.info("ipad changed to split view, show web launch bar, set isWebLaunchBarEnable true.")
               self.notifyCollapseStateChanged(to: true)
            } else if !isCollapsed, bar.isDescendant(of: view) {
               bar.removeFromSuperview()
               webview.snp.remakeConstraints { make in
                   make.top.bottom.leading.trailing.equalToSuperview()
               }
               self.isWebLaunchBarEnable = false
               Self.logger.info("ipad changed to full screen, remove web launch bar, set isWebLaunchBarEnable false")
               self.notifyCollapseStateChanged(to: false)
            }
        }
    }
}

extension WebBrowser {
    fileprivate func fetchMonitorConfig() -> LarkWebViewMonitorConfig {
        guard let dict = ECOConfig.service().getDictionaryValue(for: "lark_web_enable_hybrid") else {
            return LarkWebViewMonitorConfig()
        }
        let enableMonitor = (dict["monitor_enable"] as? Bool) ?? false
        let enableInjectJS = (dict["injectJs_enable"] as? Bool) ?? false
        return LarkWebViewMonitorConfig(enableMonitor: enableMonitor, enableInjectJS: enableInjectJS)
    }
    
    fileprivate static var enableHybridMonitor: Bool = {
        FeatureGatingManager.shared.featureGatingValue(with: FeatureGatingManager.Key(stringLiteral: "openplatform.larkwebview.hybridmonitor.enable"))// user:global
    }()
}

extension WebBrowser {
    
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if let bar = self.launchBar, self.isUserDragged {
            bar.containerDidScroll(scrollView)
        }
    }

    public func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        self.isUserDragged = true
        if let bar = self.launchBar {
            bar.containerWillBeginDragging(scrollView)
        }
    }
}
