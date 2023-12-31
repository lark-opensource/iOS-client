//
//  LarkNSExtensionDocsProcessor.swift
//  LarkNotificationServiceExtension
//
//  Created by chenjiahao.gill on 2019/9/5.
//

import Foundation
import NotificationUserInfo
import UserNotifications

public final class LarkNSExtensionDocsProcessor: LarkNSExtensionContentProcessor {
    enum PushType: String {
        case uploadPics = "PUSH_UPLOAD_PICS"
        case docFeed = "PUSH_DOC_FEED"
    }

    public init() {}

    public func transformNotificationExtra(with content: UNNotificationContent) -> Extra? {
        let userInfoExtra = LarkNSExtensionDocsProcessor.getExtra(content)
        let bizParamter = LarkNSExtensionDocsProcessor.convertStrToDict(userInfoExtra?["extra_str"] as? String)
        guard let type = bizParamter?["type"] as? String else {
            return Extra(type: .docs, content: MessageContent(messageId: "", url: "", state: .normal))
        }
        if type == PushType.docFeed.rawValue {
            // Docs Feed 推送
            let data = bizParamter?["data"] as? [String: Any]
            if let msgID = data?["msg_id"] as? String,
                let feedID = data?["feed_id"] as? String {
                let key = "" // 不影响业务
                return Extra(type: .docs, content: MessageContent(messageId: "", url: "//client/doc?key=\(key)&channelID=\(feedID)&lastMessageID=\(msgID)&sourceType=push", state: .normal))
            }
        } else if type == PushType.uploadPics.rawValue {
            if let body = LarkNSExtensionDocsProcessor.convertDocImageBody(content)?.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) {
                return Extra(type: .docs, content: MessageContent(messageId: "", url: "//client/docs/noticePush?data=\(body)&fromNotice=1", state: .normal))
            }
        }
        return Extra(type: .docs, content: MessageContent(messageId: "", url: "", state: .normal))
    }

    public func transformNotificationAlter(with content: UNNotificationContent) -> Alert? {
        return Alert(title: content.title, subtitle: content.subtitle, body: content.body)
    }

}
// MARK: - Conver
extension LarkNSExtensionDocsProcessor {
    static func convertStrToDict(_ str: String?) -> [String: Any]? {
        guard let data = str?.data(using: .utf8)  else {
            return nil
        }
        do {
            if let dict = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                return dict
            } else {
                return nil
            }
        } catch {
            return nil
        }
    }

    static func getExtra(_ content: UNNotificationContent) -> [String: Any]? {
        let userInfo = content.userInfo
        let extra = userInfo["extra_str"] as? String
        let dict = convertStrToDict(extra)
        return dict
    }

    static func convertDocImageBody(_ content: UNNotificationContent) -> String? {
        let extra = LarkNSExtensionDocsProcessor.getExtra(content)
        let body = extra?["extra_str"] as? String
        return body
    }
}
