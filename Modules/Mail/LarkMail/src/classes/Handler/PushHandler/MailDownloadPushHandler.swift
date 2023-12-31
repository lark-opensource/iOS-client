//
//  MailDownloadPushHandler.swift
//  LarkMail
//
//  Created by 龙伟伟 on 2021/11/4.
//

import Foundation
import RustPB
import LarkRustClient
import LarkContainer
import LarkSDKInterface
import LKCommonsLogging
import MailSDK

class MailDownloadPushHandler: UserPushHandler {
    func process(push: MailDownloadPushResponse) throws {
        var change = MailDownloadPushChange(status: push.status, key: push.key)
        change.transferSize = push.transferSize
        change.totalSize = push.totalSize
        change.path = push.filePath
        change.failedInfo = push.failInfo
        PushDispatcher.shared.acceptMailDownloadChangePush(push: .downloadPushChange(change))
    }
}
