//
//  LarkMainAssemblyTask.swift
//  LarkAccountDev
//
//  Created by Yiming Qu on 2020/11/16.
//

import Foundation
import BootManager

class LarkMainAssembly: FlowLaunchTask, Identifiable {
    static var identify = "LarkMainAssembly"

    override var runOnlyOnce: Bool { return true }

    override func execute(_ context: BootContext) {
        // 占位不需要做事情
    }
}
