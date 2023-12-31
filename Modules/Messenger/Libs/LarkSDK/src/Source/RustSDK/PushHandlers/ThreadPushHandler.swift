//
//  ThreadPushHandler.swift
//  LarkSDK
//
//  Created by zc09v on 2019/2/14.
//

import Foundation
import RustPB
import LarkRustClient
import LarkContainer
import LarkModel
import LarkSDKInterface
import LarkAccountInterface

final class ThreadPushHandler: UserPushHandler {

    override class var compatibleMode: Bool { SDK.userScopeCompatibleMode }
    private var pushCenter: PushNotificationCenter? { try? userResolver.userPushCenter }
    private var currentChatterId: String { (try? userResolver.resolve(assert: PassportUserService.self))?.user.userID ?? "" }

    func process(push message: RustPB.Basic_V1_Entity) {
        let threads: [RustPB.Basic_V1_Thread] = message.threads.compactMap { (_, thread) -> RustPB.Basic_V1_Thread in
            return thread
        }

        var pushThreadMessages: [ThreadMessage] = []
        // 普通群中话题模式根消息
        var pushThreadModeRootMessages: [Message] = []
        for thread in threads {
            let rootMessage = try? LarkModel.Message.transform(
                entity: message,
                id: thread.id,
                currentChatterID: currentChatterId
            )
            // 如果普通群里的话题模式消息
            if let rootMessage = rootMessage, rootMessage.threadMessageType != .unknownThreadMessage {
                pushThreadModeRootMessages.append(rootMessage)
                continue
            }

            guard let rootMsg = rootMessage else { continue }

            let replyMessages = try? ThreadMessage.transformReplyMessages(
                entity: message,
                currentChatterID: currentChatterId,
                replyIds: thread.lastReplyIds
            )
            let latestAtMessages = try? ThreadMessage.transformLatestAtMessages(
                entity: message,
                currentChatterID: currentChatterId,
                latestAtIds: thread.latestAtMessageID
            )

            let threadMessage = ThreadMessage(
                thread: thread,
                rootMessage: rootMsg,
                replyMessages: replyMessages ?? [],
                latestAtMessages: latestAtMessages ?? []
            )
            pushThreadMessages.append(threadMessage)
        }

        self.pushCenter?.post(PushThreadMessages(messages: pushThreadMessages))
        self.pushCenter?.post(PushThreads(threads: threads))
        self.pushCenter?.post(PushChannelMessages(messages: pushThreadModeRootMessages))
    }
}
