//
//  SetupLoggerTask.swift
//  LarkBaseService
//
//  Created by KT on 2020/7/1.
//

import Foundation
import BootManager
import RunloopTools
import ByteViewCommon

class SetupLoggerTask: FlowBootTask, Identifiable {
    static var identify = "ByteView.SetupLoggerTask"

    override var runOnlyOnce: Bool { return true }

    override func execute(_ context: BootContext) {
        AppLogger.setupLogger()
    }
}
