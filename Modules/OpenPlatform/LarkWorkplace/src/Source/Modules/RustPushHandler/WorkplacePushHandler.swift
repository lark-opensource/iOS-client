//
//  WorkplacePushHandler.swift
//  LarkWorkplace
//
//  Created by Meng on 2023/5/12.
//

import Foundation
import LarkContainer
import LarkRustClient
import RustPB
import LarkSetting
import LarkOPInterface
import LKCommonsLogging

/// 工作台应用更新推送
struct WorkplacePushMessage: PushMessage {
    let timestamp: String

    init(timestamp: String) {
        self.timestamp = timestamp
    }
}

/// 工作台应用更新推送 Handler
final class WorkplacePushHandler: UserPushHandler {
    static let logger = Logger.log(WorkplacePushHandler.self)

    func process(push message: RustPB.Openplatform_V1_PushAppsNeedUpdateRequest) throws {
        Self.logger.info("received workplace status", additionalData: [
            "timestamp": message.timestamp
        ])
        let pushMessage = WorkplacePushMessage(timestamp: message.timestamp)
        try userResolver.userPushCenter.post(pushMessage)
    }
}
