//
//  PushChannelNicknameHandler.swift
//  Action
//
//  Created by kongkaikai on 2018/11/12.
//

import Foundation
import RustPB
import LarkRustClient
import LarkContainer
import LarkSDKInterface

import LKCommonsLogging

final class PushChannelNicknameHandler: UserPushHandler {

    override class var compatibleMode: Bool { SDK.userScopeCompatibleMode }
    private var pushCenter: PushNotificationCenter? { try? userResolver.userPushCenter }

    func process(push message: RustPB.Contact_V1_PushChannelNickname) {
        self.pushCenter?.post(
            PushChannelNickname(
                chatterId: message.userID,
                channelId: message.channel.id,
                channerType: message.channel.type,
                newNickname: message.nickname
            )
        )
    }
}
