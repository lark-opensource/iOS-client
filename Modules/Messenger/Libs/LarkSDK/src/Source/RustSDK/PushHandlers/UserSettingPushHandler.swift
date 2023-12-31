//
//  PushHandlers.swift
//  LarkSDK
//
//  Created by Li Yuguo on 2019/2/25.
//

import Foundation
import RustPB
import LarkContainer
import LarkSDKInterface
import LarkRustClient
import LKCommonsLogging

final class PushHandlers {
    static let logger = Logger.log(PushHandlers.self, category: "Rust.PushHandler")
}

final class UserSettingPushHandler: UserPushHandler {

    override class var compatibleMode: Bool { SDK.userScopeCompatibleMode }

    private var pushCenter: PushNotificationCenter? { try? userResolver.userPushCenter }

    func process(push message: RustPB.Settings_V1_PushUserSetting) {
        pushCenter?.post(message, replay: true)
        PushHandlers.logger.debug("Push badgeStyle: \(message.badgeStyle)")
    }
}
