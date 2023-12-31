//
//  LogoutPreviousInstallUserTask.swift
//  LarkAccount
//
//  Created by au on 2021/12/6.
//

import Foundation
import BootManager

/// 详细逻辑见 ReinstallAppCleanHelper 文档注释
class LogoutPreviousInstallUserTask: FlowBootTask, Identifiable { // user:checked (boottask)

    static var identify = "LogoutPreviousInstallUserTask"

    override var runOnlyOnce: Bool { return true }

    override func execute(_ context: BootContext) {        
        ReinstallAppCleanHelper.logoutPreviousInstallUserIfNeeded()
    }
}
