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
import WebBrowser

/// Forms 路由处理器，负责对接路由返回 browser
final class FormsRouterHandler: UserTypedRouterHandler {
    
    static let logger = Logger.formsWebLog(FormsRouterHandler.self, category: "FormsRouterHandler")
    
    deinit {
        Self.logger.info("FormsRouterHandler deinit")
    }
    
    func handle(
        _ body: FormsBody,
        req: EENavigator.Request,
        res: EENavigator.Response
    ) throws {
        
        Self.logger.info("FormsRouterHandler recieve handle, body.url: \(body.url), context:\(req.context)")
        
        let monitor = OPMonitor("base_forms_browser_open")
            .setPlatform([.tea, .slardar])
        
        // 埋点 Key
        let setupModeKey = "setupMode"
        let preloadDescriptionKey = "preloadDescription"
        
        let browser: WebBrowser
        if forceCodeSetup(url: body.url) {
            Self.logger.info("forceCodeSetup, not try get preLoad Browser")
            
            monitor
                .addCategoryValue(
                    setupModeKey,
                    "codeSetupOnline"
                )
                .addCategoryValue(
                    preloadDescriptionKey,
                    "url query declare forceCodeSetup"
                )
            
            // 强制冷启动
            browser = try FormsBrowserManager
                .createCodeSetupBrowser(
                    body: body,
                    req: req,
                    userResolver: userResolver
                )
            let manager = try userResolver.resolve(assert: FormsBrowserManager.self)
            manager.setupPreloadBrowser(userResolver: userResolver)
        } else {
            if FormsConfiguration.isFormsSharePath(url: body.url) {
                // Forms 分享页会尝试获取预加载的容器
                let manager = try userResolver.resolve(assert: FormsBrowserManager.self)
                let formsPreloadBrowserAndDescription = manager
                    .getFormsPreloadBrowser(
                        currentURL: body.url,
                        userResolver: userResolver
                    )
                
                monitor
                    .addCategoryValue(
                        preloadDescriptionKey,
                        formsPreloadBrowserAndDescription.1
                    )
                
                if let formsPreloadBrowser = formsPreloadBrowserAndDescription.0 {
                    Self.logger.info("try get preLoad Browser success, set forms native data to front")
                    
                    monitor
                        .addCategoryValue(
                            setupModeKey,
                            "preloadOnline"
                        )
                    
                    browser = formsPreloadBrowser
                    
                    // 通过 userScript 设置过 BASE_SHARE_NATIVE_PAYLOAD.data 了，不要重复设置
                    let srcipt = """
                        window.BASE_SHARE_NATIVE_PAYLOAD.data.url="\(body.url.absoluteString)";
                        window.BASE_SHARE_NATIVE_PAYLOAD.data.startTime=Date.now();
                        window.BASE_SHARE_NATIVE_FINISH_DISPATCH();
                    """
                    browser
                        .webview
                        .evaluateJavaScript(
                            srcipt
                        )
                } else {
                    Self.logger.info("try get preLoad Browser failed, create cold setup browser")
                    
                    monitor
                        .addCategoryValue(
                            setupModeKey,
                            "codeSetupOnline"
                        )
                    
                    // 取不到则冷启动
                    browser = try FormsBrowserManager
                        .createCodeSetupBrowser(
                            body: body,
                            req: req,
                            userResolver: userResolver
                        )
                }
            } else {
                Self.logger.info("is no forms share path, not try get preLoad Browser")
                
                monitor
                    .addCategoryValue(
                        setupModeKey,
                        "codeSetupOnline"
                    )
                    .addCategoryValue(
                        preloadDescriptionKey,
                        "not supported business"
                    )
                
                // 非 Forms 分享页面则冷启动，如果新增 Forms 业务需要预加载的，请在上边平行增加
                browser = try FormsBrowserManager
                    .createCodeSetupBrowser(
                        body: body,
                        req: req,
                        userResolver: userResolver
                    )
            }
        }
        
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
        
        let service = try userResolver.resolve(assert: TemporaryTabService.self)
        /// browser 打开
        if Display.pad,
           service.isTemporaryEnabled,
           !isCollapsed,
           let browser = browser as? WebBrowser & TabContainable {
            // show Temp vc
            // 这个能力依赖于 NavigationBarLeftExtensionItem。
            browser.configuration.scene = .temporaryTab
            Self.logger.info("FormsRouterHandler showTab")
            browser.tabContainableIdentifier = req.context[NavigationKeys.uniqueid] as? String ?? ""
            service.showTab(browser)
            res.end(resource: nil)
        } else {
            Self.logger.info("FormsRouterHandler end browser")
            res.end(resource: browser)
        }
        
        monitor
            .flush()
        
    }
    
    /// 是否强制冷启动
    private func forceCodeSetup(url: URL) -> Bool {
        if let queryItems = URLComponents(url: url, resolvingAgainstBaseURL: true)?.queryItems {
            let hasSpecificQuery = queryItems.contains(where: { $0.name == "forceCodeSetup" && $0.value == "true" })
            if hasSpecificQuery {
                return true
            } else {
                return false
            }
        } else {
            return false
        }
    }
    
}
