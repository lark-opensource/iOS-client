//
//  MailMessage.swift
//  MailSDK
//
//  Created by majx on 2019/8/13.
//

import Foundation

struct MailMessage {
    var id: String
    var replyToMailID: String
    var createTimestamp: Int64
    var lastUpdatedTimestamp: Int64
    var content: MailContent
    var messageID: String
    var threadID: String
    var threadIndex: Int64
    var status: MailStatus
    var labels: [String]
    var deliveryState: MailMessage.DeliveryState
    var drafts: [MailDraft]

    // swiftlint:disable operator_usage_whitespace
    enum DeliveryState: Int {
        typealias RawValue = Int
        case unknownDeliveryState = 0
        case toSend    = 1
        case sending   = 2
        case delivered = 3
        case received  = 4
        case draft     = 5
        case sendError = 6

        init() {
            self = .unknownDeliveryState
        }
    }
    // swiftlint:enable operator_usage_whitespace

    init(id: String,
         replyToMailID: String,
         createTimestamp: Int64,
         lastUpdatedTimestamp: Int64,
         content: MailContent,
         messageID: String,
         threadID: String,
         threadIndex: Int64,
         status: MailStatus,
         labels: [String],
         deliveryState: MailMessage.DeliveryState,
         drafts: [MailDraft]) {
        self.id = id
        self.replyToMailID = replyToMailID
        self.createTimestamp = createTimestamp
        self.lastUpdatedTimestamp = lastUpdatedTimestamp
        self.content = content
        self.messageID = messageID
        self.threadID = threadID
        self.threadIndex = threadIndex
        self.status = status
        self.labels = labels
        self.deliveryState = deliveryState
        self.drafts = drafts
    }

    init(with clientMessage: MailClientMessage) {
        // TODO: 需要检查下类型转换是否正确
        self.init(
            id: clientMessage.id,
            replyToMailID: "",
            createTimestamp: clientMessage.createdTimestamp,
            lastUpdatedTimestamp: clientMessage.lastUpdatedTimestamp,
            content: MailContent(with: clientMessage),
            messageID: "",
            threadID: "",
            threadIndex: clientMessage.threadIndex,
            status: MailStatus(isRead: clientMessage.isRead,
                               isSpam: clientMessage.status.isSpam,
                               isArchived: clientMessage.status.isArchived,
                               isDeleted: clientMessage.status.isDeleted),
            labels: [],
            deliveryState: MailMessage.DeliveryState(rawValue: clientMessage.deliveryState.rawValue) ?? .unknownDeliveryState,
            drafts: [])
    }
}

extension MailMessage {
    func toPBModel() -> MailClientMessage {
        var clientModle = MailClientMessage()
        clientModle.id = id
        clientModle.createdTimestamp = createTimestamp
        clientModle.lastUpdatedTimestamp = lastUpdatedTimestamp
        clientModle.threadIndex = threadIndex
        clientModle.isRead = status.isRead
        var newstatus = MailClientFilterStatus()
        newstatus.isSpam = status.isSpam
        newstatus.isArchived = status.isArchived
        newstatus.isDeleted = status.isDeleted
        clientModle.status = newstatus
        clientModle.deliveryState = MailClientMessageDeliveryState(rawValue: deliveryState.rawValue) ?? .unknownDeliveryState
        clientModle.from = content.from.toPBModel()
        clientModle.to = content.to.map { $0.toPBModel() }
        clientModle.cc = content.cc.map { $0.toPBModel() }
        clientModle.bcc = content.bcc.map { $0.toPBModel() }
        clientModle.subject = content.subject
        clientModle.bodySummary = content.bodySummary
        clientModle.bodyHtml = content.bodyHtml
        clientModle.attachments = content.attachments.map { $0.toPBModel() }
        clientModle.images = content.images.map { $0.toPBModel() }
        clientModle.coverInfo = content.subjectCover?.coverInfo ?? ""
        clientModle.isFromLarkPlaintext = false
        return clientModle
    }
}
