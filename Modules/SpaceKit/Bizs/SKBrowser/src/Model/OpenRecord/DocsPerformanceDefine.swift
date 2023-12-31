//
//  DocsPerformanceDefine.swift
//  SpaceKit
//
//  Created by huahuahu on 2018/8/30.
//  swiftlint:disable cyclomatic_complexity file_length

import Foundation
import os
import SKCommon
import SKFoundation
import TTNetworkManager
import SpaceInterface
import SKInfra

public final class OpenFileRecord {
    // MARK: - 变量定义
    private var fileId: String? //加密后的fileid
    private var fileType: String? // 文档类型
    private var openType: OpenType? //打开方式

    private var timeStamps: Dictionary = [String: Double]() //各种时刻
    private var timeStampsForH5 = ThreadSafeDictionary<TimeStampKeyForH5, TimeInterval>()
    private var costTimeForStages: Dictionary = [String: Double]() //各阶段耗时
    private var fileInfo: Dictionary = [String: Any]() // 文档信息
    private var startParams: Dictionary = [String: [String: Any]]() //起始时刻带的参数，最后需要传递上去
    private var hasLoadFinish = false //  只能打开一次
    private var sessionID: String

    final private let clientVarCacheSource = "doc_cacheSource"
    final private let clientVarCacheSetTimeToNow = "doc_timesinceCache"
    final private let scmVersionKey = "scm_version"
    final private let hasBeenBackgroundKey = "doc_hasBeenBackground"

    //用于记录文档打开的速率 key是view的字典，value 记录文档打开信息
    public private(set) static var openFilePerformanceDict = [String: OpenFileRecord]()
    private static var currentOpenSessionId: Int = 10000
    
    public var startOpenTime: Double? {
        timeStamps[Stage.openFinish.rawValue]
    }
    
    // just For test
    private var localGetDataCostTime: Double?
    private var pullDataCostTime: Double?
    private var renderDocCostTime: Double?
    private var pullJSCostTime: Double!
    private var creatuiCostTime: Double?
    private var hasBeenInBackground = (UIApplication.shared.applicationState != .active)

    private var isInRecord: Bool = false

    public init(sessionId: String) {
        sessionID = sessionId
        fileInfo[clientVarCacheSource] = "no"
        fileInfo[clientVarCacheSetTimeToNow] = -1
        fileInfo[hasBeenBackgroundKey] = hasBeenInBackground ? 1 : 0
        fileInfo[DocsTracker.Params.docNetStatus] = DocsNetStateMonitor.shared.accessType.intForStatistics
        timeStampsForH5.updateValue(Date().timeIntervalSince1970, forKey: .clickUI)
        NotificationCenter.default.addObserver(self, selector: #selector(onAppInBackground(_:)), name: UIApplication.didEnterBackgroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onAppBecomeActive(_:)), name: UIApplication.didBecomeActiveNotification, object: nil)
    }

    @objc
    private func onAppInBackground(_ notify: NSNotification) {
        hasBeenInBackground = true
        fileInfo[hasBeenBackgroundKey] = 1
    }

    @objc
    private func onAppBecomeActive(_ notify: NSNotification) {
        hasBeenInBackground = false
        fileInfo[hasBeenBackgroundKey] = 0
    }

    // MARK: - 函数定义
    func markStageBeginFor(stage: String, parameters: [String: Any]?) {
        guard hasLoadFinish == false else { return }
        beginSignPostFor(stage)
        if stage == Stage.openFinish.rawValue {
            startRecordOpen(parameters: parameters)
            return
        }
        if let curParam = parameters, let timestamp = curParam["timestamp"] as? Double {
            timeStamps[stage] = timestamp / 1000
        } else {
            timeStamps[stage] = Date().timeIntervalSince1970
        }
        startParams[stage] = parameters
        var allParames: [String: Any] = parameters ?? [:]
        allParames.updateValue(stage + "_start", forKey: ReportKey.stage.rawValue)
        allParames.merge(other: fileInfo)
        #if DEBUG || BETA
        #else
        if shouldReport {
            DocsTracker.log(enumEvent: .openStageEvent, parameters: allParames)
        }
        #endif
        DocsLogger.debug("openRecord identifier:\(sessionID) event:\(DocsTracker.EventType.openStageEvent) start:\(stage)", extraInfo: allParames, error: nil, component: LogComponents.fileOpen)
        if DocsSDK.isBeingTest {
            let userInfo = allParames.merging(["eventName": DocsTracker.EventType.openStageEvent]) { (current, _) in current }
            NotificationCenter.default.post(name: Notification.Name.OpenFileRecord.StageStart, object: nil, userInfo: userInfo)
        }
    }

    private func markStageEndFor(stage: String, parameters: [String: Any]?) {
        if stage != Stage.editDoc.rawValue {
            guard hasLoadFinish == false else { return }
        } 
        endSignPostFor(stage)
        if stage == Stage.openFinish.rawValue {
            endRecordOpen(parameters: parameters)
            return
        }
        //除了这几种，有终必须有始
        if self.timeStamps[stage] == nil {
            if stage == Stage.editorUICreate.rawValue {
//                spaceAssert(startStage == .loadUrl, "\(stage) end without start !!!")
                return
            }
        }
        guard let startTime = timeStamps[stage] else {
            return
        }

        let endTime = (parameters?["timestamp"] as? Double) ?? (1000 * Date().timeIntervalSince1970)
        let costTime = endTime - 1000 * startTime
        costTimeForStages[stage] = costTime
        var allParames: [String: Any] = [ReportKey.costTime.rawValue: costTime]

        if stage == Stage.waitingFullPkgDownload.rawValue {
            allParames.updateValue(StageCode.afterFullPkgDownloaded.rawValue, forKey: ReportKey.resultCode.rawValue)
        }

        allParames.merge(other: startParams[stage])
        allParames.merge(other: fileInfo)
        allParames.merge(other: parameters)
        allParames["file_id"] = fileId
        allParames.updateValue(stage, forKey: ReportKey.stage.rawValue)
        #if DEBUG || BETA
        if stage == Stage.renderCache.rawValue {
            DocsLogger.debug("[ssr]render cache costTime:\(costTime)")
        }
        #else
        if shouldReport {
            DocsTracker.log(enumEvent: .openStageEvent, parameters: allParames)
        }
        #endif

        DocsLogger.debug("openRecord identifier:\(sessionID) event:\(DocsTracker.EventType.openStageEvent) end:\(stage)", extraInfo: allParames, error: nil, component: LogComponents.fileOpen)
        if DocsSDK.isBeingTest {
            let userInfo = allParames.merging(["eventName": DocsTracker.EventType.openStageEvent]) { (current, _) in current }
            NotificationCenter.default.post(name: Notification.Name.OpenFileRecord.StageEnd, object: nil, userInfo: userInfo)
            if stage == Stage.pullData.rawValue {
                pullDataCostTime = costTime
            } else if stage == Stage.renderDoc.rawValue {
                renderDocCostTime = costTime
            } else if stage == Stage.pullJS.rawValue {
                pullJSCostTime = costTime
            } else if stage == Stage.editorUICreate.rawValue {
                creatuiCostTime = costTime
            } else if stage == Stage.getNativeData.rawValue {
                if localGetDataCostTime != nil {
                    DocsLogger.info("has log")
                }
                localGetDataCostTime = costTime
            }
        }

        //错误了，要标记整体失败了
        if let resultKey = parameters?[ReportKey.resultKey.rawValue] as? String,
            let resultCode = parameters?[ReportKey.resultCode.rawValue] as? Int,
            resultCode != 0 || resultKey != "other" {
            endRecordOpen(parameters: parameters)
        } else if stage == Stage.renderDoc.rawValue {
            endRecordOpen(parameters: parameters)
        }
    }

     private func startRecordOpen(parameters: [String: Any]?) {
        let currentTime = Date().timeIntervalSince1970
        timeStamps[Stage.openFinish.rawValue] = currentTime
        timeStamps[Stage.renderCache.rawValue] = currentTime
        timeStamps[Stage.editDoc.rawValue] = currentTime
        var params: [String: Any] = ["doc_timeSince_sdk_init": currentTime - DocsPerformance.initTime]
        params.merge(other: parameters)
        fileInfo["doc_timeSince_sdk_init"] = currentTime - DocsPerformance.initTime
        DocsLogger.debug("openRecord identifier is \(sessionID) start record openfile:", extraInfo: params, error: nil, component: LogComponents.fileOpen)
        // for test
        NotificationCenter.default.post(name: Notification.Name.OpenFileRecord.OpenStart, object: nil, userInfo: parameters)
        // for test end
    }

    private func endRecordOpen(parameters: [String: Any]?) {
        // 分享记录不应该埋点，这里用个 FG 开关再兜底控制一下
        if !UserScopeNoChangeFG.LYL.disableFixInRecordFileRecord,
           isInRecord {
            return
        }
        guard let start = self.timeStamps[Stage.openFinish.rawValue] else {
//            spaceAssertionFailure("event \(Stage.openFinish.rawValue) end before start!!!!")
            return
        }
        let endTime = (parameters?["timestamp"] as? Double) ?? 1000 * Date().timeIntervalSince1970
        let costTime = endTime - 1000 * start
        var allParames: [String: Any] = ["cost_time": costTime]
        allParames.merge(other: parameters)
        if hasLoadFinish {
            return
        } else {
            hasLoadFinish = true
        }

        // 超时/取消，自己来做统计
        let resultKey = parameters?[ReportKey.resultKey.rawValue] as? String
        if resultKey == FinishType.overtime.rawValue || resultKey == FinishType.cancel.rawValue {
//            spaceAssert(self.costTime[Stage.loadUrl.rawValue] != nil)
//            spaceAssert(self.openType != nil)
            if self.timeStamps[Stage.pullData.rawValue] == nil {
                allParames.updateValue(StageCode.afterLoadUrl.rawValue, forKey: ReportKey.resultCode.rawValue)
                allParames.updateValue(StageCode.afterLoadUrl.rawValue, forKey: ReportKey.resultCostTimeCode.rawValue)
            } else if self.timeStamps[Stage.renderDoc.rawValue] == nil {
                allParames.updateValue(StageCode.afterPullData.rawValue, forKey: ReportKey.resultCode.rawValue)
                allParames.updateValue(StageCode.afterPullData.rawValue, forKey: ReportKey.resultCostTimeCode.rawValue)
            } else {
                allParames.updateValue(StageCode.afterRenderDoc.rawValue, forKey: ReportKey.resultCode.rawValue)
                if let pullDataTime = self.timeStamps[Stage.pullData.rawValue],
                   let renderTime = self.timeStamps[Stage.renderDoc.rawValue] {
                    if pullDataTime > renderTime {
                        allParames.updateValue(StageCode.afterPullData.rawValue, forKey: ReportKey.resultCostTimeCode.rawValue)
                    } else {
                        allParames.updateValue(StageCode.afterRenderDoc.rawValue, forKey: ReportKey.resultCostTimeCode.rawValue)
                    }
                }
            }
        }
        // 打开一个非doc、sheet文档时，等待了多久才下载好完整包，并ready之后才打开文档
        allParames["wait_resource_time"] = GeckoPackageManager.getOpenUrlWaitingFullPkgDownloadTime()
        GeckoPackageManager.resetWaitingFullPkgDownloadTime()
        if DocsPerformance.openTimes == 0 {
            let currentTime = Date().timeIntervalSince1970
            allParames["cost_time_app_launch_to_open_doc"] = currentTime - DocsPerformance.initTime
        }
        let ttv = costTimeForStages[Stage.renderCache.rawValue] ?? costTime
        allParames["time_to_visit"] = ttv
        allParames["is_first_open_docs"] = DocsPerformance.openTimes == 0
        allParames["load_ssr_after_preload_html"] = UserScopeNoChangeFG.LJY.enableRenderSSRWhenPreloadHtmlReady ? 1 : 0

        DocsPerformance.openTimes += 1

        allParames.merge(other: startParams[Stage.openFinish.rawValue])
        allParames.merge(other: startParams[Stage.loadUrl.rawValue])
        allParames.merge(other: fileInfo)
        if let webEditor = EditorManager.shared.currentEditor as? WebBrowserView {
            if webEditor.isWebViewTerminated {
                allParames.updateValue(StageCode.webviewTerminated.rawValue, forKey: ReportKey.resultCode.rawValue)
            }
            if webEditor.webviewHasBeenTerminated.value {
                allParames["is_terminated"] = 1
            }
        }
        allParames["reset_wkpool"] = EditorManager.shared.pool.resetWKProcessPoolPolicy
        #if DEBUG || BETA
        DocsLogger.debug("openRecord identifier is \(sessionID) end record openfile:", extraInfo: allParames, error: nil, component: LogComponents.fileOpen)
        #else
        if shouldReport {
            let ttNetworkManager = TTNetworkManager.shareInstance()
            let effectiveConnectionType = ttNetworkManager.getEffectiveConnectionType()
            allParames["network_quality_type"] = effectiveConnectionType.rawValue
            DocsTracker.log(enumEvent: .docsOpenFinish, parameters: allParames)
        }
        DocsLogger.info("open finish-\(sessionID), ttv:\(ttv)", component: LogComponents.fileOpen)
        #endif

        _ = allParames["file_type"] as? String
//        spaceAssert(fileType == DocsType.doc.name || fileType == DocsType.sheet.name, "fileType is \(fileType ?? "")")
        endSignPostFor(Stage.openFinish.rawValue)
        if DocsSDK.isBeingTest {
            allParames["pull_data_costtime"] = pullDataCostTime
            allParames["render_doc_costtime"] = renderDocCostTime
            allParames["pull_js_costtime"] = pullJSCostTime
            allParames["create_ui_costtime"] = creatuiCostTime
            allParames["local_get_data"] = localGetDataCostTime
            NotificationCenter.default.post(name: Notification.Name.OpenFileRecord.OpenEnd, object: nil, userInfo: allParames)
        }
    }

    func reportStatisticsToServer(eventName: String, params: [String: Any]) {
//        guard hasLoadFinish == false else { return }
        DocsTracker.log(event: eventName, parameters: params)
        if eventName == "scm", let scmVersion = params["scm_version"] as? String {
            fileInfo[scmVersionKey] = scmVersion
        }
        if DocsSDK.isBeingTest {
            let userInfo = params.merging(["eventName": eventName]) { (current, _) in current }
            NotificationCenter.default.post(name: Notification.Name.OpenFileRecord.EventHappen, object: nil, userInfo: userInfo)
        }
    }

    func setFileId(_ fileid: String) {
        if fileId == nil {
            fileId = fileid
            self.fileInfo["file_id"] = fileId
        }
        DocsLogger.debug("openRecord identifier is \(sessionID) fileid: \(fileid)", extraInfo: nil, error: nil, component: nil)
    }

    func setFileType(_ inFileType: String?, _ wikiSubType: String?) {
        if fileType == nil {
            fileType = inFileType
            self.fileInfo["file_type"] = fileType
        }
        if let wikiSubType = wikiSubType {
            self.fileInfo["sub_type"] = wikiSubType
        }
        DocsLogger.debug("openRecord identifier is \(sessionID) fileType: \(inFileType ?? "")", extraInfo: nil, error: nil, component: nil)
    }

     func setFileOpenType(_ openType: OpenType) {
        self.openType = openType
        self.fileInfo.updateValue(openType.rawValue, forKey: "docs_open_type")
        DocsLogger.debug("openRecord identifier is \(sessionID) openType: \(openType)", extraInfo: nil, error: nil, component: nil)
    }

     func updateFileinfo(_ fileInfo: [String: Any]) {
        DocsLogger.debug("openRecord identifier is \(sessionID) income Info is:", extraInfo: fileInfo, error: nil, component: nil)
        DocsLogger.debug("openRecord identifier is \(sessionID) beforeUpdate:", extraInfo: self.fileInfo, error: nil, component: nil)
        self.fileInfo.merge(other: fileInfo)
        DocsLogger.debug("openRecord identifier is \(sessionID) afterUpdate:", extraInfo: self.fileInfo, error: nil, component: nil)
    }

    func setClientVarCacheInfo(_ info: ClientVarCacheMetaInfo) {
        fileInfo[clientVarCacheSource] = info.source.rawValue
        fileInfo[clientVarCacheSetTimeToNow] = info.secondsToNow
    }
    
    // 文档版本相关的信息
    func setVersionInfo(_ versionInfo: [String: Any]) {
        fileInfo.merge(other: versionInfo)
    }
    
    func setClientVarCacheFrom(_ from: String) {
        fileInfo["clientvar_preload_from"] = from
    }
    
    func setSSRCacheFrom(_ from: String) {
        fileInfo["ssr_preload_from"] = from
    }

    func setIsInRecord(_ isInRecord: Bool) {
        self.isInRecord = isInRecord
    }
}

extension OpenFileRecord {
    public class func generateNewOpenSession() -> String {
        currentOpenSessionId += 1
        return String(currentOpenSessionId)
    }

    public class func startRecordTimeConsumingFor(sessionID: String?, stage: String, parameters: [String: Any]?, versionInfo: [String: Any]? = nil) {
        guard let openSessionID = sessionID else {
            return
        }
        var openFileInfo = openFilePerformanceDict[openSessionID]
        //一次打开的起点，wiki文档会多一个pull_wiki_info环节
        let startEventSet: Set<String> = [Stage.openFinish.rawValue, Stage.loadUrl.rawValue, Stage.pullWikiInfo.rawValue]
        if openFileInfo == nil, startEventSet.contains(stage) {
            openFileInfo = OpenFileRecord(sessionId: openSessionID)
            openFilePerformanceDict[openSessionID] = openFileInfo
            if let info = versionInfo {
                openFileInfo?.setVersionInfo(info)
            }
            // 重新加载的。这里重新开始一次
            if stage == Stage.loadUrl.rawValue {
                openFileInfo?.markStageBeginFor(stage: Stage.openFinish.rawValue, parameters: parameters)
            }
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 120) {
                openFilePerformanceDict[openSessionID] = nil
            }
        }
        openFileInfo?.markStageBeginFor(stage: stage, parameters: parameters)
    }

    public class func endRecordTimeConsumingFor(sessionID: String?, stage: String, parameters: [String: Any]?) {
        guard let openSessionID = sessionID else {
            return
        }
        let openFileInfo = openFilePerformanceDict[openSessionID]
        openFileInfo?.markStageEndFor(stage: stage, parameters: parameters)
    }

    public class func reportStatisticsToServerFor(sessionID: String?, eventName: String, params: [String: Any]) {
        guard let openSessionID = sessionID else {
            return
        }
        let openFileInfo = openFilePerformanceDict[openSessionID]
        openFileInfo?.reportStatisticsToServer(eventName: eventName, params: params)
    }

    public class func setIsInRecord(_ isInRecord: Bool, for sessionID: String?) {
        guard let openSessionID = sessionID else {
            return
        }
        let openFileInfo = openFilePerformanceDict[openSessionID]
        openFileInfo?.setIsInRecord(isInRecord)
    }

    public class func setFileId(_ fileid: String, for sessionID: String?) {
        guard let openSessionID = sessionID else {
            return
        }
        let openFileInfo = openFilePerformanceDict[openSessionID]
        openFileInfo?.setFileId(fileid)
    }

    class func setFileType(_ fileType: String?, _ wikiSubType: String?, for sessionID: String?) {
        guard let openSessionID = sessionID, let fileType = fileType else {
            return
        }
        let openFileInfo = openFilePerformanceDict[openSessionID]
        openFileInfo?.setFileType(fileType, wikiSubType)
    }

    class func setFileOpenType(_ openType: OpenFileRecord.OpenType, for sessionID: String?) {
        guard let openSessionID = sessionID else {
            return
        }
        let openFileInfo = openFilePerformanceDict[openSessionID]
        openFileInfo?.setFileOpenType(openType)
    }

    class func updateFileinfo(_ fileInfo: [String: Any], for sessionID: String?) {
        guard let openSessionID = sessionID else {
            return
        }

        let openFileInfo = openFilePerformanceDict[openSessionID]
        openFileInfo?.updateFileinfo(fileInfo)
    }

    class func setClientVarCacheInfo(_ info: ClientVarCacheMetaInfo, for sessionID: String?) {
        guard let openSessionID = sessionID else { return }
        let openFileInfo = openFilePerformanceDict[openSessionID]
        openFileInfo?.setClientVarCacheInfo(info)
    }
    
    class func setClientVarCacheFrom(_ from: String, for sessionID: String?) {
        guard let openSessionID = sessionID else { return }
        let openFileInfo = openFilePerformanceDict[openSessionID]
        openFileInfo?.setClientVarCacheFrom(from)
    }
    
    class func setSSRCacheFrom(_ from: String, for sessionID: String?) {
        guard let openSessionID = sessionID else { return }
        let openFileInfo = openFilePerformanceDict[openSessionID]
        openFileInfo?.setSSRCacheFrom(from)
    }

    class func setH5TimeStamp(_ stage: TimeStampKeyForH5, for sessionID: String?, timeStamp: TimeInterval = Date().timeIntervalSince1970 ) {
        guard let openSessionID = sessionID else { return }
        let openFileInfo = openFilePerformanceDict[openSessionID]
        openFileInfo?.timeStampsForH5.updateValue(timeStamp, forKey: stage)
    }

    class func timeStampDictForH5(for sessionId: String?) -> [String: Int64] {
        guard let openSessionID = sessionId, let openFileInfo = openFilePerformanceDict[openSessionID] else { return [:] }
        var dict = [String: Int64]()
        for (stage, time) in openFileInfo.timeStampsForH5.all() {
            dict[stage.rawValue] = Int64(time * 1000)
        }
        return dict
    }
}

extension OpenFileRecord {
    var shouldReport: Bool {
        return !GeckoPackageManager.shared.isUsingSpecial(.webInfo)
    }
}

// MARK: - 一些定义
extension OpenFileRecord {
    /// 打开方式
    enum OpenType: String {
        case noPreload = "pull" // 非预加载 打开
        case preload = "render" //预加载 方式打开
    }

    /// 超时/取消时候，进行到了哪个阶段
    ///
    /// - afterLoadUrl: 已经开始 loadURL,还没开始pullData
    /// - afterPullData: 已经开始pull_data 阶段了，还没开始render_doc
    /// - afterRenderDoc: 已经开始render_doc 了，还没结束loading
    enum StageCode: Int {
        case afterLoadUrl = 100
        case afterPullData = 200
        case afterRenderDoc = 300
        case webviewTerminated = 301
        case afterFullPkgDownloaded = 400
    }

    /// 打开结束时的状态
    ///
    /// - cancel: 被用户取消了
    /// - overtime: 超时了
    /// - succ: 成功了
    /// - nativeFail: 本地原因，失败了
    enum FinishType: String {
        case cancel = "cancel"
        case overtime = "overtime"
        case succ = "other"
        case nativeFail = "nativeFail"
    }

    // https://docs.bytedance.net/doc/DbNLKWyxBSG1ZyWc6hZKvh
    /// 通知H5的各个时刻
    enum TimeStampKeyForH5: String {
        case clickUI = "tap"
        case preloadStart = "preloadStart"
        case webviewLoadUrl = "webviewLoadUrl"
        case preloadEnd = "preloadEnd"
        case invokeRender = "invokeRender"
    }

    /// 上报到后台时的字段
    enum ReportKey: String {
        case resultKey =  "docs_result_key"
        case resultCode =  "docs_result_code"
        case costTime =  "cost_time"
        case stage = "stage"
        case resultCostTimeCode = "max_cost_time_code"
    }

    // 预加载打开 (createui 可选) -> load_url -> pull_js -> pull_data -> render_doc
    // 非预加载打开（creteui 可选) -> load_url -> waitPreload -> pull_js -> pull_data -> render_doc
    /// 打开过程中的各个阶段
    public enum Stage: String {
        case openFinish         = "dev_performance_doc_open_finish" // 从点击文档，到文档加载结束（成功或者失败）
        case editorUICreate     = "create_ui"                       // 点击文档，加载native界面的耗时
        case loadUrl            = "load_url"                        // 一次loadUrl，对应着一次打开/reload。这个event的costtime没有意义
        case waitPreload        = "wait_preload"                    // 非预加载方式打开时，等待模板完成的时间
        case pullJS             = "pull_js"                         // 调用render函数，到pull_data起始的时间
        case pullData           = "pull_data"                       // 拉取文档数据环节
        case getNativeData      = "get_native_data"                 // 从本地取clientvar的时间(pull_data 的一部分)
        case renderDoc          = "render_doc"                      // 数据已ok，前端渲染的时间
        case renderCache        = "render_cache"                    // 前端告知我们，渲染缓存html已经成功了
        case readLocalClientVar      = "read_local_clientVar"       // render函数之前，读取clientVar的时间
        case readLocalHtmlCache      = "read_local_htmlCache"       // 模板加载好，读取htmlCache缓存的时间
        case renderFunc          = "render_func"                    // 从客户端调用render函数开始，到收到前端的回调结束
        case waitingFullPkgDownload = "waiting_full_pkg_download"   // 等待完整包下载
        case editDoc            = "edit_doc"                        // sheet可编辑
        case pullWikiInfo       = "pull_wiki_info"                  // Wiki文档拉取wikiInfo的环节
        case ssrWebView         = "ssr_webview"                     //独立SSRWebView加载耗时
    }
    
    enum VersionType: Int {
        case source     // 源文档
        case version    // 文档版本
    }
    
    // 上报不同来源
    enum VersionFromKey: String {
        case sourceDoc  = "from_version_source_doc"     // 源文档打开
        case fromLink   = "from_version_link"           // 通过链接打开
        case fromSwitch = "from_version_switch"         // 版本列表切换
    }
}

extension OpenFileRecord {
    private func getSignPostNameFrom(_ stageName: String) -> StaticString? {
        switch stageName {
        case Stage.editorUICreate.rawValue: return "create_ui"
        case Stage.pullJS.rawValue: return "pull_js"
        case Stage.pullData.rawValue: return "pull_data"
        case Stage.renderDoc.rawValue: return "render_doc"
        case Stage.renderCache.rawValue: return "render_cache"
        case Stage.openFinish.rawValue: return "openDoc"
        case Stage.readLocalClientVar.rawValue: return "read_local_clientVar"
        case Stage.readLocalHtmlCache.rawValue: return "read_local_htmlCache"
        case Stage.editDoc.rawValue: return "edit_doc"
        default: return nil
        }
    }

    private func beginSignPostFor(_ stageName: String) {
        #if DEBUG
        guard #available(iOS 12, *) else {
            return
        }
        guard let signPostName = getSignPostNameFrom(stageName) else {
            return
        }
        let signPostID = OSSignpostID(UInt64(sessionID) ?? 0)
        os_signpost(.begin, log: DocsSDK.openFileLog, name: signPostName, signpostID: signPostID)
        #endif
    }

    private func endSignPostFor(_ stageName: String) {
        #if DEBUG
        guard #available(iOS 12, *) else {
            return
        }
        guard let signPostName = getSignPostNameFrom(stageName) else {
            return
        }
        let signPostID = OSSignpostID(UInt64(sessionID) ?? 0)
        os_signpost(.end, log: DocsSDK.openFileLog, name: signPostName, signpostID: signPostID, "openType %s", openType?.rawValue ?? "unknown")
        #endif
    }
}

extension DocsInfo {
    var typeForStatistics: DocsType {
        return self.isFromWiki ? .wiki : type
    }
}
