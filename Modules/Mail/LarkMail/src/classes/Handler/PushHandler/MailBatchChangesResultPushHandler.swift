//
//  MailBatchChangesResultPushHandler.swift
//  LarkMail
//
//  Created by 龙伟伟 on 2023/3/7.
//

import Foundation

import RustPB
import LarkRustClient
import LarkContainer
import LarkSDKInterface
import LKCommonsLogging
import MailSDK
import RxSwift

public typealias MailBatchResultScene = RustPB.Email_Client_V1_MailBatchChanges.Scene
public typealias MailBatchResultStatus = RustPB.Email_Client_V1_MailGetLongRunningTaskResponse.TaskStatus
public typealias MailBatchResultResponse = RustPB.Email_Client_V1_MailGetLongRunningTaskResponse

class MailBatchChangesResultPushHandler: UserPushHandler, AccountBasePushHandler {
    let logger = Logger.log(MailBatchChangesResultPushHandler.self, category: "Module.Mail")

    func process(push: RustPushPacket<MailBatchResultChangesPushResponse>) throws {
        guard checkAccount(push: push) else { return }
        let batchResultChange = MailBatchResultChange(sessionID: push.body.sessionID, scene: push.body.scene, status: push.body.task.taskStatus, totalCount: push.body.task.totalCount, progress: push.body.task.progress)
        logger.info("[mail_stranger] MailBatchChangesResultPushHandler - sessionID: \(push.body.sessionID) progress: \(push.body.task.progress)")
        PushDispatcher.shared.acceptMailBatchChangePush(push: .batchResultChange(batchResultChange))
    }
}
