//
//  StickersPushHandler.swift
//  Lark-Rust
//
//  Created by liuwanlin on 2017/12/29.
//  Copyright © 2017年 Bytedance.Inc. All rights reserved.
//

import Foundation
import RustPB
import LarkRustClient
import LarkSDKInterface
import LarkModel
import LarkContainer

final class StickersPushHandler: UserPushHandler {

    override class var compatibleMode: Bool { SDK.userScopeCompatibleMode }
    private var pushCenter: PushNotificationCenter? { try? userResolver.userPushCenter }

    func process(push message: RustPB.Im_V1_PushCustomizedStickersRequest) {
        self.pushCenter?.post(
            PushStickers(
                operation: message.operation,
                addDirection: message.addDirection,
                stickers: message.stickers,
                updateTime: message.updateTime
            )
        )
    }
}
