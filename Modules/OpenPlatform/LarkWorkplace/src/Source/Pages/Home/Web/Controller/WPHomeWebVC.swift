//
//  WPHomeWebVC.swift
//  LarkWorkplace
//
//  Created by zhysan on 2021/12/14.
//

// 文件过长，注意精简
// swiftlint:disable file_length

import UIKit
import Swinject
import RxRelay
import RxSwift
import SnapKit
import LarkUIKit
import ECOInfra
import EcosystemWeb
import WebBrowser
import ByteWebImage
import LarkWebViewContainer
import LarkNavigation
import UniverseDesignIcon
import UniverseDesignMenu
import UniverseDesignLoading
import UniverseDesignEmpty
import OPWebApp
import LarkSetting
import LKCommonsLogging
import LarkContainer
import LarkSetting

final class WPHomeWebVC: WPBaseViewController, SetMainNavRightItemsProtocol {
    static let logger = Logger.log(WPHomeWebVC.self)

    private let context: WorkplaceContext
    private(set) var initData: WPHomeVCInitData.Web
    private weak var rootDelegate: WPHomeRootVCProtocol?
    
    private let resolver: UserResolver?

    private var webBrowser: WebBrowser?

    private var webBrowserTopConstraint: Constraint?

    private var canGoBackObservation: NSKeyValueObservation?

    private var canGoForwardObservation: NSKeyValueObservation?

    private var webviewLoadStartTime = Date().timeIntervalSince1970

    private var firstLoad: Bool = true

    private var loadingView: UIView?
    private var failView: UIView?

    private let badgeAPI: BadgeAPI
    private let badgeService: WorkplaceBadgeService

    private var enableWKURLSchemaHandler: Bool {
        return context.configService.fgValue(for: .enableWKURLSchemaHandler, realTime: true)
    }
    private var enableSetMainNavi: Bool {
        return context.configService.fgValue(for: .enableSetMainNavi, realTime: true)
    }
    private var disableLeaveConfirm: Bool {
        return context.configService.fgValue(for: .disableLeaveConfirm)
    }
    private var enableAdvancedTabEffect: Bool {
        return context.configService.fgValue(for: .enableAdvancedTabEffect, realTime: true)
    }

    private let disposeBag = DisposeBag()
    
    var path: String?
    
    var queryItems: [URLQueryItem]?

    init(
        resolver: UserResolver?,
        context: WorkplaceContext,
        rootDelegate: WPHomeRootVCProtocol,
        initData: WPHomeVCInitData.Web,
        path: String?,
        queryItems: [URLQueryItem]?,
        badgeAPI: BadgeAPI,
        badgeService: WorkplaceBadgeService
    ) {
        self.resolver = resolver
        self.context = context
        self.rootDelegate = rootDelegate
        self.initData = initData
        self.path = path
        self.queryItems = queryItems
        self.badgeAPI = badgeAPI
        self.badgeService = badgeService
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - override

    override func viewDidLoad() {
        super.viewDidLoad()

        context.monitor
            .start(.workplace_page_load)
            .setPortalType(.web)
            .flush()

        subviewsInit()
        if enableWKURLSchemaHandler {
            dataInit2()
        } else {
            dataInit()
        }
        refreshBadge()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        navigationController?.isNavigationBarHidden = true
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if let browser = webBrowser {
            setupBrowserLayout(browser)
        }

        rootDelegate?.tracker.trackPageExpose(
            .web(initData),
            templatePortalCount: rootDelegate?.templatePortalCount ?? 0
        )
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        reportPageStayDurationIfNeeded()
    }

    override func onPageWillResignActive() {
        super.onPageWillResignActive()

        guard isAppeared else {
            return
        }
        reportPageStayDurationIfNeeded()
    }

    override func onPageDidBecomeActive() {
        super.onPageDidBecomeActive()

        guard isAppeared else {
            return
        }
        rootDelegate?.tracker.trackPageExpose(
            .web(initData),
            templatePortalCount: rootDelegate?.templatePortalCount ?? 0
        )
    }
    
    func loadURL(with path: String, queryItems: [URLQueryItem]?) {
        guard let url = webBrowser?.browserURL,
              var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            Self.logger.error("web portal cannot load url with path, get current url component fail")
            return
        }
        
        urlComponents.path = path
        urlComponents.queryItems = queryItems
        guard let replacedUrl = urlComponents.url else {
            Self.logger.error("web portal cannot load url with path, urlComponents to url fail")
            return
        }
        Self.logger.info("start load url", additionalData: [
            "browser_is_empty" : "\(webBrowser == nil)"
        ])
        webBrowser?.loadURL(replacedUrl)
    }
    
    func isContentLoaded() -> Bool {
        return !firstLoad
    }

    // MARK: - private

    private func subviewsInit() {
        view.backgroundColor = UIColor.ud.bgBody
    }

    private func dataInit() {
        Self.logger.info("web portal loading start: \(initData)")

        onHomeLoadingStart()

        var appConfig = WebAppIntegratedConfiguration(
            openWebAppIntegratedScene: .workplacePortal,
            enableNavigationBarItems: false,
            enableWebAppIntegratedLoadUI: true
        )
        appConfig.startPath = path
        appConfig.startQueryItems = queryItems

        var bwsConfig = WebBrowserConfiguration()
        bwsConfig.scene = .workplacePortal
        bwsConfig.fromScene = .workplacePortal
        bwsConfig.fromSceneReport = .workplacePortal
        guard let browser = WebAppIntegratedSoftwareDevelopmentKit.createBrowser(
            with: initData.refAppId,
            webAppIntegratedConfiguration: appConfig, // webAppIntegratedConfiguration 首字母小写了
            webBrowserConfiguration: bwsConfig,
            webAppIntegratedLoadDelegate: self,
            resolver: self.resolver
        ) else {
            Self.logger.error("web portal invalid: \(initData)")
            onHomeLoadingFail(OPError.wp_internal("web portal create failed: \(initData)"))
            assertionFailure()
            return
        }

        webBrowser?.view.removeFromSuperview()
        webBrowser?.removeFromParent()
        webBrowser = nil

        webBrowser = browser

        addChild(browser)
        view.insertSubview(browser.view, belowSubview: stateView)

        browser.view.snp.makeConstraints { make in
            make.bottom.left.right.equalToSuperview()
            webBrowserTopConstraint = make.top.equalToSuperview().constraint
        }
        setupBrowserLayout(browser)
        setupBrowserObservation(browser)
        setupBrowserExtension(browser)
    }

    private func dataInit2() {
        onHomeLoadingStart()
        fetchBrowser()
    }
    private func fetchBrowser() {
        showLoadingView()
        let id = initData.refAppId
        // swiftlint:disable closure_body_length
        WebAppIntegratedSoftwareDevelopmentKit.fetchWebAppBrowser(
            appID: id,
            initTrace: nil,
            startHandleTime: nil,
            scene: .workplacePortal,
            fromScene: .workplacePortal,
            fromSceneReport: .workplacePortal,
            startPath: path,
            startQueryItems: queryItems
        ) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let browser):
                self.removeLoadingView()
                self.registerExtensionItems(browser: browser, appID: id)
                self.webBrowser?.view.removeFromSuperview()
                self.webBrowser?.removeFromParent()
                self.webBrowser = nil
                self.webBrowser = browser
                // addChild之后会触发webbrowser的viewdidload，加载当前网页，然后会触发URL changed，所以需要在加载之前添加监听
                // https://bytedance.feishu.cn/docx/JA7BdpX5soIzj3xeusOcouFcnoC
                if self.enableSetMainNavi {
                    self.setupBrowserObservation(browser)
                    self.setupBrowserExtension(browser)
                }
                self.addChild(browser)
                self.view.insertSubview(browser.view, belowSubview: self.stateView)
                browser.view.snp.makeConstraints { make in
                    make.bottom.left.right.equalToSuperview()
                    self.webBrowserTopConstraint = make.top.equalToSuperview().constraint
                }
                self.setupBrowserLayout(browser)
                if !self.enableSetMainNavi {
                    self.setupBrowserObservation(browser)
                    self.setupBrowserExtension(browser)
                }
            case .failure(let error):
                self.removeLoadingView()
                if let ope = error as? OPError,
                   let errorExTypeValue = ope.userInfo["errorExType"] as? Int,
                   errorExTypeValue == OPWebAppErrorType.verisonCompatible.rawValue {
                    self.showFailView(error: nil)
                } else {
                    self.showFailView(error: error)
                }
            }
        }
        // swiftlint:enable closure_body_length
    }
    private func registerExtensionItems(browser: WebBrowser, appID: String) {
        do {
            try browser.register(item: MonitorExtensionItem())
            try browser.register(item: MemoryLeakExtensionItem())
            try browser.register(item: TerminateReloadExtensionItem(browser: browser))
            try browser.register(item: ProgressViewExtensionItem())
            try browser.register(item: ErrorPageExtensionItem())
            try browser.register(item: WebInspectorExtensionItem(browser: browser))
            try browser.register(item: UniteRouterExtensionItem())
            try browser.register(item: MediaExtensionItem())
            try browser.register(item: EcosystemAPIExtensionItem())
            try browser.register(singleItem: EcosystemWebSingleExtensionItem())
            try browser.register(item: WebMenuExtensionItem(browser: browser))
            if browser.configuration.acceptWebMeta {
                try browser.register(item: WebMetaExtensionItem(browser: browser))
            }
            try browser.register(item: NativeComponentExtensionItem())
            if Display.pad {
                try browser.register(item: PadExtensionItem(browser: browser))
            }
            try browser.register(item: WebMetaLegacyExtensionItem())
            try browser.register(item: WebAppExtensionItem(browser: browser, webAppInfo: WebAppInfo(id: appID)))
            if !disableLeaveConfirm {
                try browser.register(item: LeaveConfirmExtensionItem())
            }
            if WebTextSizeMenuPlugin.featureEnabled {
                try browser.register(item: WebTextSizeExtensionItem(browser: browser))
            }
            try browser.register(item: WebInlineAIExtensionItem(browser: browser))
        } catch {
            Self.logger.error("registerExtensionItems error", error: error)
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
            des = .init(
                descriptionText: BundleI18n.LarkWorkplace.OpenPlatform_AppErrPage_PageLoadFailedErrDesc(
                    err.domain,
                    err.code
                )
            )
        } else {
            des = .init(descriptionText: BundleI18n.LarkWorkplace.OpenPlatform_GadgetErr_ClientVerTooLow)
        }
        var primaryButtonConfig: (String?, (UIButton) -> Void)?
        if error != nil {
            primaryButtonConfig = (BundleI18n.LarkWorkplace.Lark_Legacy_WebRefresh, { [weak self] (_) in
                guard let self = self else { return }
                self.retryButtonTap()
            })
        }
        let empty = UDEmpty(
            config: .init(
                title: .init(titleText: BundleI18n.LarkWorkplace.loading_failed),
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
        fetchBrowser()
    }

    private func reloadWebContent() {
        Self.logger.info("web portal reload content")
        webBrowser?.reload()
    }

    private func setupBrowserLayout(_ browser: WebBrowser) {
        if enableAdvancedTabEffect {
            browser.view.snp.makeConstraints { make in
                make.left.right.equalToSuperview()
                make.top.equalToSuperview().offset(UIApplication.shared.statusBarFrame.height + LarkNaviBarConsts.naviHeight)
                if Display.pad {
                    make.bottom.equalToSuperview()
                } else {
                    make.bottom.equalToSuperview().offset(-(self.rootDelegate?.botTabH ?? 0))
                }
            }
        } else {
        let inset = UIEdgeInsets(top: 0, left: 0, bottom: self.rootDelegate?.botTabH ?? 0, right: 0)
        browser.webview.scrollView.contentInset = inset
        }
    }

    private func setupBrowserObservation(_ browser: WebBrowser) {
        canGoBackObservation = browser
            .webview
            .observe(
                \.canGoBack,
                options: [.old, .new],
                changeHandler: { [weak self] (_, change) in
                    guard let `self` = self, let newValue = change.newValue else { return }
                    Self.logger.info("web portal canGoBack value change: \(newValue)")
                    self.rootDelegate?.rootReloadNaviBar()
                }
            )
        canGoForwardObservation = browser
            .webview
            .observe(
                \.canGoForward,
                options: [.old, .new],
                changeHandler: { [weak self] (_, change) in
                    guard let `self` = self, let newValue = change.newValue else { return }
                    Self.logger.info("web portal canGoForward value change: \(newValue)")
                    self.rootDelegate?.rootReloadNaviBar()
                }
            )
    }

    private func setupBrowserExtension(_ browser: WebBrowser) {
        do {
            let ext = WPWebExtension(delegate: self)
            try browser.register(item: ext)
        } catch {
            Self.logger.error("web portal ext register error: \(error)")
        }
    }

    // MARK: - SetMainNavRightItemsProtocol

    /// 是否是定制主导航按钮模式
    var customMainNavigationItemsMode = false {
        didSet {
            if enableSetMainNavi {
                Self.logger.info("web portal naviItemsMode did set: \(customMainNavigationItemsMode)")
                reloadMainNavigationBar()
            }
        }
    }

    /// 自定义的主导航按钮模型
    var mainNavRightItemsParams: SetMainNavRightItemsParams? {
        didSet {
            assert(Thread.isMainThread)
            Self.logger.info("web portal naviRightItemsParams did set", additionalData: [
                "items": "\(mainNavRightItemsParams?.items.map({ (id: $0.id, iconURL: $0.iconURL) }) ?? [])"
            ])
            if Thread.isMainThread {
                rootDelegate?.rootReloadNaviBar()
            } else {
                DispatchQueue.main.async { [weak self] in
                    self?.rootDelegate?.rootReloadNaviBar()
                }
            }
        }
    }

    func reloadMainNavigationBar() {
        if enableSetMainNavi {
            if Thread.isMainThread {
                rootDelegate?.rootReloadNaviBar()
            } else {
                DispatchQueue.main.async {
                    self.rootDelegate?.rootReloadNaviBar()
                }
            }
        } else {
            rootDelegate?.rootReloadNaviBar()
        }
    }
}

extension WPHomeWebVC: WebAppIntegratedLoadProtocol {
    // 工作台 H5 组件未加载 WebAppIntegratedLoadExtensionItem，该方法不会被调用，确认无意义后删除
    func webAppIntegratedDidFailLoad(browser: WebBrowser, error: Error) {
        guard browser == self.webBrowser else { return }

        Self.logger.error("web portal app load error: \(error)")

        onHomeLoadingFail(error)
    }
}

// MARK: - 工作台聚合的一些生命周期事件处理函数

extension WPHomeWebVC {
    private func onHomeLoadingStart() {
        webviewLoadStartTime = Date().timeIntervalSince1970
    }

    private func onHomeLoadingSuccess() {
        if firstLoad {
            let endTime = Date().timeIntervalSince1970
            context.monitor
                .start(.workplace_page_show_content)
                .setResultTypeSuccess()
                .setValue(initData.id, for: .portal_id)
                .setValue(initData.refAppId, for: .app_id)
                .setPortalType(.web)
                .setDuration((endTime - webviewLoadStartTime) * 1000)
                .flush()
        }
        firstLoad = false
    }

    private func onHomeLoadingFail(_ error: Error) {
        if firstLoad {
            let endTime = Date().timeIntervalSince1970
            context.monitor
                .start(.workplace_page_show_error)
                .setResultTypeFail()
                .setError(error)
                .setValue(initData.id, for: .portal_id)
                .setValue(initData.refAppId, for: .app_id)
                .setPortalType(.web)
                .setDuration((endTime - webviewLoadStartTime) * 1000)
                .flush()
        }
        firstLoad = false
    }
}

extension WPHomeWebVC: WebBrowserLifeCycleProtocol {
}

extension WPHomeWebVC: WebBrowserNavigationProtocol {
    // swiftlint:disable implicitly_unwrapped_optional
    func browser(_ browser: WebBrowser, didCommit navigation: WKNavigation!) {
        guard browser == webBrowser else { return }
        Self.logger.info("web portal did commit")
        self.rootDelegate?.reportFirstScreenDataReadyIfNeeded()
        onHomeLoadingSuccess()
    }

    func browser(_ browser: WebBrowser, didFinish navigation: WKNavigation!) {
        guard browser == webBrowser else { return }
        Self.logger.info("web portal load finish")
    }

    func browser(_ browser: WebBrowser, didFail navigation: WKNavigation!, withError error: Error) {
        guard browser == webBrowser else { return }
        Self.logger.error("web browser load fail: \(error)")
        handleBrowserLoadError(error: error)
    }

    func browser(
        _ browser: WebBrowser,
        didFailProvisionalNavigation navigation: WKNavigation!,
        withError error: Error
    ) {
        guard browser == webBrowser else { return }
        Self.logger.error("web browser provisional fail: \(error)")
        handleBrowserLoadError(error: error)
    }
    // swiftlint:enable implicitly_unwrapped_optional

    private func handleBrowserLoadError(error: Error) {
        guard WKNavigationDelegateFailFix.isFatalWebError(error: error) else { return }
        Self.logger.error("web portal fetal error: \(error)")
    }
}

extension WPHomeWebVC: WebBrowserProtocol {
    func browser(_ browser: WebBrowser, didURLChanged url: URL?) {
        Self.logger.info("web portal url did change: \(String(describing: url))")
        guard browser == webBrowser, let url = url else { return }
        let queryDict = url.lf.queryDictionary
        guard let cusNaviBarItems = queryDict["lark_custom_main_nav_right_items"]?.lowercased() else { return }
        guard cusNaviBarItems == "true" else { return }
        customMainNavigationItemsMode = true
    }
}

extension WPHomeWebVC: WPHomeChildVCProtocol {

    /// 更新门户信息
    func updateInitData(_ wrapper: WPHomeVCInitData) {
        guard case .web(let data) = wrapper, data.isSameCoreData(with: initData) else {
            Self.logger.error("update invalid init data")
            assertionFailure()
            return
        }
        initData = data
        rootDelegate?.rootReloadNaviBar()
    }

    // 切 Tab 事件
    func onTabbarItemTap(_ isSameTab: Bool) {
        if !isSameTab {
            //  崩溃重试触发
            webBrowser?.resolve(TerminateReloadExtensionItem.self)?.backgroundToForeground()
        }
    }

    // Title
    var titleText: BehaviorRelay<String> {
        let title = self.initData.name ?? BundleI18n.LarkWorkplace.OpenPlatform_AppCenter_Title
        return BehaviorRelay(value: title)
    }

    // 是否在加载中
    var isNaviBarLoading: BehaviorRelay<Bool> {
        return BehaviorRelay(value: false)
    }

    // 是否可以显示统一导航栏
    var isNaviBarEnabled: Bool {
        true
    }
    
    var bizScene: LarkNaviBarBizScene? {
        return .workplace
    }

    func topInsetDidChanged(height: CGFloat) {
        webBrowserTopConstraint?.update(offset: height)
    }

    // Web 容器
    func larkNaviBarV2(userDefinedColorOf type: LarkNaviButtonTypeV2, state: UIControl.State) -> UIColor? {
        // 根据是否定制 KA 主题色，设置不同的按钮颜色
        switch state {
        case .disabled:
            return LarkNaviBar.viContentColor == nil ? UIColor.ud.iconDisabled :
                LarkNaviBar.buttonTintColor.withAlphaComponent(0.5)
        case .normal:
            return LarkNaviBar.viContentColor == nil ? UIColor.ud.iconN1 :
                LarkNaviBar.buttonTintColor
        default:
            return nil
        }
    }

    // 提供Button，支持自定义四个
    // 方法过长，注意精简
    func larkNaviBarV2(userDefinedButtonOf type: LarkNaviButtonTypeV2) -> UIButton? {
        if customMainNavigationItemsMode {
            // 开发者使用 API 自定义了导航栏右侧按钮
            guard let items = mainNavRightItemsParams?.items, !items.isEmpty else {
                Self.logger.warn("web portal custom nav has empty btns!")
                return nil
            }
            let item: SetMainNavRightItemsParams.SetMainNavRightItemsModelParams?
            let count = items.count
            switch type {
            case .first:
                item = (count >= 3 ? items[count - 3] : nil)
            case .second:
                item = (count >= 2 ? items[count - 2] : nil)
            case .third:
                item = (count >= 1 ? items[count - 1] : nil)
            default:
                item = nil
            }
            guard let item = item else {
                return nil
            }
            Self.logger.info("web portal set custom nav btn: \(type), item: \(item.id)")
            let button = MainNavRightItemButton(item: item)
            button.bt.setImage(
                URL(string: item.iconURL),
                for: .normal,
                completionHandler: { res in
                    switch res {
                    case .success:
                        Self.logger.info("web portal load nav image success")
                    case .failure(let err):
                        Self.logger.error("web portal load nav image error", error: err)
                    }
                }
            )
            button.addTarget(self, action: #selector(clickMainNavRightItemButton(button:)), for: .touchUpInside)
            return button
        }

        // 默认三个按钮：前进、后退、更多

        switch type {
        case .first:
            // 「后退」按钮
            let button = UIButton()
            button.setImage(UDIcon.leftOutlined, for: .normal)
            if webBrowser?.webView.canGoBack != true {
                button.setImage(UDIcon.leftOutlined, for: .disabled)
                button.isEnabled = false
            }
            button.addTarget(self, action: #selector(goBack), for: .touchUpInside)
            return button
        case .second:
            // 「前进」按钮
            let button = UIButton()
            button.setImage(UDIcon.rightOutlined, for: .normal)
            if webBrowser?.webView.canGoForward != true {
                button.setImage(UDIcon.rightOutlined, for: .disabled)
                button.isEnabled = false
            }
            button.addTarget(self, action: #selector(goForward), for: .touchUpInside)
            return button
        case .third:
            // 「更多」按钮
            let button = UIButton()
            button.setImage(UDIcon.moreOutlined, for: .normal)
            button.addTarget(self, action: #selector(showPopupMenu(button:)), for: .touchUpInside)
            return button
        default:
            return nil
        }
    }
}

// MARK: - nav button actions

extension WPHomeWebVC {
    // 自定义按钮点击
    @objc private func clickMainNavRightItemButton(button: MainNavRightItemButton) {
        do {
            Self.logger.info("web portal clickMainNavRightItemButton id: \(button.item.id)")
            webBrowser?.webview.evaluateJavaScript(
                try LarkWebViewBridge.buildCallBackJavaScriptString(
                    callbackID: "onMainNavRightItemClick",
                    params: ["id": button.item.id],
                    extra: nil,
                    type: .continued
                )
            )
        } catch {
            Self.logger.error("web portal clickMainNavRightItemButton error", error: error)
        }
    }

    // 后退
    @objc private func goBack() {
        Self.logger.info("web portal goBack click!")

        let goBackHandler = { [weak self](confirm) in
            if confirm {
                self?.webBrowser?.webView.goBack()
            }
        }
        if !disableLeaveConfirm,
           let browser = webBrowser,
           let item = browser.resolve(LeaveConfirmExtensionItem.self),
           item.showConfirmIfNeeded(browser: browser, effect: .back, callback: goBackHandler) {
            Self.logger.info("goBack showConfirm")
        } else {
            webBrowser?.webview.goBack()
        }
    }

    // 前进
    @objc private func goForward() {
        Self.logger.info("web portal goForward click!")
        webBrowser?.webView.goForward()
    }

    // 更多
    @objc private func showPopupMenu(button: UIButton) {
        let models = webBrowser?.resolve(WebMenuExtensionItem.self)?.meunItemModels
        var actions = [UDMenuAction]()
        if webBrowser?.isWebAppForCurrentWebpage == true {
            Self.logger.info("web portal web app show more click!")
            //  刷新
            var image = UDIcon.refreshOutlined
            if #available(iOS 13.0, *) {
                image = image.withTintColor(UIColor.ud.iconN1, renderingMode: .alwaysTemplate)
            }
            let actionTitle = BundleI18n.LarkWorkplace.OpenPlatform_WebPortal_Refresh
            let actionRefresh = UDMenuAction(title: actionTitle, icon: image) { [weak self] in
                Self.logger.info("web portal click menu item: reload")
                self?.reloadWebContent()
            }
            actions.append(actionRefresh)

            //  机器人
            if let botModel = models?["bot"] ?? models?["botNoRespond"] {
                var image = botModel.imageModel.image(for: .iPhoneLark, status: .normal)
                if #available(iOS 13.0, *) {
                    image = image.withTintColor(UIColor.ud.iconN1, renderingMode: .alwaysTemplate)
                }
                let actionBot = UDMenuAction(title: BundleI18n.LarkWorkplace.Lark_AppCenter_EnterBot, icon: image) {
                    Self.logger.info("web portal click menu item: bot")
                    botModel.action(botModel.itemIdentifier)
                }
                actions.append(actionBot)
            }
        } else {
            Self.logger.info("web portal h5 show more click!")
            //  刷新
            var image = UDIcon.refreshOutlined
            if #available(iOS 13.0, *) {
                image = image.withTintColor(UIColor.ud.iconN1, renderingMode: .alwaysTemplate)
            }
            let actionTitle = BundleI18n.LarkWorkplace.OpenPlatform_WebPortal_Refresh
            let actionRefresh = UDMenuAction(title: actionTitle, icon: image) { [weak self] in
                Self.logger.info("web portal click menu item: reload")
                self?.reloadWebContent()
            }
            actions.append(actionRefresh)
        }

        var style = UDMenuStyleConfig.defaultConfig()
        // 设置最大宽度，UDMenu 没有开 cell 自适应，最大不超过 browser 宽度
        style.menuMaxWidth = view.frame.width
        let menu = UDMenu(actions: actions, style: style)
        menu.showMenu(sourceView: button, sourceVC: self)
        WebBrowser.logger.info("web portal present menu, currentUrl.safeURLString: \(webBrowser?.browserURL?.safeURLString ?? "")")
    }
}

final class WPWebExtension: WebBrowserExtensionItemProtocol {
    typealias WPWebExtensionDelegate = WebBrowserLifeCycleProtocol
        & WebBrowserNavigationProtocol
        & WebBrowserProtocol
        & AnyObject

    weak var delegate: WPWebExtensionDelegate?

    /// 套件统一浏览器容器生命周期实例
    var lifecycleDelegate: WebBrowserLifeCycleProtocol? {
        delegate
    }

    /// 网页navigation生命周期实例
    var navigationDelegate: WebBrowserNavigationProtocol? {
        delegate
    }

    /// 套件统一浏览器容器代理对象
    var browserDelegate: WebBrowserProtocol? {
        delegate
    }

    init(delegate: WPWebExtensionDelegate) {
        self.delegate = delegate
    }
}

// MARK: - tracker
extension WPHomeWebVC {
    private func reportPageStayDurationIfNeeded() {
        rootDelegate?.tracker.trackPageStayDurationIfNeeded(.web(initData), duration: pageStayDuration)
    }
}

extension WPHomeWebVC {
    private func refreshBadge() {
        badgeAPI
            .pullWorkplaceWebBadgeData(for: initData)
            .subscribe(onNext: { [weak self]webBadgeData in
                Self.logger.info("pull workplace web badge success", additionalData: [
                    "hasSelf": "\(self != nil)"
                ])
                self?.badgeService.refresh(with: webBadgeData)
            }, onError: { error in
                Self.logger.error("pull workplace web badge failed", error: error)
            })
            .disposed(by: disposeBag)
    }
}
// swiftlint:enable file_length
