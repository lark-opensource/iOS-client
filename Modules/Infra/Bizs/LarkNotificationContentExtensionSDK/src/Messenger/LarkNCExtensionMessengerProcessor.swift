//
//  LarkNCExtensionMessengerProcessor.swift
//  LarkNotificationContentExtension
//
//  Created by yaoqihao on 2022/4/6.
//

import UIKit
import Foundation
import UserNotifications
import UserNotificationsUI
import LarkExtensionServices
import LarkNotificationContentExtension

public final class LarkNCExtensionMessengerProcessor: LarkNotificationContentExtensionProcessor {
    public static var category: String = MessengerCategory.category

    public static func registerCategory() -> UNNotificationCategory {
        LarkNCESDKLogger.logger.info("Register Messenger Category")
        return MessengerCategory.getCategory()
    }

    weak public var notificationViewController: UIViewController?

    var actionIdentifier: String = ""

    public var updateBlock: ((UIView?) -> Void)?

    private var inputView: LarkNCExtensionKeyboard = LarkNCExtensionKeyboard(frame: CGRect(x: 0, y: 0, width: 340, height: 62))

    required public init() { }

    public func didReceive(_ notification: UNNotification, context: NSExtensionContext?) {
        ExtensionTracker.shared.trackTeaEvent(key: "public_push_detail_view", params: [:])
    }

    public func didReceive(_ response: UNNotificationResponse,
                           from: LarkNotificationContentSource,
                           context: NSExtensionContext?,
                           completionHandler completion: @escaping (UNNotificationContentExtensionResponseOption?) -> Void) {
        let fromString = from == .watchOS ? "watchOS" : "iOS"
        LarkNCESDKLogger.logger.info("MessengerProcessor Receive UNNotificationResponse ActionIdentifier :\(response.actionIdentifier), from: \(fromString)")
        guard let extra = LarkNCEExtra.getExtraDict(from: response.notification.request.content.userInfo) else {
            LarkNCESDKLogger.logger.info("Extra error")
            completion(.dismiss)
            return
        }

        actionIdentifier = response.actionIdentifier

        let subUserId = extra.userId
        let currentAccountID = ExtensionAccountService.currentAccountID ?? ""
        let ifCrossTenant = subUserId == currentAccountID

        LarkNCExtensionMessengerAPI.sendReadMessage(extra.messageID, chatID: extra.chatId, userId: extra.userId)
        if response.actionIdentifier == "replyAction" {
            switch from {
            case .iOS:
                /// 回复按钮
                Self.trackReplyClick(msgId: extra.messageID,
                                     userId: subUserId,
                                     ifCrossTenant: ifCrossTenant,
                                     isWatch: false,
                                     isRemote: extra.isRemote)

                self.notificationViewController?.becomeFirstResponder()
                inputView.textView.becomeFirstResponder()
                inputView.sendCallBack = { (text) in
                    LarkNCExtensionMessengerAPI.sendReplyMessage(text, messageID: extra.messageID, chatID: extra.chatId, userId: extra.userId) { success in
                        completion(.dismiss)
                        if success {
                            Self.trackMsgSend(msgId: extra.messageID, 
                                              userId: subUserId,
                                              ifCrossTenant: ifCrossTenant,
                                              isWatch: false,
                                              isRemote: extra.isRemote)
                        }
                    }
                    DispatchQueue.global().asyncAfter(deadline: .now() + 1) {
                        LarkNCESDKLogger.logger.info("Send Reply Message Timeout")
                        let category: [String: Any] = ["messageId": extra.messageID, "status": "timeout"]
                        ExtensionTracker.shared.trackSlardarEvent(key: "APNs_reply_message",
                                                                  metric: [:],
                                                                  category: category,
                                                                  params: [:])
                        /// 补充日志
                        completion(.dismiss)
                    }
                }

                inputView.sendEmotionCallBack = { (key) in
                    LarkNCExtensionMessengerAPI.sendReaction(key, messageID: extra.messageID, userId: extra.userId) { success in
                        /// 补充日志
                        LarkNCESDKLogger.logger.info("Send Reaction MessageID:\(extra.messageID) text: \(key)")
                        completion(.dismiss)
                        if success {
                            Self.trackMsgSend(msgId: extra.messageID, 
                                              userId: subUserId,
                                              ifCrossTenant: ifCrossTenant,
                                              isWatch: false,
                                              isRemote: extra.isRemote)
                        }
                    }
                    DispatchQueue.global().asyncAfter(deadline: .now() + 1) {
                        LarkNCESDKLogger.logger.info("Send Reply Message Timeout")
                        let category: [String: Any] = ["messageId": extra.messageID, "type": key, "status": "timeout"]
                        ExtensionTracker.shared.trackSlardarEvent(key: "APNs_reply_reaction",
                                                                  metric: [:],
                                                                  category: category,
                                                                  params: [:])
                        /// 补充日志
                        completion(.dismiss)
                    }
                }
            case .watchOS:
                guard let res = response as? UNTextInputNotificationResponse else {
                    completion(.dismiss)
                    return
                }
                LarkNCExtensionMessengerAPI.sendReplyMessage(res.userText, messageID: extra.messageID, chatID: extra.chatId, userId: extra.userId) { success in
                    /// 补充日志
                    completion(.dismiss)
                    if success {
                        /// watch 上回复
                        Self.trackMsgSend(msgId: extra.messageID, 
                                          userId: subUserId,
                                          ifCrossTenant: ifCrossTenant,
                                          isWatch: true,
                                          isRemote: extra.isRemote)
                    }
                }
                timeout { options in
                    let category: [String: Any] = ["messageId": extra.messageID, "status": "timeout"]
                    ExtensionTracker.shared.trackSlardarEvent(key: "APNs_reply_message",
                                                              metric: [:],
                                                              category: category,
                                                              params: [:])
                    completion(options)
                }
            @unknown default:
                break
            }
        } else if response.actionIdentifier == "okAction" {
            LarkNCExtensionMessengerAPI.sendReaction("OK", messageID: extra.messageID, userId: extra.userId) { success in
                /// 补充日志
                LarkNCESDKLogger.logger.info("Send Reaction MessageID:\(extra.messageID) text: OK")
                completion(.dismiss)
                if success {
                    /// OK回复
                    Self.trackMsgSend(msgId: extra.messageID, 
                                      userId: subUserId,
                                      ifCrossTenant: ifCrossTenant,
                                      isWatch: false,
                                      isRemote: extra.isRemote)
                }
            }

            timeout { options in
                let category: [String: Any] = ["messageId": extra.messageID, "type": "OK", "status": "timeout"]
                ExtensionTracker.shared.trackSlardarEvent(key: "APNs_reply_reaction",
                                                          metric: [:],
                                                          category: category,
                                                          params: [:])
                completion(options)
            }
        }
    }

    static func trackMsgSend(msgId: String?, userId: String?, ifCrossTenant: Bool, isWatch: Bool, isRemote: Bool) {
        /// 消息发送埋点：https://bytedance.larkoffice.com/sheets/KX0Psp7nFhbPYatdMSkck2ycn8q
        ExtensionTracker.shared.trackTeaEvent(key: "public_push_detail_click", params: [
            "click": "msg_send",
            "msg_id": msgId ?? "",
            "if_cross_tenant": ifCrossTenant ? "true" : "false",
            "sub_user_id": userId ?? "",
            "is_watch": isWatch,
            "target": "none",
            "is_online_message": isRemote ? "false" : "true"
        ], md5AllowList: ["sub_user_id"])
    }

    static func trackOKSend(msgId: String?, userId: String?, ifCrossTenant: Bool, isWatch: Bool, isRemote: Bool) {
        /// ok点击埋点：https://bytedance.larkoffice.com/sheets/KX0Psp7nFhbPYatdMSkck2ycn8q
        ExtensionTracker.shared.trackTeaEvent(key: "public_push_detail_click", params: [
            "click": "ok",
            "msg_id": msgId ?? "",
            "if_cross_tenant": ifCrossTenant ? "true" : "false",
            "sub_user_id": userId ?? "",
            "is_watch": isWatch,
            "target": "none",
            "is_online_message": isRemote ? "false" : "true"
        ], md5AllowList: ["sub_user_id"])
    }

    static func trackReplyClick(msgId: String?, userId: String?, ifCrossTenant: Bool, isWatch: Bool, isRemote: Bool) {
        /// 回复点击埋点：https://bytedance.larkoffice.com/sheets/KX0Psp7nFhbPYatdMSkck2ycn8q
        ExtensionTracker.shared.trackTeaEvent(key: "public_push_detail_click", params: [
            "click": "reply",
            "msg_id": msgId ?? "",
            "if_cross_tenant": ifCrossTenant ? "true" : "false",
            "sub_user_id": userId ?? "",
            "is_watch": isWatch,
            "target": "none",
            "is_online_message": isRemote ? "false" : "true"
        ], md5AllowList: ["sub_user_id"])
    }

    public func getContentView() -> UIView? {
        return nil
    }

    public func getInputView(_ response: UNNotificationResponse?) -> UIView? {
        let actionIdentifier = response?.actionIdentifier
        if actionIdentifier == "replyAction" {
            return inputView
        }
        return nil
    }

    public func getInputViewHeight(_ response: UNNotificationResponse?) -> CGFloat {
        let actionIdentifier = response?.actionIdentifier
        if actionIdentifier == "replyAction" {
            return 62
        }
        return 0
    }

    private func timeout(completionHandler completion: @escaping (UNNotificationContentExtensionResponseOption?) -> Void) {
        DispatchQueue.global().asyncAfter(deadline: .now() + 2) {
            /// 补充日志
            LarkNCESDKLogger.logger.info("Timeout")
            completion(.dismiss)
        }
    }
}
