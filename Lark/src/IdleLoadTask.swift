//
//  IdleLoadTask.swift
//  BootManager
//
//  Created by sniperj on 2021/5/19.
//

import Foundation
import LKLoadable
import BootManager
import LarkFeatureGating
import LarkPrivacyMonitor
import LarkSensitivityControl
import LarkSecurityCompliance
import LarkDowngrade
import LarkSetting
import LarkStorage
import LKCommonsTracker

final class InitIdleLoadTask: FlowBootTask, Identifiable {

    override var runOnlyOnce: Bool { return true }

    static var identify: TaskIdentify = "IdleLoadTask"

    override func execute(_ context: BootContext) {
        LKLoadableManager.run(LKLoadable.runloopIdle)
        var hitFeedABTest: Bool = false
        if let abEnable = Tracker.experimentValue(key: "iOSEnableFeedOptimize", shouldExposure: true) as? Int, abEnable == 1 {
            hitFeedABTest = true
        }
        KVPublic.FG.enableFetchFeed.setValue(hitFeedABTest)
        KVPublic.FG.lcMonitor.setValue(LarkFeatureGating.shared.getFeatureBoolValue(for: "com.lark.lcmonitor"))
        KVPublic.FG.evilMethodOpen.setValue(LarkFeatureGating.shared.getFeatureBoolValue(for: "lark.evil.method.open"))
        KVPublic.FG.uitrackerOptimizationEnable.setValue(LarkFeatureGating.shared.getFeatureBoolValue(for: "lark.heimdallr.uitracker.optimization.enable"))
        //lite
        KVPublic.FG.coldStartLiteEnable.setValue(LarkFeatureGating.shared.getFeatureBoolValue(for: "lark.ios.cold.start.lite.enable"))
        //机型评分
        let deviceClassify = try? SettingManager.shared.setting(with: .make(userKeyLiteral: "get_device_classify"))
        let deviceScore = deviceClassify?["cur_device_score"] as? Double
        KVPublic.Common.deviceScore.setValue(deviceScore)
        //启动CPU数据上报
        KVPublic.FG.startCpuReportEnable.setValue(FeatureGatingManager.shared.featureGatingValue(with: FeatureGatingManager.Key(stringLiteral: "lark.ios.start.cpu.report.enable")))
        MonitorSettingsManager.shared.updateMonitorConfigFromSetting()
        SensitivityManager.shared.loadRemoteData()
        //空跑验证稳定性 后续删除
        //静态降级
        LarkDowngradeService.shared.Downgrade(key: "startup") { _ in
        } doNormal: { _ in
        }
        //动态降级
        LarkDowngradeService.shared.addObserver(key: "startup",
                                                indexes: [.overCPU]) { _ in
        } doCancel: { _ in
        } doNormal: { _ in
        }
    }
}
