//
//  StickerSetsPushHandler.swift
//  LarkSDK
//
//  Created by 李晨 on 2019/8/12.
//

import Foundation
import RustPB
import LarkRustClient
import LarkContainer
import LarkSDKInterface
import LarkModel

final class StickerSetsPushHandler: UserPushHandler {

    override class var compatibleMode: Bool { SDK.userScopeCompatibleMode }
    private var pushCenter: PushNotificationCenter? { try? userResolver.userPushCenter }

    func process(push message: RustPB.Im_V1_PushStickerSetsRequest) {
        self.pushCenter?.post(
            PushStickerSets(
                operation: message.operation,
                stickerSets: message.stickerSets,
                updateTime: message.updateTime)
        )
    }
}
