//
//  DataService+mailAction.swift
//  MailSDK
//
//  Created by tefeng liu on 2020/4/20.
//

import Foundation
import RustPB
import RxSwift
import Homeric
import LarkLocalizations

extension DataService {
    /// 移动到收件箱
    func moveToInbox(threadID: String, fromLabelID: String) -> Observable<Email_Client_V1_MailMutMultiLabelResponse> {
        return multiMutLabelForThread(threadIds: [threadID], addLabelIds: [Mail_LabelId_Inbox], removeLabelIds: [], fromLabelID: fromLabelID)
    }

    func moveToOther(threadID: String, fromLabelID: String) -> Observable<Email_Client_V1_MailMutMultiLabelResponse> {
        return multiMutLabelForThread(threadIds: [threadID], addLabelIds: [Mail_LabelId_Other], removeLabelIds: [], fromLabelID: fromLabelID)
    }

    func updateOutboxMail(threadId: String?,
                          messageId: String?,
                          action: Email_Client_V1_MailUpdateOutboxActionRequest.OutboxAction) -> Observable<(threadId: String?, messageId: String?)> {
        var request = Email_Client_V1_MailUpdateOutboxActionRequest()
        request.threadID = threadId ?? ""
        request.messageID = messageId ?? ""
        request.outboxAction = action
        return sendAsyncRequest(request, transform: {( response: Email_Client_V1_MailUpdateOutboxActionResponse) in
            DataService.logger.debug(
                "updateOutboxAction suc: threadID = \(threadId ?? "") messageID = \(messageId ?? ""), type: \(action)"
            )
            return (response.threadID, response.replyToMailID)
        }).observeOn(MainScheduler.instance)
    }

    func report(threadID: String, messageID: String, fromLabelID: String, addLabelIDs: [String], ignoreUnauthorized: Bool, feedCardId: String? = nil) -> Observable<Email_Client_V1_MailMutMultiLabelResponse> {
        return multiMutLabelForThread(threadIds: [threadID], messageIds: [messageID], addLabelIds: addLabelIDs, removeLabelIds: [], fromLabelID: fromLabelID, feedCardId: feedCardId, ignoreUnauthorized: ignoreUnauthorized, reportType: .spam)
    }

    func trust(threadID: String, messageID: String, fromLabelID: String, ignoreUnauthorized: Bool, feedCardId: String? = nil) -> Observable<Email_Client_V1_MailMutMultiLabelResponse> {
        return multiMutLabelForThread(threadIds: [threadID], messageIds: [messageID], addLabelIds: [Mail_LabelId_Inbox], removeLabelIds: [], fromLabelID: fromLabelID, feedCardId: feedCardId, ignoreUnauthorized: ignoreUnauthorized, reportType: .ham)
    }

    func closeSafetyBanner(threadID: String, messageID: String, fromLabelID: String, feedCardId: String? = nil) -> Observable<Email_Client_V1_MailMutMultiLabelResponse> {
        return multiMutLabelForThread(threadIds: [threadID], messageIds: [messageID], addLabelIds: [], removeLabelIds: [], fromLabelID: fromLabelID, feedCardId: feedCardId, reportType: .closed)
    }

    func unread(threadID: String, fromLabelID: String) -> Observable<Email_Client_V1_MailMutMultiLabelResponse> {
        return updateThreadReadStatus(threadID: threadID, fromlabel: fromLabelID, read: false)
    }

    func read(threadID: String, fromLabelID: String) -> Observable<Email_Client_V1_MailMutMultiLabelResponse> {
        return updateThreadReadStatus(threadID: threadID, fromlabel: fromLabelID, read: true)
    }

    func archive(threadID: String, fromLabelID: String) -> Observable<Email_Client_V1_MailMutMultiLabelResponse> {
        return multiMutLabelForThread(threadIds: [threadID], addLabelIds: [Mail_LabelId_Archived], removeLabelIds: [], fromLabelID: fromLabelID)
    }

    func trash(threadID: String, fromLabelID: String, feedCardId: String? = nil) -> Observable<Email_Client_V1_MailMutMultiLabelResponse> {
        MailLogger.error("multiMutLabelForThread request for thread: \(threadID) from: \(fromLabelID)")
        return multiMutLabelForThread(threadIds: [threadID], addLabelIds: [Mail_LabelId_Trash], removeLabelIds: [], fromLabelID: fromLabelID, feedCardId: feedCardId)
    }

    func trashMessage(messageIds: [String], threadID: String, fromLabelID: String, feedCardId: String? = nil) -> Observable<Email_Client_V1_MailMutMultiLabelResponse> {
        multiMutLabelForThread(threadIds: [threadID], messageIds: messageIds, addLabelIds: [Mail_LabelId_Trash], removeLabelIds: [], fromLabelID: fromLabelID, feedCardId: feedCardId)
    }
    
    func spam(threadID: String, fromLabelID: String, ignoreUnauthorized: Bool, feedCardId: String? = nil) -> Observable<Email_Client_V1_MailMutMultiLabelResponse> {
        return multiMutLabelForThread(threadIds: [threadID], addLabelIds: [Mail_LabelId_Spam], removeLabelIds: [], fromLabelID: fromLabelID, feedCardId: feedCardId, ignoreUnauthorized: ignoreUnauthorized, reportType: .spam)
    }

    func notSpam(threadID: String, fromLabelID: String, ignoreUnauthorized: Bool) -> Observable<Email_Client_V1_MailMutMultiLabelResponse> {
        if fromLabelID == Mail_LabelId_SEARCH_TRASH_AND_SPAM {
            return multiMutLabelForThread(threadIds: [threadID], addLabelIds: [Mail_LabelId_Inbox], removeLabelIds: [Mail_LabelId_Trash], fromLabelID: fromLabelID, ignoreUnauthorized: ignoreUnauthorized, reportType: .ham)
        } else {
            return multiMutLabelForThread(threadIds: [threadID], addLabelIds: [Mail_LabelId_Inbox], removeLabelIds: [], fromLabelID: Mail_LabelId_Spam, ignoreUnauthorized: ignoreUnauthorized, reportType: .ham)
        }
    }

    func dontSendReadReceipt(threadID: String, messageID: String, fromLabelID: String) -> Observable<Email_Client_V1_MailMutMultiLabelResponse> {
        return multiMutLabelForThread(threadIds: [threadID], messageIds: [messageID], addLabelIds: [], removeLabelIds: [Mail_LabelId_ReadReceiptRequest], fromLabelID: fromLabelID)
    }

    func sendReadReceipt(messageID: String, sendTime: String, readTime: String) -> Observable<Email_Client_V1_MailReadReceiptResponse> {
        var request = Email_Client_V1_MailReadReceiptRequest()
        request.replyMessageID = messageID
        request.sendTime = sendTime
        request.readTime = readTime
        return sendAsyncRequest(request, transform: { (response: Email_Client_V1_MailReadReceiptResponse) -> Email_Client_V1_MailReadReceiptResponse in
            DataService.logger.debug("sendReadReceipt success. messageId: \(messageID)")
            return response
        }).observeOn(MainScheduler.instance)
    }

    func createDraft(with messageID: String?, threadID: String?, msgTimestamp: Int64?, action: DraftAction, languageId: String?) -> Observable<Email_Client_V1_MailCreateDraftResponse> {
        var languageId = languageId
        MailTracker.startRecordTimeConsuming(event: Homeric.MAIL_DEV_SEND_CREATEDRAFT_COST_TIME, params: nil)
        var request = Email_Client_V1_MailCreateDraftRequest()
        request.originMessageID = messageID ?? ""
        request.action = action
        request.threadID = threadID ?? ""
        request.needSignature = !FeatureManager.realTimeOpen(.enterpriseSignature) || Store.settingData.mailClient
        var messageTimestamp: Int64 = msgTimestamp ?? Int64(Date().timeIntervalSince1970)
        if messageTimestamp == 0 {
            messageTimestamp = Int64(Date().timeIntervalSince1970)
        }
        request.timeText = getQuoteTimeText(timestamp: messageTimestamp, languageId: languageId)
        return sendAsyncRequest(request, transform: { (response: Email_Client_V1_MailCreateDraftResponse) -> Email_Client_V1_MailCreateDraftResponse in
            MailTracker.endRecordTimeConsuming(event: Homeric.MAIL_DEV_SEND_CREATEDRAFT_COST_TIME, params: nil)
            return response
        }).observeOn(MainScheduler.instance)
    }

    func getReplyLanguage(languageId: String?) -> String? {
        var languageId = languageId
        let settingReplyLanguage = Store.settingData.getCachedPrimaryAccount()?.mailSetting.replyLanguage
        MailLogger.info("[mail_client_reply] settingReplyLanguage: \(String(describing: settingReplyLanguage))")
        if settingReplyLanguage == .zh {
            languageId = "zh-CN"
        } else if settingReplyLanguage == .us {
            languageId = "en-US"
        }
        if Store.settingData.mailClient && (settingReplyLanguage == .auto || settingReplyLanguage == .followApp) {
            languageId = LanguageManager.currentLanguage.rawValue
        }
        return languageId
    }

    func getQuoteTimeText(timestamp: Int64, languageId: String?) -> String {
        let language = getReplyLanguage(languageId: languageId)
        return ProviderManager.default.timeFormatProvider?.mailDraftTimeFormat(timestamp, languageId: language) ?? ""
    }

    func getReadReceiptTimeText(timestamp: Int64, languageId: String?) -> String {
        let language = getReplyLanguage(languageId: languageId)
        return ProviderManager.default.timeFormatProvider?.mailReadReceiptTimeFormat(timestamp, languageId: language) ?? ""
    }

    func reEditMsg(threadID: String, msgID: String) -> Observable<MailDraft> {
        var request = Email_Client_V1_MailEditMessageRequest()
        request.threadID = threadID
        request.messageID = msgID
        return sendAsyncRequest(request, transform: { (response: Email_Client_V1_MailEditMessageResponse) -> MailDraft in
            let draft = MailDraft(with: response.draft)
            return draft
        }).observeOn(MainScheduler.instance)
    }

    func deleteDraft(draftID: String, threadID: String, feedCardId: String? = nil) -> Observable<Email_V1_DeleteMailDraftResponse> {
        var request = Email_V1_DeleteMailDraftRequest()
        request.messageID = draftID
        request.threadID = threadID
        if let feedCardId = feedCardId {
            request.feedCardID = feedCardId
        }
        if !request.hasMessageID {
            DataService.logger.debug(
                "deleteDraft error: \(draftID)"
            )
        }
        return sendAsyncRequest(request, transform: { (resp: Email_V1_DeleteMailDraftResponse) -> Email_V1_DeleteMailDraftResponse in
            DataService.logger.debug(
                "deleteDraft suc: \(draftID)"
            )
            return resp
        }).observeOn(MainScheduler.instance)
    }

    func updateDraft(draft: MailDraft, isdelay: Bool, feedCardId: String? = nil) -> Observable<MailDraft> {
        var request = Email_Client_V1_MailUpdateDraftRequest()
        request.draftID = draft.id
        request.isDelay = isdelay
        request.payload = draft.toPayload()
        if let feedCardId = feedCardId {
            request.feedCardID = feedCardId
        }
        return sendAsyncRequest(request, transform: { (response: Email_Client_V1_MailUpdateDraftResponse) -> MailDraft in
            DataService.logger.debug(
                "updateDraft suc"
            )
            return MailDraft(with: response.draft)
        }).observeOn(MainScheduler.instance)
    }

    func rebuildDraft(draft: MailDraft) -> Observable<MailDraft> {
        var request = Email_Client_V1_MailRebuildDraftRequest()
        request.draft = draft.toPBModel()
        return sendAsyncRequest(request, transform: { (response: Email_Client_V1_MailRebuildDraftResponse) -> MailDraft in
            DataService.logger.debug(
                "rebuildDraft suc"
            )
            return MailDraft(with: response.draft)
        })
    }

    func sendMail(_ mail: MailDraft, replyMailId: String, scheduleSendTime: Int64, feedCardId: String?) -> Observable<(message: MailMessage, threadId: String, uuid: String)> {
        var request = Email_Client_V1_MailSendDraftRequest()
        request.draft = mail.toPBModel()
        request.originMessageID = replyMailId
        if let feedCardId = feedCardId {
            request.feedCardID = feedCardId
        }
        if scheduleSendTime > 0 {
            request.scheduleSendTime = scheduleSendTime
        }
        DataService.logger.debug("mail send originMessageID \(request.originMessageID) scheduleSendTime:\(scheduleSendTime)")
        return sendAsyncRequest(request, transform: { (response: Email_Client_V1_MailSendDraftResponse) -> (message: MailMessage, threadId: String, uuid: String) in
            DataService.logger.debug(
                "send mail success threadId: \(response.threadID) uuid: \(response.uuid)"
            )
            if scheduleSendTime > 0 {
                MailTracker.log(event: "email_draft_scheduledSend_success", params: nil)
            }
            return (message: MailMessage(with: response.message), threadId: response.threadID, response.uuid)
        }).observeOn(MainScheduler.instance)
    }

    func markAllAsRead(labelID: String) -> Observable<Void> {
        var request = Email_Client_V1_SetMailsAllReadRequest()
        request.labelID = labelID
        return sendAsyncRequest(request, transform: { (response: Email_Client_V1_SetMailsAllReadResponse) -> Void in
            DataService.logger.debug(
                "markAllAsRead suc: \(labelID)"
            )
        }).observeOn(MainScheduler.instance)
    }

    func deletePermanently(labelID: String, threadIDs: [String], messageIds: [String]? = nil, isAllowAllLabels: Bool = false) -> Observable<Void> {
        var request = Email_Client_V1_MailMultiThreadDeletePermanentlyRequest()
        request.labelID = labelID
        request.threadIds = threadIDs
        request.allowAllLabel = isAllowAllLabels
        if let messageIds = messageIds {
            request.messageIds = messageIds
        }
        return sendAsyncRequest(request, transform: { (response: Email_Client_V1_MailMultiThreadDeletePermanentlyResponse) -> Void in
            // nothing
            DataService.logger.debug(
                "deletePermanently suc: \(labelID)，t_ids:\(threadIDs ?? []), msgIds:\(messageIds)"
            )
        }).observeOn(MainScheduler.instance)
    }

    func translateMessage(msgId: String,
                          threadId: String?,
                          ownerUserID: String?,
                          isBodyClipped: Bool,
                          sourceLan: String,
                          targetLan: String,
                          showOriginalText: Bool,
                          languages: [String],
                          ignoredLanguages: [String],
                          needTranslatedSubject: Bool) -> Observable<[TranslateMessage]> {
        var msg = Email_Client_V1_MailTranslateMessagesRequest.TranslateMessage()
        msg.messageID = msgId
        if let threadID = threadId {
            msg.threadID = threadID
        }
        msg.isBodyClipped = isBodyClipped
        msg.showOriginalText = showOriginalText
        msg.languages = languages
        if let ownerUserID = ownerUserID {
            msg.ownerUserID = ownerUserID
        }

        var request = Email_Client_V1_MailTranslateMessagesRequest()
        request.messages = [msg]
        request.sourceLanguage = sourceLan
        request.targetLanguage = targetLan
        request.ignoredLanguages = ignoredLanguages
        request.needTranslatedSubject = needTranslatedSubject
        return sendAsyncRequest(request) { (response: Email_Client_V1_MailTranslateMessagesResponse) -> [TranslateMessage] in
            return response.messages.compactMap { (info) -> TranslateMessage? in
                guard let result = TranslateMessageResult(rawValue: info.result.rawValue) else {
                    DataService.logger.debug("Translate Result not supported, rawValue is \(info.result.rawValue)")
                    return nil
                }
                return TranslateMessage(threadId: threadId ?? "", messageId: info.messageID, translatedSubject: info.translatedSubject,
                                        translatedBodyPlainText: info.translatedBodyPlainText, translatedBody: info.translatedBody,
                                        result: result, sourceLans: info.sourceLanguages, showOriginalText: info.showOriginalText)
            }
        }.observeOn(MainScheduler.instance)
    }
    
    func fetchIsMessageImageBlocked(messageID: String) -> Observable<(String, Bool)> {
        var request = Email_Client_V1_MailGetIsImageBlockedRequest()
        request.bizID = messageID
        
        return sendAsyncRequest(request, transform: { (response: Email_Client_V1_MailGetIsImageBlockedResponse) -> (String, Bool) in
            return (messageID, response.isBlocked)
        }).observeOn(MainScheduler.instance)
    }
    
    func fetchMessagesImageBlocked(messageFroms: [String], messageIDs: [String]) -> Observable<Email_Client_V1_MailGetIsImageAllowedResponse> {
        var request = Email_Client_V1_MailGetIsImageAllowedRequest()
        request.msgIds = messageIDs
        request.msgFroms = messageFroms
        
        return sendAsyncRequest(request, transform: { (response: Email_Client_V1_MailGetIsImageAllowedResponse) in
            return response
        }).observeOn(MainScheduler.instance)
    }
    
    func addSenderToWebImageWhiteList(sender: [Email_Client_V1_Address]) -> Observable<Void> {
        var request = Email_Client_V1_MailAddUserAllowBlockRequest()
        request.multiFrom = sender
        request.isAllow = true
        
        return sendAsyncRequest(request, transform: { (response: Email_Client_V1_MailAddUserAllowBlockResponse) -> Void in
            // nothing
            DataService.logger.debug(
                "Add sender to web image whitelist success"
            )
        }).observeOn(MainScheduler.instance)
    }
}
