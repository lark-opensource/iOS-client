//
//  NavigationBarExtensionItems.swift
//  WebBrowser
//
//  Created by 新竹路车神 on 2021/8/3.
//

import ECOInfra
import ECOProbe
import LarkSetting
import LarkUIKit
import LKCommonsLogging
import UniverseDesignColor
import UniverseDesignIcon
import UniverseDesignTheme
import WebKit
import ECOProbe
import LarkBadge
import LarkOPInterface
import LarkTraitCollection
import LarkWebViewContainer
import LarkSplitViewController

private struct WebHideNavBarItem {
    static let back = "back"
    static let close = "close"
    static let more = "more"
}

// MARK: - 导航栏样式
public protocol WebNavBarStyleItemProtocol {
    /// 是否setNavigationBarColorAPI设置导航栏颜色
    var isBarColorApi: Bool { get set }
}

/// 导航栏样式 item
final public class NavigationBarStyleExtensionItem: WebBrowserExtensionItemProtocol, WebNavBarStyleItemProtocol {
    public var itemName: String? = "NavigationBarStyle"
    static let logger = Logger.webBrowserLog(NavigationBarStyleExtensionItem.self, category: "NavigationBarStyleExtensionItem")
    
    public lazy var lifecycleDelegate: WebBrowserLifeCycleProtocol? = NavigationBarStyleWebBrowserLifeCycle(item: self)
    
    public lazy var navigationDelegate: WebBrowserNavigationProtocol? = NavigationBarStyleWebBrowserNavigation(item: self)
    
    public var isBarColorApi: Bool = false
    
    /// 记录导航栏背景色
    /// 旧版URL参数逻辑, 保持现状, 即将废弃. 外部开发者应通过WebMeta方案接入
//    @available(*, deprecated, message: "Use WebMeta barBgColor solution instead")
    private var navBgColor: UIColor?
    /// 记录导航栏颜色
    private var barBgColor: UIColor?
    fileprivate var barFgColor: UIColor?
    
    /// 记录导航栏右侧按钮, 左侧NavigationBarLeftExtensionItem维护
    private var prevRightBarBtnItems: [UIBarButtonItem]?
    
    /// 导航栏样式
    private var navigationBarStyle: NavigationBarStyle {
        if let navBgColor = navBgColor {
            return .color(navBgColor)
        }
        // 若自定义背景色和前景色均存在
        if let barBgColor = barBgColor, let barFgColor = barFgColor {
            return .custom(barBgColor, tintColor: barFgColor)
        }
        // 若仅存在背景色
        if let barBgColor = barBgColor {
            return .custom(barBgColor, tintColor: UIColor.ud.textTitle)
        }
        // 若仅存在前景色
        if let barFgColor = barFgColor {
            return .custom(UIColor.ud.bgBody, tintColor: barFgColor)
        }
        return .default
    }
    
    struct HideBarBtnItem {
        var back: Bool = false
        var close: Bool = false
        var more: Bool = false
    }
    var hideItems: HideBarBtnItem?
    
    public init() {}
    
    private var urlObservation: NSKeyValueObservation?
    /// 导航栏样式跟着webview.url变化
    func setupURLObservable(browser: WebBrowser) {
        urlObservation = browser
            .webview
            .observe(
                \.url,
                options: [.old, .new],
                changeHandler: { [weak self, weak browser] (webView, change) in
                    guard let `self` = self, let browser = browser else { return }
                    if LarkWebSettings.lkwEncryptLogEnabel {
                        // 不再重复打印，Url变化日志见 WebBrowser+LifeCycle 函数observeURLChange(webview: LarkWebView)
                        Self.logger.info("update nav style when url change")
                    } else {
                        Self.logger.info("urlecoSafeURL changed from \(change.oldValue??.safeURLString) to \(change.newValue??.safeURLString)")
                    }
                    if let url = change.newValue, let u = url {
                        self.extractParams(browser: browser, url: u)
                    }
                    self.updateNavbarColor(browser: browser)
                }
            )
    }
    
    func extractParams(browser: WebBrowser, url: URL?) {
        guard let url = url else { return }
        let paramsConfig = WebViewParamsConfig(url: url)
        navBgColor = paramsConfig.navBgColor
        if browser.isNavigationRightBarExtensionDisable {
            if !paramsConfig.isShowRightButton {
                browser.navigationItem.setRightBarButtonItems(nil, animated: false)
            }
        } else {
            if let navigationExtension = browser.resolve(NavigationBarRightExtensionItem.self) {
                navigationExtension.isShowRightButton = paramsConfig.isShowRightButton
                navigationExtension.resetAndUpdateRightItems(browser: browser)
            }
        }
        
        if let platformService = paramsConfig.opPlatformService {
            setNavgationBarHidden(browser: browser, hidden: !platformService.isShowNavigator, animated: false)
        }
        sendCustomURLMonitor(browser: browser, url: url)
        Self.logger.info("paramsConfig for urlecoSafeURL{\(url.safeURLString)} is {\(paramsConfig)}")
    }
    
    private func sendCustomURLMonitor(browser: WebBrowser, url: URL) {
        guard WebMetaNavigationBarExtensionItem.isURLCustomQueryMonitorEnabled() else {
            return
        }
        let queryDict = url.lf.queryDictionary
        let platformServiceKey = "op_platform_service"
        if let platformServiceValue = queryDict[platformServiceKey] {
            flushCustomURLMonitor(browser, platformServiceKey, platformServiceValue, url)
        }
        let showRBtnKey = "show_right_button"
        if let showRBtnValue = queryDict[showRBtnKey] {
            flushCustomURLMonitor(browser, showRBtnKey, showRBtnValue, url)
        }
        let navBGColorKey = "lark_nav_bgcolor"
        if let navBGColorValue = queryDict[navBGColorKey] {
            flushCustomURLMonitor(browser, navBGColorKey, navBGColorValue, url)
        }
    }
    
    private func flushCustomURLMonitor(_ browser: WebBrowser, _ name: String, _ content: String, _ url: URL) {
        let safeURLStr = url.safeURLString
        let appId = browser.configuration.appId ?? browser.currrentWebpageAppID()
        OPMonitor("openplatform_web_container_URLCustomQuery")
            .addCategoryValue("name", name)
            .addCategoryValue("content", content)
            .addCategoryValue("url", safeURLStr)
            .addCategoryValue("appId", appId)
            .setPlatform([.tea, .slardar])
            .tracing(browser.getTrace())
            .flush()
    }
    
    private func isBrowserTopVC(browser: WebBrowser) -> Bool {
        guard let nav = browser.navigationController else {
            Self.logger.info("isBrowserTopVC false, nav is nil")
            return false
        }
        guard let topVC = nav.topViewController else {
            Self.logger.info("isBrowserTopVC false, nav top vc is nil, vcs: \(nav.viewControllers)")
            return false
        }
        guard topVC == browser || topVC.children.contains(browser) else {
            Self.logger.info("isBrowserTopVC false, browser is not topvc, vcs: \(nav.viewControllers)")
            return false
        }
        return true
    }
    
    /// 设置导航栏隐藏状态
    func setNavgationBarHidden(browser: WebBrowser, hidden: Bool, animated: Bool) {
        let oldValue = browser.isNavigationBarHidden
        browser.isNavigationBarHidden = hidden
        guard isBrowserTopVC(browser: browser) else {
            Self.logger.info("setNavgationBarHidden from \(oldValue) to \(hidden) invalid, isBrowserTopVC false")
            return
        }
        Self.logger.info("setNavgationBarHidden from \(oldValue) to \(hidden), animated: \(animated)")
        if browser.navigationController?.isNavigationBarHidden != hidden {
            browser.navigationController?.setNavigationBarHidden(hidden, animated: animated)
        }
    }
    /// 设置导航栏左侧按钮隐藏状态
    func setNavigationLeftBarBtnItemsHidden(browser: WebBrowser, hidden: Bool, animated: Bool) {
        guard isBrowserTopVC(browser: browser) else {
            Self.logger.info("setNavigationLeftBarBtnItemsHidden \(hidden) invalid, isBrowserTopVC false")
            return
        }
        guard let leftExtensionItem = browser.resolve(NavigationBarLeftExtensionItem.self) else {
            return
        }
        Self.logger.info("setNavigationLeftBarBtnItemsHidden: \(hidden), animated: \(animated)")
        leftExtensionItem.setLeftItemsHidden(hidden: hidden, animated: animated)
    }
    /// 设置导航栏右侧按钮隐藏状态
    func setNavigationRightBarBtnItemsHidden(browser: WebBrowser, hidden: Bool, animated: Bool) {
        guard isBrowserTopVC(browser: browser) else {
            Self.logger.info("setNavigationRightBarBtnItemsHidden \(hidden) invalid, isBrowserTopVC false")
            return
        }
        if hidden {
            if let items = browser.navigationItem.rightBarButtonItems {
                prevRightBarBtnItems = items
                browser.navigationItem.setRightBarButtonItems(nil, animated: animated)
                Self.logger.info("setRightItemsHidden from false to \(hidden), animated: \(animated)")
            }
        } else {
            if browser.navigationItem.rightBarButtonItem == nil {
                if browser.configuration.autoResetNavigationBar {
                    browser.resolve(WebMenuExtensionItem.self)?.resetAndUpdateRightItems(browser: browser)
                } else if let prevRightBarBtnItems = prevRightBarBtnItems {
                    browser.navigationItem.setRightBarButtonItems(prevRightBarBtnItems, animated: animated)
                }
                Self.logger.info("setRightItemsHidden from true to \(hidden), animated: \(animated)")
            }
        }
    }
    
    // MARK: 导航栏颜色
    func updateNavbarColor(browser: WebBrowser) {
        if let navBgColor = navBgColor,
           let nvc = browser.navigationController as? LkNavigationController {
            Self.logger.info("navi color changed to \((navBgColor))")
            nvc.update(style: .color(navBgColor))
        }
    }
    
    public func updateBarBgColor(browser: WebBrowser, color: UIColor?) {
        guard isBrowserTopVC(browser: browser) else {
            Self.logger.info("updateBarBgColor \(color?.description ?? "") invalid, isBrowserTopVC false")
            return
        }
        guard let nav = browser.navigationController as? LkNavigationController else {
            return
        }
        guard barBgColor != color else {
            return
        }
        Self.logger.info("update navBgColor from \(barBgColor?.description ?? "") to \(color?.description ?? "")")
        barBgColor = color
        if let color = color {
            nav.update(style: .custom(color, tintColor: barFgColor ?? UIColor.ud.textTitle))
        } else {
            nav.update(style: .custom(UIColor.ud.bgBody, tintColor: barFgColor ?? UIColor.ud.textTitle))
        }
    }
    
    public func updateBarFgColor(browser: WebBrowser, color: UIColor?) {
        guard isBrowserTopVC(browser: browser) else {
            Self.logger.info("updateBarFgColor \(color?.description ?? "") invalid, isBrowserTopVC false")
            return
        }
        guard let nav = browser.navigationController as? LkNavigationController else {
            return
        }
        guard barFgColor != color else {
            return
        }
        Self.logger.info("update navFgColor from \(barFgColor?.description ?? "") to \(color?.description ?? "")")
        barFgColor = color
        setCustomBarBtnItemColor(color, browser: browser)
        if let color = color {
            nav.update(style: .custom(barBgColor ?? UIColor.ud.bgBody, tintColor: color))
        } else {
            nav.update(style: .custom(barBgColor ?? UIColor.ud.bgBody, tintColor: UIColor.ud.textTitle))
        }
        browser.setNeedsStatusBarAppearanceUpdate()
    }
    
    private func setCustomBarBtnItemColor(_ color: UIColor?, browser: WebBrowser) {
        guard Display.pad else {
            return
        }
        if let padExtension = browser.resolve(PadExtensionItem.self),
           let sceneBtn = padExtension.tryGetSceneButton(browser: browser),
           let sceneBarBtnItem = sceneBtn.customView as? SceneButtonItem {
            sceneBarBtnItem.iconTintColor = color
        }
        browser.secondaryOnlyButtonItem.iconTintColor = color
    }
    
    func customStatusBarStyle() -> UIStatusBarStyle? {
        guard #available(iOS 13.0, *) else {
            return nil
        }
        guard let barFgColor = barFgColor else {
            return nil
        }
        let themeStyle = UDThemeManager.getRealUserInterfaceStyle()
        if themeStyle == .dark {
            let darkTrait = UITraitCollection(userInterfaceStyle: .dark)
            let darkColor = barFgColor.resolvedColor(with: darkTrait)
            Self.logger.info("current dark mode will use \(darkColor)")
            return statusBarStyleFrom(darkColor)
        } else if themeStyle == .light {
            let lightTrait = UITraitCollection(userInterfaceStyle: .light)
            let lightColor = barFgColor.resolvedColor(with: lightTrait)
            Self.logger.info("current light mode will use \(lightColor)")
            return statusBarStyleFrom(lightColor)
        }
        return nil
    }
    
    private func statusBarStyleFrom(_ color: UIColor) -> UIStatusBarStyle {
        guard #available(iOS 13.0, *) else {
            return .default
        }
        if color == UIColor.ud.rgba("FFFFFFFF") {
            return .lightContent
        }
        if color == UIColor.ud.rgba("FF000000") {
            return .darkContent
        }
        return .default
    }
    
    private var canGoBackObservation: NSKeyValueObservation?
    /// 监听WKWebView.canGoBack状态变化来更新侧滑手势
    func setupSwipeBackObservable(browser: WebBrowser) {
        canGoBackObservation = browser
            .webview
            .observe(
                \.canGoBack,
                options: [.old, .new],
                changeHandler: { [weak self, weak browser] (webView, change) in
                    guard let `self` = self, let browser = browser else { return }
                    Self.logger.info("canGoBack state change from \(change.oldValue) to \(change.newValue)")
                    self.checkAndUpdateSwipeBack(browser: browser)
                }
            )
    }
    
    /// 当webview不能goBack时，启用navigation controller的侧滑手势
    public func checkAndUpdateSwipeBack(browser: WebBrowser) {
        // 若通过WebMeta定制容器侧滑关闭, 则侧滑时不需要返回上一级页面
        if browser.canSlideToClose {
            browser.setPopGestureEnabled(true)
            return
        }
        browser.setPopGestureEnabled(!browser.webView.canGoBack)
    }
    
    /// 在viewWillAppear时，定制导航栏相关状态
    func customizeNavigationBarWhenViewWillAppear(browser: WebBrowser, animated: Bool) {
        // 定制导航栏样式，摘自BaseUIViewController.viewWillAppear中的处理
        if browser.navigationController?.isNavigationBarHidden != browser.isNavigationBarHidden {
            browser.navigationController?.setNavigationBarHidden(browser.isNavigationBarHidden, animated: animated)
        }
        if let nav = browser.navigationController as? LkNavigationController {
            nav.update(style: navigationBarStyle)
        } else {
            let msg = "nav is not a LkNavigationController, please contact RD of Lark"
            Self.logger.error(msg)
        }
    }
    
    func updateNavBarItems(browser: WebBrowser, meta items: String) {
        guard isBrowserTopVC(browser: browser) else {
            Self.logger.info("updateNavBarItems is invalid, isBrowserTopVC false")
            return
        }
        if hideItems == nil {
            hideItems = HideBarBtnItem()
        }
        let hideNavBarItems = items.components(separatedBy: ",")
        if hideNavBarItems.contains(WebHideNavBarItem.back) {
            hideItems?.back = true
        }
        if hideNavBarItems.contains(WebHideNavBarItem.close) {
            hideItems?.close = true
        }
        if hideNavBarItems.contains(WebHideNavBarItem.more) {
            hideItems?.more = true
        }
    }
}

public func insertSpaceForWebNavBar(_ items: [UIBarButtonItem]?) -> [UIBarButtonItem]? {
    if !FeatureGatingKey.webBrowserProfileCloseBtnGap.fgValue() { // user:global
        /// 只有iPad的导航按钮之间需要增加宽度
        guard Display.pad else {
            return items
        }
    }
    return insertSpaceBetweenItems(items)
}

/// 在item之间插入间距item
func insertSpaceBetweenItems(_ items: [UIBarButtonItem]?) -> [UIBarButtonItem]? {
    NavigationBarStyleExtensionItem.logger.info("insertSpaceBetweenItems")
    /// 默认两个按钮之间宽度是8，增加一个空白的宽度4之后，实际两个按钮之间的宽度为: 8 + 4 + 8 = 20
    if let originItems = items,
       originItems.count > 0 {
        var resultItems: [UIBarButtonItem] = []
        for i in 0..<originItems.count {
            resultItems.append(originItems[i])
            if !FeatureGatingKey.webBrowserProfileCloseBtnGap.fgValue() { // user:global
                resultItems.append(LKBarSpaceItem(width: 4));
            } else {
                /// 如果是 WebBrowserBarItem ，表示本身已经很大了，不需要再增加间距
                if !(originItems[i] is WebBrowserBarItem) {
                    resultItems.append(LKBarSpaceItem(width: 4));
                }
            }
        }
        return resultItems
    }
    return items
}

final public class NavigationBarStyleWebBrowserLifeCycle: WebBrowserLifeCycleProtocol {
    private weak var item: NavigationBarStyleExtensionItem?
    init(item: NavigationBarStyleExtensionItem) {
        self.item = item
    }
    
    public func viewDidLoad(browser: WebBrowser) {
        item?.extractParams(browser: browser, url: browser.firstLoadURL)
        item?.setupURLObservable(browser: browser)
        item?.setupSwipeBackObservable(browser: browser)
    }
    
    public func viewWillAppear(browser: WebBrowser, animated: Bool) {
        item?.customizeNavigationBarWhenViewWillAppear(browser: browser, animated: animated)
    }
    
    public func viewDidAppear(browser: WebBrowser, animated: Bool) {
        item?.checkAndUpdateSwipeBack(browser: browser)
    }
}

final public class NavigationBarStyleWebBrowserNavigation: WebBrowserNavigationProtocol {
    private weak var item: NavigationBarStyleExtensionItem?
    init(item: NavigationBarStyleExtensionItem) {
        self.item = item
    }
    
    public func browser(_ browser: WebBrowser, didCommit navigation: WKNavigation!) {
        // 页面跳转时先重置设置
        item?.isBarColorApi = false
        item?.extractParams(browser: browser, url: browser.browserURL)
    }
    
    public func browser(_ browser: WebBrowser, didStartProvisionalNavigation navigation: WKNavigation!) {
        item?.updateNavbarColor(browser: browser)
    }
}

// code from houzhiyou，and houzhiyou's code from qi🍁 仅迁移位置
/// url中记录的开放平台相关服务配置
struct OPPlatformService {
    /// 是否显示导航栏
    let isShowNavigator: Bool

    init?(_ opplatformServiceString: String) {
        guard let str = opplatformServiceString.removingPercentEncoding else {
            return nil
        }
        let arr = str.split(separator: ",")
        var isShowNavigator = true
        for config in arr {
            switch config {
            case "hide_navigator":
                isShowNavigator = false
            case "show_navigator":
                isShowNavigator = true
            default:
                continue
            }
        }
        self.isShowNavigator = isShowNavigator
    }
}

// code from houzhiyou，and houzhiyou's code from qi🍁 仅迁移位置
/// 解析url中的参数配置
struct WebViewParamsConfig {
    /// 是否显示右侧导航栏按钮
    var isShowRightButton: Bool = true
    /// 导航栏背景色
    var navBgColor: UIColor?
    /// 开放平台相关服务配置
    var opPlatformService: OPPlatformService?

    init(url: URL) {
        let queryDict = url.lf.queryDictionary

        isShowRightButton = parseIsShowRightButton(queryDict)
        navBgColor = parseNaviBgColor(queryDict)
        opPlatformService = parseOPPlatformService(queryDict)
    }

    @inline(__always)
    private func parseNaviBgColor(_ dict: [String: String]) -> UIColor? {
        guard let naviBgColor = dict["lark_nav_bgcolor"] else {
            return nil
        }
        return UIColor.ud.rgba(naviBgColor)
    }

    @inline(__always)
    private func parseIsShowRightButton(_ dict: [String: String]) -> Bool {
        guard let showRightButton = dict["show_right_button"]?.lowercased() else {
            return true
        }
        switch showRightButton {
        case "true":
            return true
        case "false":
            return false
        default:
            return true
        }
    }

    @inline(__always)
    private func parseOPPlatformService(_ dict: [String: String]) -> OPPlatformService? {
        guard let str = dict["op_platform_service"]?.lowercased() else {
            return nil
        }
        return OPPlatformService(str)
    }
}

// MARK: - 导航栏按钮定制
/// 导航栏 item

final public class WebBrowserBarItem: LKBarButtonItem {
    static public func makeIconButton(_ key: UDIconType) -> WebBrowserBarItem {
        /// icon 的大小是20*20
        let size = CGSize(width: 24, height: 24)
        let icon = UDIcon.getIconByKey(key,
                                       size: size)
            .ud.withTintColor(UIColor.ud.iconN1)
        return Self.makeIconButton(icon)
    }
    
    static public func makeIconButton(_ icon: UIImage) -> WebBrowserBarItem {
        let barItem = WebBrowserBarItem(image: icon)
        /// button宽度是32，和第二个按钮的间隔是 （32-20）+ 8（默认间隔）
        barItem.setBtn(width: 36, height: 40)
        return barItem
    }
}

// MARK: - 导航栏左侧
/// 导航栏左侧 item
final public class NavigationBarLeftExtensionItem: WebBrowserExtensionItemProtocol {
    public var itemName: String? = "NavigationBarLeft"
    static let logger = Logger.webBrowserLog(NavigationBarLeftExtensionItem.self, category: "NavigationBarLeftExtensionItem")
    
    public lazy var lifecycleDelegate: WebBrowserLifeCycleProtocol? = NavigationBarLeftWebBrowserLifeCycle(item: self)
    
    public lazy var navigationDelegate: WebBrowserNavigationProtocol? = NavigationBarLeftWebBrowserNavigation(item: self)
    
    weak private var browser: WebBrowser?
    
    private var isHiddenLeftItems: Bool = false
    private var prevLeftBarBtnItems: [UIBarButtonItem]?
    
    weak private var defaultSupportSceneCloseItem: UIBarButtonItem?
    
    /// 关闭按钮
    public lazy var closeItem: LKBarButtonItem = {
        let closeItem = FeatureGatingKey.webBrowserProfileCloseBtnGap.fgValue() ? WebBrowserBarItem.makeIconButton(.closeOutlined) : LKBarButtonItem(image: LarkUIKit.Resources.navigation_close_outlined) // user:global
        closeItem.webButtonID = "1004"
        closeItem.addTarget(self, action: #selector(close), for: .touchUpInside)
        return closeItem
    }()
    @objc private func close() {
        Self.logger.info("closeItem clicked")
        if !FeatureGatingManager.shared.featureGatingValue(with: .init(stringLiteral: "openplatform.web.leaveconfirm.disable")), let browser = browser, browser.resolve(LeaveConfirmExtensionItem.self)?.showConfirmIfNeeded(browser: browser, effect: .close, callback: { [weak browser] (confirm) in // user:global
            if confirm {
                browser?.closeBrowser()
            }
        }) == true {
            // 退出前确认
            Self.logger.info("closeItem showConfirm")
        } else {
            // 直接退出
            browser?.closeBrowser()
        }
        
        closeItem.webReportClick(applicationID: browser?.currrentWebpageAppID())
    }
    /// 回退按钮
    public lazy var backItem: LKBarButtonItem = {
        let backItem = FeatureGatingKey.webBrowserProfileCloseBtnGap.fgValue() ? WebBrowserBarItem.makeIconButton(.leftOutlined) : LKBarButtonItem(image: LarkUIKit.Resources.navigation_back_light)// user:global
        backItem.webButtonID = "1001"
        backItem.addTarget(self, action: #selector(goBackOrClose), for: .touchUpInside)
        return backItem
    }()
    
    /// 前进按钮
    public lazy var forwardItem: LKBarButtonItem = {
        let forward = FeatureGatingKey.webBrowserProfileCloseBtnGap.fgValue() ? WebBrowserBarItem.makeIconButton(.rightOutlined) : LKBarButtonItem(image: UDIcon.getIconByKey(.rightOutlined))
        forward.webButtonID = "1007"
        forward.addTarget(self, action: #selector(forwardWebPage), for: .touchUpInside)
        return forward
    }()
    
    /// 刷新按钮
    public lazy var refreshItem: LKBarButtonItem = {
        let refresh = FeatureGatingKey.webBrowserProfileCloseBtnGap.fgValue() ? WebBrowserBarItem.makeIconButton(.refreshOutlined) : LKBarButtonItem(image: UDIcon.getIconByKey(.refreshOutlined))
        refresh.webButtonID = "1011"
        refresh.addTarget(self, action: #selector(reladWebPage), for: .touchUpInside)
        return refresh
    }()
    
    
    @objc private func goBackOrClose() {
        Self.logger.info("backItem clicked with canGoBack(\(browser?.webView.canGoBack))")
        
        if !FeatureGatingManager.shared.featureGatingValue(with: .init(stringLiteral: "openplatform.web.leaveconfirm.disable")), let browser = browser, browser.resolve(LeaveConfirmExtensionItem.self)?.showConfirmIfNeeded(browser: browser, effect: .back, callback: { [weak browser] (confirm) in // user:global
            if confirm {
                browser?.goBackOrClose()
            }
        }) == true {
            // 返回前确认
            Self.logger.info("goBackOrClose showConfirm")
        } else {
            // 直接返回
            browser?.goBackOrClose()
        }
        
        backItem.webReportClick(applicationID: browser?.currrentWebpageAppID())
    }
    
    @objc private func forwardWebPage(){
        Self.logger.info("forwardItem clicked with canGoForward(\(String(describing: browser?.webView.canGoForward)))")
        browser?.webview.goForward()
    }
    
    @objc private func reladWebPage(){
        Self.logger.info("reloadItem clicked")
        self.browser?.reload()
    }
    
    public init(browser: WebBrowser) {
        self.browser = browser
    }
    
    private var canGoBackObservation: NSKeyValueObservation?
    private var canGoForwardObservation: NSKeyValueObservation?
    /// 监听WKWebView.canGoBack状态变化来更新导航栏按钮，并判断是否启用侧滑手势
    func setupLeftNavigationBarButtonItemsObservable(browser: WebBrowser) {
        canGoBackObservation = browser
            .webview
            .observe(
                \.canGoBack,
                options: [.old, .new],
                changeHandler: { [weak self, weak browser] (webView, change) in
                    guard let `self` = self, let browser = browser else { return }
                    Self.logger.info("canGoBack state change from \(change.oldValue) to \(change.newValue)")
                    self.resetAndUpdateDefaultLeftItemsIfNeeded(browser: browser)
                }
            )
        canGoForwardObservation = browser
            .webview
            .observe(
                \.canGoForward,
                options: [.old, .new],
                changeHandler: { [weak self, weak browser] (_, change) in
                    guard let `self` = self, let browser = browser else { return }
                    Self.logger.info("canGoBack state change from \(change.oldValue) to \(change.newValue)")
                    self.resetAndUpdateDefaultLeftItemsIfNeeded(browser: browser)
                }
            )
    }

    /// 重置并更新左侧按钮为默认状态
    func resetAndUpdateLeftItems(browser: WebBrowser) {
        // 若iPad侧拉窗口导航栏按钮
        if let supportSceneCloseItem = browser.resolve(PadExtensionItem.self)?.tryGetSupportSceneCloseItem(browser: browser) {
            ///  无论如何都展示关闭辅助窗口的按钮
            // supportSceneCloseItem 默认被添加决定 hasCustomLeftItems 的判定，修改前请确认
            var items: [UIBarButtonItem] = [supportSceneCloseItem]
            defaultSupportSceneCloseItem = supportSceneCloseItem
            if browser.webview.canGoBack {
                //  如果是可以goback，在左边插入一个返回按钮
                items.insert(backItem, at: 0)
            }
            browser.navigationItem.setLeftBarButtonItems(insertSpaceForWebNavBar(items), animated: false)
            return
        }
        // 若iPhone或iPad主窗口导航栏按钮
        var items: [UIBarButtonItem] = []
        var isAddBackItem: Bool = false
        var isAddCloseItem: Bool = false
        let barStyleExtension = browser.resolve(NavigationBarStyleExtensionItem.self)
        var isCollapsed: Bool = false
        if let trait = browser.rootWindow()?.traitCollection, let size = browser.rootWindow()?.bounds.size {
            let newTrait =  TraitCollectionKit.customTraitCollection(trait, size)
            isCollapsed = newTrait.horizontalSizeClass == .compact
        }
        if let myAIQuickLaunchBarService = browser.resolver?.resolve(LarkOpenPlatformMyAIService.self), myAIQuickLaunchBarService.isTemporaryEnabled(), Display.pad {
            // ipad 开启标签页功能后所有的ipad都走这个逻辑
            if (browser.configuration.scene == .temporaryTab && !isCollapsed) || browser.larkSplitViewController?.splitMode == .secondaryOnly {
                // 标签页 或者 分栏时全屏模式 ，关闭在最左侧
                Self.logger.info("closeItem first scene: \(browser.configuration.scene.rawValue) splitmode: \(String(describing: browser.larkSplitViewController?.splitMode.rawValue)), isCollapsed:\(isCollapsed)")
                if barStyleExtension?.hideItems?.close == true {
                    isAddCloseItem = false
                    Self.logger.info("hide the close barbuttonitem because hideNavBarItems.close is true")
                } else {
                    isAddCloseItem = true
                }

                if isAddCloseItem {
                    items.append(closeItem)
                }
                if let split = browser.larkSplitViewController, !split.isCollapsed, browser.configuration.scene != .temporaryTab {
                    let fullScrnItem = browser.secondaryOnlyButtonItem
                    if WebMetaNavigationBarExtensionItem.isNavBgAndFgColorEnabled() {
                        fullScrnItem.tintColorEnable = true
                    }
                    items.append(fullScrnItem)
                }
                if let sceneButton = browser.resolve(PadExtensionItem.self)?.tryGetSceneButton(browser: browser) {
                    if WebMetaNavigationBarExtensionItem.isNavBgAndFgColorEnabled(),
                        let sceneBtnItem = sceneButton.customView as? SceneButtonItem,
                        let barStyleExtension = browser.resolve(NavigationBarStyleExtensionItem.self) {
                        // 多窗口按钮在Browser被添加到window时才创建, 该时机已完成URL参数解析, 故创建时根据参数设置颜色
                        sceneBtnItem.iconTintColor = barStyleExtension.barFgColor
                    }
                    items.append(sceneButton)
                }
                if barStyleExtension?.hideItems?.back == true {
                    isAddBackItem = false
                    Self.logger.info("hide the back barbuttonitem because hideNavBarItems.back is true")
                } else {
                    isAddBackItem = true
                }
                if isAddBackItem {
                    items.append(backItem)
                }
                items.append(forwardItem)
                items.append(refreshItem)
                forwardItem.isEnabled = browser.webview.canGoForward
                backItem.isEnabled = browser.webview.canGoBack
            } else {
                // 普通场景，延续线上逻辑，返回按钮在第一个，更符合操作习惯
                Self.logger.info("backItem first scene: \(browser.configuration.scene.rawValue) splitmode: \(String(describing: browser.larkSplitViewController?.splitMode.rawValue)), isCollapsed:\(isCollapsed)")
                if browser.leftNaviButtonsRootVCOpt {
                    // 返回按钮
                    Self.logger.info("reset when leftNaviButtonsRootVCOpt is true")
                    if browser.webview.canGoBack {
                        isAddBackItem = true
                        Self.logger.info("add back item when leftNaviButtonsRootVCOpt is true")
                    } else if browser.presentedViewController != nil {
                        Self.logger.info("add back item when presented")
                        isAddBackItem = true
                    } else if let first = browser.navigationController?.viewControllers.first, first != browser {
                        Self.logger.info("add back item when self is not first")
                        isAddBackItem = true
                    }
                    // 关闭按钮
                    if let first = browser.navigationController?.viewControllers.first, first != browser, browser.webview.canGoBack {
                        Self.logger.info("add close item when self is not first and cangoback")
                        isAddCloseItem = true
                    }
                    if isAddBackItem {
                        items.append(backItem)
                    }
                    if isAddCloseItem {
                        items.append(closeItem)
                    }
                } else {
                    isAddBackItem = true
                    if browser.webview.canGoBack {
                        isAddCloseItem = true
                    }
                    if isAddBackItem {
                        items.append(backItem)
                    }
                    if isAddCloseItem {
                        items.append(closeItem)
                    }
                }
                backItem.isEnabled = true
                
                if let split = browser.larkSplitViewController, !split.isCollapsed, browser.configuration.scene != .temporaryTab {
                    let fullScrnItem = browser.secondaryOnlyButtonItem
                    if WebMetaNavigationBarExtensionItem.isNavBgAndFgColorEnabled() {
                        fullScrnItem.tintColorEnable = true
                    }
                    items.append(fullScrnItem)
                }
                
                if let sceneButton = browser.resolve(PadExtensionItem.self)?.tryGetSceneButton(browser: browser) {
                    if WebMetaNavigationBarExtensionItem.isNavBgAndFgColorEnabled(),
                        let sceneBtnItem = sceneButton.customView as? SceneButtonItem,
                        let barStyleExtension = browser.resolve(NavigationBarStyleExtensionItem.self) {
                        // 多窗口按钮在Browser被添加到window时才创建, 该时机已完成URL参数解析, 故创建时根据参数设置颜色
                        sceneBtnItem.iconTintColor = barStyleExtension.barFgColor
                    }
                    items.append(sceneButton)
                }
            }
            browser.navigationItem.setLeftBarButtonItems(insertSpaceForWebNavBar(items), animated: false)
            return
        }
        // 若根视图左侧按钮显示优化
        if browser.leftNaviButtonsRootVCOpt {
            Self.logger.info("reset when leftNaviButtonsRootVCOpt is true")
            if browser.webview.canGoBack {
                Self.logger.info("add back item when leftNaviButtonsRootVCOpt is true")
                isAddBackItem = true
            } else if browser.presentedViewController != nil {
                Self.logger.info("add back item when presented")
                isAddBackItem = true
            } else if let first = browser.navigationController?.viewControllers.first, first != browser {
                Self.logger.info("add back item when self is not first")
                isAddBackItem = true
            }
            
            if let first = browser.navigationController?.viewControllers.first,
               first != browser,
               browser.webview.canGoBack {
                Self.logger.info("add close item when self is not first and cangoback")
                isAddCloseItem = true
            }
        } else {
            isAddBackItem = true
            if browser.webview.canGoBack {
                isAddCloseItem = true
            }
        }
        // 根据web-meta配置决议是否隐藏按钮项
        if barStyleExtension?.hideItems?.back == true {
            isAddBackItem = false
            Self.logger.info("hide the back barbuttonitem because hideNavBarItems.back is true")
        }
        if barStyleExtension?.hideItems?.close == true {
            isAddCloseItem = false
            Self.logger.info("hide the close barbuttonitem because hideNavBarItems.close is true")
        }
        // 返回按钮
        if isAddBackItem {
            items.append(backItem)
        } else {
            browser.navigationItem.setHidesBackButton(true, animated: false)
        }
        // 关闭按钮
        if isAddCloseItem {
            items.append(closeItem)
        }
        // 若iPad主窗口导航栏按钮
        if Display.pad {
            if let split = browser.larkSplitViewController, !split.isCollapsed {
                let fullScrnItem = browser.secondaryOnlyButtonItem
                if WebMetaNavigationBarExtensionItem.isNavBgAndFgColorEnabled() {
                    fullScrnItem.tintColorEnable = true
                }
                items.append(fullScrnItem)
            }
            if let sceneButton = browser.resolve(PadExtensionItem.self)?.tryGetSceneButton(browser: browser) {
                if WebMetaNavigationBarExtensionItem.isNavBgAndFgColorEnabled(),
                   let sceneBtnItem = sceneButton.customView as? SceneButtonItem,
                   let barStyleExtension = barStyleExtension {
                    // 多窗口按钮在Browser被添加到window时才创建, 该时机已完成URL参数解析, 故创建时根据参数设置颜色
                    sceneBtnItem.iconTintColor = barStyleExtension.barFgColor
                }
                items.append(sceneButton)
            }
        }
        
        browser.navigationItem.setLeftBarButtonItems(insertSpaceForWebNavBar(items), animated: false)
    }
    
    /// 如果不包含 defaultSupportSceneCloseItem 或者 backItem，则可以认定导航栏已经被定制
    private func hasCustomLeftItems(_ items: [UIBarButtonItem]?) -> Bool {
        guard let items = items else {
            return false
        }
        return items.contains { $0 == defaultSupportSceneCloseItem || $0 == backItem } == false
    }
    
    /// 根据需要更新左侧默认按钮列表（如果已定制，则不再更新）
    public func resetAndUpdateDefaultLeftItemsIfNeeded(browser: WebBrowser) {
        // 若左侧按钮列表隐藏, 则不需要更新
        guard !isHiddenLeftItems else {
            return
        }
        if hasCustomLeftItems(browser.navigationItem.leftBarButtonItems) {
            // 如果已经手动定制了左侧按钮，则保持使用定制按钮，不需要额外的操作 https://bytedance.feishu.cn/docx/doxcnJ0sRA6jrcwVD6VBkO0Ycfh
            if browser.leftNaviButtonsRootVCOpt {
                Self.logger.info("reset ifneeded when leftNaviButtonsRootVCOpt is true")
                resetAndUpdateLeftItems(browser: browser)
            }
            // 若通过web-meta隐藏导航栏按钮
            if let barStyleExtension = browser.resolve(NavigationBarStyleExtensionItem.self),
               (barStyleExtension.hideItems?.back == true || barStyleExtension.hideItems?.close == true) {
                Self.logger.info("reset if needed when hide back or close barbuttonitem")
                resetAndUpdateLeftItems(browser: browser)
            }
        } else {
            // 为什么要保留这个逻辑？因为在 iPad 场景需要在多 scene 切换等 viewDidAppear 场景刷新左侧按钮列表（会更新个数）
            resetAndUpdateLeftItems(browser: browser)
        }
    }
    /// 设置导航栏左侧按钮显隐状态
    fileprivate func setLeftItemsHidden(hidden: Bool, animated: Bool) {
        guard let browser = browser else {
            return
        }
        // 仅主页可以隐藏左侧导航按钮, 效果对齐 Android 实现, 避免用户误以为次级页面无法返回或关闭容器
        isHiddenLeftItems = !browser.webview.canGoBack && hidden
        if isHiddenLeftItems {
            if let items = browser.navigationItem.leftBarButtonItems {
                prevLeftBarBtnItems = items
                browser.navigationItem.setLeftBarButtonItems(nil, animated: animated)
                browser.navigationItem.setHidesBackButton(true, animated: animated)
                Self.logger.info("setLeftItemsHidden from false to \(hidden), animated: \(animated)")
            }
        } else {
            if browser.navigationItem.leftBarButtonItems == nil {
                if browser.configuration.autoResetNavigationBar || !hasCustomLeftItems(prevLeftBarBtnItems) {
                    resetAndUpdateLeftItems(browser: browser)
                } else {
                    browser.navigationItem.setLeftBarButtonItems(prevLeftBarBtnItems, animated: animated)
                }
                Self.logger.info("setLeftItemsHidden from true to \(hidden), animated: \(animated)")
            }
        }
    }
    
    public func updateLeftNaviButtonsRootVCOpt(leftNaviButtonsRootVCOpt:Bool) {
        Self.logger.info("updateLeftNaviButtonsRootVCOpt to \(leftNaviButtonsRootVCOpt)")
        if Thread.isMainThread {
            if let browser = self.browser {
                self.resetAndUpdateLeftItems(browser: browser)
            }
        } else {
            DispatchQueue.main.async {
                if let browser = self.browser {
                    self.resetAndUpdateLeftItems(browser: browser)
                }
            }
        }
    }
}

final public class NavigationBarLeftWebBrowserLifeCycle: WebBrowserLifeCycleProtocol {
    private weak var item: NavigationBarLeftExtensionItem?
    init(item: NavigationBarLeftExtensionItem) {
        self.item = item
    }
    
    public func viewDidLoad(browser: WebBrowser) {
        item?.setupLeftNavigationBarButtonItemsObservable(browser: browser)
        item?.resetAndUpdateLeftItems(browser: browser)
    }
    
    public func viewDidAppear(browser: WebBrowser, animated: Bool) {
        item?.resetAndUpdateDefaultLeftItemsIfNeeded(browser: browser)
    }
    
    public func traitCollectionDidChange(browser: WebBrowser, previousTraitCollection: UITraitCollection?) {
        item?.resetAndUpdateDefaultLeftItemsIfNeeded(browser: browser)
    }
}

final public class NavigationBarLeftWebBrowserNavigation: WebBrowserNavigationProtocol {
    private weak var item: NavigationBarLeftExtensionItem?
    init(item: NavigationBarLeftExtensionItem) {
        self.item = item
    }
    
    public func browser(_ browser: WebBrowser, didCommit navigation: WKNavigation!) {
        if browser.configuration.autoResetNavigationBar {
            // 网页前进/后退/重载时需要重置(单页应用不会，这种场景交给应用自己控制)
            item?.resetAndUpdateLeftItems(browser: browser)
        }
    }
}

// MARK: - 导航栏中部
/// 导航栏中部 item
final public class NavigationBarMiddleExtensionItem: WebBrowserExtensionItemProtocol {
    public var itemName: String? = "NavigationBarMiddle"
    static let logger = Logger.webBrowserLog(NavigationBarMiddleExtensionItem.self, category: "NavigationBarMiddleExtensionItem")
    
    public lazy var lifecycleDelegate: WebBrowserLifeCycleProtocol? = NavigationBarMiddleWebBrowserLifeCycle(item: self)
    
    /// 自定义title view
    private lazy var titleView = BaseTitleView()
    
    public init() {}
    
    /// 更新导航栏标题
    /// 因自定义了标题字体和颜色，故不能直接设置navigationItem.title或self.title
    /// 需要使用下面的方法来更新标题
    public func setNavigationTitle(browser: WebBrowser, title: String) {
        Self.logger.info("update title from \(titleView.nameLabel.text) to \(title)")
        titleView.setTitle(title: title)
    }
    
    public func setNavigationTitle(browser: WebBrowser, title: String, lineBreakMode: NSLineBreakMode) {
        Self.logger.info("update title from \(titleView.nameLabel.text) to \(title), \(lineBreakMode) mode")
        titleView.nameLabel.lineBreakMode = lineBreakMode
        titleView.setTitle(title: title)
    }
    
    private var titleObservation: NSKeyValueObservation?
    /// 导航栏title跟着document.title走
    func setupTitleObservable(browser: WebBrowser) {
        titleObservation = browser
            .webview
            .observe(
                \.title,
                options: [.old, .new],
                changeHandler: { [weak self, weak browser] (webView, change) in
                    guard let `self` = self, let browser = browser else { return }
                    Self.logger.info("webview title changed from {\(change.oldValue)} to {\(change.newValue)}")
                    var title = ""
                    if let newTitlt = change.newValue, let t = newTitlt {
                        title = t
                    }
                    self.setNavigationTitle(browser: browser, title: title)
                }
            )
    }
    
    /// 初始时配置UI
    func setupUI(browser: WebBrowser) {
        //  初始化导航栏 titleView
        browser.navigationItem.titleView = titleView
    }
    
}

final public class NavigationBarMiddleWebBrowserLifeCycle: WebBrowserLifeCycleProtocol {
    private weak var item: NavigationBarMiddleExtensionItem?
    init(item: NavigationBarMiddleExtensionItem) {
        self.item = item
    }
    
    public func viewDidLoad(browser: WebBrowser) {
        item?.setupTitleObservable(browser: browser)
        item?.setupUI(browser: browser)
    }
}

// MARK: 导航栏右侧
// 导航栏右侧 items管理
final public class NavigationBarRightExtensionItem: WebBrowserExtensionItemProtocol {
    public var itemName: String? = "NavigationBarRight"
    static let logger = Logger.webBrowserLog(NavigationBarRightExtensionItem.self, category: "NavigationBarRightExtensionItem")
    
    public lazy var lifecycleDelegate: WebBrowserLifeCycleProtocol? = NavigationBarRightWebBrowserLifeCycle(item: self)
    
    public lazy var navigationDelegate: WebBrowserNavigationProtocol? = NavigationBarRightWebBrowserNavigation(item: self)
    
    public lazy var browserDelegate: WebBrowserProtocol? = NavigationBarRightWebBrowserDelegate(item: self)
    
    private weak var browser: WebBrowser?
    
    public var isMetaHideRightItems: Bool = false
    
    public var isMetaHideMoreRightItems: Bool = false
    
    public var isShowRightButton : Bool = true
    
    public var isWebDownloadPreviewHidden : Bool = false
    
    public var isBizApiHideItems : Bool = false
    
    public var isHideRightItems : Bool = false
    
    public var customItems: [UIBarButtonItem]? = nil
    
    /// 容器Badge路径
    private var containerPath: LarkBadge.Path {
        return Path().prefix(Path().web_url, with: String(browser?.browserURL?.absoluteString.hash ?? 0))
    }
    
    /// 容器NaviButton路径
    private var containerButtonPath: LarkBadge.Path {
        containerPath.web_more
    }
    
    // 标记是否需要展示 business 插件，主要用于URL变化时清空旧插件按钮
    var isBusinessPluginsShow: Bool = false
    
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
    
    public init(browser: WebBrowser) {
        self.browser = browser
    }
    
    private var urlObservation: NSKeyValueObservation?
    /// 直接复用LarkBadge组件的能力
    func setupURLObservable(browser: WebBrowser) {
        urlObservation = browser
            .webview
            .observe(
                \.url,
                options: [.old, .new],
                changeHandler: { [weak self, weak browser] (_, _) in
                    guard let `self` = self, let browser = browser else { return }
                    /// 直接复用LarkBadge组件的能力
                    browser.view.badge.observe(for: self.containerPath)
                    browser.view.badge.set(type: .clear)
                    self.moreItem.button.badge.observe(for: self.containerButtonPath)
                }
            )
    }
    
    public func resetAndUpdateRightItems(browser: WebBrowser) {
        // meta ,
        if isMetaHideRightItems {
            Self.logger.info("hide RightBarButtonItems for meta")
            browser.navigationItem.setRightBarButtonItems(nil, animated: false)
            return
        }
        
        if isMetaHideMoreRightItems {
            Self.logger.info("hide RightBarButtonItems for close config hide more")
            browser.navigationItem.setRightBarButtonItems(nil, animated: false)
            return
        }
        
        if !isShowRightButton {
            Self.logger.info("hide RightBarButtonItems for isShowRightButton:\(isShowRightButton)")
            browser.navigationItem.setRightBarButtonItems(nil, animated: false)
            return
        }
        
        if isWebDownloadPreviewHidden {
            Self.logger.info("hide RightBarButtonItems for downdload preview")
            browser.navigationItem.setRightBarButtonItems(nil, animated: false)
            return
        }
        
        if isHideRightItems {
            Self.logger.info("hide RightBarButtonItems for hide right items")
            browser.navigationItem.setRightBarButtonItems(nil, animated: false)
            return
        }
        
        guard let url = browser.webview.url else {
            Self.logger.info("hide RightBarButtonItems for nil url")
            browser.navigationItem.setRightBarButtonItems(nil, animated: false)
            return
        }
        // 回调的url参数是browserURL包含错误页等场景, 需要使用当前的webview.url
        if WebDetectHelper.isValid(url: url) {
            Self.logger.info("hide RightBarButtonItems for detect page url")
            browser.navigationItem.setRightBarButtonItems(nil, animated: false)
            return
        }
        
        if let customItems = customItems {
            // 网页自定义右侧导航栏
            Self.logger.info("set custom right buttons\(customItems.count)")
            browser.navigationItem.setRightBarButtonItems(customItems, animated: false)
            return
        }
        
        var items:[LKBarButtonItem] = []

        if let barStyleExtension = browser.resolve(NavigationBarStyleExtensionItem.self),
           barStyleExtension.hideItems?.more == true {
            Self.logger.info("hide the more barbuttonitem because hideNavBarItems.more is true")
        } else {
            items.append(moreItem)
        }
        
        if Display.pad {
            //一事一群一档功能 或 MyAI分会话功能 打开，走新逻辑
            Self.logger.info("[Web MyAI ChatMode] display on pad")

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
    
    @objc private func clickMore() {
        guard let browser = browser else { return }
        Self.logger.info("more item clicked")
        if let menuItem = browser.resolve(WebMenuExtensionItem.self) {
            menuItem.showMenu(browser: browser, containerButtonPath: self.containerButtonPath)
        }
        moreItem.webReportClick(applicationID: browser.currrentWebpageAppID())
    }
    
    @objc private func launchNaviMyAI() {
        guard let browser = browser else { return }
        Self.logger.info("[Web MyAI ChatMode] On navigationBar, my AI item clicked")
        browser.launchMyAI()
        
        myAiItem.webReportClick(applicationID: browser.currrentWebpageAppID())
    }
}

final public class NavigationBarRightWebBrowserLifeCycle: WebBrowserLifeCycleProtocol {
    private weak var item: NavigationBarRightExtensionItem?
    init(item: NavigationBarRightExtensionItem) {
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

final public class NavigationBarRightWebBrowserNavigation: WebBrowserNavigationProtocol {
    private weak var item: NavigationBarRightExtensionItem?
    
    init(item: NavigationBarRightExtensionItem) {
        self.item = item
    }
    
    public func browser(_ browser: WebBrowser, didCommit navigation: WKNavigation!) {
        if browser.configuration.autoResetNavigationBar {
            // 网页前进/后退/刷新时需要重置右侧按钮到默认状态
            item?.customItems = nil
            item?.resetAndUpdateRightItems(browser: browser)
        }
    }
}

final public class NavigationBarRightWebBrowserDelegate: WebBrowserProtocol {
    private weak var item: NavigationBarRightExtensionItem?
    
    init(item: NavigationBarRightExtensionItem) {
        self.item = item
    }
    
    public func browser(_ browser: WebBrowser, didURLChanged url: URL?) {
        guard let item = item else { return }
        if Display.pad, browser.isBusinessPluginsEnable {
            // iPad 上一事一群一档功能打开时，URL 变化后需要移除已有 item
            item.isBusinessPluginsShow = false
            WebMenuExtensionItem.logger.info("[Web Business Plugin] url changed, resetAndUpdateRightItems")
        }
        item.resetAndUpdateRightItems(browser: browser)
        if Display.pad, browser.isWebMyAIChatModeEnable() {
            WebMenuExtensionItem.logger.info("[Web MyAI ChatMode] url changed, resetAndUpdateRightItems")
        }
    }
    
    public func browser(_ browser: WebBrowser, didImBusinessPluginChanged imPlugin: BusinessBarItemsForWeb?, didDocBusinessPluginChanged docPlugin: BusinessBarItemsForWeb?) {
        guard let item = item else {
            WebMenuExtensionItem.logger.info("WebMenuExtensionItem not exist")
            return
        }
        guard browser.isBusinessPluginsEnable else {
            WebMenuExtensionItem.logger.info("browser.isBusinessPluginsEnable is false")
            return
        }
        guard Display.pad,
              let trait = browser.rootWindow()?.traitCollection,
              let size = browser.rootWindow()?.bounds.size,
              TraitCollectionKit.customTraitCollection(trait, size).horizontalSizeClass != .compact else {
            // 处于C视图下，无需更新业务插件
            WebMenuExtensionItem.logger.info("not in R scene")
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
            WebMenuExtensionItem.logger.info("[Web MyAI ChatMode] browser.isBusinessPluginsEnable and browser.isWebMyAIChatModeEnable() is false")
            return
        }
        WebMenuExtensionItem.logger.info("[Web MyAI ChatMode] CollapseState changed to \(state), resetAndUpdateRightItems")
        item.resetAndUpdateRightItems(browser: browser)
    }
}
