//
//  CallKitSetupTask.swift
//  ByteViewMod
//
//  Created by kiri on 2021/9/26.
//

import Foundation
import BootManager
#if LarkMod
import LarkPerf
#endif

final class CallKitSetupTask: UserFlowBootTask, Identifiable {
    static var identify: TaskIdentify = "ByteView.CallKitSetupTask"

    override func execute() throws {
        MonitorUtil.run("CallKitSetupTask") {
            #if LarkMod
            let isFastLogin = context.isFastLogin
            if isFastLogin { AppStartupMonitor.shared.start(key: .initCallKit) }
            #endif
            CallKitPassportDelegate.shared.start(userResolver: userResolver)
            #if LarkMod
            if isFastLogin { AppStartupMonitor.shared.end(key: .initCallKit) }
            #endif
        }
    }
}
