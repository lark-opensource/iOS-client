//
//  LarkNSExtensionMessageProcessor.swift
//  LarkNotificationServiceExtension
//
//  Created by mochangxing on 2019/8/29.
//

import Foundation
import NotificationUserInfo
import UserNotifications

public final class LarkNSExtensionMessageProcessor: LarkNSExtensionContentProcessor {
    public init() {}

    public func transformNotificationExtra(with content: UNNotificationContent) -> Extra? {
        guard let extra = LarkNSEExtra.getExtraDict(from: content.userInfo) else {
            let content = MessageContent(messageId: "", chatId: "", position: nil, threadId: "", userId: "", url: "", state: .normal)
            return Extra(type: .message, content: content)
        }
        var url = ""
        switch extra.direct {
        case .pushToDefault:
            // 什么也不做，只是打开app
            break
        case .pushToLatestUnreadMessge:
            url = pushToLatestUnreadMessgeUrl(extra)
        case .pushToMessage:
            url = pushToMessage(extra)
        case .pushToDocPhotoSelector:
            // 什么也不做，docs处理
            break
        case .pushToChatContact:
            url = pushToChatContact(extra)
        }

        let content = MessageContent(messageId: String(extra.messageID ?? 0),
                                     chatId: String(extra.chatId ?? 0),
                                     position: extra.position,
                                     threadId: String(extra.threadId ?? 0),
                                     userId: extra.userId ?? "",
                                     url: url,
                                     state: .normal)

        return Extra(type: .message, content: content)
    }

    public func getCategoryIdentifier(with content: UNNotificationContent) -> String? {
        guard let extra = LarkNSEExtra.getExtraDict(from: content.userInfo), extra.quickReply == 1  else {
            LarkNSELogger.logger.error("Get CategoryIdentifier Nil")
            return nil
        }

        LarkNSELogger.logger.info("Get CategoryIdentifier Messenger")

        return "messenger"
    }

    public func transformNotificationAlter(with content: UNNotificationContent) -> Alert? {
        if #available(iOS 15.0, *),
           let extra = LarkNSEExtra.getExtraDict(from: content.userInfo),
           extra.pruneOutline {
            let senderName = extra.senderName
            let range = content.body.range(of: senderName)
            var body = content.body
            if let range = range {
                let subStr = body[body.index(range.upperBound, offsetBy: 0)]
                var offsetBy = 0
                if subStr == ":" || subStr == "：" {
                    offsetBy += 1
                    let subStr1 = body[body.index(range.upperBound, offsetBy: 1)]
                    if subStr1 == " " {
                        offsetBy += 1
                    }
                } else if subStr == " " {
                    offsetBy += 1
                }
                let pre = String(body[body.startIndex..<body.index(range.lowerBound, offsetBy: 0)])
                body = pre + String(body[body.index(range.upperBound, offsetBy: offsetBy)...])
            }
            return Alert(title: content.title, subtitle: content.subtitle, body: body)
        }
        return Alert(title: content.title, subtitle: content.subtitle, body: content.body)
    }

    public func transformNotificationExtra(with content: UNNotificationContent,
                                    relatedContents: [UNNotificationContent]?) -> Extra? {
        if let recallContent = relatedContents?.first(where: {
            LarkNSEExtra.getExtraDict(from: $0.userInfo)?.isRecall ?? false
        }) {
            return transformNotificationExtra(with: recallContent)
        }
        return transformNotificationExtra(with: content)
    }

    public func transformNotificationAlter(with content: UNNotificationContent,
                                    relatedContents: [UNNotificationContent]?) -> Alert? {
        if let recallContent = relatedContents?.first(where: {
            LarkNSEExtra.getExtraDict(from: $0.userInfo)?.isRecall ?? false }) {
            return transformNotificationAlter(with: recallContent)
        }
        return transformNotificationAlter(with: content)
    }

    func pushToLatestUnreadMessgeUrl(_ extra: LarkNSEExtra) -> String {
        guard let channel = extra.channel else {
            return ""
        }
        switch channel {
        case .chat:
            guard let chatId = extra.chatId else {
                return ""
            }
            return "//client/chat/\(chatId)?fromWhere=push"
        case .thread:
            guard let threadId = extra.threadId else {
                return ""
            }
            return "//client/chat/thread/detail/\(threadId)?sourceType=notification"
        case .msg_thread:
            guard let threadId = extra.threadId else {
                return ""
            }
            return "//client/chat/reply/in/thread/\(threadId)?loadType=unread&sourceType=notification"
        case .unkonwn:
            return ""
        }
    }

    func pushToMessage(_ extra: LarkNSEExtra) -> String {
        guard let channel = extra.channel, let position = extra.position else {
            return ""
        }
        switch channel {
        case .chat:
            guard let chatId = extra.chatId else {
                return ""
            }
            return "//client/chat/\(chatId)?fromWhere=push&position=\(position)"
        case .thread:
            guard let threadId = extra.threadId else {
                return ""
            }
            return "//client/chat/thread/detail/\(threadId)?loadType=position&position=\(position)&sourceType=notification"
        case .msg_thread:
            guard let threadId = extra.threadId else {
                return ""
            }
            return "//client/chat/reply/in/thread/\(threadId)?loadType=position&position=\(position)&sourceType=notification"
        case .unkonwn:
            return ""
        }
    }

    func pushToChatContact(_ extra: LarkNSEExtra) -> String {
        return "//client/contact/applications"
    }
}
