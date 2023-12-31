//
//  WebAssembly.swift
//  LarkWeb
//
//  Created by liuwanlin on 2018/7/7.
//
// swiftlint:disable all

import EENavigator
import Foundation
import LKCommonsLogging
import LarkFoundation
import HTTProtocol
import RxSwift
import Swinject
import LarkOPInterface
import LarkTab
import RxRelay
import WebBrowser
import JsSDK
import LarkFeatureGating
import LarkUIKit
import LarkSDKInterface
import LKCommonsTracker
import Homeric
import LarkReleaseConfig
import LarkSceneManager
import WebBrowser
import LarkNavigation
import LarkWebViewContainer
import LarkAI
import EcosystemWeb
import LarkOpenPlatform
import LarkAssembler
import LarkAccountInterface
import BootManager
import LarkContainer
import RunloopTools
import AppContainer
import LKLoadable
import LarkAccountAssembly
#if DEBUG || BETA || ALPHA
import LarkDebugExtensionPoint
#endif
import ECOInfra

final class WebAssemblyV2: LarkAssemblyInterface {
    static let log = Logger.webBrowserLog(WebAssemblyV2.self, category: "WebAssemblyV2")
    func registContainer(container: Swinject.Container) {
        let user = container.inObjectScope(OPUserScope.userScope)
        
        user.register(LarkWebViewProtocol.self) { resolver in
            OpenPlatformAPIHandlerImp(resolver)
        }
        user.register(WebBrowserDependencyProtocol.self) { resolver in
            OpenPlatformAPIHandlerImp(resolver)
        }
        user.register(EcosyetemWebDependencyProtocol.self) { resolver in
            OpenPlatformAPIHandlerImp(resolver)
        }
        container.register(LarkWebViewQualityServiceProtocol.self) { _ in
            QualityService()
        }
        container.register(LarkWebViewSecLinkServiceProtocol.self) { _ in
            let urlDetectService = container.resolve(URLDetectService.self)
            return SecLinkService(urlDetectService: urlDetectService)
        }
        container.register(LarkWebViewMonitorServiceProtocol.self) { _ in
            LarkWebViewMonitorServiceWrapper()
        }
        container.register(WebAppMonitorProtocol.self) { _ in// user:global
            WebAppMonitorReporter.shared// user:global
        }
    }
    func registLaunch(container: Swinject.Container) {
        NewBootManager.register(WebBeforeLoginTask.self)
    }
}
final class WebBeforeLoginTask: FlowBootTask, Identifiable {
    
    static var identify = "WebBeforeLoginTask"

    override var delayScope: Scope? { return .container }

    override var scope: Set<BizScope> { return [.specialLaunch] }
    
    override func execute(_ context: BootContext) {
        MenuPluginRegisterHepler.assembleMenuPlugin(container: BootLoader.container)
        if LarkWebViewMonitorServiceWrapper.enableMonitor {
            LarkWebViewMonitorServiceWrapper.startMonitor()
        }
        if LarkWebViewMonitorServiceWrapper.enableReporter {
            LarkWebViewMonitorServiceWrapper.registerReportReceiver(receiver: WebAppMonitorReporter.shared)
        }
        #if DEBUG || BETA || ALPHA
        DebugRegistry.registerDebugItem(WebBrowserDebugItem(), to: .debugTool)
        #endif
        if WebTextSizeMenuPlugin.featureEnabled {
            WebZoom.startNotifications()
        }
    }
}
//  原先耦合在WebAssembly中非Web业务的代码，需要个业务认领并且迁移走代码
final class OtherAssemblyV2: LarkAssemblyInterface {
    static let log = Logger.log(OtherAssemblyV2.self, category: "OtherAssemblyV2")
    func registContainer(container: Swinject.Container) {
        //  SECLINK待明确哪边维护，现阶段还是messenger维护
        container.register(URLDetectService.self) { _ in
            let configDependency = ConfigDependencyImp(resolver: container)
            let safeLinkEnable = configDependency.featureGeting(for: "safe_link")
            let secLinkWhitelist = configDependency.secLinkWhitelist
            let detectUrlHead = configDependency.suiteSecurityLink
            return URLDetectServiceImpl(
                safeLinkEnable: safeLinkEnable,
                secLinkWhitelist: secLinkWhitelist,
                detectUrlHead: detectUrlHead,
                judgeURL: { url in
                    Observable.create { (ob) -> Disposable in
                        configDependency.isSecurityUrl(url, result: { isSafe in
                            ob.onNext(isSafe)
                            ob.onCompleted()
                        })
                        return Disposables.create()
                    }
                }
            )
        }
        //  分享 @邓波
        container.register(ShareH5Service.self) { _ in
            ShareH5ServiceImpl()
        }.inObjectScope(.user)
        //  翻译 @LarkAI
        container.register(WebTranslateWebAPIRegister.self) { _ in
            WebTranslateWebAPIRegisterImpl()
        }.inObjectScope(.user)
    }
    func registRouter(container: Swinject.Container) {
        //  passport @蔡伟伟
        Navigator.shared.registerRoute_(type: UnloginWebBody.self) {
            return UnloginWebHandler(resolver: container)
        }
        Navigator.shared.registerRoute_(type: SimpleWebBody.self) {
            return SimpleWebHandler()
        }
    }

    func registUnloginWhitelist(container: Swinject.Container) {
        UnloginWebBody.pattern
        SimpleWebBody.pattern
    }
    func registURLInterceptor(container: Swinject.Container) {
        //  (URL, EENavigator.NavigatorFrom) -> Void)
        //  passport @蔡伟伟
        (WebBody.pattern, { (url: URL, from: EENavigator.NavigatorFrom) -> Void in
            let resolver = container.getCurrentUserResolver()
            guard let service = try? resolver.resolve(assert: PassportAuthorizationService.self) else {
                Self.log.warn("cannot get authz service")
                return
            }
            let isSSOSDKUrlHandled = service.handleSSOSDKUrl(url)
            Self.log.info("recieve URLInterceptorManager.shared.register \(WebBody.pattern) callback, url\(url) and handleSSOSDKUrl is \(isSSOSDKUrlHandled)")
            if isSSOSDKUrlHandled {
                // LarkSSO SDK URL handled
                return
            }
            Navigator.shared.switchTab(Tab.feed.url, from: from, animated: true) {
                Navigator.shared.push(url, from: from, animated: true, completion: nil)
            }
        })
    }
}

final class MenuPluginRegisterHepler {
    /// 注册新版菜单的插件
    /// - Parameter container: SwiftLint的Resolver
    class func assembleMenuPlugin(container: Container) {
        /// 注册分享插件
        let webShareContext = MenuPluginContext(
            plugin: WebShareMenuPlugin.self,
            parameters: [WebShareMenuPlugin.providerContextResloveKey: container]
        )
        MenuPluginPool.registerPlugin(pluginContext: webShareContext)

        /// 注册刷新插件
        let webRefreshContext = MenuPluginContext(
            plugin: WebRefreshMenuPlugin.self
        )
        MenuPluginPool.registerPlugin(pluginContext: webRefreshContext)

        /// 注册在Safari中打开的插件
        let webOpenInSafariContext = MenuPluginContext(
            plugin: WebOpenInSafariMenuPlugin.self
        )
        MenuPluginPool.registerPlugin(pluginContext: webOpenInSafariContext)

        /// 注册网页菜单头部插件
        let webMenuHeaderContext = MenuPluginContext(
            plugin: WebMenuHeaderPlugin.self
        )
        MenuPluginPool.registerPlugin(pluginContext: webMenuHeaderContext)

        /// 注册复制链接插件
        let webCopyLinkContext = MenuPluginContext(
            plugin: WebCopyLinkMenuPlugin.self
        )
        MenuPluginPool.registerPlugin(pluginContext: webCopyLinkContext)
        
        /// 微信分享
        let webWeChatShareContext = MenuPluginContext(
            plugin: WeChatShareMenuPlugin.self
        )
        MenuPluginPool.registerPlugin(pluginContext: webWeChatShareContext)

        /// 微信朋友圈分享
        let webWeChatMomentsShareContext = MenuPluginContext(
            plugin: WeChatMomentsShareMenuPlugin.self
        )
        MenuPluginPool.registerPlugin(pluginContext: webWeChatMomentsShareContext)

        /// 翻译
        let webTranslateContext = MenuPluginContext(
            plugin: WebTranslateMenuPlugin.self
        )
        MenuPluginPool.registerPlugin(pluginContext: webTranslateContext)

        /// 注册反馈插件
        let webFeedBackContext = MenuPluginContext(
            plugin: AppFeedbackMenuPlugin.self
        )
        MenuPluginPool.registerPlugin(pluginContext: webFeedBackContext)
        
        /// 调整字体大小插件
        let webTextSizeContext = MenuPluginContext(
            plugin: WebTextSizeMenuPlugin.self
        )
        MenuPluginPool.registerPlugin(pluginContext: webTextSizeContext)
        
        /// 查找内容插件
        let webSearchContext = MenuPluginContext(
            plugin: WebSearchMenuPlugin.self
        )
        MenuPluginPool.registerPlugin(pluginContext: webSearchContext)
    }
}

// code from wangmiaoqi, msg: 拆分依赖
/// 登录态相关依赖
protocol LoginDependency {
    /// 注册登录前路由白名单
    func registerUnloginRouterWhitelist(_ pattern: String)
    /// 处理SSOURL
    func handleSSOSDKUrl(_ url: URL) -> Bool
    /// 种 Cookie
    func plantCookie()
}

/// 配置相关依赖(SuiteAppConfig, FG，AppConfigService等)
protocol ConfigDependency {
    var secLinkWhitelist: [String] { get }
    var suiteSecurityLink: String? { get }

    func isSecurityUrl(_ url: String, result: @escaping (Bool) -> Void)

    func featureSwitchOn(for feature: FeatureSwitchKey) -> Bool

    func featureGeting(for key: String) -> Bool
}

/// Feature Switch 项目
enum FeatureSwitchKey: String {
    case sso
    case gadget
}
// swiftlint:enable all

final class WebTranslateWebAPIRegisterImpl: WebTranslateWebAPIRegister {
    public func registJSSDK(apiDict: [String: () -> LarkWebJSAPIHandler], jsSDK: LarkWebJSSDK) {
        JsSDKBuilder.registJSSDK(apiDict: apiDict, jsSDK: jsSDK)
    }
    public func canEnableWebTranslate(_ context: WebBrowserMenuContext) -> Bool {
        !context.isOfflineMode
    }
}
