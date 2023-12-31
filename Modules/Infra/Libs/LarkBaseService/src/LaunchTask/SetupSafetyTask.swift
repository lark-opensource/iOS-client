//
//  SetupSafetyTask.swift
//  LarkBaseService
//
//  Created by KT on 2020/7/28.
//

import Foundation
import BootManager
import LarkSafety

final class SetupSafetyTask: FlowBootTask, Identifiable { // Global
    static var identify = "SetupSafetyTask"

    override func execute(_ context: BootContext) {
        // 反调试
//        AntiDebug()
        // 反注入
        _dyld_register_func_for_add_image(AntiDylibInject)
    }
}
