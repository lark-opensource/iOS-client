//
//  WorkplaceBeforeLoginTask.swift
//  LarkWorkplace
//
//  Created by Meng on 2022/5/18.
//

import Foundation
import BootManager
import LarkContainer
import LarkRustClient
import RustPB
import AppContainer
import LKCommonsLogging

/// 工作台登陆前任务, runOnlyOnce = true, app 生命周期执行一次
final class WorkplaceBeforeLoginTask: FlowBootTask, Identifiable {
    static let logger = Logger.log(WorkplaceBeforeLoginTask.self)

    static var identify: TaskIdentify = "WorkplaceBeforeLoginTask"

    override var runOnlyOnce: Bool { return true }

    override func execute(_ context: BootContext) {
        Self.logger.info("start workplace before login task")
        SimpleRustClient.global.registerPushHandler(factories: [
            Command.pushDynamicNetStatus: { RustNetStatusPushHandler() }
        ])
    }
}
