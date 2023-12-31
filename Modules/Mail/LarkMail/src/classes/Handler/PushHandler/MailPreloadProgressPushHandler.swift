//
//  MailPreloadProgressPushHandler.swift
//  LarkMail
//
//  Created by 龙伟伟 on 2023/4/13.
//

import Foundation
import LarkRustClient
import LarkContainer
import LarkSDKInterface
import MailSDK
import LKCommonsLogging
import RustPB

typealias MailPreloadProgressPushResponse = Email_Client_V1_MailPreloadProgressPushResponse
class MailPreloadProgressPushHandler: UserPushHandler, AccountBasePushHandler {
    static let logger = Logger.log(MailChangePushHandler.self, category: "MailPreloadProgressPushHandler")
    private var dispatcher: PushDispatcher {
        return PushDispatcher.shared
    }

    func process(push: RustPushPacket<MailPreloadProgressPushResponse>) throws {
        guard checkAccount(push: push) else { return }
        let change = MailPreloadProgressPushChange(response: push.body)
        PushDispatcher.shared.acceptMailPreloadProgressChangePush(push: change)
    }
}
