//
//  AccountInterruptLauncherTask.swift
//  LarkAccount
//
//  Created by Miaoqi Wang on 2021/3/23.
//

import Foundation
import BootManager
import LarkContainer

class AccountInterrupstHandlerTask: FlowBootTask, Identifiable { // user:checked (boottask)
    static var identify = "AccountInterrupstHandlerTask"

    override func execute(_ context: BootContext) {
        AccountIntegrator.shared.registerLogoutInterrupt()
    }
}
