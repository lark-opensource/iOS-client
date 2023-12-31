//
//  WebViewControllerDependency.swift
//  WebBrowser
//
//  Created by 新竹路车神 on 2020/9/30.
//

import ECOProbe
import EENavigator
import LarkContainer
import LarkUIKit
import LarkWebViewContainer
import LKLoadable
import WebKit

//  备注，这里需要被替换掉，需要和套件统一API框架对接
//  套件统一API框架对应文档：https://bytedance.feishu.cn/docs/doccnrBlLulgvaVvBJGPi81qUzg
public protocol LarkWebJSAPIHandler {
    /// 所有的API调用都需要授权
    var needAuthrized: Bool { get }
    func handle(args: [String: Any], api: WebBrowser, sdk: LarkWebJSSDK)
}
//  备注，这里需要被替换掉，需要和套件统一API框架对接
//  套件统一API框架对应文档：https://bytedance.feishu.cn/docs/doccnrBlLulgvaVvBJGPi81qUzg
public extension LarkWebJSAPIHandler {
    var needAuthrized: Bool {
        return false
    }
}
//  备注，这里需要被替换掉，需要和套件统一API框架对接
//  套件统一API框架对应文档：https://bytedance.feishu.cn/docs/doccnrBlLulgvaVvBJGPi81qUzg
public protocol LarkWebJSSDK: AnyObject {
    /// jsAPI鉴权用的token
    var authSession: String? { get set }

    /*
     {
         method: ,
         args: {
             方法名:
             业务数据
         }
     }
     method是json中的method，args是json中的args
     */
    //  老协议调用biz系列API
    @discardableResult
    func invoke(method: String, args: [String: Any]) -> Bool
    /*
     {
         apiName: ,
         data: {
             方法名:
             业务数据
         },
         callbackID:
     }
     apiName是json中的apiName，data是json中的data.callbackID是json的callbackID
     */
    //  新协议调用biz系列API
    @discardableResult
    func invoke(apiName: String, data: [String: Any], callbackID: String?) -> Bool


    func regist(method: String, apiGetter: @escaping () -> LarkWebJSAPIHandler)
}
//  备注，这里需要被替换掉，需要和套件统一API框架对接
//  套件统一API框架对应文档：https://bytedance.feishu.cn/docs/doccnrBlLulgvaVvBJGPi81qUzg
public extension LarkWebJSAPIHandler {
    func callbackWith(api: WebBrowser?, funcName: String?, arguments: [Any]) {
        guard let api = api,
            let method = funcName else {
                return
        }
        if Thread.isMainThread {
            api.call(funcName: method, arguments: arguments)
        } else {
            DispatchQueue.main.async {
                api.call(funcName: method, arguments: arguments)
            }
        }
    }
}

//  备注，这里需要被替换掉，需要和套件统一API框架对接
//  套件统一API框架对应文档：https://bytedance.feishu.cn/docs/doccnrBlLulgvaVvBJGPi81qUzg
//  为改动任何逻辑，只是换了位置，技术对接人 liushuwei wangmiaoqi
/// 控制使用的 JsAPI Method 的范围
public enum JsAPIMethodScope {
    case none
    case all
    case allow(_ methods: [String])
    case block(_ methods: [String])
}

/// 网页视图控制器能力代理协议
public protocol WebBrowserDependencyProtocol {
    //  废弃接口
    func getLarkWebJsSDK(with api: WebBrowser, methodScope: JsAPIMethodScope) -> LarkWebJSSDK?
    
    func appInfoForCurrentWebpage(browser: WebBrowser) -> WebAppInfo?
    
    func isWebAppForCurrentWebpage(browser: WebBrowser) -> Bool
    
    func errorpageHTML() -> String?
    
    func webDetectPageHTML() -> String?
    // openAPI唤起My AI分会话，不实现，暂时注释
//    func launchMyAI(browser: WebBrowser)

    func registerExtensionItemsForBitableHomePage(browser: WebBrowser)
}

/// 更新网页容器API Session
public protocol OpenAPIWebSessionUpdate {
    
    func updateSession(_ session: String, url: URL, browser: WebBrowser)
    
}

public protocol WebBrowserSearchDependency {
    
    func highlightSearchScript() -> String?
}

class WebBrowserDpInternal {
    static let shared = WebBrowserDpInternal()
    @Provider var dp: WebBrowserDependencyProtocol
    private init() {}
}

/// 套件统一浏览器依赖对象，请一定不要修改为public，否则需要revert代码，写case study，做复盘，负事故责任
var webBrowserDependency: WebBrowserDependencyProtocol! {
    WebBrowserDpInternal.shared.dp
}

//  备注，这里需要被替换掉，需要和套件统一API框架对接
//  套件统一API框架对应文档：https://bytedance.feishu.cn/docs/doccnrBlLulgvaVvBJGPi81qUzg
/// 带api授权的网页应用jssdk相关依赖协议
public protocol WebAppApiAuthJsSDKProtocol: AnyObject {

    var currentURL: URL? { get set }

    func invoke(method: String, args: [String: Any], shouldUseNewBridgeProtocol: Bool, trace: OPTrace, webTrace: OPTrace?) -> Bool

    func updateSession(session: String, url: URL)

}

public protocol WebAppApiNoAuthProtocol: AnyObject {
    func isAPINoNeedAuth(apiName: String) -> Bool
    func invoke(method: String, args: [String: Any], shouldUseNewBridgeProtocol: Bool, trace: OPTrace, webTrace: OPTrace?) -> Bool
}

/// 网页应用模型
public final class WebAppInfo: Codable {
    /// 网页应用唯一标志符
    public let id: String
    
    /// 网页应用名称
    public let name: String?
    
    /// 网页应用图标key
    public var iconKey: String?
    
    /// 网页应用图标地址
    public var iconURL: String?
    
    /// 应用识别状态
    public var status: String
    
    /// API 权限状态
    public var apiAuthenStatus: APIAuthenStatus
    
    public convenience init(
        id: String,
        name: String? = nil,
        iconKey: String? = nil,
        iconURL: String? = nil,
        status: String = AppStatus.launch.rawValue,
        apiAuthenStatus: APIAuthenStatus = .notDetermined
    ) {
        self.init(id: id, name: name, iconKey: iconKey, iconURL: iconURL, status: status)
        self.apiAuthenStatus = apiAuthenStatus
    }
    
    public init(
        id: String,
        name: String? = nil,
        iconKey: String? = nil,
        iconURL: String? = nil,
        status: String = AppStatus.launch.rawValue
    ) {
        self.id = id
        self.name = name
        self.iconKey = iconKey
        self.status = status
        self.iconURL = iconURL
        self.apiAuthenStatus = .notDetermined
    }
}

/// 应用识别状态
public enum AppStatus: String {
    /// 启动赋予身份
    case launch
    /// 运行时赋予身份
    case runtime
}

/// API authen status
public enum APIAuthenStatus: String, Codable {
    // 已经经过config鉴权
    case authened
    // 还未经过config鉴权
    case notDetermined
}

public enum H5AppFromScene: String, Codable {
    case web_app_applink = "web_app_applink"
    case web_url_applink = "web_url_applink"
    case app_share_applink = "app_share_applink"
}

public struct WebBody: CodablePlainBody {
    //  此处存在飞书路由历史债务
    //  潜规则： EENavigator 同类Body只能打开一个容器。只要Body不指定forcePush参数，就只能同时通过路由打开一个。任意Body均受此影响。
    //  事故影响：导致、造成、引起了「yujiahui」无法使用AppLink打开网页
    //  责任人：liuwanlin@bytedance.com
    //  事故等级：P0
    //  事故影响范围：全版本，所有业务如果使用 CodablePlainBody，都会有该问题。
    //  问题文档：https://bytedance.feishu.cn/docs/doccnIsfJs2ugescOJoILBIQcOf
    public static let pattern: String = "//client/web"

    public let url: URL
    
    public let webAppInfo: WebAppInfo?
    /// 是否每次push新页面
    public var forcePush: Bool?
    
    public var fromScene: H5AppFromScene?
    
    public var appLinkTrackId: String?
    
    public var appLinkFrom: String?
    
    public var lkAnimationMode: String?  //动画mode
    public var lkNavigationMode: String? //导航栏mode
    /// 是否是 iPad 上的多 scene 打开
    public var fromWebMultiScene: Bool = false
    
    // 是否禁用统一路由，因为push url 最终会转换为WebBody,所以如果路由context["notUseUniteRoute"]中传了值，那么context中的值优先级更高。
    // notUseUniteRoute在context中的值为布尔类型, 屏蔽统一路由constext示例: ["notUseUniteRoute":true]
    public var notUseUniteRoute: Bool = false

    public init(url: URL, webAppInfo: WebAppInfo? = nil, hideShowMore: Bool = false) {
        WebBrowser.logger.info("WebBody init, url: \(url.safeURLString), appid: \(webAppInfo?.id)")
        self.url = url
        self.webAppInfo = webAppInfo
        // 临时解决方案，关于此方式的详细解释：https://bytedance.feishu.cn/docs/doccnIsfJs2ugescOJoILBIQcOf#
        // 网页需要每次都打开新VC
        self.forcePush = true
    }
}

/// 不提供 JsAPI Method 的 UnloginWebBody
public struct SimpleWebBody: CodablePlainBody {
    public static let pattern: String = "//client/web/simple"

    public let url: URL

    public let showMore: Bool
    public let showLoadingFirstLoad: Bool = false
    public let customUserAgent: String?

    public init(url: URL,
                showMore: Bool = false,
                showLoadingFirstLoad: Bool = true,
                customUserAgent: String? = nil) {
        self.url = url
        self.showMore = showMore
        self.customUserAgent = customUserAgent
    }
}
