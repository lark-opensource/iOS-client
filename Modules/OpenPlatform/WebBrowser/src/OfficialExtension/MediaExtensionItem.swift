//
//  MediaExtensionItem.swift
//  WebBrowser
//
//  Created by 新竹路车神 on 2021/8/14.
//

import Foundation
import LarkSetting
import LKCommonsLogging
import WebKit
import ECOProbe
import LarkWebViewContainer

final public class MediaExtensionItem: WebBrowserExtensionItemProtocol {
    public var itemName: String? = "Media"
    public var lifecycleDelegate: WebBrowserLifeCycleProtocol? = MediaWebBrowserLifeCycle()
    
    public init() {}
    
}

final public class MediaWebBrowserLifeCycle: WebBrowserLifeCycleProtocol {
    
    public func viewWillAppear(browser: WebBrowser, animated: Bool) {
        makeH5Active(browser: browser, active: true)
    }
    
    public func viewDidDisappear(browser: WebBrowser, animated: Bool) {
        makeH5Active(browser: browser, active: false)
        pausePlay(browser: browser)
    }
    
    /// 暂停播放音视频
    private func pausePlay(browser: WebBrowser) {
        browser.webView.evaluateJavaScript(JSInjection.pause)
    }
    
    /// 是否允许播放音视频
    private func makeH5Active(browser: WebBrowser, active: Bool) {
        browser.webView.evaluateJavaScript(JSInjection.viewActive(active: active))
    }
}


private let logger = Logger.webBrowserLog(LKWebViewHelper.self, category: "LKWebViewHelper")

class LKWebViewHelper {
    static func setConfiguration(_ configuration: WebBrowserConfiguration, withQueryApi url: URL?) {
        guard let url = url else {
            return
        }
        guard let queryDict = url.getQuery() as? [String: String] else {
            return
        }
        let mediaAutoplayKey = "lk_media_autoplay"
        if Self.isMediaAutoplayEnabled(), let mediaAutoplayValue = queryDict[mediaAutoplayKey] as? String {
            mediaAutoplayIfNeeded(configuration, url: url, name: mediaAutoplayKey, value: mediaAutoplayValue)
        }
        // 极端情况, 若自动播放同时存在新旧两种URL参数, 则采用旧URL参数值, 避免客户在新旧版本能力不一致产生问题
        let mediaAutoplayOldKey = "lark_media_auto_play"
        if let mediaAutoplayOldValue = queryDict[mediaAutoplayOldKey] as? String {
            mediaAutoplayIfNeeded(configuration, url: url, name: mediaAutoplayOldKey, value: mediaAutoplayOldValue)
        }
    }
    
    /// WKWebView非静音状态的自动播放能力, 默认系统策略
    static func mediaAutoplayIfNeeded(_ configuration: WebBrowserConfiguration, url: URL, name: String, value: String) {
        //  新策略参考 https://bytedance.feishu.cn/docx/doxcnP5yK2yAmN8wNBdHcjiwc7d
        if value.lowercased() == "false" {
            //  不允许自动播放
            logger.info("[QueryAPI] \(name) == false, mediaTypesRequiringUserActionForPlayback = .all")
            configuration.webviewConfiguration.mediaTypesRequiringUserActionForPlayback = .all
        } else if value.lowercased() == "true" {
            //  放开严格程度，比如客户要求：我想自动播放，但是不想mute
            logger.info("[QueryAPI] \(name) == true, mediaTypesRequiringUserActionForPlayback = []")
            configuration.webviewConfiguration.mediaTypesRequiringUserActionForPlayback = []
        } else {
            //  系统默认
            logger.info("[QueryAPI] \(name) == \(value), use system default")
        }
        
        if WebMetaNavigationBarExtensionItem.isURLCustomQueryMonitorEnabled() {
            OPMonitor("openplatform_web_container_URLCustomQuery")
                .addCategoryValue("name", name)
                .addCategoryValue("content", value)
                .addCategoryValue("url", url.safeURLString)
                .addCategoryValue("appId", configuration.appId)
                .setPlatform([.tea, .slardar])
                .tracing(configuration.initTrace)
                .flush()
        }
    }
    
    static func isMediaAutoplayEnabled() -> Bool {
        return FeatureGatingManager.shared.featureGatingValue(with: FeatureGatingManager.Key(stringLiteral: "openplatform.web.meta.media_autoplay"))// user:global
    }
}

// 在iOS15需要用Apple提供的media函数替换掉这里的
// code from houzhiyou and houzhiyou'code from kangtao
/// User JS
/// 支持退出web vc容器时，自动暂停播放音视频，且不允许播放
struct JSInjection {
    /// Hook当前H5播放器实例
    static let currentPlayer =
    """
        var _lark_currentPlayers = [];
        let _lark_originPlay = HTMLMediaElement.prototype.play;
        HTMLMediaElement.prototype.play = function() {
            let res = _lark_originPlay.call(this);

            if (_lark_currentPlayers.includes && !_lark_currentPlayers.includes(this)) {
                _lark_currentPlayers.push(this);
            }
            if (!_lark_viewIsActive) {
                this.pause();
            }
            return res;
        }
    """

    /// H5 viewIsActive
    static func viewActive(active: Bool) -> String {
        return "var _lark_viewIsActive = \(active);"
    }

    /// H5 Pause
    static let pause =
    """
        // 关闭捕获的播放器
        for (var i = 0; i < _lark_currentPlayers.length; i++) {
            (_lark_currentPlayers[i] instanceof HTMLMediaElement)
            && _lark_currentPlayers[i].pause();
        }
    """
}
