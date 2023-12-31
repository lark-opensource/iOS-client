//
//  OfflineUpdatedChatsPushHandler.swift
//  LarkSDK
//
//  Created by zc09v on 2019/8/20.
//

import Foundation
import RustPB
import LarkRustClient
import LarkContainer
import LarkSDKInterface
import LKCommonsLogging
import LarkModel

final class OfflineUpdatedChatsPushHandler: UserPushHandler {

    override class var compatibleMode: Bool { SDK.userScopeCompatibleMode }
    private var pushCenter: PushNotificationCenter? { try? userResolver.userPushCenter }
    static var logger = Logger.log(OfflineUpdatedChatsPushHandler.self, category: "Rust.PushHandler")

    func process(push message: RustPB.Im_V1_PushOfflineUpdatedChats) {
        let chats = RustAggregatorTransformer.transformToChatsMap(
            fromEntity: message.entity)
            .compactMap { (_, chat) -> LarkModel.Chat in
                return chat
            }
        let threads = message.entity.threads
            .compactMap { (_, thread) -> RustPB.Basic_V1_Thread in
                return thread
            }
        for chat in chats {
            pushCenter?.post(PushChat(chat: chat))
            Self.logger.info("chatTrace receive pushofflineUpdate \(chat.id) \(chat.badge) \(chat.displayInThreadMode)")
        }
        pushCenter?.post(PushThreads(threads: threads))
        pushCenter?.post(PushOfflineChats(chats: chats))
        pushCenter?.post(PushOfflineThreads(threads: threads))
    }
}
