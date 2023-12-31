//
//  ChatTopNoticePushHandler.swift
//  LarkSDK
//
//  Created by liluobin on 2021/11/8.
//
import Foundation
import RustPB
import LarkRustClient
import LarkSDKInterface
import LarkContainer

final class ChatTopNoticePushHandler: UserPushHandler {

    override class var compatibleMode: Bool { SDK.userScopeCompatibleMode }
    private var pushCenter: PushNotificationCenter? { try? userResolver.userPushCenter }

    func process(push message: RustPB.Im_V1_PushChatTopNoticeInfo) {
        self.pushCenter?.post(PushChatTopNotice(chatId: message.chatID,
                                               info: message.topNoticeInfo))
    }
}
