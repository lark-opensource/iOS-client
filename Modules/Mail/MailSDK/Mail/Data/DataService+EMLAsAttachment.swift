//
//  DataService+EMLAsAttachment.swift
//  MailSDK
//
//  Created by tanghaojin on 2023/4/4.
//

import Foundation
import RustPB
import ServerPB
import RxSwift

extension DataService {
    func getEmlSizeRequest(bizIds: [String], uuid: String) -> Observable<ServerPB_Mails_BatchGetEMLSizeResponse> {
        var req = ServerPB_Mails_BatchGetEMLSizeRequest()
        req.messageBizIds = bizIds
        req.base = genRequestBase()
        req.uuid = uuid
        return sendPassThroughAsyncRequest(req,
                                           serCommand: .mailGetEmlSize).observeOn(MainScheduler.instance).map { (resp: ServerPB_Mails_BatchGetEMLSizeResponse) ->
            ServerPB_Mails_BatchGetEMLSizeResponse in
            return resp
        }
    }
    
    func uploadEmlAsAttachmentRequest(bizId: String, uuid: String) -> Observable<ServerPB_Mails_UploadEmlAsAttachmentResponse> {
        var req = ServerPB_Mails_UploadEmlAsAttachmentRequest()
        req.messageBizID = bizId
        req.uuid = uuid
        req.base = genRequestBase()
        return sendPassThroughAsyncRequest(req,
                                           serCommand: .mailUploadEmlAsAttachment).observeOn(MainScheduler.instance).map { (resp: ServerPB_Mails_UploadEmlAsAttachmentResponse) ->
            ServerPB_Mails_UploadEmlAsAttachmentResponse in
            return resp
        }
    }
    
    func cancelEmlAsAttachmentRequest(bizId: String, uuid: String) -> Observable<ServerPB_Mails_CancelUploadEmlAsAttachmentResponse> {
        var req = ServerPB_Mails_CancelUploadEmlAsAttachmentRequest()
        req.messageBizID = bizId
        req.uuid = uuid
        req.base = genRequestBase()
        return sendPassThroughAsyncRequest(req,
                                           serCommand: .mailCancelUploadEmlAsAttachment).observeOn(MainScheduler.instance).map { (resp: ServerPB_Mails_CancelUploadEmlAsAttachmentResponse) ->
            ServerPB_Mails_CancelUploadEmlAsAttachmentResponse in
            return resp
        }
    }
    
    func getThreadLastMessageInfoRequest(labelId: String, threadIds: [String]) -> Observable<Email_Client_V1_GetThreadLastMessageInfoResponse> {
        var req = Email_Client_V1_GetThreadLastMessageInfoRequest()
        req.labelID = labelId
        req.threadIds = threadIds
        return sendAsyncRequest(req).observeOn(MainScheduler.instance)
    }
    func getSmtpMessageId(bizIds: [String]) -> Observable<Email_Client_V1_MailGetSMTPMessageIdResponse> {
        var req = Email_Client_V1_MailGetSMTPMessageIdRequest()
        req.messageBizIds = bizIds
        return sendAsyncRequest(req)
    }
    func getCardMessageBizId(bizId: String, cardId: String, userId: String) -> Observable<Email_Client_V1_GetCardMsgBizIdResponse>{
        var req = Email_Client_V1_GetCardMsgBizIdRequest()
        req.bizID = bizId
        req.cardID = cardId
        req.ownerUserID = userId
        return sendAsyncRequest(req).observeOn(MainScheduler.instance)
    }
}
