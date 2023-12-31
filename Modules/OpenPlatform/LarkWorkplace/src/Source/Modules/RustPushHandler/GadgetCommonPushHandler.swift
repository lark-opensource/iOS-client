//
//  GadgetCommonPushHandler.swift
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

enum GadgetCommonPushBiz: String {
    case widget
    case workplace_recent
}

struct GadgetCommonPushMessage: PushMessage {
    let isOnline: Bool
    let biz: String
    let timestamp: String
    let data: String

    init(isOnline: Bool, biz: String, timestamp: String, data: String) {
        self.isOnline = isOnline
        self.biz = biz
        self.timestamp = timestamp
        self.data = data
    }
}

final class GadgetCommonPushHandler: UserPushHandler {
    static let logger = Logger.log(GadgetCommonPushHandler.self)

    func process(push message: RustPB.Openplatform_V1_CommonGadgetPushRequest) throws {
        Self.logger.info("received gadget common push", additionalData: [
            "isOnline": "\(message.isOnline)",
            "biz": message.biz,
            "timestamp": message.timestamp,
        ])
        let pushMessage = GadgetCommonPushMessage(
            isOnline: message.isOnline,
            biz: message.biz,
            timestamp: message.timestamp,
            data: message.data
        )
        try userResolver.userPushCenter.post(pushMessage)
    }
}
