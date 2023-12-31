//
//  ForceTouchTask.swift
//  LarkQRCode
//
//  Created by KT on 2020/7/2.
//

import Foundation
import BootManager
import AppContainer
final class NewForceTouchTask: UserFlowBootTask, Identifiable {
    static var identify = "ForceTouchTask"

    override func execute(_ context: BootContext) {
        BootLoader.resolver(ForceTouchApplicationDelegate.self)?.setup()
    }
}
