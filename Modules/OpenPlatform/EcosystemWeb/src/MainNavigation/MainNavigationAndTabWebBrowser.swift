//
//  MainNavigationAndTabWebBrowser.swift
//  EcosystemWeb
//
//  Created by 新竹路车神 on 2021/6/25.
//

import AnimatedTabBar
import ByteWebImage
import ECOInfra
import ECOProbe
import EENavigator
import LarkCompatible
import LarkContainer
import LarkExtensions
import LarkNavigation
import LarkOPInterface
import LarkSetting
import LarkTab
import LarkUIKit
import LarkWebViewContainer
import LKCommonsLogging
import OPWebApp
import RxRelay
import SnapKit
import UniverseDesignColor
import UniverseDesignEmpty
import UniverseDesignIcon
import UniverseDesignLoading
import UniverseDesignMenu
import UniverseDesignTheme
import WebBrowser
import WebKit

/// 主导航套件统一浏览器
final class MainNavigationAndTabWebBrowser: UIViewController, LarkNaviBarAbility, SetMainNavRightItemsProtocol {
    
    static let logger = Logger.ecosystemWebLog(MainNavigationAndTabWebBrowser.self, category: NSStringFromClass(MainNavigationAndTabWebBrowser.self))
    
    private lazy var advancedTabEffectEnable = FeatureGatingManager.shared.featureGatingValue(with: FeatureGatingManager.Key(stringLiteral: "openplatform.mainnavigationbrowser.advancedtabeffect.enable"))// user:global
    private lazy var enableMonitorReporter = FeatureGatingManager.shared.featureGatingValue(with: FeatureGatingManager.Key(stringLiteral: "openplatform.larkwebview.performance.report"))// user:global
    
    private let appID: String
    
    /// webApp使用Tab对象
    private var webappTab: Tab
    private let initTrace: OPTrace?
    private let startHandleTime: TimeInterval?
    private var loadingView: UIView?
    private var failView: UIView?
    
    private let resolver: Resolver
    
    /// 是否是定制主导航按钮模式
    public var customMainNavigationItemsMode = false
    
    /// 自定义的主导航按钮模型
    public var mainNavRightItemsParams: SetMainNavRightItemsParams? {
        didSet {
            if var items = mainNavRightItemsParams?.items {
                items.reverse()
                var rItems = [LarkNaviButtonType: SetMainNavRightItemsParams.SetMainNavRightItemsModelParams]()
                rItems[.second] = items.first
                rItems[.first] = items.count >= 2 ? items[1] : nil
                rItems[.search] = items.count >= 3 ? items[2] : nil
                rightItems = rItems
            } else {
                rightItems = nil
            }
        }
    }
    
    /// 主导航按钮对应数据模型
    var rightItems: [LarkNaviButtonType: SetMainNavRightItemsParams.SetMainNavRightItemsModelParams]?
    
    /// 网页应用性能指标上报服务
    @InjectedOptional var monitorService: WebAppMonitorProtocol?// user:global
    
    private var webBrowser: WebBrowser?
    
    // 外部传入最新的主导航标题，同时页面创建后也监听最新的网页应用tab标题，改变后刷新导航的标题
    private var webappNaviTitle: String
    
    init(
        appID: String,
        tab: Tab,
        webappNaviTitle: String,
        initTrace: OPTrace? = nil,
        startHandleTime: TimeInterval? = nil,
        resolver: Resolver
    ) {
        self.appID = appID
        webappTab = tab
        self.webappNaviTitle = webappNaviTitle
        self.initTrace = initTrace
        self.startHandleTime = startHandleTime
        self.resolver = resolver
        super.init(nibName: nil, bundle: nil)
    }
    
    public func reloadMainNavigationBar() {
        reloadNaviBar()
    }
    
    deinit {
        print("main navi browser deinit")
        NotificationCenter.default.removeObserver(self)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        fetchAppBrowser()
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(didTabNameChanged(notification:)),
                                               name: Tab.tabNameChangeNotification,
                                               object: nil)
    }
    // 动态物料需求会更新底部tab的标题，目前仅做了UI上的刷新，主导航通过变动通知判断如果是当前网页应用的标题，则刷新当前的主导航。
    @objc
    func didTabNameChanged(notification: Notification){
        let changedTab = notification.object as? Tab
        if let changedTab = changedTab, changedTab.appType == .webapp, changedTab.appid == webappTab.appid {
            let action = {
                self.webappNaviTitle = changedTab.tabName
                Self.logger.info("update main navi title from\(self.webappTab.tabName) to \(changedTab.tabName)")
                self.reloadNaviBar()
            }
            if Thread.isMainThread {
                action()
            } else {
                DispatchQueue.main.async {
                    action()
                }
            }
        }
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if FeatureGatingManager.shared.featureGatingValue(with: FeatureGatingManager.Key(stringLiteral: "openplatform.web.main_navigation_hidden_animated.disable")) {// user:global
            navigationController?.isNavigationBarHidden = true
        } else {
            navigationController?.setNavigationBarHidden(true, animated: animated)
        }
    }
    
    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        guard let webBrowser = webBrowser else { return }
        //  如果被配置到第一个Tab，UIApplication.shared.statusBarFrame.height会是0，所以这里要update一下
        if advancedTabEffectEnable {
        webBrowser.view.snp.updateConstraints { make in
            make.top.equalToSuperview().offset(UIApplication.shared.statusBarFrame.height + naviHeight)
        }
        if !Display.pad {
        webBrowser.webview.scrollView.contentInset = .init(top: 0, left: 0, bottom: animatedTabBarController?.tabbarHeight ?? 0, right: 0)
        }
        } else {
            webBrowser.view.snp.updateConstraints { make in
                make.top.equalToSuperview().offset(UIApplication.shared.statusBarFrame.height + naviHeight)
                if Display.pad {
                    make.bottom.equalToSuperview()
                } else {
                    make.bottom.equalToSuperview().offset(-(animatedTabBarController?.tabbarHeight ?? 0))
                }
            }
        }
    }
    
    public override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        guard let webBrowser = webBrowser else { return }
        if enableMonitorReporter {
            monitorService?.checkBlank(appId: appID, webView: webBrowser.webview)
            monitorService?.flushEvent(webView: webBrowser.webview, clear: false)
        }
    }
    
    private func showLoadingView() {
        if loadingView != nil {
            loadingView?.removeFromSuperview()
            loadingView = nil
        }
        let loading = UDLoading.loadingImageView()
        loadingView = loading
        view.addSubview(loading)
        loading.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
    }
    
    private func removeLoadingView() {
        loadingView?.removeFromSuperview()
        loadingView = nil
    }
    
    /// 解析URL定制运行模式
    /// - Parameter url: 进入的URL对象
    private func parse(url: URL) {
        let queryDict = url.lf.queryDictionary
        guard let cusNaviBarItems = queryDict["lark_custom_main_nav_right_items"]?.lowercased() else { return }
        guard cusNaviBarItems == "true" else { return }
        customMainNavigationItemsMode = true
        
        if WebMetaNavigationBarExtensionItem.isURLCustomQueryMonitorEnabled() {
            OPMonitor("openplatform_web_container_URLCustomQuery")
                .addCategoryValue("name", "lark_custom_main_nav_right_items")
                .addCategoryValue("content", cusNaviBarItems)
                .addCategoryValue("url", url.safeURLString)
                .addCategoryValue("appId", appID)
                .setPlatform([.tea, .slardar])
                .tracing(initTrace)
                .flush()
        }
    }
    
    private var canGoBackObservation: NSKeyValueObservation?
    private var canGoForwardObservation: NSKeyValueObservation?
    private func setupObservable(browser: WebBrowser) {
        canGoBackObservation = browser
            .webview
            .observe(
                \.canGoBack,
                options: [.old, .new],
                changeHandler: { [weak self] (webView, change) in
                    guard let `self` = self else { return }
                    Self.logger.info("canGoBack state change from \(change.oldValue) to \(change.newValue)")
                    if let canGoBack = change.newValue {
                        self.reloadNaviBar()
                    }
                }
            )
        canGoForwardObservation = browser
            .webview
            .observe(
                \.canGoForward,
                options: [.old, .new],
                changeHandler: { [weak self] (webView, change) in
                    guard let `self` = self else { return }
                    Self.logger.info("canGoForward state change from \(change.oldValue) to \(change.newValue)")
                    if let canGoForward = change.newValue {
                        self.reloadNaviBar()
                    }
                }
            )
    }
}

// MARK: 接入主Tab
extension MainNavigationAndTabWebBrowser: TabRootViewController {
    public var tab: Tab { webappTab }
    
    public var controller: UIViewController { self }
    
    public var deamon: Bool { true }
}

// MARK: 注入主导航能力
extension MainNavigationAndTabWebBrowser: LarkNaviBarDataSource {
    public var titleText: BehaviorRelay<String> { BehaviorRelay(value: webappNaviTitle) }
    
    public var isNaviBarEnabled: Bool { true }
    
    public var isDrawerEnabled: Bool { true }
    
    public var isDefaultSearchButtonDisabled: Bool { true }
    
    public func larkNaviBar(userDefinedButtonOf type: LarkNaviButtonType) -> UIButton? {
        guard let webBrowser = webBrowser else { return nil }
        if customMainNavigationItemsMode {
            guard let rightItems = rightItems else {
                Self.logger.info("customMainNavigationItemsMode = true, but no rightItems")
                return nil
            }
            guard let item = rightItems[type] else {
                Self.logger.info("customMainNavigationItemsMode = true, but has no item for \(type)")
                return nil
            }
            let button = MainNavRightItemButton(item: item)
            button.bt.setImage(URL(string: item.iconURL), for: .normal, completionHandler: { [weak button] res in
                switch res {
                case .success(let res):
                    if FeatureGatingManager.shared.featureGatingValue(with: FeatureGatingManager.Key(stringLiteral: "web.set_main_nav_right_items.tintcolor_fix.disable")) {// user:global
                        if let color = LarkNaviBar.viContentColor,
                            let image = res.image?.ud.withTintColor(LarkNaviBar.buttonTintColor),
                           let button = button {
                            button.setImage(image, for: .normal)
                        }
                    } else {
                        // buttonTintColor内部会断vicontentcolor是否配置，如果配置了优先使用vicontentcolor
                        if let image = res.image?.ud.withTintColor(LarkNaviBar.buttonTintColor),
                           let button = button {
                            button.setImage(image, for: .normal)
                        }
                    }
                    Self.logger.info("load image success, \(res.image)")
                case .failure(let err):
                    Self.logger.error("load image error", error: err)
                }
            })
            button.addTarget(self, action: #selector(clickMainNavRightItemButton(button:)), for: .touchUpInside)
            return button
        }
        let button = UIButton()
        switch type {
        case .search:
            // 后退按钮，需要根据网页状态更新灰显/可操作
            button.setImage(UDIcon.leftOutlined, for: .normal)
            if !webBrowser.webView.canGoBack {
                // 显示为灰显状态（需要通过Button方式设置）
                button.setImage(UDIcon.leftOutlined, for: .disabled)
                button.isEnabled = false
            }
            button.addTarget(self, action: #selector(goBack), for: .touchUpInside)
        case .first:
            // 前进按钮，需要根据网页状态更新灰显/可操作
            button.setImage(UDIcon.rightOutlined, for: .normal)
            if !webBrowser.webView.canGoForward {
                button.setImage(UDIcon.rightOutlined, for: .disabled)
                button.isEnabled = false
            }
            button.addTarget(self, action: #selector(goForward), for: .touchUpInside)
        case .second:
            button.setImage(UDIcon.moreOutlined, for: .normal)
            button.addTarget(self, action: #selector(showPopupMenu(button:)), for: .touchUpInside)
        }
        return button
    }
    
    @objc private func clickMainNavRightItemButton(button: MainNavRightItemButton) {
        guard let webBrowser = webBrowser else { return }
        do {
            webBrowser.webview.evaluateJavaScript(try LarkWebViewBridge.buildCallBackJavaScriptString(callbackID: "onMainNavRightItemClick", params: ["id": button.item.id], extra: nil, type: .continued))
        } catch {
            Self.logger.error("clickMainNavRightItemButton error", error: error)
        }
    }
    
    @objc private func goBack() {
        guard let webBrowser = webBrowser else { return }
        
        if !FeatureGatingManager.shared.featureGatingValue(with: .init(stringLiteral: "openplatform.web.leaveconfirm.disable")), webBrowser.resolve(LeaveConfirmExtensionItem.self)?.showConfirmIfNeeded(browser: webBrowser, effect: .back, callback: { [weak webBrowser] (confirm) in// user:global
            if confirm {
                webBrowser?.webview.goBack()
            }
        }) == true {
            // 退出前确认
            Self.logger.info("goBack showConfirm")
        } else {
            // 直接退出
            webBrowser.webview.goBack()
        }
    }
    @objc private func goForward() {
        guard let webBrowser = webBrowser else { return }
        webBrowser.webView.goForward()
    }

    @objc private func showPopupMenu(button: UIButton) {
        guard let webBrowser = webBrowser else { return }
        let models = webBrowser.resolve(WebMenuExtensionItem.self)?.meunItemModels
        var actions = [UDMenuAction]()
        if webBrowser.isWebAppForCurrentWebpage {
            //  添加常用
            if let appCommonAppModel = models?["commonApp"] {
                var image = appCommonAppModel.imageModel.image(for: .iPhoneLark, status: .normal)
                if #available(iOS 13.0, *) {
                    image = image.withTintColor(UIColor.ud.iconN1, renderingMode: .alwaysTemplate)
                }
                let actionAppCommonApp = UDMenuAction(title: appCommonAppModel.title, icon: image) {
                    appCommonAppModel.action(appCommonAppModel.itemIdentifier)
                }
                actions.append(actionAppCommonApp)
            }
            //  机器人
            if let botModel = models?["bot"] ?? models?["botNoRespond"] {
                var image = botModel.imageModel.image(for: .iPhoneLark, status: .normal)
                if #available(iOS 13.0, *) {
                    image = image.withTintColor(UIColor.ud.iconN1, renderingMode: .alwaysTemplate)
                }
                let actionBot = UDMenuAction(title: botModel.title, icon: image) {
                    botModel.action(botModel.itemIdentifier)
                }
                actions.append(actionBot)
            }
            // 查找内容
            if let searchModel = models?[WebSearchMenuPlugin.menuIdentifier] {
                var image = searchModel.imageModel.image(for: .iPhoneLark, status: .normal)
                if #available(iOS 13.0, *) {
                    image = image.withTintColor(UIColor.ud.iconN1, renderingMode: .alwaysTemplate)
                }
                let actionSerch = UDMenuAction(title: searchModel.title, icon: image) {
                    searchModel.action(searchModel.itemIdentifier)
                }
                actions.append(actionSerch)
            }
            //  刷新
            var image = UDIcon.refreshOutlined
            if #available(iOS 13.0, *) {
                image = image.withTintColor(UIColor.ud.iconN1, renderingMode: .alwaysTemplate)
            }
            let actionRefresh = UDMenuAction(title: BundleI18n.EcosystemWeb.Lark_Legacy_WebRefresh, icon: image) { [weak self] in
                self?.webBrowser?.reload()
                Self.logger.info("click menu item: reload")
            }
            actions.append(actionRefresh)
            
            // about
            if let aboutModel = models?["about"] {
                var image = aboutModel.imageModel.image(for: .iPhoneLark, status: .normal)
                if #available(iOS 13.0, *) {
                    image = image.withTintColor(UIColor.ud.iconN1, renderingMode: .alwaysTemplate)
                }
                let actionAbout = UDMenuAction(title: aboutModel.title, icon: image) {
                    aboutModel.action(aboutModel.itemIdentifier)
                }
                actions.append(actionAbout)
            }
            
        } else {
            // 查找内容
            if let searchModel = models?[WebSearchMenuPlugin.menuIdentifier] {
                var image = searchModel.imageModel.image(for: .iPhoneLark, status: .normal)
                if #available(iOS 13.0, *) {
                    image = image.withTintColor(UIColor.ud.iconN1, renderingMode: .alwaysTemplate)
                }
                let actionSerch = UDMenuAction(title: searchModel.title, icon: image) {
                    searchModel.action(searchModel.itemIdentifier)
                }
                actions.append(actionSerch)
            }
            //  刷新
            var image = UDIcon.refreshOutlined
            if #available(iOS 13.0, *) {
                image = image.withTintColor(UIColor.ud.iconN1, renderingMode: .alwaysTemplate)
            }
            let actionRefresh = UDMenuAction(title: BundleI18n.EcosystemWeb.Lark_Legacy_WebRefresh, icon: image) { [weak self] in
                webBrowser.webview.reload()
                webBrowser.reload()
                Self.logger.info("click menu item: reload")
            }
            actions.append(actionRefresh)
        }
        
        var style = UDMenuStyleConfig.defaultConfig()
        style.menuMaxWidth = webBrowser.view.frame.width // 设置最大宽度，UDMenu 没有开 cell 自适应，最大不超过 browser 宽度
        let menu = UDMenu(actions: actions, style: style)
        menu.showMenu(sourceView: button, sourceVC: self)
        WebBrowser.logger.info("present menu, currentUrl.safeURLString: \(webBrowser.browserURL?.safeURLString)")
    }
    
    public func larkNaviBar(userDefinedColorOf type: LarkNaviButtonType, state: UIControl.State) -> UIColor? {
        if let color = LarkNaviBar.viContentColor {
            // 如果定制了 KA 主题色，就统一使用指定颜色
            switch state {
            case .disabled:
                return LarkNaviBar.buttonTintColor.withAlphaComponent(0.5)
            case .normal:
                return LarkNaviBar.buttonTintColor
            default:
                return LarkNaviBar.buttonTintColor
            }
        }
        switch state {
        case .disabled:
            return UIColor.ud.iconDisabled
        case .normal:
            return UIColor.ud.iconN1
        default:
            return nil
        }
    }
}

extension MainNavigationAndTabWebBrowser: LarkNaviBarDelegate {
}

// MARK: 注入主 Tab 能力
extension MainNavigationAndTabWebBrowser: TabbarItemTapProtocol {
    public func onTabbarItemTap(_ isSameTab: Bool) {
        if !isSameTab {
            //  崩溃重试触发
            webBrowser?.resolve(TerminateReloadExtensionItem.self)?.backgroundToForeground()
        }
    }
}

// MARK: Load Browser
extension MainNavigationAndTabWebBrowser {
    private func fetchAppBrowser() {
        showLoadingView()
        WebAppIntegratedSoftwareDevelopmentKit.fetchWebAppBrowser(appID: appID, initTrace: initTrace, startHandleTime: startHandleTime, scene: .mainTab, fromScene: .mainTab, fromSceneReport: .mainTab) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let browser):
                self.removeLoadingView()
                self.webBrowser = browser
                browser.resolver = self.resolver
                browser.isNavigationBarHidden = true
                self.registerExtensionItems(browser: browser)
                self.setupObservable(browser: browser)
                self.setupViewsAndMakeConstraints(browser: browser)
                if let u = browser.browserURL {
                    self.parse(url: u)
                }
                self.reloadNaviBar()
            case .failure(let error):
                self.removeLoadingView()
                if let ope = error as? OPError, let errorExTypeValue = ope.userInfo["errorExType"] as? Int, errorExTypeValue == OPWebAppErrorType.verisonCompatible.rawValue {
                    self.showFailView(error: nil)
                } else {
                    self.showFailView(error: error)
                }
            }
        }
    }
    private func setupViewsAndMakeConstraints(browser: WebBrowser) {
        addChild(browser)
        view.addSubview(browser.view)
        if advancedTabEffectEnable {
            browser.view.snp.makeConstraints { make in
                make.bottom.left.right.equalToSuperview()
                make.top.equalToSuperview().offset(UIApplication.shared.statusBarFrame.height + naviHeight)
            }
            if !Display.pad {
                browser.webview.scrollView.contentInset = .init(top: 0, left: 0, bottom: animatedTabBarController?.tabbarHeight ?? 0, right: 0)
            }
        } else {
            browser.view.snp.makeConstraints { make in
                make.left.right.equalToSuperview()
                make.top.equalToSuperview().offset(UIApplication.shared.statusBarFrame.height + naviHeight)
                if Display.pad {
                    make.bottom.equalToSuperview()
                } else {
                    make.bottom.equalToSuperview().offset(-(animatedTabBarController?.tabbarHeight ?? 0))
                }
            }
        }
    }
    private func registerExtensionItems(browser: WebBrowser) {
        do {
            try browser.register(item: MonitorExtensionItem())
            try browser.register(item: MemoryLeakExtensionItem())
            try browser.register(item: TerminateReloadExtensionItem(browser: browser))
            try browser.register(item: ProgressViewExtensionItem())
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
            try browser.register(item: NativeComponentExtensionItem())
            if Display.pad {
                try browser.register(item: PadExtensionItem(browser: browser))
            }
            try browser.register(item: WebMetaLegacyExtensionItem())
            try browser.register(item: WebAppExtensionItem(browser: browser, webAppInfo: WebAppInfo(id: appID)))
            if !FeatureGatingManager.shared.featureGatingValue(with: .init(stringLiteral: "openplatform.web.leaveconfirm.disable")) {// user:global
            try browser.register(item: LeaveConfirmExtensionItem())
            }
            if WebBrowser.isDynamicNetStatusEnabled() {
                try browser.register(item: NetStatusExtenstionItem(browser: browser))
            }
            if WebTextSizeMenuPlugin.featureEnabled {
                try browser.register(item: WebTextSizeExtensionItem(browser: browser))
            }
            try browser.register(item: WebInlineAIExtensionItem(browser: browser))
            if let searchItem = WebSearchExtensionItem(browser: browser) {
                try browser.register(item: searchItem)
            }
        } catch {
            Self.logger.error("registerExtensionItems error", error: error)
        }
    }
    private func showFailView(error: Error?) {
        if failView != nil {
            failView?.removeFromSuperview()
            failView = nil
        }
        let fail = createFailView(error: error)
        failView = fail
        view.addSubview(fail)
        fail.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    private func createFailView(error: Error?) -> UIView {
        let bgview = UIView()
        bgview.backgroundColor = UIColor.ud.bgBody
        var des: UniverseDesignEmpty.UDEmptyConfig.Description?
        if let err = error as? NSError {
            des = .init(descriptionText: BundleI18n.EcosystemWeb.OpenPlatform_AppErrPage_PageLoadFailedErrDesc(err.domain, err.code))
        } else {
            des = .init(descriptionText: BundleI18n.EcosystemWeb.OpenPlatform_GadgetErr_ClientVerTooLow)
        }
        var primaryButtonConfig: (String?, (UIButton) -> Void)?
        if error != nil {
            primaryButtonConfig = (BundleI18n.EcosystemWeb.Lark_Legacy_WebRefresh, { [weak self] (_) in
                guard let self = self else { return }
                self.retryButtonTap()
            })
        }
        let empty = UDEmpty(
            config: .init(
                title: .init(titleText: BundleI18n.EcosystemWeb.loading_failed),
                description: des,
                type: .loadingFailure,
                primaryButtonConfig: primaryButtonConfig
            )
        )
        bgview.addSubview(empty)
        empty.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.left.right.equalToSuperview()
        }
        return bgview
    }
    private func retryButtonTap() {
        failView?.removeFromSuperview()
        failView = nil
        fetchAppBrowser()
    }
}
