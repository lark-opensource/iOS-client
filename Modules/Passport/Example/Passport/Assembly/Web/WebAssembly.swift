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
import LarkWebViewController
import JsSDK
import LarkFeatureGating
import LarkUIKit
import LarkSDKInterface
import LKCommonsTracker
import Homeric
import LarkReleaseConfig
import LarkSceneManager
import LarkAccountInterface

//可以抽离到飞书源码
// 仅移动代码为改变任何逻辑，需要查询原作者请克隆LarkWebViewController仓库
class WebAssembly: Assembly {
    static let log = Logger.log(WebAssembly.self, category: "WebAssembly")

    static var accountInterface: LoginDependency {
        LoginDependencyImp()
    }

    func assemble(container: Container) {

        let dependency = OpenPlatformAPIHandlerImp(container)
//        configAPIHandlerDependency(dependency)
        configWebBrowserDependency(dependency)

        // 让所有 WKWebView 共享同一个 WKProcessPool 实例
        // 可以实现多个 WKWebView 之间共享 Cookie（session Cookie and persistent Cookie） 数据
        if #available(iOS 12.0, *) {
            makeWKProcessPoolSingleton()
            WebAssembly.log.debug("makeWKProcessPoolSingleton")
        }

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

        assembleRequestHandler(container: container)

        assembleMenuPlugin(container: container)
        /// 套件统一webview注入
        LarkWebViewContainerAssembly.register(resolver: container)
        /// 多Scene注册
        assembleMutilScene()

        OPTraceService.default().setup(
            OPTraceConfig(
                prefix: "PassportSDKDemo",
                generator: { _ in
                    UUID().uuidString
                }
            )
        )

//        container.register(OPTraceDependency.self) { (_) -> OPTraceDependency in
//            OPTraceDependencyImp()
//        }

        OfflineResourceApplicationDelegate().initOfflineResourceManager()

        LauncherDelegateRegistery.register(factory: LauncherDelegateFactory(delegateProvider: { () -> LauncherDelegate in
            OfflineResourceDelegate(resolver: container)
        }), priority: .middle)
    }

    /// 注册新版菜单的插件
    /// - Parameter container: SwiftLint的Resolver
    private func assembleMenuPlugin(container: Container) {
        /// 注册分享插件

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

        /// 注册多任务插件
        let webFloatingContext = MenuPluginContext(
            plugin: WebFloatingMenuPlugin.self
        )
        MenuPluginPool.registerPlugin(pluginContext: webFloatingContext)
        /// 微信分享
        /// 微信朋友圈分享
    }

    /// 按顺序确认各业务的匹配优先级，可优化
    func assembleRequestHandler(container: Container) {
        let resolver = container

        // NOTE: 直接打开app store
        Navigator.shared.registerRoute(regExpPattern: "^http(s)?\\://itunes\\.apple\\.com") { req, res in
            Self.log.info("recieve router callback, ^http(s)?\\://itunes\\.apple\\.com, and UIApplication.shared.open(req.url), url:\(req.url)")
            UIApplication.shared.open(req.url)
            res.end(resource: EmptyResource())
        }

        Navigator.shared.registerRoute(regExpPattern: "^http(s)?\\://", priority: .low, tester: { req in
            req.context["_canOpenInWeb"] = true
            //  其他地方抄代码请一定不要把下面一行抄进去，这个是标志http链接是否被Lark网页容器兜底处理的，否则抄的代码请revert然后写case study
            req.context["_handledByDefaultURLRouter"] = true
            return true
        }) { req, res in
            Self.log.info("recieve router callback, ^http(s)?\\://, and res.redirect WebBody, url:\(req.url)")
            res.redirect(
                body: WebBody(url: req.url),
                context: req.context
            )
        }

        Navigator.shared.registerRoute(type: WebBody.self) {
            //  仅把协议依赖改为实体依赖，避免无用的协议方法调用
            return WebHandler(resolver: resolver)
        }

        Navigator.shared.registerRoute(type: UnloginWebBody.self) {
            return UnloginWebHandler(resolver: resolver)
        }

        Self.accountInterface.registerUnloginRouterWhitelist(UnloginWebBody.pattern)

        Navigator.shared.registerRoute(type: SimpleWebBody.self) {
            return SimpleWebHandler()
        }

        Self.accountInterface.registerUnloginRouterWhitelist(SimpleWebBody.pattern)

        Navigator.shared.registerRoute(match: { url in
            // code from wangyuanxun，未做任何逻辑修改，commit msg：接入云控
            guard let scheme = url.scheme else { return false }
            if var schemeConfig = resolver.resolve(UserGeneralSettings.self)?.schemeConfig {
                return schemeConfig.schemeHandleList.contains(where: { $0.caseInsensitiveCompare(scheme) == .orderedSame }) || url.absoluteString.contains("itunes.apple.com")
            }
            return false
        }, priority: .low) { req, res in
            // code from wangyuanxun，未做任何逻辑修改，commit msg：接入云控
            if let downloadSiteList = resolver.resolve(UserGeneralSettings.self)?.schemeConfig.schemeDownloadSiteList,
               !downloadSiteList.isEmpty {
                UIApplication.shared.open(req.url, options: [:]) { (success) in
                    Self.log.info("recieve router callback, cloud control has downloadSiteList and UIApplication.shared.open result:\(success), url:\(req.url)")
                    if !success {
                        if let scheme = req.url.scheme,
                           let downloadSiteString = downloadSiteList[scheme],
                           let downloadSite = URL(string: downloadSiteString) {
                            Self.log.info("recieve router callback, cloud control has downloadSiteList, UIApplication.shared.open \(req.url) failed, and UIApplication.shared.open \(downloadSite)")
                            UIApplication.shared.open(downloadSite)
                        }
                    }
                    Tracker.post(TeaEvent(Homeric.APPLINK_FEISHU_OPEN_OTHERAPP_RESULT,
                                          params: ["schema": req.url.scheme ?? "",
                                                   "result": success ? "success" : "fail"]))
                }
            } else {
                Self.log.info("recieve router callback, cloud control has no downloadSiteList and UIApplication.shared.open, url:\(req.url)")
                UIApplication.shared.open(req.url, options: [:], completionHandler: nil)
            }
            res.end(resource: EmptyResource())
        }
        // 打开浏览器，或打开url
        URLInterceptorManager.shared.register(WebBody.pattern) { (url, from) in
            let handleSSOSDKUrl = Self.accountInterface.handleSSOSDKUrl(url)
            Self.log.info("recieve URLInterceptorManager.shared.register \(WebBody.pattern) callback, url\(url) and handleSSOSDKUrl is \(handleSSOSDKUrl)")
            if handleSSOSDKUrl {
                // LarkSSO SDK URL handled
                return
            }

            var params = NaviParams()
            params.switchTab = Tab.feed.url
            params.forcePush = true
            let context = [String: Any](naviParams: params)
            Navigator.shared.push(url, context: context, from: from, animated: true, completion: nil)
        }

        registerTab(resolver: resolver)
    }
    /// 注册网页控制器到飞书Tab，可以在飞书Tab打开网页控制器
    private func registerTab(resolver: Resolver) {
        //  code from lizhong.limboy@bytedance.com
        Navigator.shared.registerRoute(match: { (url) -> Bool in
            url.absoluteString.hasPrefix(Tab.webAppPrefix)
        }, tester: { req in
            req.context["_canOpenInWeb"] = true
            //  其他地方抄代码请一定不要把下面一行抄进去，这个是标志http链接是否被Lark网页容器兜底处理的，否则抄的代码请revert然后写case study
            req.context["_handledByDefaultURLRouter"] = true
            return true
        }) { () -> WebHandler in
            Self.log.info("recieve Navigator.shared.registerRoute url.absoluteString.hasPrefix \(Tab.webAppPrefix) callback")
            return WebHandler(resolver: resolver)
        }
        TabRegistry.registerMatcher(Tab.webAppPrefix) { WebBrowserTab(tab: Tab.webApp(key: $0?.first { $0.name == "key" }?.value ?? "")) }
    }
    /// 注册多Scene回调, 在独立窗口打开web页面
    private func assembleMutilScene() {
        if #available(iOS 13.4, *), SceneManager.shared.supportsMultipleScenes {
            SceneManager.shared.register(config: WebSceneConfig.self)
        }
    }
}

/// Web容器多Scene
@available(iOS 13.0, *)
class WebSceneConfig: SceneConfig {
    /// Web 多Scene区分业务的key
    static var key: String { "Web" }
    /// Web 多Scene新窗口的icon
    static func icon() -> UIImage { WebBrowserResources.mutil_scene_web_icon }

    static func createRootVC(scene: UIScene, session: UISceneSession, options: UIScene.ConnectionOptions,
                        sceneInfo: Scene, localContext: AnyObject?) -> UIViewController? {
        WebAssembly.log.info("\(scene) \(session) \(options) \(sceneInfo)")
        /// sceneInfo.id 为新窗口打开的网页的地址，同时这个地址作为Web多scene业务下面区分某一个窗口的key
        /// LarkScene的框架会以这个id为key，来区分寻查找历史存在的同一个地址创建的window
        if let _url = URL(string: sceneInfo.id) {
            let body = WebBody(url: _url)
            let navi = LkNavigationController()
            /// context需要携带forcePush标记，否则会命中主端路由组件EENavigator的bug
            /// 参见 https://bytedance.feishu.cn/docs/doccnIsfJs2ugescOJoILBIQcOf
            Navigator.shared.push(body: body,
                                  context: ["forcePush": true],
                                  from: navi,
                                  animated: false) { (_, _) in
                WebAssembly.log.info("open \(_url) in new scene success")
            }
            return navi
        }
        WebAssembly.log.error("open \(sceneInfo.id) in new scene failed")
        return nil
    }
}

//code from lilun，未改动任何一行逻辑，只换了位置
/// 符合飞书Tab系统的网页视图控制器Tab对象
class WebBrowserTab: TabRepresentable {
    var tab: Tab {
        appTab
    }
    private let appTab: Tab
    private let log = Logger.log(WebBrowserTab.self, category: "WebBrowserTab")
    /// 红点数据源
    private var _badge = BehaviorRelay<LarkTab.BadgeType>(value: .none)
    /// 红点是否可见数据源，可见
    private var _badgeOutsideVisable = BehaviorRelay<Bool>(value: true)
    /// 红点样式数据源，红色badge类型
    private var _badgeStyle = BehaviorRelay<BadgeRemindStyle>(value: .strong)
    // badge data source
    var badge: BehaviorRelay<LarkTab.BadgeType>? {
        return self._badge
    }
    var badgeStyle: BehaviorRelay<BadgeRemindStyle>? {
        return _badgeStyle
    }
    var badgeOutsideVisiable: BehaviorRelay<Bool>? {
        return _badgeOutsideVisable
    }
    private var badgeObsever: OPBadge.BadgePushObserver?
    init(tab: Tab) {
        log.info("WebBrowserTab init, url: \(tab.url), appid: \(tab.appid)")
        appTab = tab
        observeBadge()
    }
    /// 监听Badge变化
    private func observeBadge() {
        if let appId = tab.appid {
            var appAbility: OPBadge.AppAbility = .unknown
            switch tab.appType {
            case .webapp:
                appAbility = .H5
            default:
                appAbility = .unknown
            }
            log.info("tab \(tab.appid) \(tab.appType) observeBadge")
            self.badgeObsever = OPBadge.BadgePushObserver(
                appId: appId,
                type: appAbility,
                badgeNumCallback: { [weak self] (badgeNum, needShow) in
                    guard let self = self else {
                        return
                    }
                    /// Badge的fg是否开启，预计3.45版本之后移除fg控制
                    //未修改任何逻辑
                    guard LarkFeatureGating.shared.getFeatureBoolValue(for: OPBadge.isEnableGadgetAppBadge) else {
                        self.log.info("received badge update bug GadgetAppBadge fg not enable")
                        self._badge.accept(.none)
                        return
                    }
                    if needShow {
                        self.log.info("Tab App \(appId) type \(appAbility.description) update badge \(badgeNum)")
                        self._badge.accept(.number(badgeNum))
                    } else {
                        self.log.info("Tab App \(appId) type \(appAbility.description) hide badge")
                        self._badge.accept(.none)
                    }
                })
        }
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


extension JsSDKBuilder {

    static func jsSDKWithAllProvider(api: LarkWebViewControllerAPI, resolver: Resolver, scope: JsAPIMethodScope) -> LarkWebJSSDK {
        JsSDKBuilder.initJsSDK(
            api,
            resolver: resolver,
            handlerProviders: Self.allHandlerProviders(api: api, resolver: resolver),
            scope: scope
        )
    }

    static func allHandlerProviders(api: LarkWebViewControllerAPI, resolver: Resolver) -> [JsAPIHandlerProvider] {
        return [
            BaseJsAPIHandlerProvider(api: api, resolver: resolver),
            PassportJsAPIHandlerProvider(resolver: resolver)
        ]
    }
}

//class OPTraceDependencyImp: NSObject, OPTraceDependency {
//    func getFeatureGatingBoolValue(for key: String) -> Bool {
//        LarkFeatureGating.shared.getFeatureBoolValue(for: key)
//    }
//
//    func readSettingsConfig(for key: String) -> [String : Any] {
//        [:]
//    }
//
//    func readMinaConfig(for key: String) -> [String : Any] {
//        [:]
//    }
//}
