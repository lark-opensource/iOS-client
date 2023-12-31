//
//  ChatWidgetsPushHandler.swift
//  LarkSDK
//
//  Created by zhaojiachen on 2023/1/9.
//

import Foundation
import RustPB
import LarkRustClient
import LarkSDKInterface
import LarkContainer
import LKCommonsLogging

final class ChatWidgetsPushHandler: UserPushHandler {

    override class var compatibleMode: Bool { SDK.userScopeCompatibleMode }
    static let logger = Logger.log(ChatWidgetsPushHandler.self, category: "Rust.PushHandler")
    private var pushCenter: PushNotificationCenter? { try? userResolver.userPushCenter }

    func process(push message: RustPB.Im_V1_PushChatWidgets) {
        self.pushCenter?.post(PushChatWidgets(push: message))
        Self.logger.info("receive pushChatWidgets \(message.widgets.count) version: \(message.version) chatId: \(message.chatID)")
    }
}
