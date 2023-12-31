//
//  MailFeedFollowStatusPushHandler.swift
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

class MailFeedFollowStatusPushHandler: UserPushHandler {
    func process(push: MailFeedStatusPush) throws {
        let push = MailFeedFollowStatusChange(response: push)
        PushDispatcher.shared.acceptFollowStatusPush(push: push)
    }
}
