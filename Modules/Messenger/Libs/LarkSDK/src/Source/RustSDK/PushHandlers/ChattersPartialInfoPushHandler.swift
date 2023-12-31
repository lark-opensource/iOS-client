//
//  ChatStatusTipNotifyPushHandler.swift
//  LarkSDK
//
//  Created by 郭怡然 on 2023/1/31.
//

import Foundation
import RustPB
import LarkRustClient
import LarkSDKInterface
import LarkContainer

final class ChattersPartialInfoPushHandler: UserPushHandler {

    override class var compatibleMode: Bool { SDK.userScopeCompatibleMode }
    private var pushCenter: PushNotificationCenter? { try? userResolver.userPushCenter }

    func process(push message: RustPB.Contact_V1_PushChattersPartialInfo) {
        let userID = message.userID
        let updateStatusWithDesc = message.updateStatusWithDesc
        self.pushCenter?.post(PushChatStatusTipNotify(userID: userID, updateStatusWithDesc: updateStatusWithDesc))
    }
}
