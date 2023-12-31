//
//  MailSyncEventPushHandler.swift
//  LarkMail
//
//  Created by 龙伟伟 on 2020/11/6.
//

import Foundation
import RustPB
import LarkRustClient
import LarkContainer
import MailSDK

class MailSyncEventPushHandler: UserPushHandler, AccountBasePushHandler {
    func process(push: RustPushPacket<MailSyncEventResponse>) throws {
        guard checkAccount(push: push) else { return }
        let syncEventChange = MailSyncEventChange(syncEvent: push.body.event)
        PushDispatcher.shared.acceptMailSyncEventPush(push: .syncEventChange(syncEventChange))
    }
}

struct MailSyncEventPush: PushMessage {
    let syncEvent: RustPB.Email_Client_V1_MailSyncEventResponse.SyncEvent

    init(syncEvent: RustPB.Email_Client_V1_MailSyncEventResponse.SyncEvent) {
        self.syncEvent = syncEvent
    }
}
