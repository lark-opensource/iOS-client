//
//  SetupURLProtocolTask.swift
//  LarkBaseService
//
//  Created by KT on 2020/7/1.
//

import Foundation
import BootManager
import AppContainer

final class SetupURLProtocolTask: FlowBootTask, Identifiable { // Global
    static var identify = "SetupURLProtocolTask"

    override var runOnlyOnce: Bool { return true }

    override func execute(_ context: BootContext) {
        URLProtocolIntegration.shared.setup()
    }
}
