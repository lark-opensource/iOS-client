//
//  LarkMessengerAssembleTask.swift
//  LarkMessenger
//
//  Created by sniperj on 2021/5/25.
//

import Foundation
import BootManager
import Swinject
import LarkFile
import LarkQRCode
import LarkCore
import LarkContact
import LarkFinance
import AppContainer
import LarkMine

final class LarkMessengerAssembleTask: UserFlowBootTask, Identifiable {
    static var identify = "LarkMessengerAssembleTask"
    override var runOnlyOnce: Bool { return true }
    override func execute(_ context: BootContext) {
        let container = BootLoader.container

        MineKeyCommandRegister.registerSettingKeyCommand(resolver: container)

        CoreAssembly().assembleShareContainer(resolver: container)
    }
}
