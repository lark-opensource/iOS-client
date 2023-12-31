//
//  WidgetLaunchTask.swift
//  LarkWidget
//
//  Created by ZhangHongyun on 2020/12/3.
//

import Foundation
import UIKit
import BootManager

/// App 启动任务
final class WidgetDataLaunchTask: FlowBootTask, Identifiable {

    static var identify = "WidgetDataLaunchTask"

    override var scheduler: Scheduler { return .main }

    override func execute(_ context: BootContext) {
        LarkWidgetService.share.applicationDidLaunch()
        LarkWidgetService.share.observeAppLanguageChange()
    }
}

/// 历史遗留问题，留一个空的 LaunchTask，已废弃
final class WidgetLaunchTask: FlowBootTask, Identifiable {
    static var identify = "WidgetLaunchTask"

    override var scheduler: Scheduler { return .main }

    override func execute(_ context: BootContext) {
    }
}
