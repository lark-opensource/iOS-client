import ECOInfra
import LarkContainer
import LarkGuide
import LarkOPInterface
import LarkSetting
import LarkSuspendable
import LarkTab
import LarkUIKit
import LKCommonsLogging
import UniverseDesignIcon
import WebBrowser
import LarkFeatureGating
import OPSDK
import LarkWebViewContainer
import LarkKeepAlive
import LarkQuickLaunchInterface

/// 多任务菜单插件日志对象
private let logger = Logger.ecosystemWebLog(WebFloatingMenuPlugin.self, category: NSStringFromClass(WebFloatingMenuPlugin.self))

/// 多任务网页支持
/// 产品责任人：hujunxiao@bytedance.com
/// 多任务iOS技术负责人：wanghaidong.nku@bytedance.com
/// PRD：https://bytedance.feishu.cn/docs/doccnXBUpcw7EtchpYyYnZKkHUd
/// 技术方案：https://bytedance.feishu.cn/docs/doccndQSSsrSliIUNkLOUN1Ox6f
private let onboardingKey = "ecosystem_web_mutitask_badge"
/// 多任务浮窗的菜单插件
public final class WebFloatingMenuPlugin: MenuPlugin {

    /// 套件统一浏览器的菜单上下文
    private let menuContext: WebBrowserMenuContext
    /// 插件Badge的唯一标识符，注意也需要在SetupLarkBadgeTask文件中的BadgeImpl结构体中做相应的注册，因为这是LarkBadge组件必要的步骤，否则会直接导致crash
    static let badgeIdentifier = "webFloating"
    /// 插件的优先级 产品要求「仅次于分享」
    private static let itemPriority: Float = 85
    
//    @Injected static var guideService: NewGuideService
    var guideService: NewGuideService?
    
    public static let providerContextResloveKey = "resolver"
    
    /// 避免 menu 循环引用的帮助类
    private class MenuItemModelWeakWrapper {
        weak var menuItemModel: MenuItemModel?
    }

    public init?(menuContext: MenuContext, pluginContext: MenuPluginContext) {
        //  多任务插件只在非iPad生效
        guard !Display.pad else {
            logger.info("iPad Env, should not init floating plugin")
            return nil
        }
        let resolverParameter = pluginContext.parameters[WebFloatingMenuPlugin.providerContextResloveKey]
        guard let resolver = resolverParameter as? UserResolver else {
            logger.error("WebFloatingMenu plugin init failure because there is no resolver")
            return nil
        }
        //  多任务可能会被关闭
        guard SuspendManager.isSuspendEnabled else {
            logger.info("SuspendManager.isSuspendEnabled is false")
            return nil
        }
        //  这个插件需要 WebBrowser
        guard let webMenuContext = menuContext as? WebBrowserMenuContext else {
            logger.info("menuContext is not WebBrowser")
            return nil
        }
        if webMenuContext.isOfflineMode {
            return nil
        }
        guard webMenuContext.webBrowser?.isDownloadPreviewMode() == false else {
            logger.info("OPWDownload WebFloatingMenuPlugin init failure because download preview mode")
            return nil
        }
        guard let resolver = pluginContext.parameters[WebFloatingMenuPlugin.providerContextResloveKey] as? Resolver else {
            logger.error("launcher plugin init failure because there is no resolver")
            return nil
        }
        // 暂时不屏蔽了，和添加到导航栏共存
//        if let opMyAIService = resolver.resolve(LarkOpenPlatformMyAIService.self), opMyAIService.isQuickLaunchBarEnable() {
//            // 开启新版主导航改造后，屏蔽浮窗入口
//            return nil
//        }
        if webMenuContext.webBrowser?.browserURL?.scheme == "blob" {
            logger.info("OPWDownload WebFloatingMenuPlugin init failure because blob url scheme")
            return nil
        }
        self.menuContext = webMenuContext
        guideService = try? resolver.resolve(assert: NewGuideService.self)
        MenuItemModel.webBindButtonID(menuItemIdentifer: Self.badgeIdentifier, buttonID: OPMenuItemMonitorCode.multiTaskButton.rawValue)
    }

    public func pluginDidLoad(handler: MenuPluginOperationHandler) {
        guard menuContext.webBrowser?.isDownloadPreviewMode() == false else { return }
        updatePluginData(handler: handler)
    }
    
    private func updatePluginData(handler: MenuPluginOperationHandler) {
        guard let container = menuContext.webBrowser else { return }
        guard container.browserURL != nil else { return }
        //  Tab模式下不允许显示「添加多任务」
        let title: String
        let image: UIImage
        //  仅需要引导的时候显示红点
        var badgeNumber: UInt = 0
        if let guideService = guideService {
            badgeNumber = guideService.checkShouldShowGuide(key: onboardingKey) ? 1 : 0
        }
        let hasAddedFloating = SuspendManager.shared.contains(suspendID: container.suspendID)
        if hasAddedFloating {
            title = LarkSuspendable.BundleI18n.LarkSuspendable.Lark_Core_CancelFloating
            image = UDIcon.getIconByKey(UDIconType.unmultitaskOutlined)
        } else {
            title = LarkSuspendable.BundleI18n.LarkSuspendable.Lark_Core_FloatingWindow
            image = UDIcon.getIconByKey(UDIconType.multitaskOutlined)
        }
        /// 避免 menu 循环引用的帮助类
        let menuWrapper = MenuItemModelWeakWrapper()
        
        let menuModel = MenuItemModel(
            title: title,
            imageModel: MenuItemImageModel(normalForIPhoneLark: image),
            itemIdentifier: Self.badgeIdentifier,
            badgeNumber: badgeNumber,
            itemPriority: Self.itemPriority
        ) { [weak handler, weak container, weak self] _ in
            guard let container = container else {
                logger.info("container released")
                return
            }
            MenuItemModel.webReportClick(applicationID: container.appInfoForCurrentWebpage?.id, menuItemIdentifer: WebFloatingMenuPlugin.badgeIdentifier)
            if hasAddedFloating {
                SuspendManager.shared.removeSuspend(viewController: container)
            } else {
                SuspendManager.shared.addSuspend(viewController: container)
                //  添加了就认为需要结束onboarding了
                self?.guideService?.didShowedGuide(guideKey: onboardingKey)
                
                /// 通知菜单消除红点
                if let menu = menuWrapper.menuItemModel {
                    menu.badgeNumber = 0
                    handler?.updateItemModels(for: [menu])
                } else {
                    logger.error("menu released")
                }
            }
        }
        menuWrapper.menuItemModel = menuModel
        handler.updateItemModels(for: [menuModel])
    }
    
    /// 插件ID
    public static var pluginID: String {
        "WebFloatingMenuPlugin"
    }

    public static var enableMenuContexts: [MenuContext.Type] {
        [WebBrowserMenuContext.self]
    }
}

/// 多任务网页支持
/// 产品责任人：hujunxiao@bytedance.com
/// 多任务iOS技术负责人：wanghaidong.nku@bytedance.com
/// PRD：https://bytedance.feishu.cn/docs/doccnXBUpcw7EtchpYyYnZKkHUd
/// 技术方案：https://bytedance.feishu.cn/docs/doccndQSSsrSliIUNkLOUN1Ox6f
/// 多任务框架新版适配指南，from 多任务框架 iOS 负责人：https://bytedance.feishu.cn/docs/doccnhV7QZ2L5WmSXxxfmg9Xc2c#
extension WebBrowser: ViewControllerSuspendable {
    
    /// 收入唯一标志符，以 window 为单位
    public var suspendID: String {
        Self.logger.info("suspendID for \(self) is \(configuration.webBrowserID)")
        return configuration.webBrowserID
    }
    
    /// 浮窗 icon
    public var suspendIcon: UIImage? {
        //  应用和非应用图标不一致
        if isWebAppForCurrentWebpage {
            return UDIcon.appOutlined
        } else {
            return BundleResources.WebBrowser.muti_task_web_icon
        }
    }
    
    /// 浮窗标题
    public var suspendTitle: String {
        //  应用：应用名称，如果是空字符串，就显示类似于 https://open.feishu.cn 的链接，否则显示document.title
        //  网页：如果document.title为空，就显示类似于 https://open.feishu.cn 的链接，否则显示document.title
        if let appInfo = appInfoForCurrentWebpage {
            if let appName = appInfo.name, !appName.isEmpty {
                return appName
            }
            return suspendURL
        } else {
            if let title = webview.title,
               !title.isEmpty {
                return title
            } else {
                return suspendURL
            }
        }
    }
    
    /// 显示冷恢复的关键参数，会通过 EENavigator 启动
    public var suspendURL: String {
        Self.logger.info("suspendURL for \(self) is \(browserURL?.safeURLString)")
        if FeatureGatingManager.shared.featureGatingValue(with: FeatureGatingManager.Key(stringLiteral: "openplatform.applink.target.url.enable")),// user:global
           let appInfo = appInfoForCurrentWebpage, let url = browserURL?.absoluteString,
           let applink = ecosyetemWebDependency.generateWebAppLink(targetUrl: url, appId: appInfo.id) {
            return applink.absoluteString
        }
        return browserURL?.absoluteString ?? "" //  其实不应该走到 "" 多任务item在无 URL 的时候不应该展示
    }
    
    public var suspendIconKey: String? {
        Self.logger.info("suspendIconKey for \(self) is \(appInfoForCurrentWebpage?.iconKey)")
        return appInfoForCurrentWebpage?.iconKey
    }
    
    public var suspendIconURL: String? {
        Self.logger.info("suspendIconURL for \(self) is \(appInfoForCurrentWebpage?.iconURL?.safeURLString)")
        return appInfoForCurrentWebpage?.iconURL
    }
    
    public var suspendParams: [String : AnyCodable] {
        Self.logger.info("suspendParams for \(self) key:\(webBrowserIDKey) value:\(configuration.webBrowserID)")
        return [
            webBrowserIDKey: AnyCodable(configuration.webBrowserID),
            acceptWebMetaKey: AnyCodable(configuration.acceptWebMeta)
        ]
    }
    
    /// 是否需要侧滑添加
    public var isInteractive: Bool {
        false
    }
    
    /// 支持热启动的 VC 会在关闭后被 SuspendManager 持有，并在多任务列表中打开时重新 push 打开
    public var isWarmStartEnabled: Bool {
        return !FeatureGatingManager.shared.featureGatingValue(with: FeatureGatingManager.Key(stringLiteral: "openplatform.webbrowser.close.warmstart.disable"))// user:global
    }
    
    public var analyticsTypeName: String {
        "web"
    }
    
    /// 新版多任务浮窗列表中，对不同类型的页面进行分组，所以添加了新的枚举类型，表示接入 ViewController 所属的分组
    public var suspendGroup: SuspendGroup {
        .web
    }
}

/// 接入 `TabContainable` 协议后，该页面可由用户手动添加至“底部导航” 和 “快捷导航” 上
extension WebBrowser: TabContainable {

    /// 页面的唯一 ID，由页面的业务方自己实现
    ///
    /// - 同样 ID 的页面只允许收入到导航栏一次
    /// - 如果该属性被实现为 ID 恒定，SDK 在数据采集的时候会去重
    /// - 如果该属性被实现为 ID 变化（如自增），则会被 SDK 当成不同的页面采集到缓存，展现上就是在导航栏上出现多个这样的页面
    /// - 举个🌰
    /// - IM 业务：传入 ChatId 作为唯一 ID
    /// - CCM 业务：传入 objToken 作为唯一 ID
    /// - OpenPlatform（小程序 & 网页应用） 业务：传入应用的 uniqueID 作为唯一 ID
    /// - Web（网页） 业务：传入页面的 url 作为唯一 ID（为防止url过长，sdk 处理的时候会 md5 一下，业务方无感知
    public var tabID: String {
        //        browserURL?.absoluteString ?? UUID().uuidString
        if configuration.scene == .workplacePortal || configuration.scene == .mainTab {
            Self.logger.info("tabID return empty for scene: \(configuration.scene.rawValue)")
            return ""
        }
        if configuration.webBizType == .larkWeb || configuration.webBizType == .unknown{
            LKWSecurityLogUtils.webSafeAESURL(browserURL?.absoluteString ?? "", msg: "getTabBizID")
            let isOfflineModel = (try? self.resolver?.resolve(assert: EcosyetemWebDependencyProtocol.self).isOfflineMode(browser: self)) ?? false
            if let appInfo = appInfoForCurrentWebpage, let url = browserURL?.absoluteString, isOfflineModel {
                // 离线应用tabid使用applink
                if let applink = ecosyetemWebDependency.generateCustomPathWebAppLink(targetUrl: url, appId: appInfo.id) {
                    LKWSecurityLogUtils.webSafeAESURL(applink.absoluteString ?? "", msg: "returnTabURL")
                    return applink.absoluteString
                }
            }
            LKWSecurityLogUtils.webSafeAESURL(browserURL?.absoluteString ?? "", msg: "returnTabURL")
            return browserURL?.absoluteString ?? ""
        }
        if configuration.webBizType == .baseForms {
            Self.logger.info("baseForms get tabID")
            return browserURL?.absoluteString ?? ""
        }
        Self.logger.info("tabID return empty for biztype: \(configuration.webBizType.rawValue)")
        return ""
    }

    /// 页面所属业务应用 ID，例如：网页应用的：cli_123455
    ///
    /// - 如果 BizType == WEB_APP 的话 SDK 会用这个 BizID 来给 app_id 赋值
    ///
    /// 目前有些业务，例如开平的网页应用（BizType == WEB_APP），tabID 是传 url 来做唯一区分的
    /// 但是不同的 url 可能对应的应用 ID（BizID）是一样的，所以用这个字段来额外存储
    ///
    /// 所以这边就有一个特化逻辑：
    /// if(BizType == WEB_APP) { uniqueId = BizType + tabID, app_id = BizID}
    /// else { uniqueId = BizType+ tabID, app_id = tabID}
    public var tabBizID: String {
        if let appInfo = appInfoForCurrentWebpage {
            Self.logger.info("tabBizID for \(self) is \(appInfo.id)")
            return appInfo.id
        }
        // 普通网页
        return ""
    }
    
    /// 页面所属业务类型
    ///
    /// - SDK 需要这个业务类型来拼接 uniqueId
    ///
    /// 现有类型：
    /// - CCM：文档
    /// - MINI_APP：开放平台：小程序
    /// - WEB_APP ：开放平台：网页应用
    /// - MEEGO：开放平台：Meego
    /// - WEB：自定义H5网页
    public var tabBizType: CustomBizType {
        if appInfoForCurrentWebpage != nil {
            Self.logger.info("tabBizType return webapp")
            return .WEB_APP
        }
        Self.logger.info("tabBizType return web")
        return .WEB
    }

    /// 页面收入到 “底部导航（MainTabBar）” 和 “快捷导航（QuickLaunchWindow）” 上展示的图标（最近使用列表里面也使用同样的图标）
    /// - 如果后期最近使用列表里面要展示不同的图标需要新增一个协议
    public var tabIcon: CustomTabIcon {
        if let url = appInfoForCurrentWebpage?.iconURL {
            Self.logger.info("tabicon return appicon: \(url.safeURLString)")
            return .urlString(url)
        }
        if let faviconString = faviconURL, !faviconString.isEmpty, (faviconString.hasPrefix("http://") || faviconString.hasPrefix("https://"))  {
            Self.logger.info("tabicon return favicon: \(faviconString.safeURLString)")
            return .urlString(faviconString)
        }
//        if let iconKey = appInfoForCurrentWebpage?.iconKey {
//            return .iconKey(iconKey, entityID: nil)
//        }
        return .iconName(.fileRoundLinkBlueColorful)
    }

    /// 页面收入到 “底部导航（MainTabBar）” 和 “快捷导航（QuickLaunchWindow）” 上展示的标题（最近使用列表里面也使用同样的标题）
    public var tabTitle: String {
        if let title = webview.title, !title.isEmpty {
            return title
        } else {
            if let appInfo = appInfoForCurrentWebpage {
                if let appName = appInfo.name, !appName.isEmpty {
                    return appName
                }
                return suspendURL
            } else {
                return suspendURL
            }
        }
    }

    /// 页面的 URL 或者 AppLink，路由系统 EENavigator 会使用该 URL 进行页面跳转
    ///
    /// - 当页面冷恢复时，EENavigator 使用该 URL 来重新构建页面
    /// - 对于Web（网页） 业务的话，这个值可能和 tabID 一样
    public var tabURL: String {
        Self.logger.info("tabURL for \(self) is \(browserURL?.safeURLString)")
        if let appInfo = appInfoForCurrentWebpage, let url = browserURL?.absoluteString {
            let isOfflineModel = self.resolver?.resolve(EcosyetemWebDependencyProtocol.self)?.isOfflineMode(browser: self) ?? false
            if isOfflineModel {
                // 离线应用
                if let applink = ecosyetemWebDependency.generateCustomPathWebAppLink(targetUrl: url, appId: appInfo.id) {
                    LKWSecurityLogUtils.webSafeAESURL(applink.absoluteString ?? "", msg: "returnTabURL")
                    return applink.absoluteString
                }
                LKWSecurityLogUtils.webSafeAESURL(browserURL?.absoluteString ?? "", msg: "returnTabURL")
                return browserURL?.absoluteString ?? ""
            } else {
                // 在线应用
                if let applink = ecosyetemWebDependency.generateWebAppLink(targetUrl: url, appId: appInfo.id) {
                    LKWSecurityLogUtils.webSafeAESURL(applink.absoluteString ?? "", msg: "returnTabURL")
                    return applink.absoluteString
                }
                LKWSecurityLogUtils.webSafeAESURL(browserURL?.absoluteString ?? "", msg: "returnTabURL")
                return browserURL?.absoluteString ?? ""
            }
        }
        // 普通网页
        LKWSecurityLogUtils.webSafeAESURL(browserURL?.absoluteString ?? "", msg: "returnTabURL")
        return browserURL?.absoluteString ?? "" //  其实不应该走到 "" 多任务item在无 URL 的时候不应该展示
    }
    
    /// 埋点统计所使用的类型名称
    ///
    /// 现有类型：
    /// - private 单聊
    /// - secret 密聊
    /// - group 群聊
    /// - circle 话题群
    /// - topic 话题
    /// - bot 机器人
    /// - doc 文档
    /// - sheet 数据表格
    /// - mindnote 思维导图
    /// - slide 演示文稿
    /// - wiki 知识库
    /// - file 外部文件
    /// - web 网页
    /// - gadget 小程序
    public var tabAnalyticsTypeName: String {
        return "web"
    }
    
    public var forceRefresh: Bool {
        return false
    }
}

extension WebBrowser: PagePreservable {
    
    /// id用于和pageType生成唯一uniqueID
    public var pageID: String {
        // pageID多次调用场景如何兼容
        if configuration.webBizType == .larkWeb, let keepAliveService = try? resolver?.resolve(assert: WebAppKeepAliveService.self), keepAliveService.isWebAppKeepAliveEnable(){
            // appid 在白名单内
            // 区分iPad 和 iphone
            let isOfflineMode = (try? self.resolver?.resolve(assert: EcosyetemWebDependencyProtocol.self).isOfflineMode(browser: self)) ?? false
            if isOfflineMode {
                Self.logger.info("keepalive offline app doesn't support keepalive")
                return ""
            }
            if shouldCacheBrowserWhenClose {
                let pageID = keepAliveService.createKeepAliveIdentifier(browser: self)
                LKWSecurityLogUtils.webSafeAESURL(pageID, msg: "keepalive pageId")
                return pageID
            }
        }
        return ""
    }

    /// 不同业务优先级保活时间也不一样
    public var pageType: PageKeeperType {
        if configuration.webBizType == .larkWeb, let keepAliveService = try? resolver?.resolve(assert: WebAppKeepAliveService.self), keepAliveService.isWebAppKeepAliveEnable(){
            // appid 在白名单内
            // 区分iPad 和 iphone
            let identifier = keepAliveService.createKeepAliveIdentifier(browser: self)
            if !identifier.isEmpty {
                if configuration.appId != nil {
                    Self.logger.info("keepalive pageType:webapp")
                    return .webapp
                } else {
                    Self.logger.info("keepalive pageType:h5")
                    return .h5
                }
            }
        }
        Self.logger.info("keepalive pageType:h5")
        return .h5
    }

    /// 能否被保活，默认为True，如果需要特殊不保活可以override
    ///
    /// - Returns: PageKeepError， 不为空则无法添加到队列
    public func shouldAddToPageKeeper() -> PageKeepError? {
        if let keepAliveService = try? resolver?.resolve(assert: WebAppKeepAliveService.self), keepAliveService.isWebAppKeepAliveEnable() {
            // appid 在白名单内
            // 区分iPad 和 iphone
            let identifier = keepAliveService.createKeepAliveIdentifier(browser: self)
            if !identifier.isEmpty {
                Self.logger.info("keepalive can AddToPageKeeper")
                return nil
            }
        }
        Self.logger.info("keepalive can not AddToPageKeeper")
        return .normal
    }

    /// 特殊场景下，业务不希望被移除，如后台播放等，交由业务方自行判断
    ///
    /// - Returns: PageKeepError， 不为空则无法从队列移除
    public func shouldRemoveFromPageKeeper() -> PageKeepError? {
        Self.logger.info("keepalive can removeFromPageKeeper")
        return nil
    }

    public func getPageSceneBySelf() -> PageKeeperScene? {
        if let keepAliveService = try? resolver?.resolve(assert: WebAppKeepAliveService.self), keepAliveService.isWebAppKeepAliveEnable() {
            // appid 在白名单内
            // 区分iPad 和 iphone
            let scene = keepAliveService.createKeepAliveScene(browser: self)
            Self.logger.info("keepalive scene:\(scene.rawValue)")
            return scene
        }
        Self.logger.info("keepalive scene:nil")
        return nil
    }
    
    public func didAddToPageKeeper() {
        Self.logger.info("keepalive start add to cache, browser:\(configuration.initTrace?.traceId)")
        if let keepAliveService = try? resolver?.resolve(assert: WebAppKeepAliveService.self)
           {
            // appid 在白名单内
            // 区分iPad 和 iphone
            Self.logger.info("keepalive add to cache, browser:\(configuration.initTrace?.traceId)")
            keepAliveService.cacheBrowsers(browser: self)
        }
    }
    
    public func didRemoveFromPageKeeper() {
        Self.logger.info("keepalive start remove from cache, browser:\(configuration.initTrace?.traceId)")
        if let keepAliveService = try? resolver?.resolve(assert: WebAppKeepAliveService.self)
           {
            // appid 在白名单内
            // 区分iPad 和 iphone
            Self.logger.info("keepalive remove from cache, browser:\(configuration.initTrace?.traceId)")
            keepAliveService.removeWebAppBrowser(browser: self)
        }
    }
}
