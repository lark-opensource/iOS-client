//
//  SetupUATask.swift
//  LarkBaseService
//
//  Created by KT on 2020/7/1.
//

import Foundation
import LarkFoundation
import BootManager
import OPFoundation


class SetupUATask: FlowBootTask, Identifiable {
    static var identify = "SetupUATask"

    override var scope: Set<BizScope> { return [.specialLaunch, .openplatform, .docs] }

    override var runOnlyOnceInUserScope: Bool { return false }

    override func execute(_ context: BootContext) {
        UserDefaults.standard.register(defaults: [
            "UserAgent": Utils.userAgent,
            "User-Agent": Utils.userAgent
        ])
    }
}
