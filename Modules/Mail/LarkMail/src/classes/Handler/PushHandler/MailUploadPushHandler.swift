//
//  MailUploadPushHandler.swift
//  LarkMail
//
//  Created by 龙伟伟 on 2021/11/16.
//

import Foundation
import RustPB
import LarkRustClient
import LarkContainer
import LarkSDKInterface
import LKCommonsLogging
import MailSDK

class MailUploadPushHandler: UserPushHandler {
    static let logger = Logger.log(MailUploadPushHandler.self, category: "MailUploadPushHandler")

    func process(push: MailUploadPushResponse) throws {
        MailUploadPushHandler.logger.info("mail receive uploadPush change")
        var change = MailUploadPushChange(status: push.status, key: push.key, token: push.token)
        change.transferSize = push.transferSize
        change.totalSize = push.totalSize
        PushDispatcher.shared.acceptMailUploadChangePush(push: .uploadPushChange(change))
    }
}
