//
//  SetupBGTask.swift
//  LarkBaseService
//
//  Created by KT on 2020/7/8.
//

import Foundation
import AppContainer
import BootManager
import LarkBGTaskScheduler
import LarkKAFeatureSwitch
import LarkAccountInterface
import LarkContainer
import LarkSetting
import LarkRustClient

final class SetupBGTask: FlowBootTask, Identifiable { //Global
    static var identify = "SetupBGTask"

    override var runOnlyOnce: Bool { return true }

    override func execute(_ context: BootContext) {
        // BGTask 只能在启动的时候注册，否则会crash
        guard !BootLoader.isDidFinishLaunchingFinished else { return }
        LarkBGTaskScheduler.shared.applicationDidLaunching()
    }
}

final class BGTaskSwitch: UserFlowBootTask, Identifiable {
    static var identify = "BGTaskSwitch"

    override func execute(_ context: BootContext) {
                // 如果为true则会转而执行finishFetchExperimentFromLibra
        if userResolver.fg.staticFeatureGatingValue(with: "tt_ab_test") { return }
        BGTaskSchedulerAccountDelegate().setEnableFromSetting(rustService: try? userResolver.resolve(assert: RustService.self))
    }
}
