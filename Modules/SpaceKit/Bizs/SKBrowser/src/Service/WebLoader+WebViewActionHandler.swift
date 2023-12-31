//
//  WebLoader+WebViewActionHandler.swift
//  SKBrowser
//
//  Created by lijuyou on 2023/9/12.
//

import SKFoundation
import SKResource
import SKUIKit
import SKCommon
import SKInfra
import SpaceInterface
import UniverseDesignToast

extension WebLoader: DocsBrowserWebViewActionHandleDelegate {
    
    static let defaultReloadTipsInterval = 2
    static let defaultAutoReloadMaxCount = 3
    
    func didReceiveRedirectResponse(_ response: URLResponse) {
        guard let response = response as? HTTPURLResponse else { return }
        switch response.statusCode {
        // nolint-next-line: magic number
        case 301, 302:
            if let location = response.allHeaderFields["Location"] as? String {
                currentUrl = URL(string: location)
            }
            rootTracing.info("didReceiveRedirectResponse 301/302")
        default: break
        }
    }

    func webViewActionWebViewTerminate(_ browserView: BrowserView?, reason: UInt32) {
        DocsLogger.error("[webviewTerminat] webView terminate: isInView:\(isInViewHierarchy), isInForground: \(browserView?.isInForground),reason:\(reason) \(editorIdForLog)", component: LogComponents.fileOpen)
        delegate?.didTerminated()
        webviewHasBeenTerminated.value = true
        webviewTerminateHandler.isInViewHierarchy = isInViewHierarchy
        webviewTerminateHandler.externalUrl = currentUrl
        webviewTerminateHandler.terminateReason = reason
        webviewTerminateHandler.isVisible = webView?.isVisible() ?? false
        webviewTerminateHandler.handleTerminate(isInForground: browserView?.isInForground ?? true,
                                                hasJsCall: browserView?.isResponsive ?? false,
                                                onReloadFail: { [unowned self] in
            rootTracing.info("[webviewTerminat] reload when terminata url")
            self.reload()
        })
        let feishuIsBackground = UIApplication.shared.applicationState == .background
        let isVisible = webView?.isVisible() ?? false
        if !isVisible || feishuIsBackground {
            shouldReloadAfterTerminateWhenBecomeForeground = true
            rootTracing.info("[webviewTerminat] reload later because isVisible:\(isVisible),isBackground:\(feishuIsBackground)")
            return
        }
        
        if let browserView = browserView, browserView.isResponsive == false {
            //如果没有收到任意js调用就terminate, 尝试reset WKProcessPool
            EditorManager.shared.pool.recoverEditorIfNeed(editor: browserView, failCount: currentReloadCount + 1, inPool: false)
        }
        
        let maxCount = SettingConfig.docsWebViewConfig?.autoReloadMaxCount ?? Self.defaultAutoReloadMaxCount
        if currentReloadCount >= maxCount { // 经验值，1次重试成功率65%，两次83%，3次是92%，再往后收益低了
            rootTracing.info("[webviewTerminat] stop reload, reload count:\(currentReloadCount)")
            showTerminateErrorPageIfNeeded()
            return
        }
        rootTracing.info("[webviewTerminat] reload when terminate")
        reloadForRecover(false, fromTerminate: true)
    }
    func removeTerminateErrorPage() {
        guard let dele = delegate else {
            DocsLogger.error("[webviewTerminat] removeTerminateErrorPage error, delegate is nil")
            return
        }
        dele.removeTerminateErrorPage()
    }
    func showTerminateErrorPageIfNeeded() {
        guard let dele = delegate else {
            DocsLogger.error("[webviewTerminat] showTerminateErrorPageIfNeeded error, delegate is nil")
            return
        }
        dele.showTerminateErrorPage()
    }
    
    /// 刷新恢复
    /// - Parameter forceFullReload: 强制全量Reload
    func reloadForRecover(_ forceFullReload: Bool, fromTerminate: Bool) {
        // 后续此处要改为为从0加载文档，避免中间状态影响
        guard let web = webView else {
            DocsLogger.error("[webviewTerminat] reloadForRecover error, webview is nil")
            return
        }
        currentReloadCount += 1
        rootTracing.info("[webviewTerminat] reloadForRecover,reload count:\(currentReloadCount), terminate:\(fromTerminate), url:\(String(describing: web.url?.absoluteString.encryptToShort))")
        if fromTerminate {
            let reloadTipsInterval = SettingConfig.docsWebViewConfig?.reloadTipsInterval ?? Self.defaultReloadTipsInterval
            if reloadTipsInterval > 0, currentReloadCount % reloadTipsInterval == 0 { //降低提示频率
                DispatchQueue.safetyAsyncMain {
                    UDToast.showTips(with: SKResource.BundleI18n.SKResource.LarkCCM_Docs_NoStorage_Loading_Toast, on: web)
                }
            }
        }
        
        if docsInfo?.isVersion ?? false {
            web.stopLoading()
            reload()
        } else if (web.url == nil || URLValidator.isMainFrameTemplateURL(web.url)) && forceFullReload == false {
            //和上边handleTerminate完全一致，不要修改线上判断逻辑
            // 调用web window.render进行reload
            reload()
        } else {
            // fullReload: 直接调用WKWebView.reload
            web.reload()
        }
    }
    func addObserverForTerminateRecovery() {
        NotificationCenter
            .default
            .addObserver(
                self,
                selector: #selector(tryRecoveryTerminatedPageIfNeededWhenBecomeActive),
                name: UIApplication.willEnterForegroundNotification,
                object: nil
            )
    }
    @objc
    func tryRecoveryTerminatedPageIfNeededWhenBecomeActive() {
        guard shouldReloadAfterTerminateWhenBecomeForeground else {
            return
        }
        let isVisible: Bool
        if let web = webView {
            isVisible = web.isVisible()
        } else {
            DocsLogger.info("[webviewTerminat] webview is nil")
            isVisible = false
        }
        guard isVisible else {
            DocsLogger.info("[webviewTerminat] webview is not visible, not reload")
            return
        }
        rootTracing.info("[webviewTerminat] reload when Become Active")
        reloadForRecover(true, fromTerminate: true)
        shouldReloadAfterTerminateWhenBecomeForeground = false
    }
    /// Note: 当时迁移代码的时候就是一个空方法，暂时保留
    func browserViewAuthorizedFaild(_ browserView: BrowserView) {

    }
    
    func onFrameLoadFail(url: String, isMainFrame: Bool, error: Error) {
        guard !isMainFrame else {
            return //mainframe不处理
        }
        let nsErr = error as NSError
        let errCode = nsErr.code
        
        // 字节租户 && 网络类型错误发起内网检测
        let isBytedance = userResolver.docs.user?.info?.isBytedance ?? false
        let host = URL(string: url)?.host
        if UserScopeNoChangeFG.LJY.enableIFrameCheckVPN,
           isBytedance,
            PrivateHostChecker.isNetError(code: errCode),
            let host {
            DispatchQueue.global().async { [weak self] in
                guard let self else {
                    return
                }
                PrivateHostChecker.checkIsPrivateIfNeed(resolver: self.userResolver,
                                                        frameHost: host,
                                                        checkIP: false) { [weak self] isPrivate in
                    guard let self else { return }
                    if isPrivate {
                        notifyFrameError(code: PrivateHostChecker.privateHostError, msg: "", url: url, host: host)
                    } else {
                        notifyFrameError(code: errCode, msg: nsErr.localizedDescription, url: url, host: host)
                    }
                }
            }
        } else {
            notifyFrameError(code: errCode, msg: nsErr.localizedDescription, url: url, host: host)
        }
    }
    
    func notifyFrameError(code: Int, msg: String, url: String, host: String?) {
        DocsLogger.info("[iframecheck] notify:\(code) for:\(host ?? "invalid host")")
        delegate?.callFunction(.notifyFrameError,
                               params: ["errorCode": code,
                                        "errorMsg": msg,
                                        "url": url],
                               completion: nil)
    }
}



