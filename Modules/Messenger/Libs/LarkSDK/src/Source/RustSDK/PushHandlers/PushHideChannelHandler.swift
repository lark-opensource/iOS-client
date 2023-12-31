//
//  PushHideChannelHandler.swift
//  Lark
//
//  Created by lichen on 2018/5/8.
//  Copyright © 2018年 Bytedance.Inc. All rights reserved.
//

import Foundation
import RustPB
import LarkRustClient
import LarkContainer
import LarkSDKInterface

final class PushHideChannelHandler: UserPushHandler {

    override class var compatibleMode: Bool { SDK.userScopeCompatibleMode }
    private var pushCenter: PushNotificationCenter? { try? userResolver.userPushCenter }

    func process(push message: RustPB.Statistics_V1_PushHideChannelRequest) {
        self.pushCenter?.post(PushHideChannel(channelId: message.channel.id))
    }
}
