//
//  WebAppMonitorProtocol.swift
//  EcosystemWeb
//
//  Created by dengbo on 2022/3/15.
//

import Foundation
import LarkWebViewContainer

public protocol WebAppMonitorProtocol {
    /// 绑定appId和webview的navigationId
    func bind(appId: String?, webView: LarkWebView)
    
    /// 检查白屏
    func checkBlank(appId: String?, webView: LarkWebView)
    
    /// 清除webview缓存的监控埋点，如果webview即将被销毁，置clear为true，否则置为false
    func flushEvent(webView: LarkWebView, clear: Bool)
}
