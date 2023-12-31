//
//  FeedBizRegistTask.swift
//  LarkFeed
//
//  Created by aslan on 2022/2/14.
//

import Foundation
import BootManager
import LarkContainer
import AppContainer

final class FeedBizRegistTask: FlowBootTask, Identifiable { // Global
    static var identify = "FeedBizRegistTask"

    override var runOnlyOnce: Bool { return true }
    override var scheduler: Scheduler { return .main }

    @InjectedSafeLazy private var bizRegister: FeedBizRegisterService // Global

    override func execute(_ context: BootContext) {
        bizRegister.regist(container: BootLoader.container)
    }
}
