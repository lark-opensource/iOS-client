//
//  PassportFirstRenderTask.swift
//  LarkAccount
//
//  Created by au on 2022/12/14.
//

import Foundation
import BootManager
import LarkContainer
import ECOProbeMeta

class PassportFirstRenderTask: FlowBootTask, Identifiable { // user:checked (boottask)

    static var identify = "PassportFirstRenderTask"

    override var runOnlyOnce: Bool { return true }

    @Provider var launcher: Launcher

    override func execute(_ context: BootContext) {
        /// 详细逻辑见 ReinstallAppCleanHelper 文档注释
        ReinstallAppCleanHelper.migrateFromSharedGroupToPrivateIfNeeded()
    }
}
