//
//  MailDownloadProressPushHandler.swift
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

class MailDownloadProressPushHandler: UserPushHandler, AccountBasePushHandler {
    static let logger = Logger.log(MailDownloadProressPushHandler.self, category: "MailDownloadProressPushHandler")
    func process(push: RustPushPacket<MailDownloadProgressPush>) throws {
        Self.logger.info("mail receive downloadProgress change")
        let body = push.body
        Self.logger.info("receive push needSaveMail \(body.needSaveInMail), accountID: \(body.accountID) bytesTotal \(body.driveCallback.bytesTotal), transfer \(body.driveCallback.bytesTransferred), status: \(body.driveCallback.status), filePath \(body.driveCallback.filePath)")
        let change = MailDownloadProgressPushChange(push: body)
        PushDispatcher.shared.acceptMailDownloadProgressPush(push: change)
    }
}
