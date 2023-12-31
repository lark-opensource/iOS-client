//
//  RustMailAPI.swift
//  LarkMail
//
//  Created by 谭志远 on 2019/5/19.
//  Copyright © 2019年 Bytedance.Inc. All rights reserved.
//

import Foundation
import RustPB
import RxSwift
import LarkSDKInterface
import LarkModel
import LKCommonsLogging
import LarkAccountInterface

final class RustMailAPI: LarkAPI, MailAPI {
    static let logger = Logger.log(RustMailAPI.self, category: "RustSDK.Mail")
    static var log = RustMailAPI.logger

    // MARK: @liutefeng 暂时没有需要暴露Mail给其他模块。如果有需要的。在此处添加。
    func mailSendCard(threadId: String, messageIds: [String], chatIds: [String], note: String) -> Observable<()> {
        var request = Email_V1_MailSendCardRequest()
        request.threadID = threadId
        request.messageIds = messageIds
        request.chatIds = chatIds
        if !note.isEmpty {
            request.addNote = note
        }
        return self.client.sendAsyncRequest(request) { (_: Email_V1_MailSendCardResponse) -> Void in
            return ()
        }
    }
    func mailShareAttachment(chatIds: [String], attachmentToken: String, note: String, isLargeAttachment: Bool) -> Observable<()> {
        var request = Email_Client_V1_MailShareAttachmentRequest()
        request.chatIds = chatIds
        request.attachmentToken = attachmentToken
        request.isLargeAttachment = isLargeAttachment
        if !note.isEmpty {
            request.addNote = note
        }
        return self.client.sendAsyncRequest(request).subscribeOn(scheduler)
    }
}
