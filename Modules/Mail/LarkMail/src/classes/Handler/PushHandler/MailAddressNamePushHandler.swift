//
//  MailAddressNamePushHandler.swift
//  LarkMail
//
//  Created by 唐皓瑾 on 2022/12/15.
//

import Foundation
import RustPB
import LarkRustClient
import LarkContainer
import LarkSDKInterface
import LKCommonsLogging
import MailSDK

class MailAddressNamePushHandler: UserPushHandler {
    func process(push: MailAddressNamePush) throws {
        let push = MailAddressUpdatePushChange(response: push)
        PushDispatcher.shared.acceptMailAddressUpdateChangePush(push: push)
    }
}
