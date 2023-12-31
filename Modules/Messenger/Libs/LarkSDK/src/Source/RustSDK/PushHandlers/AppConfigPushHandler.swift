//
//  AppConfigPushHandler.swift
//  LarkSDK
//
//  Created by 李勇 on 2019/6/14.
//

import Foundation
import RustPB
import LarkRustClient
import LarkSDKInterface

import LarkContainer

/// AppConfig Push
final class AppConfigPushHandler: UserPushHandler {

    override class var compatibleMode: Bool { SDK.userScopeCompatibleMode }
    private var pushCenter: PushNotificationCenter? { try? userResolver.userPushCenter }

    func process(push message: RustPB.Basic_V1_AppConfig) {
        self.pushCenter?.post(PushAppConfig(appConfig: message))
    }
}
