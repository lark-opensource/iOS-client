//
//  SetupDispatcherTask.swift
//  LarkAccountDev
//
//  Created by Miaoqi Wang on 2020/9/25.
//

import Foundation
import BootManager
import RunloopTools

/// 触发到 afterFirstRender 和 idle 拉取 FG 等
class SetupDispatcherTask: FlowLaunchTask, Identifiable {
    static var identify = "SetupDispatcherTask"

    override func execute(_ context: BootContext) {
        RunloopDispatcher.enable = true

        RunloopDispatcher.shared.addTask(
            priority: .required,
            scope: .user,
            identify: "afterFirstRender") {
                print("trigger afterFirstRender")
            BootManager.shared.trigger(with: .afterFirstRender, contextID: context.contextID)
        }

        RunloopDispatcher.shared.addTask(
            priority: .required,
            scope: .user,
            identify: "idle") {
                print("trigger idle")
            BootManager.shared.trigger(with: .idle, contextID: context.contextID)
        }.waitCPUFree()
    }
}
