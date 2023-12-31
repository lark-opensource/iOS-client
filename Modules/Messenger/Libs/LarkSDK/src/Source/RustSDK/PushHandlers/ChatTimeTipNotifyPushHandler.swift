//
//  ChatTimeTipNotifyPushHandler.swift
//  LarkSDK
//
//  Created by 赵家琛 on 2020/2/11.
//

import Foundation
import RustPB
import LarkRustClient
import LarkSDKInterface
import LarkContainer

final class ChatTimeTipNotifyPushHandler: UserPushHandler {

    override class var compatibleMode: Bool { SDK.userScopeCompatibleMode }
    private var pushCenter: PushNotificationCenter? { try? userResolver.userPushCenter }

    func process(push message: RustPB.Im_V1_PushChatTimeTipNotify) {
        let chatId = message.chatID
        let copyWriting = message.copyWriting
        let status = message.status
        self.pushCenter?.post(PushChatTimeTipNotify(chatId: chatId,
                                                   copyWriting: copyWriting,
                                                   chatTimezone: message.chatUserTime,
                                                   myTimezone: message.externalDisplayTime,
                                                   myTimezoneType: message.externalDisplayTimezoneType,
                                                   status: status))
    }
}
