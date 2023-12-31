//
//  AddMeSettingPushHandler.swift
//  LarkSDK
//
//  Created by 姚启灏 on 2020/2/27.
//

import Foundation
import RustPB
import LarkRustClient
import LarkSDKInterface
import LKCommonsLogging

import LarkContainer

final class AddMeSettingPushHandler: UserPushHandler {

    override class var compatibleMode: Bool { SDK.userScopeCompatibleMode }
    static var logger = Logger.log(WebSocketStatusPushHandler.self, category: "Rust.PushHandler")

    private var pushCenter: PushNotificationCenter? { try? userResolver.userPushCenter }

    func process(push message: RustPB.Settings_V1_PushWayToAddMeSetting) {
        let pushMessage = PushWayToAddMeSettingMessage(addMeSetting: message.addMeSetting.contactTokenSetting)

        self.pushCenter?.post(pushMessage)
    }
}
