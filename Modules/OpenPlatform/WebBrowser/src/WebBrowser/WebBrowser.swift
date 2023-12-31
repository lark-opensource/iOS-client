//
//  WebBrowser.swift
//  WebBrowser
//
//  Created by houjihu on 2020/9/29.
//

import ECOInfra
import ECOProbe
import EENavigator
import LarkBadge
import LarkOPInterface
import LarkSceneManager
import LarkSetting
import LarkSplitViewController
import LarkUIKit
import LarkWebViewContainer
import LKCommonsLogging
import UIKit
import UniverseDesignColor
import UniverseDesignEmpty
import UniverseDesignProgressView
import UniverseDesignTheme
import LarkContainer
import LarkMonitor
import OPFoundation
import LarkQuickLaunchBar
import LarkQuickLaunchInterface
import LarkAIInfra
import RxSwift
import LarkKeyCommandKit

// https://bytedance.feishu.cn/wiki/wikcnwVecT24cPbqXj4L6teAYSd

public enum WebBrowserScene: RawRepresentable {
    /// 工作台
    case workplacePortal
    /// 主Tab
    case mainTab
    /// 正常跳转
    case normal
    /// 半屏应用
    case panel
    // ipad上的临时标签
    case temporaryTab
    
    public var rawValue: String {
        switch self {
        case .workplacePortal:
            return "workplacePortal"
        case .mainTab:
            return "mainTab"
        case .normal:
            return "normal"
        case .panel:
            return "panel"
        case .temporaryTab:
            return "temporaryTab"
        }
    }
    
    public init(rawValue: String) {
        switch rawValue {
        case "workplacePortal":
            self = .workplacePortal
        case "mainTab":
            self = .mainTab
        case "normal":
            self = .normal
        case "panel":
            self = .panel
        case "temporaryTab":
            self = .temporaryTab
        default:
            self = .normal
        }
    }
}

public enum WebBrowserFromScene: RawRepresentable {
    /// normal
    case normal
    /// char & group chat
    case chat
    /// 个人签名
    case profile
    /// 工作台
    case workplace
    // 大搜
    case search
    // 网页window.open
    case web
    // 小程序 openschema
    case gadget
    // 主导航 mainTab
    case mainTab
    // web工作台 workplacePortal
    case workplacePortal
    // feed场景
    case feed
    // launcher_more：main
    case launcherFromMain
    // launcher_more：main
    case launcherFromQuick
    // launcher_more：main
    case launcherFromTemporary
    
    public var rawValue: String {
        switch self {
        case .normal:
            return "normal"
        case .chat:
            return "chat"
        case .profile:
            return "profile"
        case .workplace:
            return "workplace"
        case .search:
            return "search"
        case .web:
            return "web"
        case .gadget:
            return "gadget"
        case .mainTab:
            return "mainTab"
        case .workplacePortal:
            return "workplacePortal"
        case .feed:
            return "feed"
        case .launcherFromMain:
            return "launcherFromMain"
        case .launcherFromQuick:
            return "launcherFromQuick"
        case .launcherFromTemporary:
            return "launcherFromTemporary"
        }
    }
    
    public init(rawValue: String) {
        switch rawValue {
        case "normal":
            self = .normal
        case "chat", "message", "multi_cardlink", "single_cardlink","topic_cardlink","single_innerlink","multi_innerlink","topic_innerlink":
            self = .chat
        case "profile", "self_signature":
            self = .profile
        case "workplace":
            self = .workplace
        case "appcenter":
            self = .workplace
        case "search", "global_search":
            self = .search
        case "webbrowser","web_url":
            // webbrowser 网页window.open ，web_url 统一路由网页openschema
            self = .web
        case "gadget", "micro_app":
            // 小程序openschema
            self = .gadget
        case "mainTab":
            self = .mainTab
        case "workplacePortal":
            self = .workplacePortal
        case "feed":
            self = .feed
        case "launcherFromMain":
            self = .launcherFromMain
        case "launcherFromQuick":
            self = .launcherFromQuick
        case "launcherFromTemporary":
            self = .launcherFromTemporary
        default:
            self = .normal
        }
    }
}

/// Suite Unite Browser
public final class WebBrowser: UIViewController, UIScrollViewDelegate, OPContainerViewModeProtocol {
    // 废弃接口，请勿使用
    public lazy var jsSDK: LarkWebJSSDK? = { [weak self] in
        guard let `self` = self else { return nil }
        var jsSdk: LarkWebJSSDK?
        if let builder = self.jsSDKBuilder {
            jsSdk = builder(self)
        } else {
            jsSdk = webBrowserDependency.getLarkWebJsSDK(
                with: self,
                methodScope: self.configuration.jsApiMethodScope
            )
        }
        return jsSdk
    }()
    
    /// 考虑到外部大小写都在用，这两个熟悉暂时都保留
    /// ⚠️警告: 请不要在 viewDidLoad 之前调用该属性，如果错误调用导致事故，需要revert代码，写case study，做复盘，承担事故责任
    public lazy var webview: LarkWebView = {
        createWebView()
    }()
    /// ⚠️警告: 请不要在 viewDidLoad 之前调用该属性，如果错误调用导致事故，需要revert代码，写case study，做复盘，承担事故责任
    public var webView: WKWebView { webview }

    // 用于同步Cookie
    //  对接人：houzhiyou@bytedance.com
    static let defaultWKProcessPool: WKProcessPool = {
        return WKProcessPool()
    }()

   public enum BroswerProcessStage: Int {
        case Init = 0
        case PrepareLoadURL = 1
        case HasStartedURL = 2
        case HasFinishedURL = 3
        case HasFailedURL = 4
        case DidTerminate = 5
    }
    /// 标记容器经过的状态
   public var processStage: BroswerProcessStage = BroswerProcessStage.Init
    
    /// 初始化时设置的URL
    var firstLoadURL: URL?
    
    /// 当前失败页正在显示时的对应的失败页面的 url，如果失败页不显示了则应当置为 nil
    var failingURL: URL? {
        didSet {
            if failingURL != oldValue {
                notifyURLChanged()
            }
        }
    }
    public var newFailingURL: URL? {
        guard let webviewURL = webview.url else {
            return nil
        }
        guard webviewURL.isErrorPageURL() else {
            return nil
        }
        guard let component = URLComponents(url: webviewURL, resolvingAgainstBaseURL: false) else {
            return nil
        }
        guard let failedUrlValue = component.queryItems?.first(where: { item in
            item.name == BrowserFailedUrlQueryName
        })?.value else {
            return nil
        }
        guard let originalUrl = URL(string: failedUrlValue) else {
            return nil
        }
        return originalUrl
    }

    /// 获取 browser 的 URL（包含了失败页面等场景的支持），不等同于 webview.url
    /// 可通过 WebBrowserProtocol 监听变化
    /// 如果要获取当前 webview.url，请直接调用 webview.url 即可(webview.url  在加载失败等场景下可能为空)
    /// 参考文档：https://bytedance.feishu.cn/docx/doxcnbdRNda3rwdK9wy0cfX8teh
    /// 由于 Browser 支持添加到浮窗，那边也有个url属性，避免冲突，这里改个名字
    /// ⚠️警告: 请不要在 viewDidLoad 之前调用该属性，如果错误调用导致事故，需要revert代码，写case study，做复盘，承担事故责任
    public var browserURL: URL? {
        return newFailingURL ?? webView.url ?? firstLoadURL
    }
    //记录最新的URL
    public var browserLastestURL: URL? = nil

    //  todo: 下边属性迁移到导航能力extension
    /// 记录导航栏隐藏状态
    public var isNavigationBarHidden: Bool = false
    
    public var bizType :LarkWebViewBizType?

    //半屏模式参数值
    public var viewMode: String?
    public var viewRatio: String?
    /// 初始化时设置的referer url
    let originRefererURL: URL?
    public var feedId: String?
    public var isFormSheet: Bool = false
    
    /// 设置该属性将会覆盖默认的 JSSDKBuildler
    public var jsSDKBuilder: ((WebBrowser) -> LarkWebJSSDK)!
    
    public var leftNaviButtonsRootVCOpt: Bool = false
    
    public var reportAppIdSet = Set<String>()
    public var resolver: Resolver?
    public var sdpTimeoutTimer: Timer? = nil
    
    public var faviconURL: String?
    
    /// 尝试以非 WebBrowser 打开
    /// - Parameters:
    ///   - url: 打开的URL
    ///   - from: 来源URL
    /// - Returns: 如果用非 WebBrowser 打开返回 true，否则 false
    func tryOpenNotInWebbrowser(url: URL, from: URL?, closeSelf: Bool = false) -> Bool {
        //  目前给passport单独开个入口，回头通过extension统一迁移到passport管理，非passport请勿设置，如果乱设置导致线上事故，请revert代码，写case study，做复盘，承担事故责任
        if configuration.notUseUniteRoute {
            return false
        }
        let canOpenInWeb = Navigator.shared.response(for: url, test: true).parameters["_canOpenInWeb"] as? Bool == true// user:global
        if canOpenInWeb || url.isFileURL {
            Self.logger.info("canOpenInWeb or fileurl, canOpenInWeb:\(canOpenInWeb)")
            return false
        }
        
        Self.logger.info("controller.openURL Navigator.shared.push \(url.safeURLString), closeSelf: \(closeSelf)")
        let canOptimize = FeatureGatingManager.shared.featureGatingValue(with: FeatureGatingManager.Key(stringLiteral: "openplatform.web.windowopen.optimize.enable"))// user:global
        let appId = self.currrentWebpageAppID() ?? ""
        if canOptimize && Display.pad {
            Navigator.shared.showDetailOrPush(// user:global
                url,
                context: [
                    "from": from?.absoluteString,
                    // 单纯为了兼容上面这个from被历史乱用的问题，其他业务场景from都是固定值，这里就变成动态的值了, 目前没法枚举都有哪些地方在消费这个from，只能新增kv
                    "lk_web_from": "webbrowser",
                    "open_doc_desc" : self.browserURL?.absoluteString ?? "",
                    "open_doc_source" : "web_applet",
                    "open_doc_app_id": appId,
                ],
                from: self)
        }else{
            Navigator.shared.push(// user:global
                url,
                context: [
                    "from": from?.absoluteString,
                    // 单纯为了兼容上面这个from被历史乱用的问题，其他业务场景from都是固定值，这里就变成动态的值了, 目前没法枚举都有哪些地方在消费这个from，只能新增kv
                    "lk_web_from": "webbrowser",
                    "open_doc_desc" : self.browserURL?.absoluteString ?? "",
                    "open_doc_source" : "web_applet",
                    "open_doc_app_id": appId,
                ],
                from: self)
        }
        if closeSelf {
            self.delayRemoveSelfInViewControllers()
        }
        return true
    }

    /// log
    public static let logger = Logger.webBrowserLog(WebBrowser.self, category: NSStringFromClass(WebBrowser.self))

    // MARK: webview custom configuration
    /// LarkWebview configuration
    public var configuration: WebBrowserConfiguration

    /// 屏幕旋转方向
    var orientation: UIDeviceOrientation = .portrait
    
    var isBrowserRotationOptimizeEnable: Bool = {
        return FeatureGatingManager.shared.featureGatingValue(with: FeatureGatingManager.Key(stringLiteral: "openplatform.web.browser.rotation.optimize.ios"))
    }()
    
    /// 当前支持的屏幕旋转方向,进入网页容器默认支持竖屏，支持通过api或者meta配置将屏幕方向设置为横屏
    var lk_supportedInterfaceorientationMask : UIInterfaceOrientationMask = .portrait
    
    var isBrowserRotationOptimizeDisable: Bool = {
        return OPUserScope.userResolver().fg.staticFeatureGatingValue(with: "openplatform.web.browser.rotation.optimize.ios.disable")
    }()
    
    /// 进入网页容器时应用方向
    let fromSceneOrientation: UIDeviceOrientation = UIDevice.current.orientation
    
    lazy var enableDarkModeOptimization: Bool = {
        if #available(iOS 13, *) {
            return true
        } else {
            return false
        }
    }()
    
    /// Extension Item 管理器
    var extensionManager = WebBrowserExtensionManager()
    
    /// 页面请求周期下载使用的原始URLRequest
    var pendingRequests = [String: URLRequest]()
    
//    @InjectedOptional var driveService: DriveDownloadServiceProtocol?// Global
    
    /// 导航栏右侧按钮控制显隐时副本
    var rightBarBtnItems: [UIBarButtonItem]?
    
    /// 需要在已有 UserAgent 末尾添加的字段
    public static var nativeAppendUA: String? = nil
    
    /// 标识“当前容器首页添加到桌面”配置是否开启
    public var addFirstLinkToDesk: Bool = false

    // 网页容器功耗埋点,https://bytedance.feishu.cn/wiki/wikcnCmvpVZJfCdnlRa5MzVtN7f
    public static let powerLoggerEventName = "op_webbrowser_load"
    
    // 网页容器侧滑关闭
    var canSlideToClose: Bool = false
    
    // 网页容器支持前进和后退
    var allowsBackForwardGestures: Bool = true
    
    // 网络状态
    @Provider var netStatusService: OPNetStatusHelper// Global
    var netStatus: OPNetStatusHelper.OPNetStatus = .unknown
    
    /// https://meego.feishu.cn/larksuite/story/detail/9683337
    public var webHomeIndicatorAutoHiddenFGEnable: Bool = FeatureGatingManager.realTimeManager.featureGatingValue(with: FeatureGatingManager.Key(stringLiteral: "openplatform.web.ios.homeindicatorautohidden"))
    
    /// 底部 Launch Bar
    ///  https://meego.feishu.cn/larksuite/story/detail/12365507
    public var launchBar: QuickLaunchBar?
    
    /// 容器侧标识底部 Launch Bar 是否开启
    /// 初始 configuration.isLaunchBarEnable 为 true（默认）, 容器侧 disable FG 关闭
    /// 且 主端 FG 开启，显示模式为 iphone 或者 iPad 的窄屏模式（应用分屏，split View），
    /// Bar 创建成功时才会显示容器底部 Launch Bar
    public var isWebLaunchBarEnable: Bool = true
    
    /// 标记用户有过滑动手势
    /// 首页加载时WebKit会自动触发向下滑动的事件（scrollViewDidScroll）使底部 Launch Bar 被收起
    /// 此处让用户滑动手势触发后才响应 scrollViewDidScroll 去收起底部 Launch Bar
    public var isUserDragged: Bool = false
    // https://bytedance.feishu.cn/wiki/VEOSwUGgnigmpykcOK1cZC8Tn3T?theme=LIGHT&contentTheme=DARK&theme=LIGHT&contentTheme=DARK
    static let appScene = "OpenWebContainer"
    /// MyAI 分会话配置
    public var myAIChatModeConfig: MyAIChatModeConfig?
    
    /// 获取网页全文内容并初步清洗的 JS 脚本
    ///  通过 settings 下发，在LaunchBarExtensionItem初始化时赋值
    public var getWebContentJS: String = ""
    
    /// 和My AI分会话交互的服务
    public var myAIChatModePageService: MyAIChatModeConfig.PageService?
    
    public typealias ChatModeConfigCompleteBlock = (MyAIChatModeConfig?) -> Void?
    
    public let disposeBag = DisposeBag()

    /// 一事一群一档功能开关
    public var isBusinessPluginsEnable: Bool = {
        let disableFG = !OPUserScope.userResolver().fg.staticFeatureGatingValue(with: FeatureGatingManager.Key(stringLiteral: "openplatform.web.businessplugins.disable"))
        let enableFG = OPUserScope.userResolver().fg.staticFeatureGatingValue(with: FeatureGatingManager.Key(stringLiteral: "core.content_plugin.whitelist"))
        return (disableFG && enableFG)
    }()
    /// IM 提供群插件的服务
    public var imPluginForWebService: ImPluginForWebProtocol? = nil
    /// 一事一群功能，IM提供的群插件，用于展示在底部 LaunchBar 或顶部 NavigationBar
    public var imBarItemsMap: BusinessBarItemsForWeb? = nil
    /// Doc 提供文档插件的服务
    public var docPluginForWebService: DocPluginForWebProtocol? = nil
    /// 一事一档功能，Doc提供的文档插件，用于展示在底部 LaunchBar 或顶部 NavigationBar
    public var docBarItemsMap: BusinessBarItemsForWeb? = nil
    
    // 导航右侧插件统一管理功能禁用,默认是false
    public var isNavigationRightBarExtensionDisable: Bool = OPUserScope.userResolver().fg.dynamicFeatureGatingValue(with: "openplatform.web.browser.navigationrightbaritem.disable")
    
    var urlObservation: NSKeyValueObservation?
    
    // TODO: luogantong, 把resolver从init传进去
    
    /// 保活相关属性开始
    /// 保活场景值，normal表示不做保活
    public var pageScene: LarkQuickLaunchInterface.PageKeeperScene = .normal

    /// 当关闭的时候是否需要走保活逻辑，默认是true，如果已经走了closeBrowser，那么设置为false
    public var shouldCacheBrowserWhenClose: Bool = true
    
    
    /// 记录初始化的时候是否是C视图
    public var initIsCollapsed: Bool = false
    
    /// 记录当前是否是C视图
    public var isCollapsed: Bool = false
    
    // 当前vc是否进行了复用，复用vc不需要重复注册插件
    public var isReuseBrowser: Bool = false
    /// 保活相关属性结束
    
    // iPad标签页场景是否执行了removeTabVC,已经执行的情况下，不需要再调用updatetabVC更新信息了
    public var didExecuteRemoveTabVC: Bool = false
    
    
    /// Browser初始化 请在主线程调用
    /// - Parameters:
    ///   - url: 初始加载地址
    ///   - configuration: The configuration for the new browser.
    public init(
        url: URL? = nil,
        configuration: WebBrowserConfiguration = WebBrowserConfiguration()
    ) {
        //  Tips：该方法结束前不要出发viewDidLoad，否则会导致严重的 Extension 框架生命周期问题
        firstLoadURL = url
        bizType = configuration.webBizType
        self.configuration = configuration
        leftNaviButtonsRootVCOpt = configuration.leftNaviButtonsRootVCOpt
        originRefererURL = configuration.originRefererURL
        self.isWebLaunchBarEnable = configuration.isLaunchBarEnable
        if FeatureGatingManager.shared.featureGatingValue(with: "openplatform.web.browser.launchbar.disable") {
            self.isWebLaunchBarEnable = false
            Self.logger.lkwlog(level: .info, "FG openplatform.web.browser.launchabar.disable is open.", traceId: configuration.initTrace?.traceId)
        }
        super.init(nibName: nil, bundle: nil)
        #if DEBUG
        try? register(item: TestCaseExtensionItem())
        #endif
        Self.logger.lkwlog(level: .info, "init WebBrowser:\(self) with urlecoSafeURL:\(url?.safeURLString) configuration:\(configuration.toString())", traceId: configuration.initTrace?.traceId)
        
        addNetStatusObserver()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        self.handleMultiExternalOnClose()
        removeNetStatusObserver()
        if !FeatureGatingManager.shared.featureGatingValue(with: FeatureGatingManager.Key(stringLiteral: "openplatform.web.browser.larkappmonitor.disable")) {// user:global
            BDPowerLogManager.endEvent(WebBrowser.powerLoggerEventName, params: [
                webBrowserIDKey : self.configuration.webBrowserID ?? "",
                traceIDKey : self.configuration.initTrace?.traceId ?? ""
            ])
        }
        if isBusinessPluginsEnable {
            self.imPluginForWebService?.destroyBarItems()
            self.docPluginForWebService?.destroyBarItems()
        }
        extensionManager.items.forEach { $0.lifecycleDelegate?.webBrowserDeinit(browser: self) }
        Self.logger.lkwlog(level: .info, "deinit WebBrowser:\(self)", traceId: self.configuration.initTrace?.traceId)
    }
    //  此函数需要等路由统一提供能力后迁移过去
    public func closeBrowser() -> Bool {
        Self.logger.info("close WebBrowser")
        if !FeatureGatingManager.shared.featureGatingValue(with: FeatureGatingManager.Key(stringLiteral: "openplatform.web.meta.landscape.popanimation.disable")) { // user:global
            // disable 开关，线上有问题的话，关闭后 不做任何处理，使用系统的退出动画，界面会很突兀
            // 判断当前方向是否是竖屏，如果不是竖屏, 且前一个界面是竖屏，那么先切回竖屏方向
            if !Display.pad , (self.orientation == UIDeviceOrientation.landscapeRight || self.orientation == UIDeviceOrientation.landscapeLeft), fromSceneOrientation == .portrait {
                Self.logger.info("change orientation to portrait before closeBrowser")
                self.setScreenOrientation(UIDeviceOrientation.portrait)
            }
        }
        if configuration.scene == .temporaryTab, let myAIQuickLaunchBarService = resolver?.resolve(LarkOpenPlatformMyAIService.self) {
            didExecuteRemoveTabVC = true
            if configuration.scene == .temporaryTab, let pageKeeperService = try? resolver?.resolve(assert: PageKeeperService.self), let pagePreservable = self as? PagePreservable{
                Self.logger.info("keepalive user close browser:\(configuration.initTrace?.traceId)")
                pageKeeperService.removePage(pagePreservable, force: true, notice: true) { result in
                    Self.logger.info("keepalive user close remove from pagekeeper result:\(result)")
                }
                shouldCacheBrowserWhenClose = false
            }
            Self.logger.info("close browser scene == .temporaryTab myAIQuickLaunchBarService.removeTabVC(self)")
            myAIQuickLaunchBarService.removeTabVC(self)
            Self.logger.info("removeTabVC, traceId:\(configuration.initTrace?.traceId)")
            return true
        }
        
        
        // method code from lixiaorui, commit msg: iPad兼容 从 ios-client 迁移过来，没修改任何逻辑
        guard let nav = navigationController else {
            // present
            dismiss(animated: true, completion: nil)
            return true
        }
        guard let topvc = nav.topViewController else {
            Self.logger.warn("nav top vc is nil, nav: \(nav), vcs: \(nav.viewControllers)")
            return false
        }
        guard topvc == self || topvc.children.contains(self) else {
            Self.logger.warn("web vc is not at the top level, topvc: \(nav.viewControllers)")
            return false
        }
        // zhysan todo: iPad 兼容性验证
        //  iPad兼容 @lixiaorui
        if nav.viewControllers.count == 1 {
            if let split = nav.larkSplitViewController,
               nav === split.secondaryViewController {
                // if split detail pop last, show default detail page
                if let fromVC = Navigator.shared.mainSceneWindow?.fromViewController {// user:global
                    Navigator.shared.showDetail(LKSplitViewController2.DefaultDetailController(), from: fromVC)// user:global
                } else {
                    Self.logger.error("OpenPlatformAPIHandlerImp close can not show vc because no fromViewController")
                }
            } else {
                // nav has only one vc, so no more vc to pop, go dismiss
                nav.dismiss(animated: true, completion: nil)
            }
        } else {
            nav.popViewController(animated: true)
        }
        return true
    }
    /// 若当前页面 未配置侧滑关闭 且 可以在会话历史记录中向后移动一页, 则直接到上一页. 否则直接关闭容器
    /// ⚠️警告: 请不要在 viewDidLoad 之前调用该属性，如果错误调用导致事故，需要revert代码，写case study，做复盘，承担事故责任
    public func goBackOrClose() {
        if !canSlideToClose && webView.canGoBack {
            webView.goBack()
            return
        }
        closeBrowser()
    }
    
    /// 加载URL (code from houzhiyou)
    public func loadURL(_ url: URL, originRefererURL: URL? = nil) {
        processStage = .PrepareLoadURL
        extensionManager.items.forEach { $0.browserDelegate?.browser(self, willLoadURL: url) }
        webview.lwvc_loadRequest(URLRequest(url: url), prevUrl: originRefererURL)
    }
    
    /// 重新加载（支持失败页面场景重试），不等同于 webview.reload/reloadFromOrigin
    /// ⚠️警告: 请不要在 viewDidLoad 之前调用该属性，如果错误调用导致事故，需要revert代码，写case study，做复盘，承担事故责任
    public func reload() {
        var reloadURL: URL? = nil
        if let newFailingURL = newFailingURL {
            reloadURL = newFailingURL
            webview.evaluateJavaScript("location.replace('\(newFailingURL.absoluteString)')")
        } else if let webURL = webview.url {
            reloadURL = webURL
            // 正常情况下通过 reloadFromOrigin 方式重试
            webView.reloadFromOrigin()
        } else {
            if let url = browserURL {
                reloadURL = url
            // 兜底情况
            loadURL(url)
            } else {
                Self.logger.error("url is nil, cannot reload")
            }
        }
        if browserNewErrorTimedOutNoResponse {
        if let url = reloadURL {
            processStage = .PrepareLoadURL
            extensionManager.items.forEach { $0.browserDelegate?.browser(self, didReloadURL: url) }
        }
        }
    }

    /// Split 容器状态发生变化
    public override func splitVCSplitModeChange(split: SplitViewController) {
        Self.logger.info("splt change to  \(split.splitMode.rawValue)")
        resolve(NavigationBarStyleExtensionItem.self)?.checkAndUpdateSwipeBack(browser: self)
        if let myAIQuickLaunchBarService = resolver?.resolve(LarkOpenPlatformMyAIService.self), myAIQuickLaunchBarService.isTemporaryEnabled() {
            resolve(NavigationBarLeftExtensionItem.self)?.resetAndUpdateDefaultLeftItemsIfNeeded(browser: self)
        }
    }
    
    public func recordBrowserTimeConsumingIn(phase:WebviewTimeConsumingPhase, duration:TimeInterval){
        self.webview.recordTimeConsumingIn(phase: phase, duration: duration)
    }
    
    public func recordExtensionItemTimeConsumingIn(phase:WebviewTimeConsumingPhase, duration:TimeInterval,itemName:String?){
        if let name = itemName {
            self.webview.recordExtensionItemTimeConsumingIn(phase: phase, duration: duration, itemName: name)
        }
    }
    
    override public func keyBindings() -> [KeyBindingWraper] {
        return super.keyBindings() + externalKeyCommand()
    }
}

extension WebBrowser {
    /// ⚠️警告: 请不要在 viewDidLoad 之前调用该属性，如果错误调用导致事故，需要revert代码，写case study，做复盘，承担事故责任
    public func getTrace() -> OPTrace {
        return webview.trace ?? configuration.initTrace ?? OPTraceService.default().generateTrace()
    }
}

extension WebBrowser {
    // 废弃接口请勿使用
    public func call(funcName: String, arguments: [Any]) {
        webView.lu.sendMessage(functionName: funcName, arguments: arguments, completionHandler: {(_ , error) in
            if let err = error {
                Self.logger.error("", error: err)
            }
        })
    }
    public var currentWebPage: WKBackForwardListItem? {
        webview.backForwardList.currentItem
    }
}

/// orientation code from houzhiyou
extension WebBrowser {
    /// 对外API，强制旋转屏幕方向
    public func landscapeScreen(_ orientation: UIDeviceOrientation) {
        Self.logger.info("try landscapeScreen from \(self.orientation) to \(orientation)")
        self.orientation = orientation
        let c = UIDevice.current.orientation
        if c != orientation {
            self.forceRotateOrientation(c, targetOrientation: orientation)
        }
    }
    
    /// WebMeta 方向设置接口
    public func setScreenOrientation(_ orientation: UIDeviceOrientation) {
        Self.logger.info("try setScreenOrientation from \(self.orientation.rawValue) to \(orientation.rawValue)")
        self.orientation = orientation
        let c = UIDevice.current.orientation
        if orientation != .unknown {
            // 对于强制指定方向，不管是否已经设置，都要刷新，避免设置不刷新
            self.forceRotateOrientation(c, targetOrientation: orientation)
        } else {
            // 对于非强制指定方向，保持现有方式
            if c != orientation {
                self.forceRotateOrientation(c, targetOrientation: orientation)
            }
        }
    }

    /// 充分利用系统的转屏策略，不需要多余干扰，仅在controller内部进行处理即可
    /// 1）进入WebViewController时可以全方向旋转
    /// 2）开发者调用rotate orientation相关API后，控制屏幕旋转方向
    public override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        #if swift(>=5.7)
        if #available(iOS 16.0, *) {
            if !isBrowserRotationOptimizeDisable {
                // 开启优化策略后，统一使用lk_supportedInterfaceorientationMask
                return self.interfaceOrientationMaskFromDeviceOrientation(orientation)
            } else if(self.useRotateScreenOldAPI()) {
                // iOS 16.0 (20A5283p)-beta1版本上发现新转屏相关API崩溃；开启该开关走旧API；默认关闭，走新API。
                return self.interfaceOrientationMaskFromDeviceOrientation(orientation)
            } else {
                // Mark: iOS16.0后，如延用之前的switch逻辑，使用requestGeometryUpdate强制转屏会遇到转屏失败,返回.allButUpsideDown转屏OK
                return .allButUpsideDown
            }
        } else {
            return self.interfaceOrientationMaskFromDeviceOrientation(orientation)
        }
        #else
        return self.interfaceOrientationMaskFromDeviceOrientation(orientation)
        #endif
    }

    
    public override var preferredStatusBarStyle: UIStatusBarStyle {
        guard WebMetaNavigationBarExtensionItem.isNavBgAndFgColorEnabled() else {
            return super.preferredStatusBarStyle
        }
        if let style = resolve(NavigationBarStyleExtensionItem.self)?.customStatusBarStyle() {
            return style
        }
        return super.preferredStatusBarStyle
    }
    
    private func interfaceOrientationMaskFromDeviceOrientation(_ deviceOrientation: UIDeviceOrientation) -> UIInterfaceOrientationMask {
        if !isBrowserRotationOptimizeDisable {
            return lk_supportedInterfaceorientationMask
        } else {
            switch deviceOrientation {
            case .landscapeLeft:
                return .landscapeLeft
            case .landscapeRight:
                return .landscapeRight
            case .portrait:
                return .portrait
            case .portraitUpsideDown:
                return .portraitUpsideDown
            default:
                return .allButUpsideDown
            }
        }
    }
    
    /// 强制转屏
    private func forceRotateOrientation(_ originOrientation: UIDeviceOrientation, targetOrientation: UIDeviceOrientation) {
        let originMask = lk_supportedInterfaceorientationMask
        switch targetOrientation {
        case .portrait, .portraitUpsideDown:
            lk_supportedInterfaceorientationMask = .portrait
        case .landscapeLeft, .landscapeRight:
            lk_supportedInterfaceorientationMask = .landscapeRight
        default:
            lk_supportedInterfaceorientationMask = .portrait
        }
        #if swift(>=5.7)
        if #available(iOS 16.0, *) {
            if !isBrowserRotationOptimizeDisable {
                if let activeScene = SceneManager.shared.windowApplicationScenes.first(where: {
                    $0.activationState == .foregroundActive && $0.isKind(of: UIWindowScene.self)
                }), let windowScene = activeScene as? UIWindowScene {
                    // Mark: iOS16.0上supportedInterfaceOrientations支持 .allButUpsideDown
                    var interfaceOrientationMask : UIInterfaceOrientationMask = .portrait
                    switch targetOrientation {
                    case .landscapeLeft:
                        interfaceOrientationMask = .landscapeRight
                    case .landscapeRight:
                        interfaceOrientationMask = .landscapeRight
                    case .portrait:
                        interfaceOrientationMask = .portrait
                    default:
                        interfaceOrientationMask = .portrait
                    }
                    Self.logger.info("iOS16 WebBrowser force rotate (device)Orientation from \(originOrientation.rawValue) to \(targetOrientation.rawValue)")
                    let geometryPreferences = UIWindowScene.GeometryPreferences.iOS(interfaceOrientations: interfaceOrientationMask)
                    setNeedsUpdateOfSupportedInterfaceOrientations()
                    windowScene.requestGeometryUpdate(geometryPreferences, errorHandler: { err in
                        Self.logger.error("iOS16 WebBrowser force rotate (device)Orientation failed:  \(err.localizedDescription ?? "")")
                    })
                }
            } else if (self.useRotateScreenOldAPI()) {
                // iOS 16.0(20A5283p)-beta1版本上发现新转屏相关API崩溃；开启该开关走旧API；默认关闭，走新API。
                Self.logger.info("iOS16 WebBrowser force rotate (device)Orientation(use oldapi) from \(originOrientation.rawValue) to \(targetOrientation.rawValue)")
                UIDevice.current.setValue(targetOrientation.rawValue, forKey: "orientation")
                UIViewController.attemptRotationToDeviceOrientation()
            } else {
                if let activeScene = SceneManager.shared.windowApplicationScenes.first(where: {
                    $0.activationState == .foregroundActive && $0.isKind(of: UIWindowScene.self)
                }), let windowScene = activeScene as? UIWindowScene {
                    // Mark: iOS16.0上supportedInterfaceOrientations支持 .allButUpsideDown
                    var interfaceOrientationMask : UIInterfaceOrientationMask = .portrait
                    switch targetOrientation {
                    case .landscapeLeft:
                        interfaceOrientationMask = .landscapeLeft
                    case .landscapeRight:
                        interfaceOrientationMask = .landscapeRight
                    case .portrait:
                        interfaceOrientationMask = .portrait
                    default:
                        interfaceOrientationMask = .allButUpsideDown
                    }
                    Self.logger.info("iOS16 WebBrowser force rotate (device)Orientation from \(originOrientation.rawValue) to \(targetOrientation.rawValue)")
                    let geometryPreferences = UIWindowScene.GeometryPreferences.iOS(interfaceOrientations: interfaceOrientationMask)
                    windowScene.requestGeometryUpdate(geometryPreferences, errorHandler: { err in
                        Self.logger.error("iOS16 WebBrowser force rotate (device)Orientation failed:  \(err.localizedDescription ?? "")")
                    })
                }
            }
        } else {
            Self.logger.info("Less than iOS16 WebBrowser force rotate (device)Orientation from \(originOrientation.rawValue) to \(targetOrientation.rawValue)")
            UIDevice.current.setValue(targetOrientation.rawValue, forKey: "orientation")
            UIViewController.attemptRotationToDeviceOrientation()
        }
        #else
        Self.logger.info("Less than iOS16 WebBrowser force rotate (device)Orientation from \(originOrientation.rawValue) to \(targetOrientation.rawValue)")
        UIDevice.current.setValue(targetOrientation.rawValue, forKey: "orientation")
        UIViewController.attemptRotationToDeviceOrientation()
        #endif
    }
    
    private func useRotateScreenOldAPI () -> Bool {
        let flag = FeatureGatingManager.shared.featureGatingValue(with: FeatureGatingManager.Key(stringLiteral: "openplatform.larkwebview.rotatenewapi.disable"))// user:global
        return flag
    }
    
    // WebMeta 容器侧滑关闭设置
    public func setSlideToClose(_ value: Bool) {
        guard canSlideToClose != value else {
            return
        }
        Self.logger.info("try setSlideToClose from \(canSlideToClose) to \(value)")
        canSlideToClose = value
        resolve(NavigationBarStyleExtensionItem.self)?.checkAndUpdateSwipeBack(browser: self)
        // iPad分屏浏览时, 若窗口导航栈中只有一个控制器, 则不会响应其侧滑手势
        // 同步设置网页前进/后退手势, 保证开启侧滑关闭且不能侧滑的场景, 也不应该返回网页上一级
        if Display.pad {
            webview.allowsBackForwardNavigationGestures = !value
        }
    }
    
    // WebMeta 容器支持手势前进后退
    public func setAllowsBackForwardGestures(_ value: Bool) {
        guard allowsBackForwardGestures != value else {
            return
        }
        Self.logger.info("try setAllowsBackForwardGestures from \(allowsBackForwardGestures) to \(value)")
        allowsBackForwardGestures = value
        webview.allowsBackForwardNavigationGestures = value
    }
    
    /// 更改网页容器左侧按钮优化配置开关，
    /// true 表示开启优化，开启后会根据当前容器的展示模式决定是否添加左侧返回按钮。
    /// fasle表示关闭(线上逻辑，始终显示返回按钮，webview.cangoback后显示关闭按钮)
    public func updateLeftNaviButtonsRootVCOpt(leftNaviButtonsRootVCOpt:Bool) {
        Self.logger.info("updateLeftNaviButtonsRootVCOpt to \(leftNaviButtonsRootVCOpt)")
        if Thread.isMainThread {
            self.leftNaviButtonsRootVCOpt = leftNaviButtonsRootVCOpt
            if let navibarLeftextensionItem = resolve(NavigationBarLeftExtensionItem.self) {
                navibarLeftextensionItem.updateLeftNaviButtonsRootVCOpt(leftNaviButtonsRootVCOpt: leftNaviButtonsRootVCOpt)
            } else  {
                Self.logger.info("navibarLeftextensionItem is nil")
            }
        } else {
            DispatchQueue.main.async {
                self.leftNaviButtonsRootVCOpt = leftNaviButtonsRootVCOpt
                if let navibarLeftextensionItem = self.resolve(NavigationBarLeftExtensionItem.self) {
                    navibarLeftextensionItem.updateLeftNaviButtonsRootVCOpt(leftNaviButtonsRootVCOpt: leftNaviButtonsRootVCOpt)
                } else  {
                    Self.logger.info("navibarLeftextensionItem is nil")
                }
            }
        }
    }
    
    func setPopGestureEnabled(_ enabled: Bool) {
        naviPopGestureRecognizerEnabled = enabled
        if Self.isPopGestureOptimizeEnabled() {
            // LarkUIKit组件LKBaseNavigationController侧滑手势开关仅跟随didShow回调设置
            // 网页容器多级页面场景, 在后退时关闭容器手势而导致主页不能侧滑退出容器
            // 故此处重新设置导航侧滑手势开关保证正确
            navigationController?.interactivePopGestureRecognizer?.isEnabled = enabled
        }
    }
    
    private static func isPopGestureOptimizeEnabled() -> Bool {
        return !FeatureGatingManager.shared.featureGatingValue(with: FeatureGatingManager.Key(stringLiteral: "openplatform.web.pop_gesture_optimize.disabled"))// user:global
    }
}

// MARK: Network State
extension WebBrowser {
    fileprivate func addNetStatusObserver() {
        guard Self.isDynamicNetStatusEnabled() else {
            return
        }
        netStatus = netStatusService.status
        NetStatusExtenstionItem.logger.info("net status init \(netStatus)")
        NotificationCenter.default.addObserver(self, selector: #selector(dynamicNetStatusChanged), name: .UpdateNetStatus, object: nil)
    }
    
    fileprivate func removeNetStatusObserver() {
        guard Self.isDynamicNetStatusEnabled() else {
            return
        }
        NotificationCenter.default.removeObserver(self, name: .UpdateNetStatus, object: nil)
    }
    
    public static func isDynamicNetStatusEnabled() -> Bool {
        return FeatureGatingManager.shared.featureGatingValue(with: FeatureGatingManager.Key(stringLiteral: "openplatform.web.weak.network.toast"))// user:global
    }
    
    @objc private func dynamicNetStatusChanged() {
        let newValue = netStatusService.status
        guard netStatus != newValue else {
            return
        }
        NetStatusExtenstionItem.logger.info("net status changed from \(netStatus) to \(newValue)")
        netStatus = newValue
        if let netStatusItem = resolve(NetStatusExtenstionItem.self) {
            netStatusItem.onNetStatusChange()
        }
    }
    
    public func removeAllDownloadFiles() {
        //文件下载地址具体见: https://bytedance.feishu.cn/wiki/Y2SMwFIaMiyteAkMeopctzzPnlG
        do {
            //删除 系统沙盒存储路径
            // lint:disable lark_storage_check
            let downloadsPath = try FileManager.default.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: false).appendingPathComponent(OPEN_PLATFORM_WEB_DRIVE_DOWNLOAD_FOLDER).path
            if FileManager.default.fileExists(atPath: downloadsPath) {
                Self.logger.info("remove downloadsPath item")
                try FileManager.default.removeItem(atPath: downloadsPath)
            }
            // lint:enable lark_storage_check
            
            //统一存储删除
            let embedFolderIsoPath = OPDownload.downloadsFolderPath(isEmbed: true)
            if embedFolderIsoPath.exists {
                Self.logger.info("remove embedFolderIsoPath item")
                try embedFolderIsoPath.removeItem()
            }
        
            let notEmbedFolderPath = OPDownload.downloadsFolderPath(isEmbed: false)
            if notEmbedFolderPath.exists {
                Self.logger.info("remove notEmbedFolderPath item")
                try notEmbedFolderPath.removeItem()
            }
        } catch {
            Self.logger.error("remove All DownloadFiles error", error: error)
        }
    }
}
