//
//  WebLoader+Responsive.swift
//  SKBrowser
//
//  Created by lijuyou on 2022/12/2.
//  


import SKFoundation
import SKUIKit
import SKCommon
import SKInfra

extension WebLoader {
    
    //打开文档超时，如果是因为长时间WebView没有响应(JS调用)，则认为可能发生了卡死，自动进行一次卡死检测
    func startCheckWebViewResoponsiveInOpenIfNeed() {
        if !hasCheckResponsiveInOpen,
           OpenAPI.docs.checkResponsiveInOpenDoc,
           let lastCallJSTime = jsServiceManager?.lkwAPIHandler?.lastCallTime {
            let defaultUnresposiveTime = 20
            let maxUnresposiveTime = SettingConfig.timeoutForOpenDocNew?.maxUnresposiveTime ?? defaultUnresposiveTime
            let duration = Date().timeIntervalSince1970 - lastCallJSTime
            if duration > Double(maxUnresposiveTime) {
                hasCheckResponsiveInOpen = true //只检测一次
                DocsLogger.error("checkWebViewResponsiveInOpenOvertime, maxUnrspTime:\(maxUnresposiveTime), lastCall:\(lastCallJSTime), dur:\(duration)", component: LogComponents.fileOpen)
                self.delegate?.checkWebViewResponsiveInOpenOvertime()
            }
        }
    }
    
    func startCheckPreloadJsModuleOvertimeIfNeed() {
        let shouldCheck = needCheckPreloadOvertime()
        if shouldCheck {
            let timeout = SettingConfig.docsWebViewConfig?.preloadJsModuleTimeOut ?? 5.0
            DocsLogger.error("start check preload is overtime:\(timeout)", component: LogComponents.fileOpen)
            if timeout > 0 {
                self.perform(#selector(preloadOvertime), with: nil, afterDelay: timeout)
            }
        }
    }

    private func needCheckPreloadOvertime() -> Bool {
        //为了减少误判和影响，只有缓存池连续预加载失败达到一定次数才进行超时检测
        let tryReloadContinuousFailCount = SettingConfig.docsWebViewConfig?.tryReloadContinuousFailCount ?? 0
        let shouldCheck = !self.preloadStatus.value.hasLoadSomeThing
        && tryReloadContinuousFailCount > 0
        && (userResolver.docs.editorManager?.pool.continuousFailCount ?? 0) > tryReloadContinuousFailCount
        && !webviewHasBeenTerminated.value && !webviewHasBeenNonResponsive
        return shouldCheck
    }

    @objc
    func preloadOvertime() {
        //执行preloadJsModule超时
        guard !webviewHasBeenTerminated.value, let url = self.currentUrl, !URLValidator.isMainFrameTemplateURL(url) else { return }
        webviewHasBeenNonResponsive = true
        self.rootTracing.error("webview maybe nonresponsive, killAndReloadWebView")
        cancleDeferringOvertimeTip()
        becomeOverTime()
        self.delegate?.killAndReloadWebView()
    }
    
    private func reportPreloadOvertime() {
        let param: [String: Any] = ["from": CheckResponsiveFrom.preloadJSModule.rawValue,
                                    "responsive": 0,
                                    "continuousFailCount": userResolver.docs.editorManager?.pool.continuousFailCount ?? 0
        ]
        DocsTracker.newLog(enumEvent: .webviewResponsiveState, parameters: param)
    }
    
    func reportLoadFinishAfterNonResponsive() {
        let param: [String: Any] = ["from": CheckResponsiveFrom.preloadJSModule.rawValue,
                                    "responsive": 0,
                                    "continuousFailCount": userResolver.docs.editorManager?.pool.continuousFailCount ?? 0
        ]
        DocsTracker.newLog(enumEvent: .webviewResponsiveState, parameters: param)
    }
}
