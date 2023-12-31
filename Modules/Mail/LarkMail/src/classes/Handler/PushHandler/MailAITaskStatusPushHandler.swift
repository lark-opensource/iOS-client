//
//  MailAITaskStatusPushHandler.swift
//  LarkMail
//
//  Created by 唐皓瑾 on 2023/6/8.
//

import Foundation
import RustPB
import LarkRustClient
import LarkContainer
import LarkSDKInterface
import LKCommonsLogging
import MailSDK

class MailAITaskStatusPushHandler: UserPushHandler {
    func process(push: MailAITaskStatusPush) throws {
        let push = MailAITaskStatusPushChange(response: push)
        PushDispatcher.shared.acceptMailAITaskStatusPush(push: push)
    }
}
