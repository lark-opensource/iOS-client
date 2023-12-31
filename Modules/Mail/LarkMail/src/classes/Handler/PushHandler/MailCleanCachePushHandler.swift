//
//  MailCleanCachePushHandler.swift
//  LarkMail
//
//  Created by ByteDance on 2023/8/22.
//

import Foundation
import RustPB
import LarkRustClient
import LarkContainer
import LarkSDKInterface
import LKCommonsLogging
import MailSDK

class MailCleanCachePushHandler: UserPushHandler, AccountBasePushHandler {
    static let logger = Logger.log(MailCleanCachePushHandler.self, category: "MailCleanCachePushHandler")

    func process(push: RustPushPacket<MailCleanCachePush>) throws {
        Self.logger.info("mail receive MailCleanCachePush change")
        let body = push.body
        Self.logger.info("receive push MailCleanCachePush accountID: \(body.accountID) tokenCount: \(body.tokens.count), cleanType: \(body.cleanType)")
        let change = MailCleanCachePushChange(cleanType: body.cleanType, tokens: body.tokens, accountID: body.accountID)
        PushDispatcher.shared.acceptMailCleanCachePush(push: change)
    }
}
