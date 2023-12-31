//
//  SuiteLoginLoggerTask.swift
//  LarkAccount
//
//  Created by KT on 2020/7/1.
//

import Foundation
import BootManager

class SuiteLoginLoggerTask: FlowBootTask, Identifiable { // user:checked (boottask)
    static var identify = "SuiteLoginLoggerTask"

    override var runOnlyOnce: Bool { return true }

    override func execute(_ context: BootContext) {
        AccountIntegrator.shared.setupLogger()
    }
}
