//
//  PrivacyMonitorColdLaunchTask.swift
//  LarkSecurityCompliance
//
//  Created by huanzhengjie on 2023/2/9.
//

import Foundation
import BootManager
import LarkPrivacyMonitor

/// Monitor设置冷启动结束状态
final class PrivacyMonitorColdLaunchTask: FlowBootTask, Identifiable { // Global
    static var identify: TaskIdentify = "PrivacyMonitorColdLaunchTask"

    override func execute(_ context: BootContext) {
        if MonitorSettingsManager.shared.monitorEnabled() {
            // 标注冷启动结束的状态
            PrivacyMonitor.shared.markHasShownFirstRender()
        }
    }

    override var runOnlyOnce: Bool {
        return true
    }
}
