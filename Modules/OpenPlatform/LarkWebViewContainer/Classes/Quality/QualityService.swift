//
//  QualityService.swift
//  LarkWebViewContainer
//
//  Created by lijuyou on 2020/9/18.
//  

import Foundation
import ECOProbe
import LKCommonsLogging
import LarkSetting

private let userAgentKey = "User-Agent"

public final class QualityService: LarkWebViewQualityServiceProtocol {
    public init() {}
    /// 设置自定义Header&UA
    public func setCustomHeaderAndUserAgent(webView: LarkWebView, request: URLRequest) {
        //设置自定义header
        var req = request
        if let headers = webView.webviewDelegate?.buildExtraHttpHeaders?() {
            headers.forEach({ key, value in
                req.setValue(value, forHTTPHeaderField: key)
            })
        }
        //设置自定义User-Agent
        if let userAgent = webView.webviewDelegate?.buildCustomUserAgent?() {
            //req.setValue(userAgent, forHTTPHeaderField: userAgentKey)
            webView.customUserAgent = userAgent
        }
        logger.debug("set Custom Header And UserAgent")
    }

    /// 上报PerformanceTiming数据
    public func reportPerformanceTiming(webView: LarkWebView) {
        if FeatureGatingManager.shared.featureGatingValue(with: .init(stringLiteral: "openplatform.web.report_performance_timing.fix.v2")) {// user:global
            // 上述修复方案失败，无路可走，为避免 crash，放弃调用，将会丢失 performance 数据上报
            return
        } else if FeatureGatingManager.shared.featureGatingValue(with: .init(stringLiteral: "openplatform.web.report_performance_timing.downgrade")) {// user:global
            // 上述修复方案失败，完全还原成原始情况
            webView.fetchPerformanceTimingString { timingString in
                OPMonitor(event: .performanceTiming, code: QualityMonitorCode.performanceTiming, webview: webView)
                    .addCategoryValue(.performance, timingString)
                    .flush()
            }
            return
        }
        if FixLarkWebView.isWebViewDeallocating(webView: webView) {
            // 在 weak webview 之前，先判断一下是否正在 deallocating，如果是，则不执行 weak 及后续逻辑
            return
        }
        webView.fetchPerformanceTimingString { [weak webView]timingString in
            guard let webView = webView else { return }
            OPMonitor(event: .performanceTiming, code: QualityMonitorCode.performanceTiming, webview: webView)
                .addCategoryValue(.performance, timingString)
                .flush()
        }
    }
}
