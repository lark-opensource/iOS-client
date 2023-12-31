//
//  ResourceSetupTask.swift
//  LarkBaseService
//
//  Created by 李晨 on 2020/7/16.
//

import Foundation
import AppContainer
import BootManager
import LarkResource

final class ResourceSetupTask: FlowBootTask, Identifiable { // Global
    static var identify = "ResourceSetupTask"

    override var runOnlyOnce: Bool { return true }

    override var scheduler: Scheduler { .concurrent }

    override func execute(_ context: BootContext) {
        /// 初始化资源
        ResourceManager.setupResourceModule()
    }
}
