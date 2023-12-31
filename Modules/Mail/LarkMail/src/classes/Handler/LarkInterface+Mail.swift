//
//  LarkInterface+Mail.swift
//  Action
//
//  Created by majx on 2019/6/2.
//

import EENavigator

// 邮件首页
struct MailHomeBody: CodablePlainBody {
    static let pattern = "//client/mail/home"

    init() {}
}

// 发送邮件
struct MailSendBody: CodablePlainBody {
    static let pattern = "//client/mail/send"
    let emailAddress: String
    let subject: String
    let body: String
    let originUrl: String
    let cc: String
    let bcc: String

    init(emailAddress: String,
                subject: String = "",
                body: String = "",
                originUrl: String = "",
                cc: String = "",
                bcc: String = "") {
        self.emailAddress = emailAddress
        self.subject = subject
        self.body = body
        self.originUrl = originUrl
        self.cc = cc
        self.bcc = bcc
    }
}

// 回复邮件
struct MailReplayBody: CodablePlainBody {
    static let pattern = "//client/mail/replay"

    init() {}
}

// 邮件内容 messagelist
struct MailMessageListBody: CodablePlainBody {
    static let pattern = "//client/mail/messagelist"
    let threadId: String
    let messageId: String
    let labelId: String
    let accountId: String?
    let fromScene: Bool
    let statFrom: String
    let cardId: String?
    let ownerId: String?
    let feedCardId: String?
    let feedCardAvatar: String?

    init(threadId: String, messageId: String, labelId: String, accountId: String?, fromScene: Bool = false, statFrom: String, cardId: String?, ownerId: String?, feedCardId: String?, feedCardAvatar: String?) {
        self.threadId = threadId
        self.messageId = messageId
        self.labelId = labelId
        self.accountId = accountId
        self.fromScene = fromScene
        self.statFrom = statFrom
        self.cardId = cardId
        self.ownerId = ownerId
        self.feedCardId = feedCardId
        self.feedCardAvatar = feedCardAvatar
    }
}

/// recall mail
struct MailRecallMessageBody: CodablePlainBody {
    static let pattern = "//client/mail/recall"
    let threadId: String
    let messageId: String

    init(threadId: String, messageId: String) {
        self.threadId = threadId
        self.messageId = messageId
    }
}

// 设置页
public struct EmailSettingBody: CodablePlainBody {
    public static let pattern = "//client/email/setting"
    public init() {}
}

// Feed读信页面
public struct MailFeedReadBody: CodablePlainBody {
    public static let pattern = "//client/mail/feed"
    let feedCardId: String
    let mail: String
    let name: String
    let avatar: String
    let fromNotice: Int

    init(feedCardId: String, mail: String, name: String, avatar: String, fromNotice: Int = 0) {
        self.feedCardId = feedCardId
        self.mail = mail
        self.name = name
        self.avatar = avatar
        self.fromNotice = fromNotice
    }
}
