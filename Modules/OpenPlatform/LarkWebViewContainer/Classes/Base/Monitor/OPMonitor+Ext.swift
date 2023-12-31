//
//  OPMonitor+Ext.swift
//  LarkWebViewContainer
//
//  Created by lijuyou on 2020/9/2.
//

import Foundation
import ECOProbe
import LarkSetting

extension OPMonitor {
    /// 创建OPMonitor实例
    /// - Parameters:
    ///   - event: LarkWebViewMonitor事件
    ///   - code: OPMonitorCode
    convenience init(event: LarkWebViewMonitorEvent,
                     code: OPMonitorCode?,
                     webview: LarkWebView? = nil) {
        self.init(service: nil, name: event.rawValue, code: code)
        if let webview = webview {
            _ = self.setWebView(webview)
        }
    }

    /// 创建OPMonitor实例
    /// - Parameter event: LarkWebViewMonitor事件
    convenience init(_ event: LarkWebViewMonitorEvent,
                     webview: LarkWebView? = nil) {
        self.init(event: event, code: nil, webview: webview)
    }

    /// 添加一个自定义的 Key-Value，value 为枚举/分类类型（可分类筛选)
    /// 重复设置相同key会覆盖
    func addCategoryValue(_ larkWebViewMonitorEventKey: LarkWebViewMonitorEventKey, _ value: Any?) -> OPMonitor {
        addCategoryValue(larkWebViewMonitorEventKey.rawValue, value)
    }

    /// 添加一个自定义的 Key-Value，value 为枚举/分类类型（可分类筛选)
    /// 重复设置相同key会覆盖
    func addCategoryValueIfNotNull(_ larkWebViewMonitorEventKey: LarkWebViewMonitorEventKey, _ value: Any?) -> OPMonitor {
        if let value = value {
            addCategoryValue(larkWebViewMonitorEventKey.rawValue, value)
        }
        return self
    }

    /// 设置监控的WebView，上报WebView基础信息
    func setWebView(_ webview: LarkWebView) -> OPMonitor {
        addMap(webview.lkwb_monitor.allExtensionMonitorData())
        if webview.loadURLCount <= 1 || webview.loadURLEndCount < 1 {
            addCategoryValueIfNotNull(.isFirstPage, true)
        }
        addCategoryValueIfNotNull(.biz, webview.config.bizType.rawValue)
        .addCategoryValueIfNotNull(.usedCount, webview.renderTimes)
        .addCategoryValueIfNotNull(.scene, webview.config.scene)
        .addCategoryValueIfNotNull(.appId, webview.config.appId)
        .tracing(webview.opTrace())
        .setWebViewURL(webview, webview.url)
        return self
    }
    
    /// 设置监控的WebView，上报WebView基础信息
    func setWebViewURL(_ webview: LarkWebView, _ url: URL?) -> OPMonitor {
        if webview.config.advancedMonitorInfoEnable {
            addCategoryValueIfNotNull(.host, url?.host)
            .addCategoryValueIfNotNull(.path, url?.path)
        }
        addCategoryValueIfNotNull(.url, url?.safeURLString)
        return self
    }

    /// 设置webview当前是否可见
    /// - Parameter value: 可见与否
    /// - Returns: Monitor对象
    func setVisible(_ value: Bool) -> OPMonitor {
        addCategoryValue(.visible, value)
    }

    /// 设置可见崩溃次数
    /// - Parameter value: 可见崩溃次数
    /// - Returns: Monitor对象
    func setVisibleCrashCount(_ value: Int) -> OPMonitor {
        addCategoryValue(.visibleCrashCount, value)
    }

    /// 设置不可见崩溃次数
    /// - Parameter value: 不可见崩溃次数
    /// - Returns: Monitor对象
    func setInvisibleCrashCount(_ value: Int) -> OPMonitor {
        addCategoryValue(.invisibleCrashCount, value)
    }

    /// 设置退出时是否崩溃
    /// - Parameter value: 退出时是否崩溃
    /// - Returns: Monitor对象
    func setIsTerminateState(_ value: Bool) -> OPMonitor {
        addCategoryValue(.isTerminateState, value)
    }

    /// 设置load url 次数
    /// - Parameter value: 加载 url 次数
    /// - Returns: Monitor对象
    func setLoadURLCount(_ value: Int) -> OPMonitor {
        addCategoryValue(.loadURLCount, value)
    }
    
    /// 设置webview各个阶段耗时情况
    /// - Parameter value: 耗时info json字符串
    /// - Returns: Monitor对象
    func setTimeConsumigInfo(_ value: Any?) -> OPMonitor {
        addCategoryValueIfNotNull(.timeConsuming, value)
        return self
    }
    
    func setCustomEventInfo(_ eventInfo: UInt64) ->OPMonitor {
        addCategoryValueIfNotNull(.customEventInfo, eventInfo)
        return self
    }
    
    func setPreloadInfo(_ info: String?) -> OPMonitor {
        addCategoryValueIfNotNull(.webviewPreload, info)
        return self
    }
}
