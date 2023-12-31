//
//  WebBrowserView+KeepActive.swift
//  SKBrowser
//
//  Created by lijuyou on 2022/11/15.
//  


import SKFoundation
import SKCommon
import SKInfra

extension WebBrowserView: KeepActiveTimerOwner {
    public func startKeepActiveTimer() {
        stopKeepActiveTimer()
        guard self.isNormalThermalState else {
            DocsLogger.error("[KeepWebActive] cannot startTimer in wrong thermalState")
            return
        }
        let keepActiveTimeMS = SettingConfig.magicShareFloatingWinConfig?.keepWebviewActiveTime ?? 30000
        DocsLogger.info("[KeepWebActive] startTimer...(\(keepActiveTimeMS))")
        let timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true, block: { [weak self] _ in
            DocsLogger.info("[KeepWebActive] heartbeat ...")
            self?.webView.evaluateJavaScript("1+1")
        })
        self.keepWebViewActiveTimer = timer
        RunLoop.main.add(timer, forMode: .common)
        if keepActiveTimeMS > 0 {
            //只保活一段时间,0则一直保活
            let seconds = TimeInterval(keepActiveTimeMS / 1000)
            perform(#selector(keepActiveTimeUp), with: nil, afterDelay: seconds)
        }
    }
    
    @objc
    private func keepActiveTimeUp() {
        DocsLogger.info("[KeepWebActive] time up")
        stopKeepActiveTimer()
    }
    
    public func stopKeepActiveTimer() {
        guard self.keepWebViewActiveTimer != nil else { return }
        DocsLogger.info("[KeepWebActive] stopTimer")
        NSObject.cancelPreviousPerformRequests(withTarget: self,
                                               selector: #selector(keepActiveTimeUp),
                                               object: nil)
        self.keepWebViewActiveTimer?.invalidate()
        self.keepWebViewActiveTimer = nil
    }
    
    @objc
    func onThermalStateChange() {
        guard self.keepWebViewActiveTimer != nil else { return }
        if !isNormalThermalState {
            DocsLogger.error("[KeepWebActive] stopTimer with thermalState")
            stopKeepActiveTimer()
        }
    }
    
    private var isNormalThermalState: Bool {
        let monitorThermalState = SettingConfig.magicShareFloatingWinConfig?.monitorThermalState ?? false
        guard monitorThermalState else { return true }
        
        let thermalState = ProcessInfo.processInfo.thermalState
        debugPrint("[KeepWebActive] thermalState:\(thermalState.rawValue)")
        let disable = thermalState == .serious || thermalState == .critical
        return !disable
    }
}
