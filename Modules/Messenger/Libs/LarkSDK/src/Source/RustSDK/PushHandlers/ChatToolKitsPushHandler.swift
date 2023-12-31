//
//  ChatToolKitsPushHandler.swift
//  LarkSDK
//
//  Created by JackZhao on 2022/6/24.
//

import RustPB
import Foundation
import LarkContainer
import LarkRustClient
import LarkSDKInterface

final class ChatToolKitsPushHandler: UserPushHandler {

    override class var compatibleMode: Bool { SDK.userScopeCompatibleMode }

    private var pushCenter: PushNotificationCenter? { try? userResolver.userPushCenter }

    func process(push message: RustPB.Im_V1_PushChatToolkitsResponse) {
        self.pushCenter?.post(PushChatToolKits(toolKits: message.toolkits))
    }
}
