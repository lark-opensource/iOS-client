//
//  SettingBundleTask.swift
//  LarkSettingsBundle
//
//  Created by KT on 2020/7/1.
//

import Foundation
import BootManager
import LKCommonsLogging
import AppContainer

final class SettingBundleTask: FlowBootTask, Identifiable {
    static var identify = "SettingBundleTask"

    static let logger = Logger.log(SettingBundleTask.self, category: "Module.SettingsBundle")

    override func execute(_ context: BootContext) {
        // Currently, all reset task excute when did finish launch.
        // May support specify time point for each reset task in the future
        SettingsBundle.loadPreferenceIfNeed()

        if SettingsBundle.needResetCache() {
            SettingBundleTask.logger.info("start reset")
            ResetTaskManager.reset(complete: {
                SettingBundleTask.logger.info("reset complete")
            })
            SettingsBundle.setNeedResetCache(false)
        }
    }
}
