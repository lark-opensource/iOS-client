//
//  saveToSpaceStorePushHandler.swift
//  Lark
//
//  Created by chengzhipeng-bytedance on 2018/2/5.
//  Copyright © 2018年 Bytedance.Inc. All rights reserved.
//

import Foundation
import UIKit
import RustPB
import LarkRustClient
import LarkContainer
import LarkSDKInterface

final class SaveToSpaceStorePushHandler: UserPushHandler {

    override class var compatibleMode: Bool { SDK.userScopeCompatibleMode }
    private var pushCenter: PushNotificationCenter? { try? userResolver.userPushCenter }

    func process(push message: PushSaveToSpaceStoreStateResponse) {
        self.pushCenter?.post(
            PushSaveToSpaceStoreState(
                messageId: message.messageID,
                state: PushSaveToSpaceStoreState.SaveState(rawValue: message.state.rawValue) ?? .failed,
                sourceType: message.sourceType,
                sourceID: message.sourceID
            )
        )

    }
}
