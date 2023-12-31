//
//  File.swift
//  LarkSafeMode
//
//  Created by luyz on 2022/11/4.
//

import Foundation
import BootManager
import Heimdallr
import LarkDebugExtensionPoint
import LarkReleaseConfig
import LarkAccountInterface

public final class LarkSafeModeForemostTask: BranchBootTask, Identifiable {
    public static var identify = "LarkSafeModeForemostTask"
    public override var runOnlyOnce: Bool { return true }
    public override func execute(_ context: BootContext) {
        LarkSafeModeHook.exitBinding()

        if !LarkSafeMode.safeModeForemostEnable {
            return
        }
        HMDInjectedInfo.default().useURLSessionUpload = true
        HMDInjectedInfo.default().appID = ReleaseConfig.appId
        HMDInjectedInfo.default().deviceID = AccountServiceAdapter.shared.deviceService.deviceId
        LarkSafeMode.addApplicationTerminateObserver()

        if LarkSafeMode.checkwhetherEnterSafeMode() {
            self.flowCheckout(.safeModeFlow)
        } else {
            LarkSafeMode.normalProcessForemost()
        }
        if self.needDebugItem() {
            DebugRegistry.registerDebugItem(SafeModeItem(), to: .debugTool)
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                BadAccessDebug.test()
                ExceptionDebug.test()
            }
        }
    }

    private func needDebugItem() -> Bool {
        let appId = ReleaseConfig.appIdForAligned
        return ["1161", "462391"].contains(appId)
    }
}
