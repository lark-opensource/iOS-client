//
//  MiniprogramPreviewPushHandler.swift
//  LarkSDK
//
//  Created by yinyuan on 2019/10/28.
//

import Foundation
import RustPB
import LarkRustClient
import LarkContainer
import LarkSDKInterface

final class MiniprogramPreviewPushHandler: UserPushHandler {

    override class var compatibleMode: Bool { SDK.userScopeCompatibleMode }

    private var pushCenter: PushNotificationCenter? { try? userResolver.userPushCenter }

    func process(push message: RustPB.Openplatform_V1_PushMiniprogramPreviewRequest) {
        guard message.hasCliID else {
            return
        }
        self.pushCenter?.post(PushMiniprogramPreview(client_id: message.cliID,
                                                    url: message.url,
                                                    extra: message.extra,
                                                    timeStamp: message.timeStamp))
    }
}
