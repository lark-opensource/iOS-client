//
//  LarkNSExtensionTodoProcessor.swift
//  LarkNotificationServiceExtension
//
//  Created by 白言韬 on 2021/1/5.
//

import Foundation
import NotificationUserInfo
import UserNotifications
import LarkExtensionServices

public final class LarkNSExtensionTodoProcessor: LarkNSExtensionContentProcessor {

    static let logger = LogFactory.createLogger(label: "LarkNSExtensionTodoProcessor")

    public init() {}

    public func transformNotificationExtra(with content: UNNotificationContent) -> Extra? {
        guard let extra = LarkNSETodoExtra.getTodoExtra(from: content.userInfo),
              let newMessageData = extra.data as? LarkNSETodoExtra.NewMessageData else {
            Self.logger.info("get messageData failed.")
            return nil
        }
        let todoContent = TodoPushContent(guid: newMessageData.guid)
        Self.logger.info("successful transform, guid:\(newMessageData.guid)")
        /// 打开Todo详情
        return Extra(type: .todo, content: todoContent)
    }

    public func transformNotificationAlter(with content: UNNotificationContent) -> Alert? {
        return Alert(title: content.title, subtitle: content.subtitle, body: content.body)
    }
}

protocol LarkNSETodoData {
    var guid: String { get }
}

// MARK: - LarkNSETodoExtra
struct LarkNSETodoExtra {
    struct NewMessageData: LarkNSETodoData {
        let guid: String
    }

    var data: LarkNSETodoData?

    public init?(dict: [String: Any]) {
        if let guid = dict["GUID"] as? String {
            self.data = NewMessageData(guid: guid)
        }
    }

    static func getTodoExtra(from userInfo: [AnyHashable: Any]) -> LarkNSETodoExtra? {
        /// get extra_str
        guard let extraString = LarkNSEExtra.getExtraDict(from: userInfo)?.extraString else {
            return nil
        }
        /// get Todo extra
        if let data = extraString.data(using: .utf8) {
            do {
                guard let dict = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
                    return nil
                }
                return LarkNSETodoExtra(dict: dict)
            } catch {
            }
        }
        return nil
    }
}
