//
//  HeartBeatTask.swift
//  LarkBaseService
//
//  Created by aslan on 2022/9/19.
//

import Foundation
import BootManager
import AppContainer

final class HeartBeatTask: UserFlowBootTask, Identifiable {
    static var identify = "HeartBeatTask"

    override var runOnlyOnce: Bool { return false }

    override var scheduler: Scheduler { return .async }

    override func execute(_ context: BootContext) {
        let delegate = BootLoader.resolver(HeartBeatApplicationDelegate.self)
        delegate?.triggerFocusV2Event()
    }
}
