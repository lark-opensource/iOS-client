//
//  MyThreadsReplyPromptHandler.swift
//  LarkSDK
//
//  Created by 李勇 on 2020/10/19.
//

import Foundation
import RustPB
import LarkRustClient
import LarkContainer
import LarkModel
import LarkAccountInterface
import LarkSDKInterface

final class MyThreadsReplyPromptHandler: UserPushHandler {

    override class var compatibleMode: Bool { SDK.userScopeCompatibleMode }
    private var pushCenter: PushNotificationCenter? { try? userResolver.userPushCenter }

    @ScopedProvider var passportUserService: PassportUserService?

    func process(push message: Im_V1_PushMyThreadsReplyPrompt) {
        // 获取有几条@我的消息，按照时间增序排序，最后为最新的
        var newAtReplyMessages: [Message] = []
        message.newAtReplyIds.forEach { (id) in
            do {
                let message = try Message.transform(entity: message.entity, id: id, currentChatterID: passportUserService?.user.userID ?? "")
                newAtReplyMessages.append(message)
            } catch {
                RustThreadAPI.logger.error("getThreads miss newAtReplyId \(id)")
            }
        }

        self.pushCenter?.post(PushMyThreadsReplyPrompt(
                                groupId: message.groupID,
                                newReplyCount: message.newReplyCount,
                                newAtReplyMessages: newAtReplyMessages,
                                newAtReplyCount: message.newAtReplyCount))
    }
}
