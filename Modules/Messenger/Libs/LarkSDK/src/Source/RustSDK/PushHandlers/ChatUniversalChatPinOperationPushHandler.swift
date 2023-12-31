//
//  ChatUniversalChatPinOperationPushHandler.swift
//  LarkSDK
//
//  Created by zhaojiachen on 2023/5/19.
//

import Foundation
import RustPB
import LarkRustClient
import LarkSDKInterface
import LarkContainer

final class ChatUniversalChatPinOperationPushHandler: UserPushHandler {

    override class var compatibleMode: Bool { SDK.userScopeCompatibleMode }
    private var pushCenter: PushNotificationCenter? { try? userResolver.userPushCenter }

    func process(push message: RustPB.Im_V1_PushUniversalChatPinOperation) {
        self.pushCenter?.post(PushUniversalChatPinOperation(push: message))
    }
}
