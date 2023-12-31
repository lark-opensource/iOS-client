//
//  LarkNSExtensionOpenAppChatProcessor.swift
//  LarkNotificationServiceExtension
//
//  Created by 袁平 on 2020/5/21.
//

import UserNotifications
import Foundation
import NotificationUserInfo

/// https://bytedance.feishu.cn/docs/doccntI12wmTi9UOilZOqFKK2qf#vHfh8F
struct LarkNSAppChatExtra {
    let appId: String?
    let iosSchema: String?
    let feedId: String?
    let seqId: UInt64?

    public init(dict: [String: Any]) {
        appId = dict["cli_app_id"] as? String
        iosSchema = dict["ios_schema"] as? String
        feedId = dict["open_app_chat_feed_id"] as? String
        seqId = dict["last_notification_seq_id"] as? UInt64
    }

    static func getExtraDict(from userInfo: [AnyHashable: Any]) -> LarkNSAppChatExtra? {
        guard let extraString = LarkNSEExtra.getExtraDict(from: userInfo)?.extraString else {
            return nil
        }
        if let data = extraString.data(using: .utf8) {
            do {
                guard let dict = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
                    return nil
                }
                return LarkNSAppChatExtra(dict: dict)
            } catch {}
        }
        return nil
    }
}

public final class LarkNSExtensionOpenAppChatProcessor: LarkNSExtensionContentProcessor {

    public init() {}

    public func transformNotificationExtra(with content: UNNotificationContent) -> Extra? {
        guard let extra = LarkNSEExtra.getExtraDict(from: content.userInfo),
            let appChatExtra = LarkNSAppChatExtra.getExtraDict(from: content.userInfo) else {
            let content = OpenAppChatContent(url: "")
            return Extra(type: .openAppChat, content: content)
        }
        var urlString = ""
        var chatId: String?
        var type = "bot"
        if let id = extra.chatId, let feedId = appChatExtra.feedId {
            chatId = "\(id)"
            urlString = "//client/chat/\(id)?fromWhere=push&feedId=\(feedId)"
        }
        // 如果有appId，表示是小程序通知
        if appChatExtra.appId != nil, let appUrl = appChatExtra.iosSchema {
            type = "app"
            urlString = appUrl
            if var component = URLComponents(string: urlString),
                let seqId = appChatExtra.seqId,
                let feedId = appChatExtra.feedId {
                var items = component.queryItems
                items?.append(URLQueryItem(name: "seqID", value: "\(seqId)"))
                items?.append(URLQueryItem(name: "feedID", value: feedId))
                component.queryItems = items
                urlString = component.url?.absoluteString ?? appUrl
            }
        }
        // 打点信息
        if var component = URLComponents(string: urlString) {
            var items = component.queryItems
            items?.append(URLQueryItem(name: "appId", value: appChatExtra.appId))
            items?.append(URLQueryItem(name: "chatId", value: chatId))
            items?.append(URLQueryItem(name: "type", value: type))
            component.queryItems = items
            urlString = component.url?.absoluteString ?? urlString
        }
        let content = OpenAppChatContent(url: urlString)
        return Extra(type: .openAppChat, content: content)
    }

    public func transformNotificationAlter(with content: UNNotificationContent) -> Alert? {
        return Alert(title: content.title, subtitle: content.subtitle, body: content.body)
    }
}
