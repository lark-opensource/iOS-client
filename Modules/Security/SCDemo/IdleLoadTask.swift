//
//  IdleLoadTask.swift
//  SCDemo
//
//  Created by qingchun on 2022/9/15.
//

import Foundation
import LKLoadable
import BootManager
import LarkFeatureGating
import LarkStorage
import UniverseDesignTheme

final class InitIdleLoadTask: FlowBootTask, Identifiable { //Global

    override var runOnlyOnce: Bool { return true }

    static var identify: TaskIdentify = "IdleLoadTask"

    override func execute(_ context: BootContext) {
        LKLoadableManager.run(LKLoadable.runloopIdle)
        KVPublic.FG.lcMonitor.setValue(LarkFeatureGating.shared.getFeatureBoolValue(for: "com.lark.lcmonitor")) // Global
        KVPublic.FG.evilMethodOpen.setValue(LarkFeatureGating.shared.getFeatureBoolValue(for: "lark.evil.method.open")) // Global
        KVPublic.FG.uitrackerOptimizationEnable.setValue(LarkFeatureGating.shared.getFeatureBoolValue(for: "lark.heimdallr.uitracker.optimization.enable")) // Global

        if #available(iOS 13.0, *) {
            UDThemeManager.setUserInterfaceStyle(.unspecified)
        }
    }
}
