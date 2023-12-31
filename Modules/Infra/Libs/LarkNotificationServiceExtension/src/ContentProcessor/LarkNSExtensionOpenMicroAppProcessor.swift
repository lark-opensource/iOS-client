//
//  LarkNSExtensionOpenMicroAppProcessor.swift
//  LarkNotificationServiceExtension
//
//  Created by ByteDancer on 2022/5/30.
//

import UserNotifications
import Foundation
import NotificationUserInfo

struct LarkNSMicroAppExtra {
    let appId: String?
    let iosSchema: String?
    let appId64: UInt64?
    let seqId: UInt64?

    public init(dict: [String: Any]) {
        appId64 = dict["i64_app_id"] as? UInt64
        appId = dict["cli_app_id"] as? String
        iosSchema = dict["ios_schema"] as? String
        seqId = dict["last_notification_seq_id"] as? UInt64
    }

    static func getExtraDict(from userInfo: [AnyHashable: Any]) -> LarkNSMicroAppExtra? {
        guard let extraString = LarkNSEExtra.getExtraDict(from: userInfo)?.extraString else {
            LarkNSELogger.logger.info("[NSE] extraString nothing")
            return nil
        }
        if let data = extraString.data(using: .utf8) {
            do {
                guard let dict = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
                    LarkNSELogger.logger.info("[NSE] data nothing")
                    return nil
                }
                LarkNSELogger.logger.info("[NSE] dict:\(dict)")
                return LarkNSMicroAppExtra(dict: dict)
            } catch {}
        }
        return nil
    }
}

public final class LarkNSExtensionOpenMicroAppProcessor: LarkNSExtensionContentProcessor {
    public init() {}

    public func transformNotificationExtra(with content: UNNotificationContent) -> Extra? {
        guard let appChatExtra = LarkNSMicroAppExtra.getExtraDict(from: content.userInfo) else {
            let content = OpenMicroAppContent(url: "")
            return Extra(type: .openMicroApp, content: content)
        }
        let urlString: String = appChatExtra.iosSchema ?? ""
        LarkNSELogger.logger.info("[NSE] url:\(urlString)")
        let content = OpenMicroAppContent(url: urlString)
        return Extra(type: .openMicroApp, content: content)
    }

    public func transformNotificationAlter(with content: UNNotificationContent) -> Alert? {
        return Alert(title: content.title, subtitle: content.subtitle, body: content.body)
    }
}
