//
//  LarkNSExtensionDispatcher.swift
//  LarkNotificationServiceExtension
//
//  Created by mochangxing on 2019/8/21.
//
import Foundation
import UserNotifications
import NotificationUserInfo
import LarkExtensionServices
import LarkHTTP
import LarkStorageCore

#if DEBUG
public let appGrounpName = "group.com.bytedance.ee.lark.yzj"
#else
public let appGrounpName = Bundle.main.infoDictionary?["EXTENSION_GROUP"] as? String ?? ""
#endif

public final class LarkNSExtensionDispatcher {
    static let tracingId = UUID().uuidString

    var contentHandler: ((UNNotificationContent) -> Void)?
    var bestAttemptContent: UNMutableNotificationContent?
    var originAttemptContent: UNMutableNotificationContent?

    public init() {
    }

    public func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
        self.contentHandler = contentHandler
        originAttemptContent = (request.content.mutableCopy() as? UNMutableNotificationContent)
        bestAttemptContent = (request.content.mutableCopy() as? UNMutableNotificationContent)

        guard let bestAttemptContent = bestAttemptContent else {
            /// 仅作为兜底，不会出现这个异常
            LarkNSELogger.logger.error("bestAttemptContent is nil")
            HTTP.trackForLark(event: "im_ios_apns_parse_fail_dev")
            return
        }

        #if !LARK_NO_DEBUG
        // cache received content for debugging
        cacheReceivedContent(bestAttemptContent)
        #endif

        guard let extra = LarkNSEExtra.getExtraDict(from: bestAttemptContent.userInfo) else {
            /// extra json 异常时候才会遇到，几乎不会有
            let description = bestAttemptContent.userInfo.description
            HTTP.trackForLark(event: "im_ios_apns_parse_fail_dev")
            LarkNSELogger.logger.error("userInfo is invalid: \(description)")
            ExtensionTracker.shared.trackSlardarEvent(key: "APNs_transfer_extra_error", metric: [:], category: [:], params: [:])

            contentHandler(bestAttemptContent)
            return
        }

        /// 横幅展示埋点：https://bytedance.larkoffice.com/sheets/KX0Psp7nFhbPYatdMSkck2ycn8q
        ExtensionTracker.shared.trackTeaEvent(key: "public_push_notification_view", params: [
            "sub_user_id": extra.userId ?? "",
            "msg_id": extra.messageID ?? 0,
            "is_online_message": extra.isRemote ? "false" : "true"
        ], md5AllowList: ["sub_user_id"])

        if extra.isRemote {
            /// remote notification 才进行到达率上报
            HTTP.trackForLark(event: "im_ios_apns_received_dev", parameters: [
                "chat_id": extra.chatId ?? 0,
                "message_id": extra.messageID ?? 0,
                "sid": extra.Sid,
                "biz": extra.biz?.rawValue ?? "unkonwn"
            ]) { response in
                LarkNSELogger.logger.info("[track receive notification] \(String(describing: response.text))")
            }
        }

        let category: [String: Any] = ["Sid": extra.Sid, "messageId": extra.messageID ?? ""]
        ExtensionTracker.shared.trackSlardarEvent(key: "APNs_receive", metric: [:], category: category, params: [:])

        LarkNSELogger.logger.info("Receive Notification, Sid: \(extra.Sid), RecTime: \(Date().timeIntervalSince1970 * 1000), "
                                  + "messageID: \(String(describing: extra.messageID))"
                                  + "bizType: \(extra.biz)")
        // 通知诊断的发消息推送
        if extra.messageType == 26 {
            let messageIDStr = extra.messageID.map(String.init) ?? ""
            KVPublic.NotificationDiagnosis.message.setValue(messageIDStr)
        }

        // badge
        LarkNSExtensionBadgeProcessor.processBadge(bestAttemptContent, extra: extra)

        // content
        LarkNSEContentProcessor.processContent(extra: extra, request: request, bestAttemptContent: bestAttemptContent) { content in
            contentHandler(content)
        }
    }

    public func serviceExtensionTimeWillExpire() {
        // Called just before the extension will be terminated by the system.
        // Use this as an opportunity to deliver your "best attempt" at modified content, otherwise the original push payload will be used.
        if let contentHandler = contentHandler, let bestAttemptContent = originAttemptContent {
            LarkNSELogger.logger.info("ServiceExtension Time Will Expire")

            if let extra = LarkNSEExtra.getExtraDict(from: bestAttemptContent.userInfo) {
                let category: [String: Any] = ["Sid": extra.Sid, "messageId": extra.messageID ?? ""]
                ExtensionTracker.shared.trackSlardarEvent(key: "APNs_timeout", metric: [:], category: category, params: [:])
            }
            contentHandler(bestAttemptContent)
        }
    }
}

#if !LARK_NO_DEBUG
extension LarkNSExtensionDispatcher {
    private func cacheReceivedContent(_ content: UNMutableNotificationContent) {
        guard
            NotificationDebugCache.isEnabled,
            let extraString = content.userInfo["extra_str"] as? String,
            let data = extraString.data(using: .utf8)
        else {
            return
        }

        do {
            var body = "***"
            if content.body.count > 4 {
                let lowerBound = content.body.startIndex
                let upperBound = content.body.index(content.body.startIndex, offsetBy: 2)
                body = content.body[lowerBound..<upperBound] + body
            }
            var dict: [String: Any] = [:]
            if let dictionary = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                dict = dictionary
                dict["apns.title"] = content.title
                dict["apns.body"] = body
            }

            var data: [[String: Any]] = []
            if let dataSource = NotificationDebugCache.receivedContents {
                data = dataSource
            }
            data.append(dict)

            NotificationDebugCache.receivedContents = data
        } catch {
        }
    }
}


// lint:disable lark_storage_check - for debugging

/// 缓存「离线通知」信息，方便在「主 App」Debug 面板中查看
public struct NotificationDebugCache {

    private static var store: UserDefaults? = {
        #if DEBUG
        UserDefaults(suiteName: "group.com.bytedance.ee.lark.yzj")
        #else
        UserDefaults(suiteName: AppConfig.AppGroupName)
        #endif
    }()

    public static var isEnabled: Bool {
        get {
            store?.bool(forKey: "com.bytedance.ee.isEnabled") ?? false
        }
        set {
            store?.setValue(newValue, forKey: "com.bytedance.ee.isEnabled")
        }
    }

    public static var receivedContents: [[String: Any]]? {
        get {
            store?.array(forKey: "com.bytedance.ee.notifications") as? [[String: Any]]
        }
        set {
            store?.setValue(newValue, forKey: "com.bytedance.ee.notifications")
        }
    }
}

// lint:enable lark_storage_check - for debugging

#endif
