//
//  MailChangePushHandler.swift
//  LarkMail
//
//  Created by Ryan on 2020/3/20.
//

import UIKit
import LarkRustClient
import LarkContainer
import LarkSDKInterface
import MailSDK
import LKCommonsLogging
import RustPB

typealias MailChangePushResponse = Email_V1_MailChangePushResponse
class MailChangePushHandler: UserPushHandler, AccountBasePushHandler {
    static let logger = Logger.log(MailChangePushHandler.self, category: "MailChangePushHandler")
    private var dispatcher: PushDispatcher {
        return PushDispatcher.shared
    }

    func process(push: RustPushPacket<MailChangePushResponse>) throws {
        guard checkAccount(push: push) else { return }
        var info = "MailChangePushHandler -> "
        if let change = push.body.change {
            switch change {
            case .threadChange(let change):
                info += "threadChange"
                self.dispatcher
                    .acceptMailChangePush(push: .threadChange(MailSDK.MailThreadChange(labelIds: change.labelIds,
                                                                                       threadId: change.threadID)))
            case .multiThreadsChange(let change):
                info += "multiThreadsChange"
                let label2Threads = change.label2Threads.mapValues { (threadIds: $0.threadIds, needReload:  $0.needReload) }
                let updateDelegation = change.source == .delegation
                self.dispatcher
                    .acceptMailChangePush(push: .multiThreadsChange(
                                            MailSDK.MailMultiThreadsChange(label2Threads: label2Threads,
                                                                           hasFilterThreads: change.hasFilterThreads_p,
                                                                          updateDelegation: updateDelegation)))
            case .updateLabelsChange(let change):
                info += "updateLabelsChange"
                self.dispatcher
                    .acceptMailChangePush(push: .updateLabelsChange((MailSDK.MailLabelChange(labels: change.labels))))
            case .labelPropertyChange(let change):
                info += "labelPropertyChange"
                self.dispatcher
                    .acceptMailChangePush(push: .labelPropertyChange(MailSDK.MailLabelPropertyChange(label: change.label,
                                                                                                     isDelete: change.isDelete)))
            case .cacheInvalidChange:
                info += "cacheInvalidChange"
                self.dispatcher
                    .acceptMailChangePush(push: .cacheInvalidChange(MailSDK.MailCacheInvalidChange()))
            case .refreshThreadChange(let change):
                info += "refreshThreadChange"
                self.dispatcher.acceptMailChangePush(push: .refreshThreadChange(MailSDK.MailRefreshLabelThreadsChange(labelIDs: change.labelIds)))
            case .mailMigrationChange(let change):
                info += "mailMigrationChange"
                self.dispatcher.acceptMailMigrationPush(push: .migrationChange(MailSDK.MailMigrationChange(stage: Int(change.stage),
                                                                                                           progressPct: Int(change.progressPct))))
            case .recalledChange(let change):
                info += "recalledChange"
                self.dispatcher
                    .acceptMailChangePush(push: .recalledChange(MailSDK.MailRecallChange(messageId: change.messageID)))
            case .recallDoneChange(let change):
                info += "recallDoneChange"
                self.dispatcher
                    .acceptMailChangePush(push: .recallDoneChange(MailSDK.MailRecallDoneChange(messageId: change.messageID, status: change.status)))
            case .draftChange(let change):
                info += "draftChange"
                self.dispatcher.acceptMailChangePush(push: .draftChange(MailSDK.MailDraftChange(draftId: change.draftID, action: change.action)))
            @unknown default:
                assertionFailure()
            }
            MailChangePushHandler.logger.info(info)
        }
    }
}

/// Mail recall change push
struct MailRecallChange: PushMessage {
    let messageId: String
    init(messageId: String) {
        self.messageId = messageId
    }
}

/// Mail recall done change push
struct MailRecallDoneChange: PushMessage {
    let messageId: String
    let status: Email_Client_V1_Message.RecallStatus

    init(messageId: String, status: Email_Client_V1_Message.RecallStatus) {
        self.messageId = messageId
        self.status = status
    }
}

/// MailMultiThreadsChange.
struct LarkMailMultiThreadsChange: PushMessage {
    var label2Threads: [String: (threadIds: [String], needReload: Bool)]
    var hasFilterThreads: Bool
    init(label2Threads: [String: (threadIds: [String], needReload: Bool)], hasFilterThreads: Bool) {
        self.label2Threads = label2Threads
        self.hasFilterThreads = hasFilterThreads
    }
}
