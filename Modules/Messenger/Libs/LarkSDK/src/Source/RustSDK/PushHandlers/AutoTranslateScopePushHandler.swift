//
//  AutoTranslateScopePushHandler.swift
//  LarkSDK
//
//  Created by 李勇 on 2019/9/27.
//

import Foundation
import RustPB
import LarkContainer
import LarkRustClient
import LarkModel
import LarkSDKInterface

/// 部分翻译设置数据
final class AutoTranslateScopePushHandler: UserPushHandler {

    override class var compatibleMode: Bool { SDK.userScopeCompatibleMode }
    private var pushCenter: PushNotificationCenter? { try? userResolver.userPushCenter }

    func process(push message: RustPB.Im_V1_PushAutoTranslateScopeNotify) {
        let autoTranslateScope = PushAutoTranslateScope(translateScope: message.scopes)
        self.pushCenter?.post(autoTranslateScope)
    }
}
