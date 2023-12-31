//
//  ChatTabsPushHandler.swift
//  LarkSDK
//
//  Created by zhaojiachen on 2022/3/17.
//

import Foundation
import RustPB
import LarkRustClient
import LarkSDKInterface
import LarkContainer
import LKCommonsLogging

final class ChatTabsPushHandler: UserPushHandler {

    override class var compatibleMode: Bool { SDK.userScopeCompatibleMode }
    static let logger = Logger.log(ChatTabsPushHandler.self, category: "Rust.PushHandler")
    private var pushCenter: PushNotificationCenter? { try? userResolver.userPushCenter }

    func process(push message: RustPB.Im_V1_PushChatTabs) {
        self.pushCenter?.post(PushChatTabs(version: message.version,
                                          chatId: message.chatID,
                                          tabs: message.tabs))
        Self.logger.info("receive pushChatTabs \(message.tabs.count) version: \(message.version) chatId: \(message.chatID)")
    }
}
