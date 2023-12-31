//
//  SetupRustTask.swift
//  LarkAccount
//
//  Created by KT on 2020/7/3.
//

import Foundation
import BootManager
import LarkContainer
import LarkRustClient

final class SetupRustTask: UserFlowBootTask, Identifiable {
    static var identify = "SetupRustTask"
    override func execute(_ context: BootContext) {
        @Injected var client: LarkRustClient
        client.loginFinish(userID: userResolver.userID)
    }
}
