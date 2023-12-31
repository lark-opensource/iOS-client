//
//  ChatPinCountPushHandler.swift
//  LarkSDK
//
//  Created by zhaojiachen on 2022/6/20.
//

import Foundation
import RustPB
import LarkRustClient
import LarkSDKInterface
import LarkContainer

final class ChatPinCountPushHandler: UserPushHandler {

    override class var compatibleMode: Bool { SDK.userScopeCompatibleMode }
    private var pushCenter: PushNotificationCenter? { try? userResolver.userPushCenter }

    func process(push message: RustPB.Im_V1_PushChatPinCountResponse) {
        self.pushCenter?.post(PushChatPinCount(chatId: message.chatID, count: message.count))
    }
}
