//
//  MessageFeedbackStatusPushHandler.swift
//  LarkSDK
//
//  Created by 李勇 on 2023/6/21.
//

import Foundation
import RustPB
import LarkRustClient
import LarkContainer
import LarkSDKInterface
import LarkModel

final class MessageFeedbackStatusPushHandler: UserPushHandler {
    override class var compatibleMode: Bool { SDK.userScopeCompatibleMode }
    private var pushCenter: PushNotificationCenter? { try? userResolver.userPushCenter }

    func process(push message: Im_V1_PushAIMessagesLikeFeedback) {
        self.pushCenter?.post(PushMessageFeedbackStatus(chatId: message.chatID, messageFeedbackStatus: message.aiLikeFeedback as? [Int64: Basic_V1_Message.AIMessageLikeFeedbackStatus] ?? [:]))
    }
}
