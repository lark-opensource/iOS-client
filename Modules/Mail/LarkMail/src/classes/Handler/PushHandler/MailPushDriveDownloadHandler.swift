//
//  MailPushDriveDownloadHandler.swift
//  LarkMail
//
//  Created by Quanze Gao on 2022/11/22.
//

import Foundation
import LarkRustClient
import LarkContainer
import RustPB
import MailSDK

class MailPushDriveDownloadHandler: UserPushHandler {
    func process(push: Space_Drive_V1_PushDownloadCallback) throws {
        NotificationCenter.default.post(name: Notification.Name.Mail.MAIL_DOWNLOAD_DRIVE_IMAGE, object: push)
    }
}


