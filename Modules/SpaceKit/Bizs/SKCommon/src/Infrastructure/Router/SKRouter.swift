//
//  SpaceRouter.swift
//  SpaceKit
//
//  Created by Gill on 2019/2/18.
//

import SKFoundation
import EENavigator
import SKResource
import UniverseDesignToast
import SpaceInterface
import SKInfra

/// [README](https://bytedance.feishu.cn/docs/doccnCf7RNsvWxaZy1e6wMyqqGf#cQeaaq)
@available(*, deprecated, message: "new code should use EENavigator directly")
final public class SKRouter {

    public static let shared = SKRouter()

    public static let logComponent = "[SKRouter]"
    /// 传参
    public typealias Params = [AnyHashable: Any]
    /// 构建工厂
    public typealias Factory = (SKRouterResource, Params?, DocsType) -> UIViewController?

    /// URL 重定向。返回新的路由目标
    /// - Parameters: DocsType/URL/额外参数
    /// - Returns: URL: 重定向某个网址
    public typealias Redirector = (SKRouterResource, Params?) -> (SKRouterResource, Params?)?
    private static let redirectCountKey = "_skrouter_redirect_count"
    // 最多允许连续10次重定向
    private static let redirectCountLimit = 10

    /// 视图拦截器。会被重定向到一个新的 ViewController
    /// - Parameters: DocsType/URL/额外参数
    /// - Returns: UIViewController: 新的 ViewController
    public typealias VCInterceptor = (SKRouterResource, Params?) -> (UIViewController?)
    /// 视图拦截器检验
    /// - Parameters: DocsType/URL/额外参数
    /// - Returns: Bool: 是否要启用拦截器
    public typealias InterceptorChecker = (SKRouterResource, Params?) -> (Bool)

    private struct Router {
        let type: DocsType?
        let factory: Factory

        init(type: DocsType, factory: @escaping Factory) {
            self.type = type
            self.factory = factory
        }
    }

    private var docsTypeRouter: [DocsType: Router] = [:]
    private var interceptors: [(InterceptorChecker, VCInterceptor)] = []
    private var redirectors: [Redirector] = []

    /// 注册处理 DocsType 构建方法
    /// URLInterceptor 可用于处理其他环境变量，可以让结果重定向到兜底 Webview
    public func register(types: [DocsType],
                  factory: @escaping Factory) {
        types.forEach { (type) in
            let router = Router(type: type, factory: factory)
            docsTypeRouter[type] = router
        }
    }

    /// 注册视图拦截器
    /// VCInterceptor 优先级高于 DocsType 构建方法
    public func register(checker: @escaping InterceptorChecker,
                  interceptor: @escaping VCInterceptor) {
        interceptors.insert((checker, interceptor), at: 0)
    }

    public func register(redirector: @escaping Redirector) {
        redirectors.append(redirector)
    }

    /// 获取相应类型所对应的构造方法
    public func getFactory(with type: DocsType) -> Factory? {
        return docsTypeRouter[type]?.factory
    }

    /// 通过 URL 构建 VC
    ///
    /// - Parameters:
    ///   - url: 传入的url
    ///   - extraInfos: 扩展字段，可以用来传参
    /// - Returns: (nextVC, 是否是支持类型)
    public func open(with resource: SKRouterResource,
              params: Params? = nil) -> (UIViewController?, Bool) {
        /// VC 拦截器。优先级最高
        for interceptor in interceptors {
            let needIntercept = interceptor.0(resource, params)
            if needIntercept {
                return (interceptor.1(resource, params), false)
            }
        }

        let redirectCount = params?[Self.redirectCountKey] as? Int ?? 0
        if redirectCount < Self.redirectCountLimit {
            for redirector in redirectors {
                if let (newResource, newParams) = redirector(resource, params) {
                    var nextParams = newParams ?? [:]
                    nextParams[Self.redirectCountKey] = redirectCount + 1
                    return open(with: newResource, params: nextParams)
                }
            }
        }

        /// 处理支持的业务逻辑
        let isSupported = resource.isSupported
        let type = resource.docsType
        /// 开始创建 VC
        /// 不支持的类型直接跳到兜底页
        if !isSupported {
            if let file = resource as? SpaceEntry, let url = URL(string: file.shareUrl ?? "") {
                DocsLogger.info("resource不是支持的SpaceEntry类型。Type: \(type)", component: SKRouter.logComponent)
                return (defaultRouterView(url), false)
            }
            DocsLogger.info("resource url 不匹配有效的类型", component: SKRouter.logComponent)
            return (defaultRouterView(resource.url), false)
        }
        
        if let router = docsTypeRouter[type] {
            return navigate(to: resource, type: type, params: params, router: router)
        } else {
            DocsLogger.warning("\(SKRouter.logComponent) 找不到 \(type) 的路由")
            return(defaultRouterView(resource.url), false)
        }
    }

    private func navigate(to resource: SKRouterResource,
                          type: DocsType,
                          params: Params?,
                          router: Router) -> (UIViewController?, Bool) {
        return (router.factory(resource, params, type), true)
    }

    /// 使用普通的webview加载对应的URL
    private func defaultWebView(_ url: URL) -> UIViewController {
        return DocsContainer.shared.resolve(SKCommonDependency.self)!.createDefaultWebViewController(url: url)
    }
    //原生兜底页
    private func defaultNavtiveView(_ url: URL) -> UIViewController {
        let vc = SKRouterBottomViewController(.unavailable(.defaultView), title: BundleI18n.SKResource.CreationMobile_ECM_SiteUnavailableTitle())
        return vc
    }
    
    //获取兜底页
    public func defaultRouterView(_ url: URL) -> UIViewController {
        return defaultRouterView(url, type: .unavailable(.defaultView))
    }
    
    public func defaultRouterView(_ url: URL, type: ContentPromptype) -> UIViewController {
        if URLValidator.isBlackPath(url: url) {
            // 黑名单内走 webView
            return defaultWebView(url)
        } else {
            return defaultNavtiveView(url)
        }
    }
    
}
