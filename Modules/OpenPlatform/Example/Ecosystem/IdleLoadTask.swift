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
import LarkStorage

final class InitIdleLoadTask: FlowBootTask, Identifiable {

    override var runOnlyOnce: Bool { return true }

    static var identify: TaskIdentify = "IdleLoadTask"

    override func execute(_ context: BootContext) {
        LKLoadableManager.run(LKLoadable.runloopIdle)
        KVPublic.FG.lcMonitor.setValue(LarkFeatureGating.shared.getFeatureBoolValue(for: "com.lark.lcmonitor"))
    }
}
