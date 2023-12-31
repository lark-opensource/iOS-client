//
//  MailThread.swift
//  MailSDK
//
//  Created by majx on 2019/8/13.
//

import Foundation

struct MailThread {
    // TODO: 需要将数据结构对齐到 MailClientThread
    var id: String
    var createTimestamp: Int64
    var lastUpdatedTimestamp: Int64
    var lastMessageTimestamp: Int64
    var messageCount: Int64
    var lastReadIndex: Int64
    var messages: [Int64: MailMessage]
    var status: MailStatus
    var labels: [String]
    var drafts: [MailDraft]
}
