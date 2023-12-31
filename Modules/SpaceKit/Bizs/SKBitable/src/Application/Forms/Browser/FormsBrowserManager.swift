import ECOProbe
import EENavigator
import Foundation
import LarkContainer
import LarkNavigator
import LarkQuickLaunchInterface
import LarkSceneManager
import LarkSetting
import LarkTab
import LarkTraitCollection
import LarkUIKit
import LKCommonsLogging
import Swinject
import WebBrowser
import WebKit

/// 接入了用户态框架的 Forms 容器管理器
final class FormsBrowserManager {
    
    static let logger = Logger.formsWebLog(FormsBrowserManager.self, category: "FormsBrowserManager")
    
    /// 预加载 Forms 分享页的浏览器对象，如果新增新业务，请并行增加 browser 对象
    var formsPreloadBrowser: WebBrowser?
    
    let userResolver: UserResolver
    
    init(userResolver: UserResolver) {
        Self.logger.info("FormsBrowserManager init")
        self.userResolver = userResolver
    }
    
    deinit {
        Self.logger.info("FormsBrowserManager deinit")
    }
    
}

extension FormsBrowserManager {
    
    /// 尝试初始化 Forms 预加载容器
    func setupPreloadBrowser(
        userResolver: UserResolver
    ) {
        if let url = FormsConfiguration.formsPreloadURL(userResolver: userResolver) {
            do {
                let browser = try createPreloadBrowser(url: url, userResolver: userResolver)
                formsPreloadBrowser = browser
                Self.logger.info("setupPreloadBrowser success")
            } catch {
                Self.logger.error("createPreloadBrowser error", error: error)
            }
        } else {
            Self.logger.error("get no formsPreloadURL")
        }
    }
    
    /// 尝试获取 Forms 预加载容器
    func getFormsPreloadBrowser(
        currentURL: URL,
        userResolver: UserResolver
    ) -> (WebBrowser?, String) {
        defer {
            // 不管能不能取到冷启动的 Forms 容器，取的时候都尝试创建一个
            setupPreloadBrowser(userResolver: userResolver)
        }
        guard let preloadBrowser = formsPreloadBrowser else {
            Self.logger.info("preloadBrowser is nil")
            return (nil, "preloadBrowser is nil")
        }
        guard preloadBrowser.processStage == .HasFinishedURL else {
            Self.logger.error("preloadBrowser.processStage is \(preloadBrowser.processStage)")
            return (nil, "preloadBrowser is not HasFinishedURL")
        }
        guard let webviewURL = preloadBrowser
            .webview
            .url else {
            Self.logger.error("preloadBrowser.webview.url is nil")
            return (nil, "preloadBrowser.webview.url is nil")
        }
        guard webviewURL.scheme == currentURL.scheme else {
            Self.logger.error("preloadBrowser.scheme is \(webviewURL.scheme) and currentURL.scheme is \(currentURL.scheme)")
            return (nil, "scheme not equal, preloadBrowser's scheme is \(webviewURL.scheme)")
        }
        guard webviewURL.host == currentURL.host else {
            Self.logger.error("preloadBrowser.host is \(webviewURL.host), currentURL.host is \(currentURL.host)")
            return (nil, "host not equal")
        }
        Self.logger.error("preloadBrowser check success")
        return (preloadBrowser, "success")
    }
    
    /// 创建冷启动 Forms 容器
    class func createCodeSetupBrowser(
        body: FormsBody,
        req: EENavigator.Request,
        userResolver: UserResolver
    ) throws -> WebBrowser {
        /// config 配置
        var webBrowserConfiguration = Self.createWebBrowserConfiguration(autoLoadRequest: true)
        
        // 如果这个是true，就代表是窄屏幕
        // 判断方式 code from luogantong and luogantong's code from api team
        var isCollapsed: Bool = false
        if let trait = req
            .from
            .fromViewController?
            .rootWindow()?
            .traitCollection,
           let size = req
            .from
            .fromViewController?
            .rootWindow()?
            .bounds
            .size {
            isCollapsed = TraitCollectionKit
                .customTraitCollection(
                    trait, size
                )
                .horizontalSizeClass == .compact
        }
        
        if Display.pad,
           try userResolver
            .resolve(
                assert: TemporaryTabService.self
            )
                .isTemporaryEnabled,
           !isCollapsed {
            // Temporary 需要设置 browser 的 scene
            Self.logger.info("FormsRouterHandler, webBrowserConfiguration.scene = .temporaryTab")
            webBrowserConfiguration.scene = .temporaryTab
        }
        
        /// browser构建与插件注册
        let browser = WebBrowser(url: body.url, configuration: webBrowserConfiguration)
        browser.resolver = userResolver
        
        try Self.registerFormsCommonExtensionItems(browser: browser)
        
        try browser.register(item: MemoryLeakExtensionItem()) // 冷启动需要注册内存泄漏检测插件
        try browser.register(item: TerminateReloadExtensionItem(browser: browser))

        
        Self.logger.info("FormsBrowserManager new browser, body.url: \(body.url), context:\(req.context), webBrowserConfiguration: \(webBrowserConfiguration.toString())")
        
        return browser
    }
    
    /// 创建 Forms 预加载容器
    func createPreloadBrowser(
        url: URL,
        userResolver: UserResolver
    ) throws -> WebBrowser {
        /// config 配置
        let webBrowserConfiguration = Self.createWebBrowserConfiguration(autoLoadRequest: false)
        
        /// browser构建与插件注册
        let browser = WebBrowser(url: nil, configuration: webBrowserConfiguration)
        browser.resolver = userResolver
        
        try Self.registerFormsCommonExtensionItems(browser: browser)

        try browser.register(item: FormsPreloadBrowserTerminateReloadExtensionItem())  // 预加载的渲染进程终结恢复策略和常规模式不同
        
        Self.logger.info("FormsBrowserManager new preloadBrowser, url: \(url), webBrowserConfiguration: \(webBrowserConfiguration.toString())")
        
        browser.loadURL(url)
        
        return browser
    }
}

extension FormsBrowserManager {
    
    /// 创建 browser config
    class func createWebBrowserConfiguration(autoLoadRequest: Bool) -> WebBrowserConfiguration {
        
        var webBrowserConfiguration = WebBrowserConfiguration(
            isAutoSyncCookie: true, // 需要登录态
            secLinkEnable: false, // 一方业务
            jsApiMethodScope: .none, // 不需要兼容开放平台biz债务API
            webBizType: .baseForms, // LarkWebView 设置
            webviewConfiguration: FormsBrowserManager.formsWebViewConfig()
        )
        // 容器侧反馈：底部 Tab 上线后被用户喷了。和 Forms 及容器 PM 沟通后在我们业务内下掉
        webBrowserConfiguration.isLaunchBarEnable = false
        webBrowserConfiguration.isMyAiItemEnable = false
        
        // 如果是预加载，不需要自动loadRequest
        webBrowserConfiguration.autoLoadRequest = autoLoadRequest
        
        // 支持配置开启 inspect
        if #available(iOS 16.4, *) {
            do {
                let key = UserSettingKey.make(userKeyLiteral: "ccm_mobile_system_bugfix")
                let manager = SettingManager.shared
                let settings = try manager.setting(with: key)
                if let inspect = settings["inspect"] as? Bool, inspect {
                    webBrowserConfiguration.isInspectable = true
                }
            } catch {
                Self.logger.error("try manager.setting(with: ccm_mobile_system_bugfix) error", error: error)
            }
        }
        
        return webBrowserConfiguration
        
    }
    
    class func registerFormsCommonExtensionItems(
        browser: WebBrowser
    ) throws {
        // API 调用移除掉鉴权流程，一方不需要鉴权
        try browser.register(singleItem: FormsWebBrowserExtensionSingleItem())
        
        try browser.register(item: ErrorPageExtensionItem())
        try browser.register(item: NavigationBarStyleExtensionItem())
        try browser.register(item: NavigationBarLeftExtensionItem(browser: browser))
        try browser.register(item: NavigationBarMiddleExtensionItem())
        try browser.register(item: NetStatusExtenstionItem(browser: browser))
        try browser.register(item: ProgressViewExtensionItem())
        try browser.register(item: WebMenuExtensionItem(browser: browser))
        try browser.register(item: NavigationBarRightExtensionItem(browser: browser))
        
        try browser.register(item: FormsExtensionItem(isFormsBrowser: true))
    }
    
}

extension FormsBrowserManager {
    
    /// 创建 Forms 独立容器 WKWebViewConfiguration
    class func formsWebViewConfig() -> WKWebViewConfiguration {
        
        let config = WKWebViewConfiguration()
        
        let abilityConfig = FormsConfiguration.formsAbilityConfig()
        
        var str = "{}"
        
        do {
            let jsonData = try JSONSerialization
                .data(
                    withJSONObject: abilityConfig,
                    options: .prettyPrinted
                )
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                str = jsonString
            }
        } catch {
            Self.logger.error("abilityConfig to data error", error: error)
        }
        
        let source = """
        window.BASE_SHARE_NATIVE_PAYLOAD = {
            data: {
                nativeConfig: \(str)
            }
        }
        """
        
        let userScript = WKUserScript(
            source: source,
            injectionTime: .atDocumentStart,
            forMainFrameOnly: true
        )
        config
            .userContentController
            .addUserScript(
                userScript
            )
        
        return config
        
    }
    
}
