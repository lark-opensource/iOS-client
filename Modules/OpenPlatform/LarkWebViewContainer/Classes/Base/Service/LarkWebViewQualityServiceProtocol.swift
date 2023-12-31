//
//  LarkWebViewQualityServiceProtocol.swift
//  LarkWebViewContainer
//
//  Created by lijuyou on 2020/9/18.
//

import Foundation

/// 套件统一WebView品质服务
@objc public protocol LarkWebViewQualityServiceProtocol {
    /// 设置自定义Header&UA
    func setCustomHeaderAndUserAgent(webView: LarkWebView, request: URLRequest)

    /// 上报PerformanceTiming数据
    func reportPerformanceTiming(webView: LarkWebView)
}
