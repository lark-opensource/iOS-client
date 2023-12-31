//
//  MailSharedAccountChangePushHandler.swift
//  LarkMail
//
//  Created by majx on 2020/6/12.
//

import Foundation
import RustPB
import LarkRustClient
import LarkContainer
import LKCommonsLogging
import MailSDK

class MailSharedAccountChangePushHandler: UserPushHandler {
    func process(push: MailSharedAccountChangePushResponse) throws {
        let accountChange = MailSharedAccountChange(account: push.account,
                                                    isBind: push.isBind,
                                                    isCurrent: push.isCurrent,
                                                    fetchAccountList: push.fetchAccountList)
        PushDispatcher.shared.acceptMailAccountPush(push: .shareAccountChange(accountChange))
    }
}

struct MailSharedAccountChangePush: PushMessage {
    let account: Email_Client_V1_MailAccount
    let isBind: Bool
    let isCurrent: Bool
    let fetchAccountList: Bool

    init(account: Email_Client_V1_MailAccount, isBind: Bool, isCurrent: Bool, fetchAccountList: Bool) {
        self.account = account
        self.isBind = isBind
        self.isCurrent = isCurrent
        self.fetchAccountList = fetchAccountList
    }
}
