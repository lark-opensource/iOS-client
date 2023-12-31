//
//  MsgActionPlusMenuCommonPushHandler.swift
//  LarkOpenPlatform
//
//  Created by ByteDance on 2023/11/10.
//

import Foundation
import LarkRustClient
import RustPB
import LKCommonsLogging

final class MsgActionPlusMenuCommonPushHandler: UserPushHandler {
    private static let logger = Logger.oplog(MsgActionPlusMenuCommonPushHandler.self, category: MessageActionPlusMenuDefines.messageActionLogCategory)
    
    func process(push message: RustPB.Openplatform_V1_CommonGadgetPushRequest) throws {
        Self.logger.info("msg action plus menu common push")
        NotificationCenter.default.post(name: NSNotification.Name("gadget.common.push"),
                                        object: nil,
                                        userInfo: ["message": message])
    }
}
