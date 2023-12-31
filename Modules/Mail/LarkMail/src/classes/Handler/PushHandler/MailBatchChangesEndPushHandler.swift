//
//  MailBatchChangesEndPushHandler.swift
//  LarkMail
//
//  Created by 龙伟伟 on 2020/10/27.
//

import Foundation
import RustPB
import LarkRustClient
import LarkContainer
import LarkSDKInterface
import LKCommonsLogging
import MailSDK
import RxSwift

class MailBatchChangesEndPushHandler: UserPushHandler, AccountBasePushHandler {
    func process(push: RustPushPacket<MailBatchChangesEndPushResponse>) throws {
        guard checkAccount(push: push) else { return }
        let batchChange = MailBatchEndChange(sessionID: push.body.sessionID, action: push.body.action, code: push.body.code)
        PushDispatcher.shared.acceptMailBatchChangePush(push: .batchEndChange(batchChange))
    }
}

struct MailBatchChangesEndPush: PushMessage {
    let action: RustPB.Email_V1_MailBatchChangesEnd.Action
    let sessionID: String
    let code: Int32

    init(sessionID: String, action: RustPB.Email_V1_MailBatchChangesEnd.Action, code: Int32) {
        self.sessionID = sessionID
        self.action = action
        self.code = code
    }
}
