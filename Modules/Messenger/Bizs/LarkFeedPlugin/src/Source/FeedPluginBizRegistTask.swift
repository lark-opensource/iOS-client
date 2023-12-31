//
//  FeedPluginBizRegistTask.swift
//  LarkFeedPlugin
//
//  Created by aslan on 2022/2/14.
//

import Foundation
import BootManager
import LarkContainer
import AppContainer
import LarkAccountInterface

final class FeedPluginBizRegistTask: FlowBootTask, Identifiable { // Global
    static var identify = "FeedPluginBizRegistTask"

    override var runOnlyOnce: Bool { return true }
    override var scheduler: Scheduler { return .main }

    @InjectedUnsafeLazy private var bizRegister: FeedPluginBizRegistService // Global

    override func execute(_ context: BootContext) {
        bizRegister.regist(container: BootLoader.container)
    }
}
