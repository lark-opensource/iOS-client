//
//  WebviewTerminateHandler.swift
//  SpaceKit
//
//  Created by guotenghu on 2019/3/7.
//  

import SKFoundation
import WebKit
import SKCommon
import SKUIKit
import SpaceInterface
import SKInfra

let normalTerminateReason = UInt32(10000)

struct WebviewTerminateHandler {
    private weak var webView: DocsWebViewProtocol?
    private var terminateCount: Int = 0
    private let maxReloadCount = 1 //之前webview挂掉了会重试三次，其实大部分重试还是会失败。最多重试一次试试
    private let editorIdentity: String

    /// 外部的url，如果当前获取webview的url失败，用这个
    var externalUrl: URL?
    var isInViewHierarchy: Bool = true
    var isVisible = false
    var terminateReason: UInt32 = normalTerminateReason

    init(webView: DocsWebViewProtocol?, webviewIdentify: String) {
        self.editorIdentity = webviewIdentify
        self.webView = webView
    }

    private var currentUrl: URL? {
        return webView?.url ?? externalUrl
    }

    mutating func handleTerminate(isInForground: Bool, hasJsCall: Bool, onReloadFail: () -> Void) {
        doStatistics(isInForground: isInForground, hasJsCall: hasJsCall)
        if isInViewHierarchy == false {
            DocsLogger.info("不在视图层级的webview挂掉了，不处理 \(editorIdentity)")
            return
        }
        guard terminateCount < maxReloadCount else {
            DocsLogger.info("WebView超过重试次数限制，不再reload \(editorIdentity)")
            return
        }
        
        terminateCount += 1
    }

    private func doStatistics(isInForground: Bool, hasJsCall: Bool) {
        #if DEBUG || BETA
        #else
        let shouldReport = !GeckoPackageManager.shared.isUsingSpecial(.webInfo)

        if shouldReport {
            let isTemplate = URLValidator.isMainFrameTemplateURL(currentUrl)
            var docsType = DocsType.unknownDefaultType
            if !isTemplate, let url = currentUrl, let type = DocsType(url: url) {
                docsType = type
            }
            doStatisticsWithoutType(docsType, isTemplate: isTemplate,
                                    isInForground: isInForground,
                                    hasJsCall: hasJsCall)
            doStatisticsWithType(docsType, isTemplate: isTemplate)
        }
        #endif
    }

    private func doStatisticsWithoutType(_ type: DocsType,
                                         isTemplate: Bool,
                                         isInForground: Bool,
                                         hasJsCall: Bool) {
        var info: [String: Any] = ["次数": (terminateCount + 1)]
        info["id"] = editorIdentity
        DocsLogger.severe("WKWebView 挂掉啦", extraInfo: info, error: nil, component: nil)
        let memInfo = SKMemoryMonitor.getMemory()
        let params: [String: Any] = [DocsTracker.Params.webviewTerminateCount: terminateCount,
                                     "is_in_viewHierarchy": isInViewHierarchy,
                                     "is_visible": isVisible,
                                     "reason": terminateReason,
                                     "app_memory": memInfo.appMemory,
                                     "sys_use_memory": memInfo.sysUseMemory,
                                     "total_memory": memInfo.totalMemory,
                                     "in_forground": isInForground,
                                     "has_js_call": hasJsCall,
                                     DocsTracker.Params.fileType: type.name]
        DocsTracker.log(enumEvent: .webviewTerminate, parameters: params)
    }

    private func doStatisticsWithType(_ type: DocsType, isTemplate: Bool) {
        var info: [String: Any] = ["次数": (terminateCount + 1)]
        info["id"] = editorIdentity
        guard !isTemplate else { return }
        var params: [String: Any] = [DocsTracker.Params.fileType: type.name,
                                     "is_visible": isVisible,
                                     "reason": terminateReason]
        params[DocsTracker.Params.webviewTerminateCount] = terminateCount
        DocsTracker.log(enumEvent: .openingWebviewTerminaterd, parameters: params)
    }
}
