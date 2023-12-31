//
//  MailSearchResultCellViewModel.swift
//  MailSDK
//
//  Created by tefeng liu on 2019/7/8.
//

import Foundation
import RustPB

protocol MailSearchResultCellViewModelDelegate: AnyObject {
    func viewModelDidUpdate(threadId: String, viewModel: MailSearchResultCellViewModel)
}

class MailSearchResultCellViewModel: MailSearchCellViewModel {
    var threadId: String
    var messageId: String
    var from: String
    var msgSummary: String
    var subject: String
    var createTimestamp: Int64
    var lastMessageTimestamp: Int64
    var highlightString: [String]
    var highlightSubject: [String]
    var isRead: Bool = false
    var replyTagType: MailReplyType
    var hasDraft: Bool
    var hasAttachment: Bool = false
    var priorityType: MailPriorityType
    var msgNum: Int
    var messageIds: [String]
    var labels: [MailClientLabel]
    var fullLabels: [String]
    var actions: [ActionType]
    var isFlagged: Bool = false
    var isExternal: Bool = false
    var senderAddresses: [String]
    var attachmentNameList: [String] = []
    var headFroms: [String]
    var unauthorizedHeadFroms: [String]
    var folders: [String]
    var currentLabelID: String
    var addressList: [Email_Client_V1_Address]
    weak var delegate: MailSearchResultCellViewModelDelegate?

    init(threadId: String,
         messageId: String,
         from: String,
         msgSummary: String,
         subject: String,
         createTimestamp: Int64,
         lastMessageTimestamp: Int64,
         highlightString: [String],
         highlightSubject: [String],
         replyTagType: MailReplyType,
         hasDraft: Bool,
         priorityType: MailPriorityType,
         msgNum: Int,
         messageIds: [String],
         labels: [MailClientLabel],
         fullLabels: [String],
         isFlagged: Bool,
         isExternal: Bool,
         senderAddresses: [String],
         folders: [String],
         headFroms: [String],
         unauthorizedHeadFroms: [String],
         currentLabelID: String,
         addressList: [Email_Client_V1_Address]) {
        self.threadId = threadId
        self.messageId = messageId
        self.from = from
        self.msgSummary = msgSummary
        self.subject = subject
        self.createTimestamp = createTimestamp
        self.lastMessageTimestamp = lastMessageTimestamp
        self.highlightString = highlightString
        self.highlightSubject = highlightSubject
        self.replyTagType = replyTagType
        self.hasDraft = hasDraft
        self.priorityType = priorityType
        self.msgNum = msgNum
        self.messageIds = messageIds
        self.labels = labels
        self.fullLabels = fullLabels
        self.actions = [ActionType]()
        self.isFlagged = isFlagged
        self.isExternal = isExternal
        self.senderAddresses = senderAddresses
        self.folders = folders
        self.headFroms = headFroms
        self.unauthorizedHeadFroms = unauthorizedHeadFroms
        self.currentLabelID = currentLabelID
        self.addressList = addressList
    }
}
