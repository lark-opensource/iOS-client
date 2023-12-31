//
//  FixLarkWebView.swift
//  LarkWebViewContainer
//
//  Created by yinyuan on 2022/5/6.
//

import ECOInfra
import ECOProbe
import LarkSetting
import LKCommonsLogging

final class FixLarkWebView {
    
    /// 如果一个 WebView 在 deinit 时被赋给weak指针，将会crash，因此这种场景都需要判断是否在 deinit，避免 crash
    public static func isWebViewDeallocating(webView: WKWebView) -> Bool {
        return FixWKWebView.isWebViewDeallocating(webView)
    }
    
    public static func tryFixLarkWebView(webView: LarkWebView) {
        logger.info("lk_tryFixWKReloadFrameErrorRecoveryAttempter");
        LarkWebView.lk_tryFixWKReloadFrameErrorRecoveryAttempter()
    }
    
}
