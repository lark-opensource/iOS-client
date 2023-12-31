//
//  MailDraft.swift
//  MailSDK
//
//  Created by majx on 2019/8/13.
//

import Foundation

struct MailDraft {
    var id: String
    var replyToMailID: String
    var threadID: String
    var createTimestamp: Int64
    var lastUpdatedTimestamp: Int64
    var content: MailContent
    var fromAddress: String
    var fromName: String
    var docID: String
    var attachmentCount: Int
    let replyShareMsgID: String
    var fromEntityId: String
    var isSendSeparately: Bool
    var calendarEvent: DraftCalendarEvent?

    init(id: String,
         replyToMailID: String,
         threadID: String,
         createTimestamp: Int64,
         lastUpdatedTimestamp: Int64,
         fromAddress: String,
         fromName: String,
         content: MailContent,
         docID: String,
         attachmentCount: Int,
         replyShareMsgID: String,
         fromEntityId: String,
         isSendSeparately: Bool,
         subjectCover: MailSubjectCover?,
         calendarEvent: DraftCalendarEvent?) {
        self.id = id
        self.replyToMailID = replyToMailID
        self.threadID = threadID
        self.createTimestamp = createTimestamp
        self.lastUpdatedTimestamp = lastUpdatedTimestamp
        self.fromAddress = fromAddress
        self.fromName = fromName
        self.content = content
        self.docID = docID
        self.attachmentCount = attachmentCount
        self.replyShareMsgID = replyShareMsgID
        self.fromEntityId = fromEntityId
        self.isSendSeparately = isSendSeparately
        self.calendarEvent = calendarEvent
    }

    /// 通过 MailClientDraft 来初始化 MailDraft
    init(with clientDraft: MailClientDraft) {
        let content = MailContent(with: clientDraft)
        self.init(id: clientDraft.id,
                  replyToMailID: clientDraft.replyMessageID,
                  threadID: clientDraft.threadID,
                  createTimestamp: clientDraft.createdTimestamp,
                  lastUpdatedTimestamp: clientDraft.lastUpdatedTimestamp,
                  fromAddress: clientDraft.from.address,
                  fromName: clientDraft.from.name,
                  content: content,
                  docID: clientDraft.docID,
                  attachmentCount: clientDraft.attachments.count,
                  replyShareMsgID: clientDraft.replyShareMessageID,
                  fromEntityId: clientDraft.from.larkEntityIDString,
                  isSendSeparately: clientDraft.isSendSeparately,
                  subjectCover: nil,
                  calendarEvent: clientDraft.hasCalendarEvent ? clientDraft.calendarEvent : nil)
    }

    init(fromAddress: String,
         fromName: String,
         content: MailContent,
         docID: String) {
        self.fromAddress = fromAddress
        self.fromName = fromName
        self.content = content
        self.docID = docID

        self.id = ""
        self.replyToMailID = ""
        self.threadID = ""
        self.createTimestamp = 0
        self.lastUpdatedTimestamp = 0
        self.attachmentCount = 0
        self.replyShareMsgID = ""
        self.fromEntityId = ""
        self.isSendSeparately = false
        self.calendarEvent = nil
    }
}

extension MailDraft {
    /// 将 MailDraft 转换为 MailClientDraft
    func toPBModel() -> MailClientDraft {
        var clientDraft = MailClientDraft()
        clientDraft.id = id
        clientDraft.threadID = threadID
        clientDraft.replyMessageID = replyToMailID
        clientDraft.replyShareMessageID = replyShareMsgID
        clientDraft.from = content.from.toPBModel()
        clientDraft.to = content.to.map { $0.toPBModel() }
        clientDraft.cc = content.cc.map { $0.toPBModel() }
        clientDraft.bcc = content.bcc.map { $0.toPBModel() }
        clientDraft.subject = content.subject
        clientDraft.bodyHtml = content.bodyHtml
        clientDraft.bodySummary = content.bodySummary
        clientDraft.lastUpdatedTimestamp = lastUpdatedTimestamp
        clientDraft.createdTimestamp = createTimestamp
        clientDraft.attachments = content.attachments.map { $0.toPBModel() }
        clientDraft.images = content.images.map { $0.toPBModel() }
        clientDraft.docsPermissions = content.docsConfigs
        clientDraft.priorityType = content.priorityType
        clientDraft.needReadReceipt = content.needReadReceipt
        clientDraft.isSendSeparately = isSendSeparately
        clientDraft.docID = docID
        clientDraft.coverInfo = content.subjectCover?.coverInfo ?? ""
        if let calendar = calendarEvent {
            clientDraft.calendarEvent = calendar
        }
        clientDraft.isFromLarkPlaintext = false // 移动端只有false
        return clientDraft
    }

    func toPayload() -> MailDraftPayload {
        var payload = MailDraftPayload()
        let draft = toPBModel()
        payload.from = draft.from
        payload.threadID = draft.threadID
        payload.to = draft.to
        payload.cc = draft.cc
        payload.bcc = draft.bcc
        payload.bodyHtml = draft.bodyHtml
        payload.bodySummary = draft.bodySummary
        payload.subject = draft.subject
        payload.images = draft.images
        payload.attachments = draft.attachments
        payload.docsPermissions = draft.docsPermissions
        payload.priorityType = draft.priorityType
        payload.needReadReceipt = draft.needReadReceipt
        payload.isSendSeparately = draft.isSendSeparately
        payload.coverInfo = content.subjectCover?.coverInfo ?? ""
        if draft.hasCalendarEvent {
            payload.calendarEvent = draft.calendarEvent
        }
        payload.isFromLarkPlaintext = false
        return payload
    }
}

extension MailDraft: Equatable {
    static func == (lhs: MailDraft, rhs: MailDraft) -> Bool {
        if lhs.id != rhs.id { return false }
        if lhs.replyToMailID != rhs.replyToMailID { return false }
        if lhs.threadID != rhs.threadID { return false }
        /// ignore the time stamp of 
        /// if lhs.createTimestamp != rhs.createTimestamp { return false }
        /// if lhs.lastUpdatedTimestamp !=  rhs.lastUpdatedTimestamp { return false }
        if lhs.content != rhs.content { return false }
        if lhs.fromAddress != rhs.fromAddress { return false }
        if lhs.docID != rhs.docID { return false }
        if lhs.attachmentCount != rhs.attachmentCount { return false }
        if lhs.isSendSeparately != rhs.isSendSeparately { return false }
        if lhs.calendarEvent != rhs.calendarEvent { return false }
        return true
    }
}
