//
//  MailMixedSearchPushHandler.swift
//  LarkMail
//
//  Created by 龙伟伟 on 2022/4/15.
//

import Foundation
import RustPB
import LarkRustClient
import LarkContainer
import LarkSDKInterface
import LKCommonsLogging
import MailSDK

class MailMixedSearchPushHandler: UserPushHandler {
    func process(push: MailMixedSearchPushResponse) throws {
        var change = MailMixSearchPushChange(state: push.state, searchSession: push.searchSession,
                                             begin: push.begin, count: push.count)
        PushDispatcher.shared.acceptMailMixSearchChangePush(push: .mixSearchPushChange(change))
    }
}
