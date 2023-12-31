//
//  BrowserView+Statistics.swift
//  SpaceKit
//
//  Created by huahuahu on 2018/9/13.
//

import SKFoundation
import os
import SKCommon
import LarkSceneManager
import SKUIKit
import WebKit
import SKInfra

protocol BrowserViewStatisticsDelegate: AnyObject {
    func browserView(_ browserView: BrowserView, isPreLoad url: String) -> Bool
    func browserView(_ browserView: BrowserView, encryptedTokenFor token: String) -> String
}

extension WebBrowserView {

    public class func statisticsDidStartCreatUIFor(sessionId: String, versionInfo: [String: Any]?, url: URL) {
        OpenFileRecord.startRecordTimeConsumingFor(sessionID: sessionId, stage: OpenFileRecord.Stage.openFinish.rawValue, parameters: nil, versionInfo: versionInfo)
        OpenFileRecord.startRecordTimeConsumingFor(sessionID: sessionId, stage: OpenFileRecord.Stage.editorUICreate.rawValue, parameters: nil, versionInfo: versionInfo)
        if DocsUrlUtil.isBaseRecordUrl(url) {
            OpenFileRecord.setIsInRecord(true, for: sessionId)
        }
    }

    private func getFileInfoFrom(_ urlstr: String) -> [String: Any] {
        var info = [String: Any]()
        info[DocsTracker.Params.docHasCached] = "unknown"
        info[DocsTracker.Params.docFrom] = "unknown"
        info[DocsTracker.Params.preloadHtmlEnabled] = "unknown"
        if let url = URL(string: urlstr),
            let type = DocsUrlUtil.getFileType(from: url),
            let fileToken = DocsUrlUtil.getFileToken(from: url) {
            let preloadKey = PreloadKey(objToken: fileToken, type: type, wikiInfo: docsInfo?.wikiInfo)
            let hasCachedClientVar = preloadKey.hasClientVar
            info[DocsTracker.Params.docHasCached] = hasCachedClientVar ? 1 : 0
            info[DocsTracker.Params.preloadHtmlEnabled] = 1
        }
        if let urlcomponent = URLComponents(string: urlstr) {
            let fromQuery = urlcomponent.queryItems?.first { $0.name == "from" }
            info[DocsTracker.Params.docFrom] = fromQuery?.value
        }
        //这里取反，fg默认是关闭的
        if !UserScopeNoChangeFG.HZK.openDocAddFromParamDisable,
           let openDocDesc = fileConfig?.openDocDesc,
           !openDocDesc.isEmpty {
            info[DocsTracker.Params.openDocDesc] = openDocDesc
        }
        return info
    }
    
    private func getVersionSourceFrom(_ urlstr: String) -> String? {
        if let urlcomponent = URLComponents(string: urlstr) {
            let fromQuery = urlcomponent.queryItems?.first { $0.name == "versionfrom" }
            return fromQuery?.value
        }
        return nil
    }

    public func statisticsLoadingStageChangeTo(_ stage: LoadStatus.LoadingStage) {
        guard let sessionId = self.docsLoader?.openSessionID else {
            return
        }

        switch stage {
        case .beforeReadLocalHtmlCache:
            OpenFileRecord.startRecordTimeConsumingFor(sessionID: sessionId, stage: OpenFileRecord.Stage.readLocalHtmlCache.rawValue, parameters: nil)
        case .renderCalled:
            OpenFileRecord.endRecordTimeConsumingFor(sessionID: sessionId, stage: OpenFileRecord.Stage.readLocalHtmlCache.rawValue, parameters: nil)
            OpenFileRecord.startRecordTimeConsumingFor(sessionID: sessionId, stage: OpenFileRecord.Stage.readLocalClientVar.rawValue, parameters: nil)
        case .afterReadLocalClientVar:
            OpenFileRecord.endRecordTimeConsumingFor(sessionID: sessionId, stage: OpenFileRecord.Stage.readLocalClientVar.rawValue, parameters: nil)
        default:
            break
        }
    }

    func recordBeforeCallRender() {
        guard let sessionId = self.docsLoader?.openSessionID else {
            return
        }
        OpenFileRecord.startRecordTimeConsumingFor(sessionID: sessionId, stage: OpenFileRecord.Stage.renderFunc.rawValue, parameters: nil)
    }

    func receiveRenderCallBack(success: Bool, error: Error?) {
        guard let sessionId = self.docsLoader?.openSessionID else {
            return
        }
        OpenFileRecord.endRecordTimeConsumingFor(sessionID: sessionId, stage: OpenFileRecord.Stage.renderFunc.rawValue, parameters: nil)
        if UserScopeNoChangeFG.LYL.enableStatisticTrace {
            lifeCycleEvent.browserReceiveRenderCallBack(success: success, error: error)
        }
    }

    func statisticsDidStartLoad(_ url: String, openType: OpenFileRecord.OpenType ) {
        guard shouldDoStatisticsFor(url: url) else { return }
        guard let docsinfo = docsInfo else {
            spaceAssertionFailure("invald docsInfo in statisticsDidStartLoad")
            return
        }
        let sessionId = self.docsLoader?.openSessionID
        var param: [String: Any] = ["isLarkWebview": self.isLarkWebView()]
        if docsInfo?.isVersion ?? false {
            param["is_version"] = OpenFileRecord.VersionType.version.rawValue
            param["edition_id"] = docsInfo?.versionInfo?.version ?? ""
        } else {
            param["is_version"] = OpenFileRecord.VersionType.source.rawValue
        }
        if #available(iOS 16.0, *), UserScopeNoChangeFG.GXY.lockdownModeEnable  {
            let wkwebview = webView as WKWebView
            // iOS16beta3 版本增加的属性，beta3以前的系统访问会crash，添加判断
            if let prefrence = wkwebview.configuration.defaultWebpagePreferences,
               prefrence.responds(to: Selector(("isLockdownModeEnabled"))) {
                param["lock_down_mode_enable"] = prefrence.isLockdownModeEnabled ? "1" : "0"
            }
        }
        param["pool_index"] = self.poolIndex
        param["check_rsp_in_open"] = (self.webLoader?.hasCheckResponsiveInOpen ?? false) ? 1 : 0
        let hasPreloadType = self.webLoader?.preloadStatus.value.hasPreload(docsinfo.type) ?? false
        
        // 文档打开时，是否有预加载任务在队列里，上报时间
        if docsInfo?.type == .docX,
           let token = docsInfo?.objToken {
            if let ssrPreloadTime = userResolver.docs.editorManager?.getSSRPreloadTime(token) {
                if ssrPreloadTime > 0 {
                    param["time_to_preload_ssr"] = (Date().timeIntervalSince1970 - ssrPreloadTime) * 1000
                } else {
                    param["time_to_preload_ssr"] = -1
                }
            }
            if let clientPreloadTime = userResolver.docs.editorManager?.getClientVarsPreloadTime(token) {
                if clientPreloadTime > 0 {
                    param["time_to_preload_clientvar"] = (Date().timeIntervalSince1970 - clientPreloadTime) * 1000
                } else {
                    param["time_to_preload_clientvar"] = -1
                }
            }
        }
        
        if DocsUserBehaviorManager.isEnable() {
            let shouldPreloadTemplate = DocsUserBehaviorManager.shared.shouldPreloadTemplate(type: docsinfo.type)
            let shouldPreloadWebview = DocsUserBehaviorManager.shared.shouldPreloadWebView()
            param["interrupt_template_preload"] = shouldPreloadTemplate ? "true" : "false"
            param["interrupt_webview_preload"] = shouldPreloadWebview ? "true" : "false"
            DocsUserBehaviorManager.shared.openDocs(docsInfo: docsinfo)
        }
        
        OpenFileRecord.startRecordTimeConsumingFor(sessionID: sessionId, stage: OpenFileRecord.Stage.loadUrl.rawValue, parameters: param)
        OpenFileRecord.updateFileinfo(getFileInfoFrom(url), for: sessionId)
        if let token = self.docsInfo?.objToken,
            let encrypteToken = self.statisticsDelegate?.browserView(self, encryptedTokenFor: token) {
             OpenFileRecord.setFileId(encrypteToken, for: sessionId)
        }
        OpenFileRecord.setFileType(self.docsInfo?.typeForStatistics.name, self.docsInfo?.wikiInfo?.docsType.name, for: sessionId)
        OpenFileRecord.setFileOpenType(openType, for: sessionId)
        OpenFileRecord.endRecordTimeConsumingFor(sessionID: sessionId, stage: OpenFileRecord.Stage.editorUICreate.rawValue, parameters: nil)
        OpenFileRecord.endRecordTimeConsumingFor(sessionID: sessionId, stage: OpenFileRecord.Stage.loadUrl.rawValue, parameters: nil)
        if openType == .preload {
            OpenFileRecord.startRecordTimeConsumingFor(sessionID: sessionId, stage: OpenFileRecord.Stage.pullJS.rawValue, parameters: nil)
        } else {
            OpenFileRecord.startRecordTimeConsumingFor(sessionID: sessionId, stage: OpenFileRecord.Stage.waitPreload.rawValue, parameters: nil)
            lifeCycleEvent.browserStartPreload()
        }
        var urlInLog = url
        if let token = docsInfo?.objToken, let tokenInLog = docsInfo?.objTokenInLog {
            urlInLog = url.replacingOccurrences(of: token, with: tokenInLog).encryptToShort
        }
        DocsLogger.info("\(editorIdentity), start open \(urlInLog) with type \(openType.rawValue), waitTemplate:\(!hasPreloadType), openRecord identifier \(sessionId ?? "noid")", component: LogComponents.fileOpen)
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(type(of: self).statisticsMarkOverTime), object: nil)
        var openDocTimeout = (DocsNetStateMonitor.shared.accessType == .wifi) ? OpenAPI.docs.wifiOpenDocTimeout : OpenAPI.docs.noWifiOpenDocTimeout
        openDocTimeout += (openType == .preload) ? 0 : OpenAPI.docs.templateWaitTime
        self.perform(#selector(type(of: self).statisticsMarkOverTime), with: nil, afterDelay: openDocTimeout)
    
        if docsinfo.isVersion {
            let sourceFrom = getVersionSourceFrom(url)
            var params: [String: Any] = ["open_type": OpenFileRecord.VersionFromKey.fromLink.rawValue]
            if sourceFrom == FromSource.sourceVersionList.rawValue {
                params = ["open_type": OpenFileRecord.VersionFromKey.sourceDoc.rawValue]
            } else if sourceFrom == FromSource.switchVersion.rawValue {
                params = ["open_type": OpenFileRecord.VersionFromKey.fromSwitch.rawValue]
            }
            params.merge(other: DocsParametersUtil.createCommonParams(by: docsinfo))
            if docsInfo?.inherentType == .sheet {
                DocsTracker.newLog(enumEvent: .sheetVersionPage, parameters: params)
            } else {
                DocsTracker.newLog(enumEvent: .docsVesionPage, parameters: params)
            }
        }
    }

    func resetStaticsOverTime() {
        //进入后台时修改超时逻辑
        switch self.webLoader?.loadStatus {
        case .loading:
            guard  OpenAPI.docs.backGroundOpenDocTimeout > 0 else { return }
            DocsLogger.info("resetStaticsOverTime loading")
            NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(statisticsMarkOverTime), object: nil)
            var backGroundOpenDocsTimeout = OpenAPI.docs.backGroundOpenDocTimeout
            backGroundOpenDocsTimeout += (webLoader?.canRender() ?? true) ? 0 : OpenAPI.docs.templateWaitTime
            self.perform(#selector(type(of: self).statisticsMarkOverTime), with: nil, afterDelay: backGroundOpenDocsTimeout)
        default:
            DocsLogger.info("resetStaticsOverTime defaultValue")
        }
    }

    func statisticsLoaderDidEndLoadTemplate(_ loader: DocsLoader) {
        OpenFileRecord.endRecordTimeConsumingFor(sessionID: loader.openSessionID, stage: OpenFileRecord.Stage.waitPreload.rawValue, parameters: nil)
        OpenFileRecord.startRecordTimeConsumingFor(sessionID: loader.openSessionID, stage: OpenFileRecord.Stage.pullJS.rawValue, parameters: nil)
        lifeCycleEvent.browserEndPreload()
    }

    func statisticsLoaderDidCallRender(_ loader: DocsLoader) {
        OpenFileRecord.setH5TimeStamp(.preloadStart, for: loader.openSessionID, timeStamp: preloadStartTimeStamp)
        OpenFileRecord.setH5TimeStamp(.webviewLoadUrl, for: loader.openSessionID, timeStamp: webviewStartLoadUrlTimeStamp)
        OpenFileRecord.setH5TimeStamp(.preloadEnd, for: loader.openSessionID, timeStamp: preloadEndTimeStamp)
        OpenFileRecord.setH5TimeStamp(.invokeRender, for: loader.openSessionID )
    }

    func statisticsDidEndLoadFinishType(_ finishType: OpenFileRecord.FinishType, resultCode: Int? = nil, params: [String: Any]? = nil) {
        guard shouldDoStatisticsFor(url: docsLoader?.currentUrl?.absoluteString) else { return }
        statisticsCancelOverTimerMonitor()
        let sessionId = self.docsLoader?.openSessionID
        var allParams = params ?? [:]
        if SceneManager.shared.supportsMultipleScenes,
           #available(iOS 13.0, *), SKDisplay.pad,
           let sceneInfo = self.window?.currentScene()?.sceneInfo {
            allParams["im_aux_window"] = !sceneInfo.isMainScene()
        }
        allParams.updateValue(finishType.rawValue, forKey: OpenFileRecord.ReportKey.resultKey.rawValue)
        allParams.updateValue(resultCode ?? -1, forKey: OpenFileRecord.ReportKey.resultCode.rawValue)
        allParams.updateValue((self.webLoader?.renderSSRWebviewType ?? .none).rawValue, forKey: "doc_html_cache_from")
        OpenFileRecord.endRecordTimeConsumingFor(sessionID: sessionId, stage: OpenFileRecord.Stage.openFinish.rawValue, parameters: allParams)
    }

    @objc
    private func statisticsMarkOverTime() {
        guard shouldDoStatisticsFor(url: docsLoader?.currentUrl?.absoluteString) else { return }
        statisticsDidEndLoadFinishType(.overtime)
    }

    private func statisticsCancelOverTimerMonitor() {
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(type(of: self).statisticsMarkOverTime), object: nil)
    }

    private func shouldDoStatisticsFor(url: String?) -> Bool {
        guard let url = url else {
            return false
        }
        guard let statisDelegate = self.statisticsDelegate else {
            //spaceAssertionFailure()
            return false
        }

        if statisDelegate.browserView(self, isPreLoad: url) {
            return false
        }

        guard self.isInEditorPool == false else {
            //bugfix: https://bytedance.feishu.cn/docx/doxcn37ozYxGGH4O7Yldg8z3BEb
            //在复用池中不上报，例如收到黑暗模式变化触发reload导致的上报
            return false
        }

        return true
    }
}

extension WebBrowserView {
    func waitingDownloadFullPkgStatistics(isStart: Bool) {
        guard let sessionId = self.docsLoader?.openSessionID else {
            return
        }
        if isStart {
            OpenFileRecord.startRecordTimeConsumingFor(sessionID: sessionId, stage: OpenFileRecord.Stage.waitingFullPkgDownload.rawValue, parameters: nil)
        } else {
            OpenFileRecord.endRecordTimeConsumingFor(sessionID: sessionId, stage: OpenFileRecord.Stage.waitingFullPkgDownload.rawValue, parameters: nil)

        }
    }
}
