//
//  PinReadStatePushHandler.swift
//  LarkSDK
//
//  Created by 李晨 on 2018/12/20.
//

import Foundation
import RustPB
import LarkRustClient
import LarkContainer
import LarkSDKInterface

final class PinReadStatePushHandler: UserPushHandler {

    override class var compatibleMode: Bool { SDK.userScopeCompatibleMode }

    private var pushCenter: PushNotificationCenter? { try? userResolver.userPushCenter }

    func process(push message: RustPB.Im_V1_PushPinReadStatusResponse) {
        self.pushCenter?.post(PushChatPinReadStatus(chatId: String(message.chatID), hasRead: message.isRead))
    }
}
