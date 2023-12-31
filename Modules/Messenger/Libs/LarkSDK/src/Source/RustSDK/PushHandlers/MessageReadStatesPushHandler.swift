//
//  MessageReadStatesPushHandler.swift
//  LarkSDK
//
//  Created by 赵家琛 on 2020/7/20.
//

import Foundation
import RustPB
import LarkRustClient
import LarkContainer
import LarkSDKInterface

final class MessageReadStatesPushHandler: UserPushHandler {

    override class var compatibleMode: Bool { SDK.userScopeCompatibleMode }
    private var pushCenter: PushNotificationCenter? { try? userResolver.userPushCenter }

    func process(push message: RustPB.Im_V1_PushMessageReadStates) {
        self.pushCenter?.post(PushMessageReadStates(messageReadStates: message))
    }
}
