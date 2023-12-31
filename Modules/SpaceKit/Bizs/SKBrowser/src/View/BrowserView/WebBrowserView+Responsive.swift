//
//  WebBrowserView+Responsive.swift
//  SKBrowser
//
//  Created by lijuyou on 2022/5/11.
//  


import SKFoundation
import SKCommon
import SKUIKit
import UniverseDesignToast
import SKInfra

//WebView卡死检测 https://bytedance.sg.feishu.cn/docx/doxlgqopjqnZzbV4yuxWhO2c0gb

enum CheckResponsiveFrom: Int {
    case enterForeground    //从后台进入前台
    case reclaimToPool      //回收到缓存池
    case preloadJSModule    //预加载JS模板
    case timerInPool        //复用池里定时检测
    case openTimeOut        //打开超时
    case wkProcessPool      //WKProcessPool重置
}

extension WebBrowserView {
    
    func checkForResponsiveness(from: CheckResponsiveFrom) {
        guard OpenAPI.webviewCheckResponsiveEnable else {
            DocsLogger.info("checkForResponsiveness is disable")
            return
        }
        let editorId = self.editorIdentity
        let timeOut = OpenAPI.docs.webviewResponsivenessTimeout
        let fromNum = NSNumber(value: from.rawValue)
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(type(of: self).didBecomeUnresponsive(from:)), object: fromNum)
        DocsLogger.info("checkForResponsiveness start:\(editorId), inPool:\(self.isInEditorPool), from:\(from),timeOut:\(timeOut)", component: LogComponents.fileOpen)
        let startTime = CFAbsoluteTimeGetCurrent()
        self.webView.evaluateJavaScript("1+1") { [weak self] _, error in
            guard let self = self else { return }
            let costTime = CFAbsoluteTimeGetCurrent() - startTime
            if let error = error {
                DocsLogger.error("checkForResponsiveness finish cost: \(costTime):\(editorId), err:\(error)", component: LogComponents.fileOpen)
            } else {
                DocsLogger.info("checkForResponsiveness finish cost: \(costTime):\(editorId)", component: LogComponents.fileOpen)
            }
            
            let isResponsive = costTime < timeOut
            if isResponsive {
                DocsLogger.info("checkForResponsiveness cancel,\(editorId)")
                NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(type(of: self).didBecomeUnresponsive(from:)), object: fromNum)
            }
            self.reportResponsiveState(isResponsive: isResponsive,
                                       from: from.rawValue,
                                       checkCostTime: costTime)
        }
        self.perform(#selector(didBecomeUnresponsive(from:)), with: fromNum, afterDelay: timeOut)
    }
    
    @objc
    private func didBecomeUnresponsive(from: NSNumber) {
        guard let webview = self.webView as? DocsWebViewV2 else { return }
        
        //只有正在打开的文档，并且从后台回台前台时才自动刷新
        let autoReload = from.intValue == CheckResponsiveFrom.enterForeground.rawValue && !self.isInEditorPool
        //重新走打开文档流程，在打开文档超时时执行
        let reopenDoc = from.intValue == CheckResponsiveFrom.openTimeOut.rawValue
        DocsLogger.error("didBecomeUnresponsive autoReload:\(autoReload)，reopen:\(reopenDoc),from:\(from.intValue),\(self.editorIdentity)", component: LogComponents.fileOpen)
        
#if DEBUG
        UDToast.docs.showMessage("WebView become unresponsive reload:\(autoReload)", on: self.webView, msgType: .warn)
#endif
        
        //卡死了也当Terminated处理，会触发EditorPool的回收,see addObserveTerminateFor
        webLoader?.webviewHasBeenTerminated.value = true
        
        if reopenDoc {
            killAndReloadWebView()
        }
        else if autoReload {
            //卡死的时候reload已经没用了，需要kill掉webview进程重启
            DocsLogger.info("didBecomeUnresponsive,kill process,\(self.editorIdentity)", component: LogComponents.fileOpen)
            webview.killProcess()
            DocsLogger.info("didBecomeUnresponsive,reload \(self.editorIdentity)", component: LogComponents.fileOpen)
            webview.reload()
        }
        self.reportResponsiveState(isResponsive: false,
                                   from: from.intValue,
                                   autoReload: autoReload)
    }
    
    func killAndReloadWebView() {
        guard let webview = self.webView as? DocsWebViewV2 else { return }
        DocsLogger.info("killAndReloadWebView,\(self.editorIdentity)", component: LogComponents.fileOpen)
        webview.killProcess()
        
        DispatchQueue.main.async { [weak self] in
            guard let url = self?.currentUrl, !URLValidator.isMainFrameTemplateURL(url) else { return }
            DocsLogger.info("preload after nonresponsive,\(self?.editorIdentity ?? "")", component: LogComponents.fileOpen)
            self?.preload()
            DispatchQueue.main.async {
                self?.load(url: url)
            }
        }
    }
    
    func checkWebViewResponsiveInOpenOvertime() {
        if self.webLoader?.loadStatus.isOvertime ?? false {
            statisticsDidEndLoadFinishType(.cancel) //打开文档时卡死重试先当cancel，重试完会再上报，只重试一次
        }
        self.checkForResponsiveness(from: .openTimeOut)
    }
    
    func makeWebViewUnresponsive() {
        DocsLogger.error("makeWebViewUnresponsive...,\(self.editorIdentity)")
        self.webView.evaluateJavaScript("while(true){console.log('abc');}") { _, _ in
            DocsLogger.info("makeWebViewUnresponsive end")
        }
    }
    
    private func reportResponsiveState(isResponsive: Bool,
                                       from: Int,
                                       autoReload: Bool = false,
                                       checkCostTime: Double? = 0) {
        let usedTime = CFAbsoluteTimeGetCurrent() - createTime
        let param: [String: Any] = ["from": from,
                                    "in_pool": self.isInEditorPool ? 1 : 0,
                                    "auto_reload": autoReload ? 1 : 0,
                                    "userd_count": self.usedCounter,
                                    "responsive": isResponsive ? 1 : 0,
                                    "used_time": usedTime,
                                    "cost": checkCostTime ?? 0.0
        ]
        DocsTracker.newLog(enumEvent: .webviewResponsiveState, parameters: param)
    }
    
    func startInPoolCheckForResponsivenessTimer() {
        DispatchQueue.main.async { [weak self] in
            guard let `self` = self else { return }
            guard UserScopeNoChangeFG.GXY.inPoolWebViewCheckUnResponseTimerEnable,
                  (MobileClassify.mobileClassType == .highMobile || MobileClassify.mobileClassType == .middleMobile) else {
                return
            }
            self.stopInPoolCheckForResponsivenessTimer()
            guard self.isInEditorPool else {
                DocsLogger.info("not in pool cannot start check timer")
                return
            }
            let timer = Timer.scheduledTimer(withTimeInterval: OpenAPI.webviewCheckResponsivTime, repeats: true, block: { [weak self] _ in
                guard let `self` = self else { return }
                self.inPoolCheckForResponsivenessTimeUp()
            })
            self.InPoolCheckForResponsivenessTimer = timer
            RunLoop.main.add(timer, forMode: .common)
        }
    }
    
    func stopInPoolCheckForResponsivenessTimer() {
        guard self.InPoolCheckForResponsivenessTimer != nil else { return }
        DocsLogger.info("stopInPoolCheckForResponsivenessTimer")
        NSObject.cancelPreviousPerformRequests(withTarget: self,
                                               selector: #selector(inPoolCheckForResponsivenessTimeUp),
                                               object: nil)
        self.InPoolCheckForResponsivenessTimer?.invalidate()
        self.InPoolCheckForResponsivenessTimer = nil
    }
    
    @objc
    private func inPoolCheckForResponsivenessTimeUp() {
        guard self.isInEditorPool else {
            DocsLogger.info("not in pool cannot start check")
            return
        }
        DocsLogger.info("start check ForResponsiveness in pool")
        checkForResponsiveness(from: .timerInPool)
    }
}
