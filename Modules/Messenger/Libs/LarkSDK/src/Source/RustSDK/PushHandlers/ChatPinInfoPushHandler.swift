//
//  ChatPinInfoPushHandler.swift
//  LarkSDK
//
//  Created by Zigeng on 2023/7/26.
//

import Foundation
import RustPB
import LarkRustClient
import LarkSDKInterface
import LarkContainer

final class ChatPinInfoPushHandler: UserPushHandler {

    override class var compatibleMode: Bool { SDK.userScopeCompatibleMode }
    private var pushCenter: PushNotificationCenter? { try? userResolver.userPushCenter }

    func process(push message: RustPB.Im_V1_PushChatPinInfo) {
        self.pushCenter?.post(PushChatPinInfo(push: message))
    }
}
