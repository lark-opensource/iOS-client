//
//  RNManager+Reload.swift
//  SpaceKit
//
//  Created by maxiao on 2019/10/17.
//

import SKFoundation
import SKInfra

extension RNManager {

    enum RNTrackerWebOpenState: Int {
        case foreground = 0
        case background
    }

    func checkFeatureGatingOpen() -> Bool {
        return true
    }

    func sendHeartbeatToRN() {
        let param = ["operation": "processRunning",
                     "body": ""]
        sendSpaceBaseBusinessInfoToRN(data: param)
    }

    func receiveRNConfirm() {
        DocsLogger.info("=====RN-收到RN回复，本次未超时！")
        NSObject.cancelPreviousPerformRequests(withTarget: self,
                                               selector: #selector(checkRNContactTimeout),
                                               object: nil)
    }

    func checkBackgroundOrForeGround() -> RNTrackerWebOpenState {
        if DocsContainer.shared.resolve(SKCommonDependency.self)!.currentEditorView != nil {
            return .foreground
        }
        return .background
    }

    @objc
    func checkRNContactTimeout() {
        DocsLogger.info("=====RN-检测到RN环境超时！当前web状态\(checkBackgroundOrForeGround())")
        if checkBackgroundOrForeGround() == .background {
            DocsLogger.info("=====RN-检测到RN环境超时，并不在web页面，开始重新reloadBundle！")
            reloadBundle { (result) in
                DocsLogger.info("=====RN-reload \(result == true ? "成功" : "失败")！")
            }
        }
        DocsTracker.log(enumEvent: .rnOutOfContact,
                        parameters: ["webview_open_state": checkBackgroundOrForeGround().rawValue,
                                     "scm_version": GeckoPackageManager.shared.currentVersion(type: .webInfo)])
    }

}

extension RNManager: DocTimerObserverProtocol {
    public var timeInterval: TimeInterval { return 60.0 }

    public func tiktok() {
        DocsLogger.info("tiktok=========RN-收到GlobalTimer心跳包，并发送心跳到RN！")
        sendHeartbeatToRN()
        perform(#selector(checkRNContactTimeout), with: nil, afterDelay: 15.0)
    }
}
