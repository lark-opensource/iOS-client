//
//  LarkSafeModeTask.swift
//  LarkSafeMode
//
//  Created by luyz on 2022/11/4.
//

import Foundation
import BootManager
import Heimdallr
import LarkDebugExtensionPoint
import LarkReleaseConfig
import LarkStorage

public final class LarkSafeModeTask: BranchBootTask, Identifiable {
    public static var identify = "LarkSafeModeTask"
    public override var runOnlyOnce: Bool { return true }
    public override func execute(_ context: BootContext) {
        if LarkSafeMode.safeModeForemostEnable {
            return
        }
        HMDInjectedInfo.default().useURLSessionUpload = false
        LarkSafeMode.addApplicationTerminateObserver()

        if LarkSafeMode.checkwhetherEnterSafeMode() {
            self.flowCheckout(.safeModeFlow)
        } else {
            LarkSafeMode.normalProcess()
        }
        if self.needDebugItem() {
            DebugRegistry.registerDebugItem(SafeModeItem(), to: .debugTool)
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                BadAccessDebug.test()
                ExceptionDebug.test()
            }
        }
        // 将 UserDefaults(suiteName: LARKSAFEMODE) 纳入 LarkStorage 管控
        KVManager.shared.registerUnmanaged(.suiteName(LARKSAFEMODE))
    }

    private func needDebugItem() -> Bool {
        let appId = ReleaseConfig.appIdForAligned
        return ["1161", "462391"].contains(appId)
    }
}
