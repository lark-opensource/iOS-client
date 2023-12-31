//
//  ChatMenuItemsPushHandler.swift
//  LarkSDK
//
//  Created by zhaojiachen on 2022/9/12.
//

import Foundation
import RustPB
import LarkRustClient
import LarkSDKInterface
import LarkContainer
import LKCommonsLogging

final class ChatMenuItemsPushHandler: UserPushHandler {

    override class var compatibleMode: Bool { SDK.userScopeCompatibleMode }
    static let logger = Logger.log(ChatMenuItemsPushHandler.self, category: "Rust.PushHandler")
    private var pushCenter: PushNotificationCenter? { try? userResolver.userPushCenter }

    func process(push message: RustPB.Im_V1_PushChatMenuItems) {
        self.pushCenter?.post(PushChatMenuItems(version: message.version,
                                               chatId: message.chatID,
                                               menuItems: message.menuItems))
        Self.logger.info("receive pushChatMenuItems \(message.menuItems.count) version: \(message.version) chatId: \(message.chatID)")
    }
}
