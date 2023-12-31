//
//  TodoSetupTask.swift
//  Lark
//
//  Created by 张威 on 2021/5/26.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import LarkContainer
import BootManager
import AppContainer
import Todo

class TodoSetupTask: UserFlowBootTask, Identifiable {
    static var identify = "TodoSetupTask"

    override var scope: Set<BizScope> { return [.todo] }

    override func execute(_ context: BootContext) {
    }
}
