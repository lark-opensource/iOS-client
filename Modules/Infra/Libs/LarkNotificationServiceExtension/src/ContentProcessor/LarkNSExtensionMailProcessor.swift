//
//  LarkNSExtensionMailProcessor.swift
//  LarkNotificationServiceExtension
//
//  Created by majx on 2019/9/3.
//

import Foundation
import LarkExtensionServices
import NotificationUserInfo
import UserNotifications

public final class LarkNSExtensionMailProcessor: LarkNSExtensionContentProcessor {
    static let logger = LogFactory.createLogger(label: "LarkNSExtensionMailProcessor")

    public init() {}

    public func transformNotificationExtra(with content: UNNotificationContent) -> Extra? {
        LarkNSExtensionMailProcessor.logger.info("transformNotificationExtra called")
        guard let extra = LarkNSEMailExtra.getMailExtra(from: content.userInfo) else {
            LarkNSExtensionMailProcessor.logger.error("fail to init extra")
            return Extra(type: .mail, content: MailContent(url: pushToMailHome()))
        }
        LarkNSExtensionMailProcessor.logger.info("extra type: \(String(describing: extra.type?.rawValue))")
        /// 收到新邮件
        if extra.type == .newMessage || extra.type == .shareIncoming || extra.type == .shareThread, let newMessageData = extra.data as? LarkNSEMailExtra.NewMessageData {
            if let feedCardId = newMessageData.feedCardId, !feedCardId.isEmpty {
                let mailUrl = pushToFeedMail(feedCardId: feedCardId)
                return Extra(type: .mail, content: MailContent(url: mailUrl))
            } else {
                let mailUrl = pushToMessageList(threadId: newMessageData.threadId,
                                                messageId: newMessageData.messageId,
                                                labelId: newMessageData.labeldId,
                                                accountId: newMessageData.accountId)
                return Extra(type: .mail, content: MailContent(url: mailUrl))
            }
            
        }
        if extra.type == .recallMessage, let newMessageData = extra.data as? LarkNSEMailExtra.RecallMessageData {
            return Extra(type: .mail, content: MailContent(url: recallMessage(threadId: newMessageData.threadId, messageId: newMessageData.messageId)))
        }

        /// 打开邮件首页
        return Extra(type: .mail, content: MailContent(url: pushToMailHome()))
    }

    public func transformNotificationAlter(with content: UNNotificationContent) -> Alert? {
        return Alert(title: content.title, subtitle: content.subtitle, body: content.body)
    }

    func pushToMailHome() -> String {
        return "//client/mail/home"
    }

    func pushToMessageList(threadId: String, messageId: String, labelId: String, accountId: String?) -> String {
        var accountParam = ""
        if let theAccountId = accountId, !theAccountId.isEmpty {
            accountParam = "&accountId=\(theAccountId)"
        }
        return "//client/mail/messagelist?threadId=\(threadId)&messageId=\(messageId)&labelId=\(labelId)"+accountParam
    }

    func recallMessage(threadId: String, messageId: String) -> String {
        return "//client/mail/recall?threadId=\(threadId)&messageId=\(messageId)"
    }
    
    func pushToFeedMail(feedCardId: String) -> String {
        return "//client/mail/feed?feedCardId=\(feedCardId)&fromNotice=1"
    }
}

// MARK: - LarkNSEMailPushType & LarkNSEMailData
enum LarkNSEMailPushType: String {
    case newMessage = "PUSH_MAIL_NEW_MESSAGE"
    case shareThread = "PUSH_MAIL_SHARE_THREAD"
    case shareIncoming = "PUSH_MAIL_SHARE_INCOMING"
    case recallMessage = "PUSH_MAIL_RECALL_MESSAGE"
}

protocol LarkNSEMailData {

}

// MARK: - LarkNSEMailExtra
struct LarkNSEMailExtra {
    struct NewMessageData: LarkNSEMailData {
        let threadId: String
        let messageId: String
        let labeldId: String
        let accountId: String?
        let feedCardId: String?
    }

    struct RecallMessageData: LarkNSEMailData {
        let threadId: String
        let messageId: String
    }

    var type: LarkNSEMailPushType?
    var data: LarkNSEMailData?

    public init?(dict: [String: Any]) {
        guard let typeStr = dict["type"] as? String,
            let dataDic = dict["data"] as? [String: Any],
            let type = LarkNSEMailPushType(rawValue: typeStr) else {
                return nil
        }
        self.type = type
        if  let threadId = dataDic["t_id"] as? String,
            let messageId = dataDic["m_id"] as? String {
            let accountId = dataDic["ma_id"] as? String
            let folderId = dataDic["f_id"] as? String
            let feedCardId = dataDic["fc_id"] as? String
            var labelId = "INBOX" // default value
            if folderId != nil && !folderId!.isEmpty {
                labelId = folderId!
            }
            switch type {
            case .newMessage:
                self.data = NewMessageData(threadId: threadId, messageId: messageId, labeldId: labelId, accountId: accountId, feedCardId: feedCardId)
            case .shareThread, .shareIncoming:
                self.data = NewMessageData(threadId: threadId, messageId: messageId, labeldId: "SHARE", accountId: accountId, feedCardId: feedCardId)
            case .recallMessage:
                self.data = RecallMessageData(threadId: threadId, messageId: messageId)
            }
        }
    }

    static func getMailExtra(from userInfo: [AnyHashable: Any]) -> LarkNSEMailExtra? {
        /// get extra_str
        guard let extraString = LarkNSEExtra.getExtraDict(from: userInfo)?.extraString else {
            return nil
        }
        /// get mail extra
        if let data = extraString.data(using: .utf8) {
            do {
                guard let dict = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
                    return nil
                }
                return LarkNSEMailExtra(dict: dict)
            } catch {
            }
        }
        return nil
    }
}
