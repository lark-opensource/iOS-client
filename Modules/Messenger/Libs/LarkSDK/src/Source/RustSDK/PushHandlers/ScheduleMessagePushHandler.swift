//
//  ScheduleMessagePushHandler.swift
//  LarkSDK
//
//  Created by JackZhao on 2022/9/2.
//

import RustPB
import Foundation
import LarkContainer
import LarkRustClient
import LarkSDKInterface

final class ScheduleMessagePushHandler: UserPushHandler {

    override class var compatibleMode: Bool { SDK.userScopeCompatibleMode }

    private var pushCenter: PushNotificationCenter? { try? userResolver.userPushCenter }

    func process(push message: RustPB.Im_V1_PushScheduleMessage) {
        self.pushCenter?.post(PushScheduleMessage(messageItems: message.messageItems, entity: message.entity))
    }
}
