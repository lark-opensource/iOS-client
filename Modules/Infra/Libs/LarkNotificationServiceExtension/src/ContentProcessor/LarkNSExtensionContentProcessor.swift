//
//  LarkNSExtensionContentProcessor.swift
//  LarkNotificationServiceExtension
//
//  Created by mochangxing on 2019/8/29.
//

import Foundation
import NotificationUserInfo
import UserNotifications
import Intents

public protocol LarkNSExtensionContentProcessor {
    func getCategoryIdentifier(with content: UNNotificationContent) -> String?

    func transformNotificationExtra(with content: UNNotificationContent) -> Extra?

    func transformNotificationAlter(with content: UNNotificationContent) -> Alert?

    func transformNotificationExtra(with content: UNNotificationContent, relatedContents: [UNNotificationContent]?) -> Extra?

    func transformNotificationAlter(with content: UNNotificationContent, relatedContents: [UNNotificationContent]?) -> Alert?
}

public extension LarkNSExtensionContentProcessor {
    func getCategoryIdentifier(with content: UNNotificationContent) -> String? {
        return nil
    }

    func transformNotificationExtra(with content: UNNotificationContent, relatedContents: [UNNotificationContent]?) -> Extra? {
        return transformNotificationExtra(with: content)
    }

    func transformNotificationAlter(with content: UNNotificationContent, relatedContents: [UNNotificationContent]?) -> Alert? {
        return transformNotificationAlter(with: content)
    }
}

public extension LarkNSEExtra {
    public var contentProcessor: LarkNSExtensionContentProcessor? {
        guard contentMutable else {
            return nil
        }
        switch biz {
        case .lark:
            return LarkNSExtensionMessageProcessor()
        case .docs:
            return LarkNSExtensionDocsProcessor()
        case .mail:
            return LarkNSExtensionMailProcessor()
        case .voip:
            return LarkNSExtensionByteViewProcessor(pushType: .call)
        case .vc:
            return LarkNSExtensionByteViewProcessor(pushType: .video)
        case .unkonwn:
            return LarkNSExtensionDefaultProcessor()
        case .calendar:
            return LarkNSExtensionCalendarProcessor()
        case .todo:
            return LarkNSExtensionTodoProcessor()
        case .openAppChat:
            return LarkNSExtensionOpenAppChatProcessor()
        case .openMicroApp:
            return LarkNSExtensionOpenMicroAppProcessor()
        case .none:
            return LarkNSExtensionDefaultProcessor()
        }
    }
}

final public class LarkNSEContentProcessor {
    static let delay = 0.5

    static func processAlert(_ bestAttemptContent: UNMutableNotificationContent, alert: Alert?, userInfoExtra: Extra?, extra: LarkNSEExtra) {
        guard let alert = alert else {
            return
        }
        if let body = alert.body {
            bestAttemptContent.body = body
        }
        if let title = alert.title {
            bestAttemptContent.title = title
        }
        if let subtitle = alert.subtitle {
            bestAttemptContent.subtitle = subtitle
        }

        // 优先取sound，如果没有则取soundName
        if let sound = alert.sound {
            bestAttemptContent.sound = sound
        } else if let soundName = alert.soundName {
            bestAttemptContent.sound = UNNotificationSound(named: UNNotificationSoundName(rawValue: soundName))
        }
    }

    static public func processContent(
        extra: LarkNSEExtra,
        request: UNNotificationRequest,
        bestAttemptContent: UNMutableNotificationContent,
        contentHandler: @escaping (UNNotificationContent) -> Void
    ) {
        guard let processor = extra.contentProcessor else {
            LarkNSELogger.logger.error("Processor is nil for biz: \(extra.biz ?? .unkonwn)")
            contentHandler(bestAttemptContent)
            return
        }

        let alert = processor.transformNotificationAlter(with: bestAttemptContent)
        if let categoryIdentifier = processor.getCategoryIdentifier(with: bestAttemptContent) {
            bestAttemptContent.categoryIdentifier = categoryIdentifier
        }

        var userInfoExtra = processor.transformNotificationExtra(with: bestAttemptContent)
        if let userid = extra.userId,
            let originUrl = userInfoExtra?.content.url {
            userInfoExtra?.content.url = "//client/tenant/switch?userId=\(String(describing: userid))&&redirect=\(originUrl.urlEncoded())"
        }

        processAlert(bestAttemptContent, alert: alert, userInfoExtra: userInfoExtra, extra: extra)

        /// userInfoExtra: Extra 里面内容经过转化，nseExtra 是推送全量数据
        var userInfo = UserInfo(sid: extra.Sid, alert: alert, extra: userInfoExtra)
        userInfo.nseExtra = extra
        bestAttemptContent.userInfo = userInfo.toDict()

        let shouldNoticeAfterRemove = userInfoExtra != nil && userInfoExtra!.pushAction == .removeThenNotice
        LarkNSELogger.logger.info("starts processing Intent identifier: \(request.identifier), shouldRemove: \(shouldNoticeAfterRemove)")
        if #available(iOSApplicationExtension 15.0, iOS 15.0, *) {
            LarkNSExtensionIntentsProcessor.processIntents(by: bestAttemptContent,
                                                           extra: extra) { content in
                LarkNSEContentProcessor.noticeAfterRemove(request: request,
                                                          shouldNoticeAfterRemove: shouldNoticeAfterRemove,
                                                          content: content,
                                                          contentHandler: contentHandler)
            }
        } else {
            LarkNSEContentProcessor.noticeAfterRemove(request: request,
                                                      shouldNoticeAfterRemove: shouldNoticeAfterRemove,
                                                      content: bestAttemptContent,
                                                      contentHandler: contentHandler)
        }
    }

    static private func noticeAfterRemove(request: UNNotificationRequest,
                                          shouldNoticeAfterRemove: Bool,
                                          content: UNNotificationContent,
                                          contentHandler: @escaping (UNNotificationContent) -> Void) {
        if shouldNoticeAfterRemove {
            UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: [request.identifier])
            DispatchQueue.main.asyncAfter(deadline: .now() + LarkNSEContentProcessor.delay) {
                contentHandler(content)
            }
        } else {
            contentHandler(content)
        }
    }

    /// 预期效果是 "聊天群名文字长度超过...-明日头条租户"
    static public func process(prefixString: String, tenantName: String) -> String {
        if tenantName.isEmpty {
            return prefixString
        }
        let maxPrefixStringLength: Int = 10
        let maxSenderLength: Int = 20
        let joinCharacter: String = "-"
        let trailingCharater: String = "..."

        let prefixStringLength = prefixString.count
        let tenantNameLength = tenantName.count
        let joinCharacterLength = joinCharacter.count

        /// 计算下总体是不是过长
        if prefixStringLength + tenantNameLength + joinCharacterLength <= maxSenderLength {
            return prefixString + joinCharacter + tenantName
        }

        var resultSender = prefixString
        /// 控制发送人名字/群名不超过 10 个字符
        if prefixStringLength > maxPrefixStringLength {
            resultSender = String(prefixString.prefix(maxPrefixStringLength))
            resultSender.append(trailingCharater)
        }

        return resultSender + joinCharacter + tenantName
    }
}

fileprivate extension String {
    func urlEncoded() -> String {
        let encodeUrlString = self.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
        return (encodeUrlString ?? "").replacingOccurrences(of: "&", with: "%26")
    }
}