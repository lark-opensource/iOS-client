//
//  MailGroupMemberCountPushHandler.swift
//  LarkMail
//
//  Created by Ender on 2023/5/12.
//

import Foundation
import LarkRustClient
import RustPB
import MailSDK

final class MailGroupMemberCountPushHandler: UserPushHandler {
    func process(push: Email_Client_V1_MailGroupMemberCountPushResponse) throws {
        let message = MailGroupMemberCountPush(response: push)
        PushDispatcher.shared.acceptMailGroupMemberCountPush(push: message)
    }
}
