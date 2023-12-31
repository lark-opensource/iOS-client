//
//  LarkWebViewControllerConfiguration.swift
//  LarkWebViewController
//
//  Created by 新竹路车神 on 2020/10/4.
//

import Foundation
import WebKit
import LarkWebViewContainer

/// log for DynamicURLConfig
private let logger = Logger.live

/// 网页控制器配置
public struct WebViewControllerConfiguration {
    /// 是否需要同步Cookie
    var isAutoSyncCookie: Bool

    /// 是否打开安全链接
    let secLinkEnable: Bool

    /// 是否开启性能监控
    let performanceTimingEnable: Bool

    /// 是否开启vConsole调试功能
    let vConsoleEnable: Bool

    /// 自定义UA
    let customUserAgent: String?

    /// 是否允许分享到chat
    var allowShareToChat: Bool

    // MARK: url params config
    /// 隐藏输入框
    var isHiddenInputViewBar: Bool
    /// 是否开启JS注入
    var isInjectIgnorePageReady: Bool
    /// 是否显示更多
    var showMore: Bool
    /// 首次打开是否展示Loading页面
    var showLoadingFirstLoad: Bool
    /// 是否显示进度条
    var showProgress: Bool
    /// 动态化下是否强制竖屏
    var screenForcePortrait: Bool?
    /// 导航背景是否透明色
    var isNaviBgClear: Bool
    /// 是否启用滚动条
    var scrollviewEnabled: Bool
    /// 视图背景颜色
    var viewBgColor: UIColor?

    /// webview configuration
    var webviewConfiguration: WKWebViewConfiguration

    /// 自定义参数
    var customParams: [String: Any]
    /// 是否进入无痕预览模式，无痕模式下不会携带任何app内的cookie，并且退出web会清除所有的临时数据
    var shouldNonPersistent: Bool
    var originRefererURL: URL?

    //  对齐 OPWebViewController，code from lixiaorui@bytedance.com 提交：API鉴权
    var appID: String
    var appName: String
    var avatarurl: String

//    var jsApiMethodScope: JsAPIMethodScope
    var webBizType: LarkWebViewBizType

    /// 初始化方法
    public init(
        isAutoSyncCookie: Bool = true,
        secLinkEnable: Bool = true,
        performanceTimingEnable: Bool = true,
        vConsoleEnable: Bool = false,
        customUserAgent: String? = nil,
        allowShareToChat: Bool = true,
        isHiddenInputViewBar: Bool = false,
        isInjectIgnorePageReady: Bool = false,
        showMore: Bool = true,
        showLoadingFirstLoad: Bool = true,
        showProgress: Bool = true,
        screenForcePortrait: Bool? = nil,
        isNaviBgClear: Bool = false,
        scrollviewEnabled: Bool = true,
        viewBgColor: UIColor? = nil,
        customParams: [String: Any] = [:],
        shouldNonPersistent: Bool = false,
        originRefererURL: URL? = nil,
        appID: String = "",
        appName: String = "",
        avatarurl: String = "",
//        jsApiMethodScope: JsAPIMethodScope = .all,
        webBizType: LarkWebViewBizType? = nil,
        webviewConfiguration: WKWebViewConfiguration = WKWebViewConfiguration()
    ) {
        self.isAutoSyncCookie = isAutoSyncCookie
        self.secLinkEnable = secLinkEnable
        self.performanceTimingEnable = performanceTimingEnable
        self.vConsoleEnable = vConsoleEnable
        self.customUserAgent = customUserAgent
        self.allowShareToChat = allowShareToChat
        // url params config
        self.isHiddenInputViewBar = isHiddenInputViewBar
        self.isInjectIgnorePageReady = isInjectIgnorePageReady
        self.showMore = showMore
        self.showLoadingFirstLoad = showLoadingFirstLoad
        self.showProgress = showProgress
        self.screenForcePortrait = screenForcePortrait
        self.isNaviBgClear = isNaviBgClear
        self.scrollviewEnabled = scrollviewEnabled
        self.viewBgColor = viewBgColor
        self.customParams = customParams
        self.shouldNonPersistent = shouldNonPersistent
        self.originRefererURL = originRefererURL
        self.appID = appID
        self.appName = appName
        self.avatarurl = avatarurl
        self.webBizType = webBizType ?? LarkWebViewBizType.larkWeb
        self.webviewConfiguration = webviewConfiguration
    }

    /// copy a new instance
    func copy() -> WebViewControllerConfiguration {
        return WebViewControllerConfiguration(
            isAutoSyncCookie: isAutoSyncCookie,
            secLinkEnable: secLinkEnable,
            performanceTimingEnable: performanceTimingEnable,
            vConsoleEnable: vConsoleEnable,
            customUserAgent: customUserAgent,
            isHiddenInputViewBar: isHiddenInputViewBar,
            isInjectIgnorePageReady: isInjectIgnorePageReady,
            showMore: showMore,
            showLoadingFirstLoad: showLoadingFirstLoad,
            showProgress: showProgress,
            screenForcePortrait: screenForcePortrait,
            isNaviBgClear: isNaviBgClear,
            scrollviewEnabled: scrollviewEnabled,
            viewBgColor: viewBgColor,
            customParams: customParams,
            shouldNonPersistent: shouldNonPersistent,
            originRefererURL: originRefererURL,
            appID: appID,
            appName: appName,
            avatarurl: avatarurl,
//            jsApiMethodScope: jsApiMethodScope,
            webBizType: webBizType,
            webviewConfiguration: webviewConfiguration
        )
    }

    /// description of all properties
    public func toString() -> String {
        return """
            WebViewControllerConfiguration(
            isAutoSyncCookie:\(isAutoSyncCookie),
            secLinkEnable:\(secLinkEnable),
            performanceTimingEnable:\(performanceTimingEnable),
            vConsoleEnable:\(vConsoleEnable),
            customUserAgent:\(customUserAgent),
            isHiddenInputViewBar:\(isHiddenInputViewBar),
            isInjectIgnorePageReady:\(isInjectIgnorePageReady),
            showMore:\(showMore),
            showLoadingFirstLoad:\(showLoadingFirstLoad),
            showProgress:\(showProgress),
            screenForcePortrait:\(screenForcePortrait),
            isNaviBgClear:\(isNaviBgClear),
            scrollviewEnabled:\(scrollviewEnabled),
            viewBgColor:\(viewBgColor),
            customParams:\(customParams),
            shouldNonPersistent:\(shouldNonPersistent),
            appID:\(appID),
            appName:\(appName),
            webBizType: \(webBizType.rawValue)
            webviewConfiguration:\(webviewConfiguration)
            )
            """
    }
}
