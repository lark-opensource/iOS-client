//
//  PassportPreloadLaunchTask.swift
//  LarkAccount
//
//  Created by KT on 2020/7/28.
//

import Foundation
import BootManager

/// 子线程初始化登录依赖的Service
class PassportGetUserListTask: FlowBootTask, Identifiable { // user:checked (boottask)
    static var identify = "PassportGetUserListTask"
    //切换租户后也需要执行
    override var runOnlyOnceInUserScope: Bool { return true }

    override func execute(_ context: BootContext) {
        UserManager.shared.updateUserList()
    }
}
