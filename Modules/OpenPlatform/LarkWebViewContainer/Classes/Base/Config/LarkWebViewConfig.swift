//
//  LarkWebViewConfig.swift
//  LarkWebViewContainer
//
//  Created by houjihu on 2020/8/12.
//

import ECOProbe
import LarkSetting
import WebKit

/// 业务类型
@objcMembers
public final class LarkWebViewBizType: NSObject {
    /// 日历
    public static let calendar = LarkWebViewBizType("calendar")
    /// 文档
    public static let docs = LarkWebViewBizType("docs")
    /// 小程序
    public static let gadget = LarkWebViewBizType("gadget")
    /// 邮箱
    public static let mail = LarkWebViewBizType("mail")
    /// LarkWeb
    public static let larkWeb = LarkWebViewBizType("larkweb")
    /// Passport
    public static let passport = LarkWebViewBizType("passport")
    /// UG
    public static let ug = LarkWebViewBizType("ug.register")
    /// 半屏网页容器
    public static let larkWebPanel = LarkWebViewBizType("larkweb_panel")
    /// bitable
    public static let larkBase = LarkWebViewBizType("lark_base")
    /// base_forms 特指 Base Forms 项目组提供的能力，不单是收集表，也欢迎 Base 内其他业务接入
    public static let baseForms = LarkWebViewBizType("base_forms")
    /// 未知
    public static let unknown = LarkWebViewBizType("unknown")

    public var rawValue: String
    public init(_ value: String) {
        assert(!value.isEmpty, "biz type cannot be empty")
        self.rawValue = value
    }
}


public enum LarkWebViewSeclinkPrecheckResult {
    ///未检测
    case unPrecheck
    ///检测中
    case prechecking
    ///检测为安全
    case safe
    ///检测为非安全
    case unsafe
}

/// IESWebViewMonitor开关配置
@objcMembers
public final class LarkWebViewMonitorConfig: NSObject {
    /// IESWebViewMonitor总开关，开启后会监控WebView性能数据，原理见https://tech.bytedance.net/articles/6930917346194227213
    public let enableMonitor: Bool
    
    /// 总开关关闭时下列开关都将无效
    /// 是否注入slardar-sdk.js，开启后会向WebView中注入slardar-sdk.js用以采集前端性能数据
    public let enableInjectJS: Bool
    
    public init(enableMonitor: Bool = false,
                enableInjectJS: Bool = false) {
        self.enableMonitor = enableMonitor
        self.enableInjectJS = enableInjectJS
        super.init()
    }
    
    func toString() -> String {
        """
        monitor enable: \(enableMonitor), \
        inject JS enable: \(enableInjectJS)
        """
    }
}

/// WebView初始化配置
@objcMembers
public final class LarkWebViewConfig: NSObject {
    /// 业务类型
    public fileprivate(set) var bizType = LarkWebViewBizType.unknown
    /// WKWebView Configuration
    public fileprivate(set) var webViewConfig = WKWebViewConfiguration()
    /// 是否自动同步Cookie，在创建或dequeue WebView时会同步一次Cookie
    public fileprivate(set) var isAutoSyncCookie = false
    /// 是否开启SecLink
    public fileprivate(set) var secLinkEnable = false
    /*  是否豁免secLink检查
    *   目前将主导航、工作台场景，且渠道为.larkWeb 网页容器不进行secLink检查
    *   并且针对该功能增加了FG开关，作为安全兜底
    */
    /// 首页seclink预检测结果
    private var _seclinkPrecheckResult : LarkWebViewSeclinkPrecheckResult = .unPrecheck
    static private let seclinkPrecheckLock = NSLock()
    public var seclinkPrecheckResult : LarkWebViewSeclinkPrecheckResult {
        set {
            defer{
                Self.seclinkPrecheckLock.unlock()
            }
            Self.seclinkPrecheckLock.lock()
            self._seclinkPrecheckResult = newValue
        }
        get {
            defer{
                Self.seclinkPrecheckLock.unlock()
            }
            Self.seclinkPrecheckLock.lock()
            return self._seclinkPrecheckResult
        }
        
    }
    
    /// 是否开启性能监控
    public fileprivate(set) var performanceTimingEnable = false
    /// 是否上报高级埋点信息，例如去除query和fragment的URL
    public internal(set) var advancedMonitorInfoEnable = false
    /// IESWebViewMonitor开关配置
    public fileprivate(set) var monitorConfig = LarkWebViewMonitorConfig()
    /// 由外部指定的初始化 trace，如果指定了就直接用该 traceID，不再内部生成
    public fileprivate(set) var initTrace: OPTrace?
    /// 由外部传入的startHandleTime
    public var startHandleTime: TimeInterval?
    /// 由外部传入的AppId
    public var appId: String?
    /// 由外部传入的 webBrowser scene场景
    public var scene: String?
    /// 是否启动前端同步FG系统
    public var promptFGSystemEnable: Bool = false
    /// 是否关闭 deinit  清除 bridge 上下文
    public var disableClearBridgeContext: Bool = false
}

extension LarkWebViewConfig {
    
    /// 配置自定义 UserAgent
    /// - Parameters:
    ///   - needSafari: 是否需要 safari 标志，背景是各大浏览器补充了该标志已兼容历史悠久的网页代码，非必需请使用 false
    ///   - appNameAndVersion: 应用名称和版本，如不希望包含此信息，传入nil
    ///   - languageKeyAndValue: 语言标志符记号和语言值，如不希望包含此信息，传入nil，推荐不要传入，使用navigator.language
    ///   - customUA: 业务自定义UA数据，请不要和前边的属性冲突，如果冲突，请调用方承担一切事故责任
    public func appendCustomUserAgent(needSafari: Bool = false, appNameAndVersion: (String, String)?, languageKeyAndValue: (String, String)?, customUA: String? = nil) {
        let safari = "Safari/604.1 "
        var appendUAAfterOriginUA = ""
        if needSafari {
            appendUAAfterOriginUA = appendUAAfterOriginUA + safari
        }
        if let appNameAndVersion = appNameAndVersion {
            appendUAAfterOriginUA = appendUAAfterOriginUA + "\(appNameAndVersion.0)/\(appNameAndVersion.1) "
        }
        if let languageKeyAndValue = languageKeyAndValue {
            appendUAAfterOriginUA = appendUAAfterOriginUA + "\(languageKeyAndValue.0)/\(languageKeyAndValue.1) "
        }
        if let customUA = customUA {
            appendUAAfterOriginUA = appendUAAfterOriginUA + customUA
        }
        guard !appendUAAfterOriginUA.isEmpty else {
            let msg = "please don't append empty custom ua"
            logger.error(msg)
            assertionFailure(msg)
            return
        }
        if let applicationNameForUserAgent = webViewConfig.applicationNameForUserAgent {
            //  要注意的是，部分场景 applicationNameForUserAgent 不为空，而是可能为 Mobile/15E148 之流，需要 append 上去
            webViewConfig.applicationNameForUserAgent = applicationNameForUserAgent + " " + appendUAAfterOriginUA
        } else {
            webViewConfig.applicationNameForUserAgent = appendUAAfterOriginUA
        }
    }
}

/// WebView初始化配置builder
@objcMembers
public final class LarkWebViewConfigBuilder: NSObject {
    private let internalWebViewConfig = LarkWebViewConfig()

    public func setWebViewConfig(_ webViewConfig: WKWebViewConfiguration) -> LarkWebViewConfigBuilder {
        self.internalWebViewConfig.webViewConfig = webViewConfig
        return self
    }
    
    public func setMonitorConfig(_ monitorConfig: LarkWebViewMonitorConfig) -> LarkWebViewConfigBuilder {
        self.internalWebViewConfig.monitorConfig = monitorConfig
        return self
    }

    /// 创建WebView配置
    /// - Parameters:
    ///   - bizType: 业务类型
    ///   - isAutoSyncCookie: 是否自动同步Cookie，在创建或dequeue WebView时会同步一次Cookie
    ///   - secLinkEnable: 是否开启SecLink
    ///   - performanceTimingEnable: 是否开启性能监控
    ///   - advancedMonitorInfoEnable: 是否上报高级埋点信息，例如去除query和fragment的URL
    ///   - promptFGSystemEnable: 是否开启前端prompt FG功能
    ///   - disableClearBridgeContext: 是否关闭 deinit  清除 bridge 上下文
    public func build(
        bizType: LarkWebViewBizType,
        isAutoSyncCookie: Bool = false,
        secLinkEnable: Bool = false,
        performanceTimingEnable: Bool = false,
        vConsoleEnable: Bool = false,
        advancedMonitorInfoEnable: Bool = false,
        promptFGSystemEnable: Bool = false
    ) -> LarkWebViewConfig {
        self.internalWebViewConfig.bizType = bizType
        self.internalWebViewConfig.isAutoSyncCookie = isAutoSyncCookie
        self.internalWebViewConfig.secLinkEnable = secLinkEnable
        self.internalWebViewConfig.performanceTimingEnable = performanceTimingEnable
        self.internalWebViewConfig.advancedMonitorInfoEnable = advancedMonitorInfoEnable
        self.internalWebViewConfig.promptFGSystemEnable = promptFGSystemEnable
        return self.internalWebViewConfig
    }
    
    public func setInitTrace(initTrace: OPTrace) -> LarkWebViewConfigBuilder {
        self.internalWebViewConfig.initTrace = initTrace
        return self
    }
    
    public func setDisableClearBridgeContext(_ value: Bool) -> LarkWebViewConfigBuilder {
        self.internalWebViewConfig.disableClearBridgeContext = value
        return self
    }
}
