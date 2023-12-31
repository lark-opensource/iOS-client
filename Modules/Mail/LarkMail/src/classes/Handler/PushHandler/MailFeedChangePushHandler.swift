//
//  MailFeedChangePUshHandler.swift
//  LarkMail
//
//  Created by ByteDance on 2023/9/22.
//

import Foundation
import RustPB
import LarkRustClient
import LarkContainer
import LarkSDKInterface
import LKCommonsLogging
import MailSDK

class MailFeedChangePushHandler: UserPushHandler {
    func process(push: MailFeedPush) throws {
        let push = MailFeedFromChange(response: push)
        PushDispatcher.shared.acceptFeedChangePush(push: push)
    }
}
