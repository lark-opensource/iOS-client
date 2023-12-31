//
//  ThemeSetupTask.swift
//  LarkBaseService
//
//  Created by 李晨 on 2020/7/16.
//

import Foundation
import AppContainer
import BootManager
import LarkUIExtension

final class ThemeSetupTask: FlowBootTask, Identifiable { // Global
    static var identify = "ThemeSetupTask"

    override var runOnlyOnce: Bool { return true }

    override func execute(_ context: BootContext) {
        /// 初始化皮肤
        ThemeManager.setupIfNeeded()
    }
}
