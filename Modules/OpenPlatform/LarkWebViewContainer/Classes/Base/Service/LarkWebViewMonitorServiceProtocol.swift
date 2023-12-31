//
//  LarkWebViewMonitorServiceProtocol.swift
//  LarkWebViewContainer
//
//  Created by dengbo on 2021/12/30.
//

import Foundation
import WebKit

@objc public protocol LarkWebViewMonitorReceiver {
    func recv(key: String?, data: [AnyHashable: Any]?)
}

/// 套件统一WebView监控服务
@objc public protocol LarkWebViewMonitorServiceProtocol {
    /// 给webview实例添加monitor配置
    func configWebView(webView: LarkWebView)
    /// 更新WKWebViewConfiguration的Monitor相关属性
    func updateWKWebViewConfiguration(configuration: WKWebViewConfiguration, monitorConfig: LarkWebViewMonitorConfig)
    /// 获取hybrid sdk中的navigationId
    func fetchNavigationId(webView: LarkWebView) -> String?
}
