//
//  PassportPreloadLaunchTask.swift
//  LarkAccount
//
//  Created by KT on 2020/7/28.
//

import Foundation
import BootManager

/// 子线程初始化登录依赖的Service
class PassportPreloadLaunchTask: FlowBootTask, Identifiable { // user:checked (boottask)
    static var identify = "PassportPreloadLaunchTask"

    override var runOnlyOnce: Bool { return true }

    override func execute(_ context: BootContext) {
        // 初始化登录相关服务
        NewBootManager.shared.addConcurrentTask {
            AccountIntegrator.shared.preload()
        }
    }
}
