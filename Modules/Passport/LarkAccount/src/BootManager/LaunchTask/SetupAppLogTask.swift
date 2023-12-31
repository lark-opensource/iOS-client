//
//  SetupAppLogTask.swift
//  LarkAccount
//
//  Created by Yiming Qu on 2020/11/13.
//

import Foundation
import BootManager

class SetupAppLogTask: FlowBootTask, Identifiable { // user:checked (boottask)
    static var identify = "SetupAppLogTask"

    override var runOnlyOnce: Bool { return true }

    override func execute(_ context: BootContext) {
        AccountIntegrator.shared.setupAppLog()
    }
}
