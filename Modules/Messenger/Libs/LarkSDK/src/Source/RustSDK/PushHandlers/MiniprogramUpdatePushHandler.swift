//
//  MiniprogramUpdatePushHandler.swift
//  LarkSDK
//
//  Created by yinyuan on 2019/6/11.
//

import Foundation
import RustPB
import LarkRustClient
import LarkContainer
import LarkSDKInterface

import UIKit

final class MiniprogramUpdatePushHandler: UserPushHandler {

    override class var compatibleMode: Bool { SDK.userScopeCompatibleMode }

    private var pushCenter: PushNotificationCenter? { try? userResolver.userPushCenter }

    func process(push message: RustPB.Openplatform_V1_PushTenantMiniprogramNeedUpdateRequest) {
        guard message.hasCliID else {
            return
        }
        self.pushCenter?.post(PushMiniprogramNeedUpdate(client_id: message.cliID,
                                                       latency: Int(message.latency),
                                                       extra: message.extra),
                             replay: true)
    }
}
