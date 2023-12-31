//
//  DynamicNetStatusPushHandler.swift
//  Lark
//
//  Created by Yuguo on 2018/12/6.
//  Copyright © 2018年 Bytedance.Inc. All rights reserved.
//

import Foundation
import RustPB
import LarkContainer
import LarkRustClient
import LKCommonsLogging
import LarkSDKInterface

final class DynamicNetStatusPushHandler: UserPushHandler {

    override class var compatibleMode: Bool { SDK.userScopeCompatibleMode }

    static var logger = Logger.log(DynamicNetStatusPushHandler.self, category: "Rust.PushHandler")

    private var pushCenter: PushNotificationCenter? { try? userResolver.userPushCenter }

    func process(push message: RustPB.Basic_V1_DynamicNetStatusResponse) {
        self.pushCenter?.post(PushDynamicNetStatus(dynamicNetStatus: message.netStatus), replay: true)
        DynamicNetStatusPushHandler.logger.info("dynamicNetStatus: \(message.netStatus)")
    }
}
