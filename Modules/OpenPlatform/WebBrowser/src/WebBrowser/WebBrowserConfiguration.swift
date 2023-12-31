import ECOProbe
import LarkWebViewContainer
import LKCommonsLogging
import WebKit

private let logger = Logger.webBrowserLog(WebBrowserConfiguration.self, category: "WebBrowserConfiguration")

/// 套件统一浏览器唯一标志符key，通过飞书路由的context可以传入
public let webBrowserIDKey = "webBrowserID"
public let acceptWebMetaKey = "acceptWebMeta"
public let urlKey = "url"
public let traceIDKey = "traceID"

/// 网页控制器配置
public struct WebBrowserConfiguration {
    /// 是否需要同步Cookie
    var isAutoSyncCookie: Bool

    /// 是否打开安全链接
    let secLinkEnable: Bool

    /// 自定义UA
    let customUserAgent: String?

    /// webview configuration
    public var webviewConfiguration: WKWebViewConfiguration

    /// 是否进入无痕预览模式，无痕模式下不会携带任何app内的cookie，并且退出web会清除所有的临时数据
    var shouldNonPersistent: Bool
    var originRefererURL: URL?

    public var jsApiMethodScope: JsAPIMethodScope
    public var webBizType: LarkWebViewBizType
    
    /// 套件统一浏览器唯一标志符，可以以window为级别进行标志
    public var webBrowserID: String
    
    /// 是否不走统一路由拦截（目前给passport单独开个入口，回头通过extension统一迁移到passport管理，非passport请勿设置，如果乱设置导致线上事故，请revert代码，写case study，做复盘，承担事故责任）
    let notUseUniteRoute: Bool
    
    /// 页面跳转时是否自动重置导航栏按钮（定制导航栏按钮场景下机制 https://bytedance.feishu.cn/docx/doxcnxrkIn5PZLINemFwcLcR9Df ）
    public var autoResetNavigationBar: Bool = false
    
    /// 是否开启下载文件的能力支持
    let downloadEnable: Bool
    
    /// 是否开启 WebMeta 能力
    public var acceptWebMeta: Bool = false
    
    ///startHandleTime 用于数据监控
    public var startHandleTime: TimeInterval?
    
    public var appId: String?
    
    public var scene: WebBrowserScene = .normal
    
    public var fromScene: WebBrowserFromScene = .normal
    
    public var fromSceneReport: WebBrowserFromSceneReport = .normal
    
    /// 是否开启重定向打开 Native 窗口优化
    public var enableRedirectOptimization: Bool = false
    
    public var resourceInterceptConfiguration: (Set<String>, WKResourceInterceptProtocol)?
    /// 由外部指定的初始化 trace，如果指定初始化 reace，那么需要在初始化的位置自行进行 wb_container_start_handle 点位的上报
    public var initTrace: OPTrace?
    /// 是否是离线Web
    public var offline: Bool = false
    public var applinkURLString: String = ""

    /// 是否开启根视图左侧按钮显示优化,内部做兼容场景太多，先通过配置的方式来解决左侧按钮实现应用根视图场景下首页隐藏
    /// https://bytedance.feishu.cn/wiki/wikcnYAKX33FxwThGP8PdVYBm1d
    public var leftNaviButtonsRootVCOpt: Bool = false
    
    /// 是否开启底部导航栏 LaunchBar
    public var isLaunchBarEnable: Bool = true
    
    ///  是否开启底部导航栏 LaunchBar 的 MyAi 入口
    public var isMyAiItemEnable: Bool = true
    
    public var isInspectable = false
    
    public var autoLoadRequest = true

    /// Tips：该方法请尽量给每一个参数都附带上默认参数，降低使用成本
    /// 初始化方法
    public init(
        isAutoSyncCookie: Bool = true,
        secLinkEnable: Bool = true,
        customUserAgent: String? = nil,
        shouldNonPersistent: Bool = false,
        originRefererURL: URL? = nil,
        jsApiMethodScope: JsAPIMethodScope = .all,
        webBizType: LarkWebViewBizType? = nil,
        webviewConfiguration: WKWebViewConfiguration = WKWebViewConfiguration(),
        webBrowserID: String = UUID().uuidString,
        notUseUniteRoute: Bool = false,
        downloadEnable: Bool = false
    ) {
        self.isAutoSyncCookie = isAutoSyncCookie
        self.secLinkEnable = secLinkEnable
        self.customUserAgent = customUserAgent
        self.shouldNonPersistent = shouldNonPersistent
        self.originRefererURL = originRefererURL
        self.jsApiMethodScope = jsApiMethodScope
        self.webBizType = webBizType ?? LarkWebViewBizType.larkWeb
        self.webviewConfiguration = webviewConfiguration
        self.webBrowserID = webBrowserID
        self.notUseUniteRoute = notUseUniteRoute
        self.downloadEnable = downloadEnable
    }

    /// description of all properties
    public func toString() -> String {
        return """
            WebBrowserConfiguration(
            isAutoSyncCookie:\(isAutoSyncCookie),
            secLinkEnable:\(secLinkEnable),
            customUserAgent:\(customUserAgent),
            shouldNonPersistent:\(shouldNonPersistent),
            jsApiMethodScope: \(jsApiMethodScope),
            webBizType: \(webBizType.rawValue),
            webviewConfiguration:\(webviewConfiguration),
            webBrowserID:\(webBrowserID),
            downloadEnable:\(downloadEnable),
            acceptWebMeta:\(acceptWebMeta),
            leftNaviButtonsRootVCOpt:\(leftNaviButtonsRootVCOpt),
            initTrace:\(initTrace)
            )
            """
    }
}
