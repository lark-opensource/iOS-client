//
//  KAUpgradeLaunchTask.swift
//  LarkVersion
//
//  Created by 王元洵 on 2022/11/21.
//

import Foundation
import BootManager

/// 启动任务，启动后CPU空闲阶段上报升级埋点
final class KAUpgradeLaunchTask: UserFlowBootTask, Identifiable {
    override class var compatibleMode: Bool { Version.userScopeCompatibleMode }

    static let identify = "KAUpgradeLaunchTask"

    override var runOnlyOnce: Bool { true }

    override var scheduler: Scheduler { .async }

    override func execute(_ context: BootContext) { UpgradeTracker.trackKAUpgrade() }
}
