//
//  VoIPSetupBootTask.swift
//  ByteViewMod
//
//  Created by kiri on 2021/9/27.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//
import Foundation
import BootManager
import LarkPerf
import LKCommonsLogging
import LarkContainer

final class VoIPSetupBootTask: UserFlowBootTask, Identifiable {
    static var identify: TaskIdentify = "ByteView.VoIPSetupTask"

    override var scope: Set<BizScope> {
        [.vc]
    }

    override func execute() throws {
        let isFastLogin = context.isFastLogin
        if isFastLogin { AppStartupMonitor.shared.start(key: .voipSDK) }
        VoIPPassportDelegate.shared.executeBootTask(self.context, userResolver: userResolver)
        if isFastLogin { AppStartupMonitor.shared.end(key: .voipSDK) }
    }
}
