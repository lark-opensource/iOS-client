//
//  SetupICloudTask.swift
//  LarkBaseService
//
//  Created by KT on 2020/7/1.
//

import Foundation
import BootManager
import LarkStorage

final class SetupICloudTask: FlowBootTask, Identifiable { // Global
    static var identify = "SetupICloudTask"

    override var scheduler: Scheduler { return .async }

    override var runOnlyOnce: Bool { return true }

    override func execute(_ context: BootContext) {
        // 设置用户目录忽略IiCloud备份
        SBUtil.addSkipBackupAttributeToAllUserFile()
    }
}
