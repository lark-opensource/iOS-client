//
//  ExtensionLaunchTask.swift
//  Lark
//
//  Created by 王元洵 on 2020/10/19.
//  Copyright © 2020 Bytedance.Inc. All rights reserved.
//
import Foundation
import BootManager
import LarkReleaseConfig
import LarkSetting

final class ExtensionLaunchTask: UserFlowBootTask, Identifiable {
    static var identify = "ExtensionLaunchTask"

    override var runOnlyOnce: Bool { true }

    override var scheduler: Scheduler { return .async }

    override func execute(_ context: BootContext) {
        ExtensionLogCleaner.moveAndClean()
        ExtensionDomain.observePush(resolver: userResolver)
        ExtensionTrackPoster.post()
        ExtensionAppConfigs.saveAppConfig(userResolver: userResolver)
    }
}
