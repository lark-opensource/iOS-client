//
//  SilentModeTask.swift
//  LarkBaseService
//
//  Created by aslan on 2022/9/15.
//

import Foundation
import BootManager
import AppContainer

final class SilentModeTask: FlowBootTask, Identifiable { // Global
    static var identify = "SilentModeTask"

    override var runOnlyOnce: Bool { return true }

    override var scheduler: Scheduler { return .async }

    override func execute(_ context: BootContext) {
        let delegate = BootLoader.resolver(SilentModeApplicationDelegate.self)
        delegate?.trackSilentMode()
    }
}
