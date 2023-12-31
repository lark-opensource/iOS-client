//
//  MailIMAPMigrationStatePushHandler.swift
//  LarkMail
//
//  Created by ByteDance on 2023/9/19.
//

import Foundation
import RustPB
import LarkRustClient
import LarkContainer
import LarkSDKInterface
import LKCommonsLogging
import MailSDK

class MailIMAPMigrationStatePushHandler: UserPushHandler, AccountBasePushHandler {
    static let logger = Logger.log(MailChangePushHandler.self, category: "MailIMAPMigrationStatePushHandler")
    private var dispatcher: PushDispatcher {
        return PushDispatcher.shared
    }

    func process(push: RustPushPacket<Email_Client_V1_MailIMAPMigrationStatePushResponse>) throws {
        guard checkAccount(push: push) else { return }
        let change = MailIMAPMigrationStateChange(response: push.body)
        Self.logger.info("[mail_client] [imap_migration] did push change migrationID: \(push.body.state.migrationID) status \(push.body.state.status), imapProvider: \(push.body.state.imapProvider), messageID: \(push.body.state.reportMessageID)")
        PushDispatcher.shared.acceptIMAPMigrationStatePush(push: change)
    }
}

