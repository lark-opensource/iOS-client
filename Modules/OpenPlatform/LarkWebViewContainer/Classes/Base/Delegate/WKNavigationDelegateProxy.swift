//
//  WKNavigationDelegateProxy.swift
//  LarkWebViewContainer
//
//  Created by houjihu on 2020/9/14.
//

import ECOProbe
import ECOInfra
import LarkSetting
import LKCommonsLogging
import WebKit
import LarkFeatureGating

/// SDK内部的uiDelegate，会调用外部设置的delegate实现.
/// 针对此对象内没有实现的方法，会通过消息派发直接转发到外部设置的delegate
@objcMembers
public final class WKNavigationDelegateProxy: BaseDelegateProxy {
    /// SDK外部设置的navigationDelegate
    var internNavigationDelegate: WKNavigationDelegate? {
        get {
            return self.internDelegate as? WKNavigationDelegate
        }
        set {
            self.internDelegate = newValue
        }
    }

    let logger = Logger.lkwlog(WKNavigationDelegateProxy.self, category: NSStringFromClass(WKNavigationDelegateProxy.self))

    private var isLastLoading: Bool = false
    
    private var isDecideHandlerFixEnable: Bool = OPUserScope.userResolver().fg.dynamicFeatureGatingValue(with: "openplatform.web.webview.decide.handler.crashfix")
}

extension WKNavigationDelegateProxy: WKNavigationDelegate {
    public func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        guard let webView = webView as? LarkWebView else {
            if isDecideHandlerFixEnable {
                // https://bytedance.feishu.cn/wiki/WVsiw8B9Xidm3lkAbpscRoppnee
                decisionHandler(.cancel)
            }
            logger.lkwlog(level: .info, "decidePolicyForNavigationAction return when webView\(webView) is not LarkWebView")
            return
        }
        logger.lkwlog(level: .info, "decidePolicyForNavigationAction", traceId: webView.opTraceId())
        let startTime = Date().timeIntervalSince1970
        defer {
            webView.recordTimeConsumingIn(phase: .navigationPolicy, duration: Date().timeIntervalSince1970 - startTime)
        }
        if self.internNavigationDelegate?.webView?(webView,
                                                   decidePolicyFor: navigationAction,
                                                   decisionHandler: decisionHandler) == nil {
            decisionHandler(WKNavigationActionPolicy.allow)
        }
        HTTPHeaderInfoUtils.requestCacheInfo(navigationAction.request, traceId: webView.opTraceId())
    }

    //start
    public func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        guard let webView = webView as? LarkWebView else { return }
        let startTime = Date().timeIntervalSince1970
        defer {
            webView.recordTimeConsumingIn(phase: .navigationStart, duration: Date().timeIntervalSince1970 - startTime)
        }
        webView.isTerminateState = false
        webView.loadURLCount += 1
        // Biz Handler
        self.internNavigationDelegate?.webView?(webView, didStartProvisionalNavigation: navigation)
        // Report loadUrlStart
        
        if (webView.isFirstPage) {
            OPMonitor(event: .loadUrlStart, code: BaseMonitorCode.loadUrlStart, webview: webView)
                .addCategoryValue("navigation_id", navigation.hashValue)
                .flush()
        }
        LKWSecurityLogUtils.webSafeAESURL(webView.url?.absoluteString ?? "", msg: "didStart")
        isLastLoading = true
    }

    //start failed
    public func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        guard let webView = webView as? LarkWebView else { return }
        // SecLink
        webView.secLinkService?.webViewDidFailProvisionalNavigation(error: error, url: webView.url)
        // Biz Handler
        self.internNavigationDelegate?.webView?(webView, didFailProvisionalNavigation: navigation, withError: error)
        
        var pageUrl: URL?
        if let error = error as? NSError, let url = error.userInfo[NSURLErrorFailingURLErrorKey] as? URL {
            // 出现异常的时候，URL 需要通过这种方式来获取
            pageUrl = url
            if (error.code == NSURLErrorCancelled) {
                isLastLoading = false
                return;
            }
        } else {
            pageUrl = webView.url
        }
        
        // Report loadUrl failed
        OPMonitor(event: .loadUrlEnd, code: BaseMonitorCode.loadUrlEnd, webview: webView)
            .addCategoryValue(.appType, "webApp")
            .addCategoryValue("navigation_id", navigation.hashValue)
            .addCategoryValue(.resultCode, LoadUrlResult.failed.rawValue)
            .setError(error)
            .setWebViewURL(webView, pageUrl)
            .addCategoryValue("failType", "didFailProvisionalNavigation")
            .setCustomEventInfo(webView.customEventInfo())
            .setTimeConsumigInfo(webView.fetchDifferentPhaseTimeConsumingInfo())
            .setResultTypeFail()
            .flush()
        
        webView.monitorLoadUrlDuration(url: pageUrl, isSuccess: false, resutlCode: .failed,error: error)
        logger.lkwlog(level: .error, "webview load url failed", traceId: webView.opTraceId(), error: error)
        isLastLoading = false
    }

    //content return
    public func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        guard let webView = webView as? LarkWebView else { return }
        let startTime = Date().timeIntervalSince1970
        defer {
            webView.recordTimeConsumingIn(phase: .webCommit, duration: Date().timeIntervalSince1970 - startTime)
        }
        self.internNavigationDelegate?.webView?(webView, didCommit: navigation)
        if (webView.isFirstPage) {
            OPMonitor(event: .loadUrlCommit, code: BaseMonitorCode.loadUrlCommit, webview: webView)
                .addCategoryValue("navigation_id", navigation.hashValue)
                .flush()
        }
    }

    //finish
    public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        guard let webView = webView as? LarkWebView else { return }
        // Report loadUrlEnd
        OPMonitor(event: .loadUrlEnd, code: BaseMonitorCode.loadUrlEnd, webview: webView)
            .addCategoryValue(.appType, "webApp")
            .addCategoryValue("navigation_id", navigation.hashValue)
            .addCategoryValue(.resultCode, LoadUrlResult.success.rawValue)
            .setResultTypeSuccess()
            .setCustomEventInfo(webView.customEventInfo())
            .setTimeConsumigInfo(webView.fetchDifferentPhaseTimeConsumingInfo())
            .setPreloadInfo(webView.preloadInfo())
            .flush()
        LKWSecurityLogUtils.webSafeAESURL(webView.url?.absoluteString ?? "", msg: "didFinish")
        
        webView.monitorLoadUrlDuration(url: nil, isSuccess: true, resutlCode: .success, error: nil)
        
        
        // SecLink
        webView.secLinkService?.webViewDidFinish(url: webView.url)
        // report PerformanceTiming data if need
        if webView.config.performanceTimingEnable {
            webView.qualityService?.reportPerformanceTiming(webView: webView)
        }
        // Biz Handler
        self.internNavigationDelegate?.webView?(webView, didFinish: navigation)
        webView.loadURLEndCount += 1
        isLastLoading = false
    }

    //nav failed
    public func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        guard let webView = webView as? LarkWebView else { return }
        webView.secLinkService?.webViewDidFail(error: error, url: webView.url)
        self.internNavigationDelegate?.webView?(webView, didFail: navigation, withError: error)
        
        var pageUrl: URL?
        if let error = error as? NSError, let url = error.userInfo[NSURLErrorFailingURLErrorKey] as? URL {
            pageUrl = url
            if (error.code == NSURLErrorCancelled) {
                isLastLoading = false
                return;
            }
        } else {
            pageUrl = webView.url
        }
        
        // Report loadUrl failed
        OPMonitor(event: .loadUrlEnd, code: BaseMonitorCode.loadUrlEnd, webview: webView)
            .addCategoryValue(.appType, "webApp")
            .addCategoryValue("navigation_id", navigation.hashValue)
            .addCategoryValue(.resultCode, LoadUrlResult.failed.rawValue)
            .setError(error)
            .setWebViewURL(webView, pageUrl)
            .addCategoryValue("failType", "didFail")
            .setResultTypeFail()
            .setCustomEventInfo(webView.customEventInfo())
            .setTimeConsumigInfo(webView.fetchDifferentPhaseTimeConsumingInfo())
            .flush()
                
        webView.monitorLoadUrlDuration(url: pageUrl, isSuccess: false, resutlCode: .failed, error: error)
        
        logger.lkwlog(level: .error, "webview nav failed", traceId: webView.opTraceId(), error: error)
        isLastLoading = false
    }

    //recieve server redirect
    public func webView(_ webView: WKWebView, didReceiveServerRedirectForProvisionalNavigation navigation: WKNavigation!) {
        guard let webView = webView as? LarkWebView else { return }
        LKWSecurityLogUtils.webSafeAESURL(webView.url?.absoluteString ?? "", msg: "didReceiveServerRedirect")
        let startTime = Date().timeIntervalSince1970
        defer {
            webView.recordTimeConsumingIn(phase: .webRedirect, duration: Date().timeIntervalSince1970 - startTime)
        }
        //重定向start
        OPMonitor(event: .loadUrlOverride, code: BaseMonitorCode.loadUrlOverride, webview: webView)
            .setWebViewURL(webView, webView.url)
            .addCategoryValue("override_loading_type", "start")
            .flush()
        
        self.internNavigationDelegate?.webView?(webView, didReceiveServerRedirectForProvisionalNavigation: navigation)
        
        //重定向end
        OPMonitor(event: .loadUrlOverride, code:BaseMonitorCode.loadUrlOverride, webview: webView)
            .setWebViewURL(webView, webView.url)
            .addCategoryValue("override_loading_type", "end")
            .addCategoryValue("override_loading_end_point", "override_end")
            .flush()
    }

    //response decide
    public func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse, decisionHandler: @escaping (WKNavigationResponsePolicy) -> Swift.Void) {
        guard let webView = webView as? LarkWebView else {
            if isDecideHandlerFixEnable {
                //https://bytedance.feishu.cn/wiki/WVsiw8B9Xidm3lkAbpscRoppnee
                decisionHandler(.cancel)
            }
            logger.lkwlog(level: .info, "decidePolicyFornavigationResponse return when webView\(webView) is not LarkWebView")
            return
        }
        logger.lkwlog(level: .info, "decidePolicyFornavigationResponse", traceId: webView.opTraceId())
        
        let startTime = Date().timeIntervalSince1970
        if let response = (navigationResponse.response as? HTTPURLResponse) {
            // 有 HTTP 错误 (https://www.ietf.org/rfc/rfc2616.txt)
            if (200...299).contains(response.statusCode) == false {
                // 埋点，上报 HTTPS 错误
                OPMonitor(.loadReceivedError, webview: webView)
                    .setWebViewURL(webView, response.url)
                    .setErrorCode("\(response.statusCode)")
                    .setErrorMessage(HTTPURLResponse.localizedString(forStatusCode: response.statusCode))
                    .flush()
            }
        }
        // SecLinkService不为空 且 没有命中secLink豁免
        if let secLinkService = webView.secLinkService, !webView.exemptSecLinkCheck() {
            // 线程保护
            let useHandlerOptimized = FeatureGatingManager.shared.featureGatingValue(with: "admin.security.seclink_handler_optimized")// user:global
            logger.lkwlog(level: .info, "SecLink check start for url:\(navigationResponse.response.url?.safeURLString), use seclink handler optimized:\(useHandlerOptimized)", traceId: webView.opTraceId())
            let secLinkStartTime = Date().timeIntervalSince1970
            
            let decisionHandlerWrapper: (WKNavigationResponsePolicy) -> Swift.Void
            if useHandlerOptimized {
                decisionHandlerWrapper = { [weak self, weak webView] (policy: WKNavigationResponsePolicy) -> Swift.Void in
                    executeOnMainQueueAsync {
                        guard let webView = webView else {
                            decisionHandler(.cancel)
                            return
                        }
                        if policy == .cancel {
                            decisionHandler(.cancel)
                            OPMonitor(event: .seclinkCheck, code: QualityMonitorCode.seclinkCheck, webview: webView)
                                .setResultTypeFail()
                                .addCategoryValue(.url, navigationResponse.response.url?.safeURLString)
                                .flush()
                            self?.logger.lkwlog(level: .error, "SecLink check unpassed, this URL is considered illegal by SecLink, url:\(navigationResponse.response.url?.safeURLString)", traceId: webView.opTraceId())
                        } else {
                            self?.logger.lkwlog(level: .info, "SecLink check passed for url:\(navigationResponse.response.url?.safeURLString)", traceId: webView.opTraceId())
                            if self?.internNavigationDelegate?.webView?(webView,
                                                                               decidePolicyFor: navigationResponse,
                                                                               decisionHandler: decisionHandler) == nil {
                                decisionHandler(.allow)
                            }
                        }
                        webView.recordTimeConsumingIn(phase: .navigationResponse, duration: Date().timeIntervalSince1970 - startTime)
                        webView.recordTimeConsumingIn(phase: .webSecLink, duration: Date().timeIntervalSince1970 - secLinkStartTime)
                    }
                }
            } else {
                decisionHandlerWrapper = { [weak self] (policy: WKNavigationResponsePolicy) -> Swift.Void in
                    executeOnMainQueueAsync {
                        if policy == .cancel {
                            decisionHandler(.cancel)
                            OPMonitor(event: .seclinkCheck, code: QualityMonitorCode.seclinkCheck, webview: webView)
                                .setResultTypeFail()
                                .addCategoryValue(.url, navigationResponse.response.url?.safeURLString)
                                .flush()
                            self?.logger.lkwlog(level: .error, "SecLink check unpassed, this URL is considered illegal by SecLink, url:\(navigationResponse.response.url?.safeURLString)", traceId: webView.opTraceId())
                        } else {
                            self?.logger.lkwlog(level: .info, "SecLink check passed for url:\(navigationResponse.response.url?.safeURLString)", traceId: webView.opTraceId())
                            if self?.internNavigationDelegate?.webView?(webView,
                                                                               decidePolicyFor: navigationResponse,
                                                                               decisionHandler: decisionHandler) == nil {
                                decisionHandler(.allow)
                            }
                        }
                        webView.recordTimeConsumingIn(phase: .navigationResponse, duration: Date().timeIntervalSince1970 - startTime)
                        webView.recordTimeConsumingIn(phase: .webSecLink, duration: Date().timeIntervalSince1970 - secLinkStartTime)
                    }
                }
            }
            secLinkService.webView(webView, decidePolicyFor: navigationResponse, decisionHandler: decisionHandlerWrapper)
        } else {
            // Biz Handler
            if self.internNavigationDelegate?.webView?(webView,
                                                       decidePolicyFor: navigationResponse,
                                                       decisionHandler: decisionHandler) == nil {
                decisionHandler(.allow)
            }
            webView.recordTimeConsumingIn(phase: .navigationResponse, duration: Date().timeIntervalSince1970 - startTime)
        }
        HTTPHeaderInfoUtils.responseCacheInfo(navigationResponse.response, traceId: webView.opTraceId())
    }

    public func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
        guard let webView = webView as? LarkWebView else { return }

        if webView.isLoading {
            OPMonitor(event: .loadUrlEnd, code: BaseMonitorCode.loadUrlEnd, webview: webView)
                .addCategoryValue(.appType, "webApp")
                .addCategoryValue(.resultCode, LoadUrlResult.terminated.rawValue)
                .setWebViewURL(webView, webView.url)
                .addCategoryValue("failType", "didFail")
                .setResultTypeFail()
                .setCustomEventInfo(webView.customEventInfo())
                .setTimeConsumigInfo(webView.fetchDifferentPhaseTimeConsumingInfo())
                .flush()
            webView.monitorLoadUrlDuration(url: webView.url, isSuccess: false, resutlCode: .terminated, error: nil)
        }

        webView.isTerminateState = true
        let isVisible = webView.isVisible()
        if isVisible {
            webView.visibleTerminateCount += 1
        } else {
            webView.invisibleTerminateCount += 1
        }
        self.internNavigationDelegate?.webViewWebContentProcessDidTerminate?(webView)
        OPMonitor(event: .renderProcessGone, code: QualityMonitorCode.webViewProcessGone, webview: webView)
            .setVisible(isVisible)
            .setVisibleCrashCount(webView.visibleTerminateCount)
            .setInvisibleCrashCount(webView.invisibleTerminateCount)
            .setResultTypeFail()
            .flush()
        self.logger.lkwlog(level: .error, "WebContent Process Did Terminate!, renderTimes:\(webView.renderTimes), reloadTimes:\(webView.reloadTimes),url:\(webView.url?.safeURLString)", traceId: webView.opTraceId())
    }
    
    func getHTTPHeaderFromResponse(response: HTTPURLResponse, header: String) -> String? {
        return HTTPHeaderInfoUtils.value(response: response, forHTTPHeaderField: header)
    }
}
