//
//  SetupMainTabTask.swift
//  LarkAccountDev
//
//  Created by Miaoqi Wang on 2020/9/23.
//

import UIKit
import BootManager
import LarkUIKit

/// 主界面 Task
class SetupDemoMainTabTask: FlowLaunchTask, Identifiable {
    static var identify = "SetupMainTabTask"
    override func execute(_ context: BootContext) {
        context.window?.rootViewController = LkNavigationController(
            rootViewController: MainViewController()
        )
    }
}
