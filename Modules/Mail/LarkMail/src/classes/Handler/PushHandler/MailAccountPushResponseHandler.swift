//
//  MailAccountPushResponseHandler.swift
//  LarkSDK
//
//  Created by majunxiao on 2020/09/08.
//

import RustPB
import LarkRustClient
import LarkContainer
import LarkSDKInterface
import LKCommonsLogging
import MailSDK

class MailAccountPushResponseHandler: UserPushHandler {
    static let logger = Logger.log(MailChangePushHandler.self, category: "MailAccountPushResponseHandler")

    func process(push: MailAccountPushResponse) throws {
        MailAccountPushResponseHandler.logger.info("mail account change")
        PushDispatcher.shared
            .acceptMailAccountPush(push: .accountChange(MailSDK.MailAccountChange(account: push.account,
                                                                                  fromLocal: push.rustPush)))
    }
}

struct MailAccountChangePush: PushMessage {
    let account: Email_Client_V1_MailAccount
    let fromLocal: Bool
}
