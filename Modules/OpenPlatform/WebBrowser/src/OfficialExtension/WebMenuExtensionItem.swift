//
//  WebMenuExtensionItem.swift
//  WebBrowser
//
//  Created by 新竹路车神 on 2021/8/14.
//

import ECOInfra
import ECOProbe
import LarkBadge
import LarkSetting
import LarkUIKit
import LKCommonsLogging
import UniverseDesignIcon
import WebKit
import LarkOPInterface
import LarkTraitCollection

/// 更多菜单 code from liuyang.apple 未修改逻辑，仅迁移到 Extension 框架 后续 框架层交接到 yinyuan 维护，接入层由套件统一浏览器同学维护
final public class WebMenuExtensionItem: WebBrowserExtensionItemProtocol, MenuPanelDelegate {
    public var itemName: String? = "WebMenu"
    static let logger = Logger.webBrowserLog(WebMenuExtensionItem.self, category: "WebMenuExtensionItem")
    
    public lazy var lifecycleDelegate: WebBrowserLifeCycleProtocol? = WebMenuWebBrowserLifeCycle(item: self)
    
    public lazy var navigationDelegate: WebBrowserNavigationProtocol? = WebMenuWebBrowserNavigation(item: self)
    
    public lazy var browserDelegate: WebBrowserProtocol? = WebMenuWebBrowserDelegate(item: self)
    
    private weak var browser: WebBrowser?
    
    var urlIsNil: Bool
    // 标记是否需要展示 business 插件，主要用于URL变化时清空旧插件按钮
    var isBusinessPluginsShow: Bool = false
    
    /// 容器Badge路径
    private var containerPath: LarkBadge.Path {
        return Path().prefix(Path().web_url, with: String(browser?.browserURL?.absoluteString.hash ?? 0))
    }
    /// 容器NaviButton路径
    private var containerButtonPath: LarkBadge.Path {
        containerPath.web_more
    }
    
    //  菜单功能使用对象
    //  菜单对接同学：liuyang.apple
    private lazy var newMenuHandler: MenuPanelOperationHandler? = {
        self.makeMenuHandler()
    }()
    
    /// web 点击 show more 之后展示的 item
    public var meunItemModels = [String: MenuItemModelProtocol]()
    
    private weak var headerView: MenuAdditionView? = nil
    
    public init(browser: WebBrowser) {
        self.browser = browser
        if browser.browserURL == nil {
            urlIsNil = true
        } else {
            urlIsNil = false
        }
        bindOtherButtonID()
    }
    
    /// 绑定一些其他非开放领域业务的buttonID https://bytedance.feishu.cn/sheets/shtcncTYngXV6omM6ltYTzccpOD
    /// 由开放平台集中管控的数据，不允许非开放平台的代码自定义设置
    private func bindOtherButtonID() {
        // 翻译插件
        MenuItemModel.webBindButtonID(menuItemIdentifer: "translate", buttonID: "2018")
    }
    
    private var urlObservation: NSKeyValueObservation?
    /// 直接复用LarkBadge组件的能力
    func setupURLObservable(browser: WebBrowser) {
        urlObservation = browser
            .webview
            .observe(
                \.url,
                options: [.old, .new],
                changeHandler: { [weak self, weak browser] (webView, change) in
                    guard let `self` = self, let browser = browser else { return }
                    /// 直接复用LarkBadge组件的能力
                    browser.view.badge.observe(for: self.containerPath)
                    browser.view.badge.set(type: .clear)
                    self.moreItem.button.badge.observe(for: self.containerButtonPath)
                }
            )
    }
    
    public lazy var moreItem: LKBarButtonItem = {
        let rightItem = LKBarButtonItem(image: UDIcon.moreOutlined)
        rightItem.webButtonID = "1003"
        rightItem.addTarget(self, action: #selector(clickMore), for: .touchUpInside)
        return rightItem
    }()
    
    public lazy var myAiItem: LKBarButtonItem = {
        let rightItem = LKBarButtonItem(image: UDIcon.getIconByKey(.myaiColorful, size: CGSize(width: 24, height: 24)), buttonType: .custom)
        rightItem.webButtonID = "2026"
        rightItem.addTarget(self, action: #selector(launchNaviMyAI), for: .touchUpInside)
        return rightItem
    }()
    
    func resetAndUpdateRightItems(browser: WebBrowser) {
        // 顶部导航栏右侧统一管理功能关闭，走旧逻辑
        if browser.isNavigationRightBarExtensionDisable {
            if urlIsNil {
                return
            }
            var items:[LKBarButtonItem] = []
            if Display.pad {
                Self.logger.info("[Web MyAI ChatMode] display on pad")
                if let barStyleExtension = browser.resolve(NavigationBarStyleExtensionItem.self),
                   barStyleExtension.hideItems?.more == true {
                    Self.logger.info("hide the more barbuttonitem because hideNavBarItems.more is true")
                } else {
                    items.append(moreItem)
                }
                if let trait = browser.rootWindow()?.traitCollection,
                   let size = browser.rootWindow()?.bounds.size,
                   TraitCollectionKit.customTraitCollection(trait, size).horizontalSizeClass != .compact,
                   !browser.configuration.offline,
                   browser.newFailingURL == nil,
                   let _ = browser.launchBar {
                    // 处于R视图下，非离线应用，非错误页，有 launchBar
                    Self.logger.info("[Web MyAI ChatMode] In resetAndUpdateRightItems, not in offlinemode, not error page, and in R scene, and has launchBar")
                    // 新增 My AI 分会话按钮
                    if browser.isWebMyAIChatModeEnable() {
                        Self.logger.info("[Web MyAI ChatMode] In resetAndUpdateRightItems, create myAIChatItem successfully.")
                        items.append(myAiItem)
                    }
                    // 添加文档插件和群插件
                    if browser.isBusinessPluginsEnable, isBusinessPluginsShow {
                        if let docBarItem = browser.docBarItemsMap?.navigationBarItem,
                           browser.docBarItemsMap?.url == browser.webview.url {
                            items.append(docBarItem)
                            Self.logger.info("In resetAndUpdateRightItems, match latest url, Create docBarItem successfully.")
                        }
                        
                        if let imBarItem = browser.imBarItemsMap?.navigationBarItem,
                           browser.imBarItemsMap?.url == browser.webview.url {
                            items.append(imBarItem)
                            Self.logger.info("In resetAndUpdateRightItems, match latest url, Create imBarItem successfully.")
                        }
                    }
                }
            }
    
            browser.navigationItem.setRightBarButtonItems(insertSpaceForWebNavBar(items), animated: false)
        }
        
    }
    
    @objc private func clickMore() {
        guard let browser = browser else { return }
        Self.logger.info("more item clicked")
        showMenu(browser: browser)
        
        moreItem.webReportClick(applicationID: browser.currrentWebpageAppID())
    }
    
    @objc private func launchNaviMyAI() {
        guard let browser = browser else { return }
        Self.logger.info("[Web MyAI ChatMode] On navigationBar, my AI item clicked")
        browser.launchMyAI()
        
        myAiItem.webReportClick(applicationID: browser.currrentWebpageAppID())
    }
    
    /// 展示菜单面板
    private func showMenu(browser: WebBrowser) {
        browser.view.endEditing(true)

        guard let button = browser.navigationItem.rightBarButtonItem as? LKBarButtonItem else {
            return
        }

        let domainMenuContext = WebBrowserMenuContext(webBrowser: browser)
        self.newMenuHandler?.makePlugins(with: domainMenuContext)
        Self.logger.info("show new menu")
        
        var buttonList = MenuItemModel.webButtonList(headerButtonIDList: headerView?.webButtonIDList, meunItemModels: meunItemModels)
        
        OPMonitor("openplatform_web_container_menu_view")
            // 下边这一行需要抽离
            .addCategoryValue("identify_status", webBrowserDependency.isWebAppForCurrentWebpage(browser: browser) ? "web_app" : "web")
            .addCategoryValue("application_id", webBrowserDependency.appInfoForCurrentWebpage(browser: browser)?.id ?? "none")
            .addCategoryValue("scene_type", "none")
            .addCategoryValue("solution_id", "none")
            .addCategoryValue("url", browser.browserURL?.safeURLString)
            .addCategoryValue("button_list", buttonList)
            .addCategoryValue("container_open_type", "single_tab")
            .addCategoryValue("windows_type", "embedded_window")
            .tracing(browser.webview.trace)
            .setPlatform([.tea, .slardar])
            .flush()
        
        self.newMenuHandler?.show(from: .init(sourceButtonItem: button), parentPath: .init(path: containerButtonPath), animation: true, complete: nil)
    }
    
    /// 展示菜单面板,7.6改版后走这个逻辑
    public func showMenu(browser: WebBrowser, containerButtonPath: LarkBadge.Path) {
        browser.view.endEditing(true)

        guard let button = browser.navigationItem.rightBarButtonItem as? LKBarButtonItem else {
            return
        }

        let domainMenuContext = WebBrowserMenuContext(webBrowser: browser)
        self.newMenuHandler?.makePlugins(with: domainMenuContext)
        Self.logger.info("show new menu")
        
        var buttonList = MenuItemModel.webButtonList(headerButtonIDList: headerView?.webButtonIDList, meunItemModels: meunItemModels)
        
        OPMonitor("openplatform_web_container_menu_view")
            // 下边这一行需要抽离
            .addCategoryValue("identify_status", webBrowserDependency.isWebAppForCurrentWebpage(browser: browser) ? "web_app" : "web")
            .addCategoryValue("application_id", webBrowserDependency.appInfoForCurrentWebpage(browser: browser)?.id ?? "none")
            .addCategoryValue("scene_type", "none")
            .addCategoryValue("solution_id", "none")
            .addCategoryValue("url", browser.browserURL?.safeURLString)
            .addCategoryValue("button_list", buttonList)
            .addCategoryValue("container_open_type", "single_tab")
            .addCategoryValue("windows_type", "embedded_window")
            .tracing(browser.webview.trace)
            .setPlatform([.tea, .slardar])
            .flush()
        
        self.newMenuHandler?.show(from: .init(sourceButtonItem: button), parentPath: .init(path: containerButtonPath), animation: true, complete: nil)
    }
    
    /// 更新菜单的操作句柄，更新将会包含插件和数据模型
    /// 此方法必须在主线程调用，否则不会产生更新，触发一些奇怪的问题
    public func updateMenuHanlderIfNeeded() {
        // 增加线程保护代码
        guard Thread.isMainThread else {
            let errorMsg = "updateMenuHanlderIfNeeded must be executed in main thread, but now you aren't in \(Thread.current.description)"
            assertionFailure(errorMsg)
            Self.logger.error(errorMsg)
            return
        }
        guard let browser = browser else { return }

        let domainMenuContext = WebBrowserMenuContext(webBrowser: browser)
        self.newMenuHandler?.makePlugins(with: domainMenuContext)
    }
    
    /// 创建一个菜单操作句柄
    /// - Returns: 菜单操作句柄
    private func makeMenuHandler() -> MenuPanelOperationHandler? {
        guard let browser = browser else { return nil }
        let handler = MenuPanelHelper.getMenuPanelHandler(in: browser, for: .traditionalPanel)
        handler.delegate = self
        return handler
    }
    
    /// 更新菜单按钮的Badge
    /// - Parameters:
    ///   - itemIdentifier: 来自于哪个菜单选项，选项的ID
    ///   - isDisplay: 是否应该显示红点
    private func updateBadgeNumber(for itemIdentifier: String, isDisplay: Bool) {
        let path = self.containerButtonPath.raw(itemIdentifier)
        if isDisplay {
            BadgeManager.setBadge(path, type: .dot(.web), strategy: .weak)
        } else {
            BadgeManager.clearBadge(path)
        }
    }

    /// 菜单面板收到了新的数据模型后通知代理的方法
    public func menuPanelItemModelsDidChanged(models: [MenuItemModelProtocol]) {
        for model in models {
            self.updateBadgeNumber(for: model.itemIdentifier, isDisplay: model.badgeNumber > 0)
            meunItemModels[model.itemIdentifier] = model
        }
    }
    
    public func menuPanelItemDidClick(identifier: String?, model: MenuItemModelProtocol?) {
        // 部分其他业务注册的菜单项，我们也要补充埋点
        if identifier == "translate" {
            // 翻译插件菜单
            MenuItemModel.webReportClick(applicationID: browser?.currrentWebpageAppID(), menuItemIdentifer: model?.itemIdentifier)
        }
    }
    
    public func menuPanelHeaderDidChanged(view: MenuAdditionView?) {
        headerView = view
    }
    
    /// 从 URL 中解析 add_first_link_to_desk 参数状态
    /// - Parameter url
    /// - Returns: 如果 url 为空，或者不存在 add_first_link_to_desk 参数，将返回 false
    public func resolveAddFirstLinkToDest(url: URL?) -> Bool {
        if let url = url {
            if let urlComponent = URLComponents(url: url, resolvingAgainstBaseURL: false) {
                if let value = urlComponent.queryItems?.first(where: { item in
                    item.name == "add_first_link_to_desk"
                })?.value {
                    Self.logger.info("handle add_first_link_to_desk query")
                    if value == "true" {
                        Self.logger.info("add_first_link_to_desk query is true")
                        return true
                    } else {
                        Self.logger.info("add_first_link_to_desk query is not true")
                    }
                }
            } else {
                Self.logger.warn("no url components add_first_link_to_desk")
            }
        } else {
            Self.logger.info("url is nil")
        }
        return false
    }
}

final public class WebMenuWebBrowserLifeCycle: WebBrowserLifeCycleProtocol {
    
    private weak var item: WebMenuExtensionItem?
    
    init(item: WebMenuExtensionItem) {
        self.item = item
    }
    
    public func viewDidLoad(browser: WebBrowser) {
        item?.setupURLObservable(browser: browser)
        /*
        if browser.url.absoluteString.hasPrefix("http") {
         */
        if let url = browser.browserURL, url.absoluteString.hasPrefix("http") {
            item?.resetAndUpdateRightItems(browser: browser)
        }
    }
}

final public class WebMenuWebBrowserNavigation: WebBrowserNavigationProtocol {
    private weak var item: WebMenuExtensionItem?
    
    init(item: WebMenuExtensionItem) {
        self.item = item
    }
    
    public func browser(_ browser: WebBrowser, didCommit navigation: WKNavigation!) {
        let canOptimizeCommit = FeatureGatingManager.shared.featureGatingValue(with: FeatureGatingManager.Key(stringLiteral: "openplatform.web.optimizecommit.enable"))// user:global
        if !canOptimizeCommit {
            item?.updateMenuHanlderIfNeeded()
        }
        if browser.configuration.autoResetNavigationBar {
            // 网页前进/后退/刷新时需要重置右侧按钮到默认状态
            item?.resetAndUpdateRightItems(browser: browser)
        }
        if FeatureGatingManager.shared.featureGatingValue(with: "openplatfrom.web.add_first_link_to_desk") {// user:global
            // 当WebPage生成的时候读取URL中add_first_link_to_desk参数状态并更新到容器配置
            if item?.resolveAddFirstLinkToDest(url: browser.webview.url) == true {
                browser.addFirstLinkToDesk = true
            }
        }
    }
    
    public func browser(_ browser: WebBrowser, didFinish navigation: WKNavigation!) {
        let canOptimizeCommit = FeatureGatingManager.shared.featureGatingValue(with: FeatureGatingManager.Key(stringLiteral: "openplatform.web.optimizecommit.enable"))// user:global
        if canOptimizeCommit {
            item?.updateMenuHanlderIfNeeded()
        }
    }
}

final public class WebMenuWebBrowserDelegate: WebBrowserProtocol {
    
    private weak var item: WebMenuExtensionItem?
    
    init(item: WebMenuExtensionItem) {
        self.item = item
    }
    
    public func browser(_ browser: WebBrowser, didURLChanged url: URL?) {
        guard let item = item else { return }
        if (browser.isBusinessPluginsEnable || browser.isWebMyAIChatModeEnable()),
           browser.isNavigationRightBarExtensionDisable,
           Display.pad {
            // 顶部导航栏右侧统一管理功能关闭
            //一事一群一档 或 My AI 分会话功能未关闭，走新逻辑
            if item.urlIsNil, url != nil {
                item.urlIsNil = false
            }
            item.isBusinessPluginsShow = false
            item.resetAndUpdateRightItems(browser: browser)
            WebMenuExtensionItem.logger.info("[Web MyAI ChatMode] url changed, resetAndUpdateRightItems")
        } else {
            //一事一群一档 且 My AI功能关闭，走旧逻辑
            if item.urlIsNil {
                if url != nil {
                    item.urlIsNil = false
                    item.resetAndUpdateRightItems(browser: browser)
                }
            }
        }
    }
    
    public func browser(_ browser: WebBrowser, didImBusinessPluginChanged imPlugin: BusinessBarItemsForWeb?, didDocBusinessPluginChanged docPlugin: BusinessBarItemsForWeb?) {
        guard let item = item else {
            WebMenuExtensionItem.logger.info("WebMenuExtensionItem not exist")
            return
        }
        guard browser.isBusinessPluginsEnable else {
            WebMenuExtensionItem.logger.info("openplatform.web.businessplugins.disable is true")
            return
        }
        guard Display.pad,
              let trait = browser.rootWindow()?.traitCollection,
              let size = browser.rootWindow()?.bounds.size,
              TraitCollectionKit.customTraitCollection(trait, size).horizontalSizeClass != .compact else {
            // 处于C视图下
            WebMenuExtensionItem.logger.info("not in R scene")
            return
        }
        guard browser.isNavigationRightBarExtensionDisable else {
            WebMenuExtensionItem.logger.info("[Web MyAI ChatMode] browser.isNavigationRightBarExtensionDisable is false, will update in NavigationRightBarExtensionBrowserDelegate.")
            return
        }
        item.isBusinessPluginsShow = true
        item.resetAndUpdateRightItems(browser: browser)
        
    }
    
    public func browser(_ browser: WebBrowser, didCollapseStateChangedTo state: Bool) {
        guard let item = item else {
            WebMenuExtensionItem.logger.info("[Web MyAI ChatMode] WebMenuExtensionItem not exist")
            return
        }
        guard Display.pad else {
            WebMenuExtensionItem.logger.info("[Web MyAI ChatMode] not displayed on pad")
            return
        }
        guard (browser.isBusinessPluginsEnable || browser.isWebMyAIChatModeEnable()) else {
            WebMenuExtensionItem.logger.info("[Web MyAI ChatMode] browser.isBusinessPluginsEnable or browser.isWebMyAIChatModeEnable() is false")
            return
        }
        guard browser.isNavigationRightBarExtensionDisable else {
            WebMenuExtensionItem.logger.info("[Web MyAI ChatMode] browser.isNavigationRightBarExtensionDisable is false, will update in NavigationRightBarExtensionBrowserDelegate.")
            return
        }
        WebMenuExtensionItem.logger.info("[Web MyAI ChatMode] CollapseState changed to \(state), resetAndUpdateRightItems")
        item.resetAndUpdateRightItems(browser: browser)
    }
}

/// Webbrowser菜单的上下文 code from liuyang.apple 只是换了个位置
final public class WebBrowserMenuContext: NSObject, MenuContext {

    /// 上下文的数据代理
    public private(set) weak var webBrowser: WebBrowser?

    /// 这个方法建议访问权限为internal，但是由于新老菜单机制需要同时存在的原因，需要public，外界需要使用这个方法
    public init(webBrowser: WebBrowser?) {
        self.webBrowser = webBrowser
        super.init()
    }
    
    public func disabled(menuIdentifier: String) -> Bool {
        if FeatureGatingManager.shared.featureGatingValue(with: FeatureGatingManager.Key(stringLiteral: "openplatform.web.meta.meta_hidemenuitems")),let webBrowser = webBrowser, let menuConfigExtensionItem = webBrowser.resolve(WebMetaMoreMenuConfigExtensionItem.self) {// user:global
            return menuConfigExtensionItem.disabled(menuIdentifier: menuIdentifier)
        } else {
            return false
        }
    }
}
