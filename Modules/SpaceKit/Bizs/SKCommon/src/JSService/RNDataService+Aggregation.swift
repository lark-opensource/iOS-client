//
//  RNDataService+Aggregation.swift
//  SKCommon
//
//  Created by lijuyou on 2022/11/11.
//
//  RN消息聚合逻辑
//  https://bytedance.sg.feishu.cn/docx/Mu0sdW2gwovGzUxEag7lripMgdg


import SKFoundation
import SKInfra

private let defaultDebounceTime = 3000
private let defaultRNAggregationInterval = 5000
private let defaultMaxAggregationSize = 100

extension RNDataService {
    func onChangeToFloatingWindow(isFloating: Bool) {
        guard let docsInfo = self.docsInfo else {
            return
        }
        DocsLogger.info("RNDataService ChangeFloatingWindow（\(self.editorIdentity)）:\(isFloating)")
        
        onAggregationStatusChange(isFloating)
        
        let body: [String: Any] = ["isFloating": isFloating,
                                   "docsType": docsInfo.inherentType.rawValue,
                    "token": docsInfo.token]
        let data: [String: Any] = ["operation": "vcfollow.floatingStatusChange", "body": body]
        RNManager.manager.sendSpaceBaseBusinessInfoToRN(data: data)
    }
    
    func onAggregationStatusChange(_ needAggregation: Bool) {
        guard let docsInfo = self.docsInfo, UserScopeNoChangeFG.LJY.enableRnAggregation else {
            return
        }
        if docsInfo.inherentType == .docX {
            if needAggregation {
                let debounceTime = SettingConfig.magicShareFloatingWinConfig?.debounceTime ?? defaultDebounceTime
                debouncer.debounce(.milliseconds(debounceTime)) {
                    self.startAggregationTimer() //短时间频繁大小窗debounce处理
                }
            } else {
                stopAggregationTimerIfNeed()
                sendAggregationCacheMsgToWebView() //MS切换到大窗时前清空一次消息
            }
        } else {
            stopAggregationTimerIfNeed()
        }
    }
    
    func startAggregationTimer() {
        stopAggregationTimerIfNeed()
        let canAggregation = model?.vcFollowDelegate?.isFloatingWindow == true || UIApplication.shared.applicationState == .background
        guard self.docsInfo?.inherentType == .docX, canAggregation else {
            DocsLogger.info("RNDataService try startTimer but shoule not intercept")
            return
        }
        let interval = SettingConfig.magicShareFloatingWinConfig?.rnAggregationInterval ?? defaultRNAggregationInterval
        DocsLogger.info("RNDataService startTimer...(\(interval))")
        let timer = Timer.scheduledTimer(withTimeInterval: TimeInterval(interval / 1000), repeats: true, block: { [weak self] _ in
            //定期发送消息
            DocsLogger.info("RNDataService time to send aggregation msg")
            self?.sendAggregationCacheMsgToWebView()
        })
        self.aggregationTimer = timer
        RunLoop.main.add(timer, forMode: .common)
    }
    
    func stopAggregationTimerIfNeed() {
        debouncer.endDebounce()
        guard self.aggregationTimer != nil else { return }
        DocsLogger.info("RNDataService stopTimer")
        self.aggregationTimer?.invalidate()
        self.aggregationTimer = nil
    }
    
    func sendAggregationCacheMsgToWebView() {
        guard let callback = rnToWebCallbackScript, !aggregationCache.isEmpty else {
            DocsLogger.info("RNDataService cacheMsg is empty(\(aggregationCache.count))")
            return
        }
        let scriptList = aggregationCache.map { buildAggregationScript(callback: callback, params: $0) }
        aggregationCache.removeAll()
        let chunkSize = SettingConfig.magicShareFloatingWinConfig?.maxAggregationSize ?? defaultMaxAggregationSize
        let chunkList = scriptList.chunked(into: chunkSize)
        var count = 0
        for chunk in chunkList {
            let script = chunk.joined(separator: ";")
            model?.jsEngine.evaluateJavaScript(script, completion: nil)
            count += chunk.count
            debugPrint("RNDataService srcipt:\(script)")
            DocsLogger.info("RNDataService sendRNCacheMsgToWebView (\(count)/\(scriptList.count))")
        }
        spaceAssert(count == scriptList.count)
    }
    
    
    var shouleInterceptMsg: Bool {
        guard UserScopeNoChangeFG.LJY.enableRnAggregation, self.aggregationTimer != nil else {
            return false
        }
        return true
    }
    
    var needAggregationInBackground: Bool {
        //进入后台也开启RN聚合策略，如果已经小窗则忽略，走小窗逻辑
        return UserScopeNoChangeFG.LJY.enableRnAggregation &&
        self.docsInfo?.inherentType == .docX &&
        self.isInVideoConference &&
        SettingConfig.magicShareFloatingWinConfig?.enableInAppBackground ?? true &&
        model?.vcFollowDelegate?.isFloatingWindow == false
    }
    
    func buildAggregationScript(callback: String, params: [String: Any]) -> String {
        let paramsStr = params.ext.toString()
        let script = "\(callback)(\(paramsStr ?? ""))"
        return script
    }
}
