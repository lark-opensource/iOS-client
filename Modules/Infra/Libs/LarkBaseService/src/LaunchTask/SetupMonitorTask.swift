//
//  SetupMonitorTask.swift
//  LarkBaseService
//
//  Created by KT on 2020/7/1.
//

import Foundation
import BootManager
import AppContainer
import LarkAccountInterface
import LarkKAFeatureSwitch
import Heimdallr
import LKCommonsTracker
import Homeric
import LarkContainer

final class SetupMonitorTask: FlowBootTask, Identifiable { // Global
    static var identify = "SetupMonitorTask"

    override var runOnlyOnce: Bool { return true }

    override func execute(_ context: BootContext) {
        BootLoader.resolver(MonitorApplicationDelegate.self)?.setupMonitor()
        #if ALPHA
        //测试环境开启频繁打点监控
        let frequenceDetectParam = HMDFrequenceDetectParam()
        frequenceDetectParam.enabled = true
        frequenceDetectParam.duration = 1
        frequenceDetectParam.maxCount = 80
        frequenceDetectParam.reportInterval = 30
        HMDTTMonitor.setFrequenceDetectParam(frequenceDetectParam)
        #endif
        //启动1分钟单独统计FPS
        HMDFPSMonitor.shared().enterFluencyCustomScene(withUniq: "Lark.Start.1Min")
        DispatchQueue.main.asyncAfter(deadline: .now() + 60) {
            HMDFPSMonitor.shared().leaveFluencyCustomScene(withUniq: "Lark.Start.1Min")
        }
    }
}

final class UpdateMonitorTask: UserFlowBootTask, Identifiable {
    static var identify = "UpdateMonitorTask"

    override var scheduler: Scheduler { return .async }

    override func execute() throws {
        let monitor = try userResolver.resolve(assert: LarkMonitorDelegate.self)
        try monitor.updateMonitor(resolver: userResolver)
    }
}

final class SetupSlardarTask: FlowBootTask, Identifiable { // Global
    static var identify = "SetupSlardarTask"

    override var runOnlyOnce: Bool { return true }

    override func execute(_ context: BootContext) {
        MonitorApplicationDelegate.updateSlardarConfig(setup: true)
    }
}

final class StartTrafficOfLauncherTask: FlowBootTask, Identifiable { // Global
    static var identify = "StartTrafficOfLauncherTask"

    override var runOnlyOnce: Bool { return true }

    override func execute(_ context: BootContext) {
        HMDNetTrafficMonitor.shared().startCustomTrafficSpan(withSpanName: "lark_launch")
    }
}

final class SetupAlogTask: FlowBootTask, Identifiable { // Global
    static var identify = "SetupAlogTask"

    override var runOnlyOnce: Bool { return true }

    override var scheduler: Scheduler { return .async }

    override func execute(_ context: BootContext) {
        MonitorApplicationDelegate.setupAlog()
    }
}
