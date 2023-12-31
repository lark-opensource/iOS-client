//
//  UnloginProcessHandlerTask.swift
//  LarkAccount
//
//  Created by KT on 2020/7/8.
//

import Foundation
import BootManager

class UnloginProcessHandlerTask: FlowBootTask, Identifiable { // user:checked (boottask)
    static var identify = "UnloginProcessHandlerTask"

    override func execute(_ context: BootContext) {
        AccountIntegrator.shared.processUnloginHandlerAfterLogin()
    }
}
