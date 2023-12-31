//
//  SetupLoggerTask.swift
//  LarkBaseService
//
//  Created by KT on 2020/7/1.
//

import Foundation
import BootManager

final class SetupLoggerTask: FlowBootTask, Identifiable { // Global
    static var identify = "SetupLoggerTask"

    override var runOnlyOnce: Bool { return true }

    override func execute(_ context: BootContext) {
        LarkLogger.setup()
    }
}
