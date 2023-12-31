import EENavigator
import HTTProtocol
import LarkAccountInterface
import LarkAssembler
import LarkTab
import LKCommonsLogging
import LKLoadable
import ObjectiveC
import Swinject
import WebBrowser
import ECOInfra
import LarkRustClient
import LarkOPInterface
import LarkSetting
import LarkContainer

final public class EcosystemWebAssemblyV2: LarkAssemblyInterface {
    static let logger = Logger.ecosystemWebLog(EcosystemWebAssemblyV2.self, category: "EcosystemWebAssemblyV2")
    
    public init() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(didTabNameChanged(notification:)),
                                               name: Tab.tabNameChangeNotification,
                                               object: nil)
        
        
    }
    deinit {
        NotificationCenter.default.removeObserver(self)
        
    }
    public func registContainer(container: Container) {
        container.register(OpenAPIWebSessionUpdate.self) { _ in
            OpenAPIWebSessionUpdateIMP()
        }.inObjectScope(.container)
        
        let user = container.inObjectScope(OPUserScope.userScope)
        
        user.register(WebAppKeepAliveService.self) { resolver in
            WebAppKeepAliveManager(resolver)
        }
        container.register(WebBrowserSearchDependency.self) { _ in
            WebBrowserSearchDependencyIMP()
        }.inObjectScope(.container)
    }
    public func registRouter(container: Swinject.Container) {
        // NOTE: 直接打开app store
        Navigator.shared.registerRoute_(regExpPattern: "^http(s)?\\://itunes\\.apple\\.com") { req, res in
            Self.logger.info("recieve router callback, ^http(s)?\\://itunes\\.apple\\.com, and UIApplication.shared.open(req.url), url:\(req.url)")
            UIApplication.shared.open(req.url)
            res.end(resource: EmptyResource())
        }
        //  低优先级注册http(s)的URL拦截路由，非特定业务拦截应当使用统一浏览器打开
        Navigator.shared.registerRoute_(regExpPattern: "^http(s)?\\://", priority: .low, tester: { req in
            req.context["_canOpenInWeb"] = true
            req.context["_handledByDefaultURLRouter"] = true
            return true
        }) { req, res in
            Self.logger.info("recieve router callback, ^http(s)?\\://, and res.redirect WebBody, url:\(req.url.safeURLString)")
            res.redirect(
                body: WebBody(url: req.url),
                context: req.context
            )
        }
        Navigator.shared.registerRoute.type(WebBody.self).factory(NormalWebRouterHandler.init(resolver:))
        //  注册主导航网页路由
        Navigator.shared.registerRoute.match { (url) -> Bool in
            url.absoluteString.hasPrefix(Tab.webAppPrefix)
        }.tester { req in
            req.context["_canOpenInWeb"] = true
            req.context["_handledByDefaultURLRouter"] = true
            return true
        }.factory(MainNavigationAndTabWebRouterHandler.init(resolver:))
        //  即将废弃：打开离线网页应用路由，后续应该用3.0架构的SDK打开
        Navigator.shared.registerRoute.type(WebOfflineBody.self).factory(WebOfflineRouterHandler.init(resolver:))
        Navigator.shared.registerRoute.plain(WebInspectorPatternHandler.pattern).factory(WebInspectorPatternHandler.init(resolver:))
    }
    public func registLarkAppLink(container: Swinject.Container) {
        NormalWebAppLinkHandler.assemble(container: container)
    }
    public func registMatcherTabRegistry(container: Swinject.Container) {
        //  主导航网页Tab注册
        (Tab.webAppPrefix, { (i: [URLQueryItem]?) -> LarkTab.TabRepresentable in
            let badgeAPI = try? container.resolve(assert: OPBadgeAPI.self)
            let featureGatingService = try? container.resolve(assert: FeatureGatingService.self)
            let pushCenter = try? container.resolve(assert: PushNotificationCenter.self)
            return MainNavigationAndTabWebBrowserTab(
                tab: Tab.webApp(key: i?.first { $0.name == "key" }?.value ?? ""),
                badgeAPI: badgeAPI,
                pushCenter: pushCenter,
                featureGatingService: featureGatingService
            )
        })
    }
    @available(iOS 13.0, *)
    public func registLarkScene(container: Swinject.Container) {
        //  多窗口
        BrowserMutilScene.assembleMutilScene()
    }
    
    public func registLauncherDelegate(container: Container) {
        (LauncherDelegateFactory {
            WebViewStorageServiceDelegate()
        }, LauncherDelegateRegisteryPriority.low)
    }
    
    /// 注册消息推送
    public func registRustPushHandlerInUserSpace(container: Container) {
        (Command.pushOpenAppBadgeNodes, OPBadgePushHandler.init(resolver:))
    }
    
    // 动态物料需求会更新底部tab的标题，目前仅做了UI上的刷新，所以主导航通过变动通知手动缓存最新的网页应用标题，在创建网页主导航controller的时候进行使用。
    @objc
    func didTabNameChanged(notification: Notification){
        let changedTab = notification.object as? Tab
        if let changedTab = changedTab, changedTab.appType == .webapp {
            let action = {
                if let appid = changedTab.appid, !appid.isEmpty, !changedTab.tabName.isEmpty {
                    Self.logger.info("add or update newest title:\(changedTab.tabName) for app:\(appid)")
                    MainNavigationAndTabWebRouterHandler.newestTabTitleMap[appid] = changedTab.tabName
                }
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
}

@objcMembers
public final class WKProcessPoolSingletonTool: NSObject {
    public class func singleton() {
        // code from wangxiaohua
        // 让所有 WKWebView 共享同一个 WKProcessPool 实例
        // 可以实现多个 WKWebView 之间共享 Cookie（session Cookie and persistent Cookie） 数据
        if #available(iOS 12.0, *) {
            makeWKProcessPoolSingleton()
        }
    }
}
