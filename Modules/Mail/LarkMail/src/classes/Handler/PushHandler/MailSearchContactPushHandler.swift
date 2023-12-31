//
//  MailSearchContactPushHandler.swift
//  LarkMail
//
//  Created by Quanze Gao on 2022/6/29.
//

import Foundation
import LarkRustClient
import RustPB
import MailSDK

final class MailSearchContactPushHandler: UserPushHandler {

    func process(push: Email_Client_V1_MailContactSearchResponse) throws {
        let message = MailSearchContactPushChange(response: push)
        PushDispatcher.shared.acceptMailSearchContactChangePush(push: message)
    }
}
