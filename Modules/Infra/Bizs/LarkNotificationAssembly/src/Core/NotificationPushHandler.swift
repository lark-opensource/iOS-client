//
//  NotificationPushHandler.swift
//  LarkNotificationAssembly
//
//  Created by aslan on 2023/11/15.
//

import UIKit
import Foundation
import Homeric
import LarkRustClient
import LarkModel
import LarkContainer
import NotificationUserInfo
import EENotification
import UserNotifications
import LKCommonsLogging
import LKCommonsTracker
import LarkSDKInterface
import AppContainer
import RustPB
import LarkUIKit
import LarkAccountInterface
import LarkNotificationServiceExtension
import LarkLocalizations

public final class NotificationPushHandler: UserPushHandler {

    let logger = Logger.log(NotificationPushHandler.self, category: "LarkNotificationAssembly")

    private var pushCenter: PushNotificationCenter? { try? userResolver.userPushCenter }

    public func process(push message: RustPB.Basic_V1_Notification) {
        self.logger.info("process push notification: \(userResolver.userID)")
        guard message.shouldNotify else {
            self.logger.info("receive push but should not notify")
            return
        }
        guard case .messageData(_)? = message.extraData else {
            self.logger.info("receive push but not message data")
            return
        }
        guard let passportService = try? userResolver.resolver.resolve(type: PassportService.self) else {
            return
        }
        let targetUserID = message.messageData.targetUserID
        self.logger.info("receive push for user. \(targetUserID)")
        guard passportService.foregroundUser?.userID != String(targetUserID) else {
            self.logger.info("receive push but is foreground user")
            return
        }

        guard let userInfo = message.transformNotificationUserInfo(userResolver: self.userResolver) else {
            return
        }
        var request = NotificationRequest(group: "",
                                          identifier: message.transformIdentifier(),
                                          version: message.messageData.unitKey,
                                          userInfo: userInfo.toDict(),
                                          trigger: nil)
        request.soundName = userInfo.nseExtra?.soundUrl ?? "default"
        request.threadIdentifier = message.transformThreadIdentifier()
        self.handleNotitication(request: request, userInfo: userInfo)
    }

    func handleNotitication(request: NotificationRequest, userInfo: UserInfo) {
        NotificationManager.shared.getAllNotifications(completionHandler: { (reqs) in
            DispatchQueue.global().async {
                /// 能否在推送中心中找到已有的
                reqs.forEach { req in
                    if req.identifier == request.identifier {
                        /// 如果有，判断推送的版本
                        /// 如果版本一样，说明推送重复了，不应该再处理新的，直接中断
                        /// 如果版本不一样，应该用最新的覆盖掉，场景比如：撤回
                        if !req.version.isEmpty, !request.version.isEmpty, req.version == request.version {
                            self.logger.info("repeat nofitication: \(request.identifier)")
                            return
                        }
                    }
                }

                /// 判断是否要显示
                if let notificationRequest = request.transformNotificationRequest(), let nseExtra = userInfo.nseExtra {
                    guard let bestAttemptContent = (notificationRequest.content.mutableCopy() as? UNMutableNotificationContent) else {
                        self.logger.info("bestAttemptContent is nil")
                        return
                    }
                    /// 经过content内容的处理，处理成通信通知
                    LarkNSEContentProcessor.processContent(extra: nseExtra, request: notificationRequest, bestAttemptContent: bestAttemptContent) { content in
                        guard let newContent = (content.mutableCopy() as? UNMutableNotificationContent) else {
                            return
                        }
                        if #available(iOSApplicationExtension 15.0, iOS 15.0, *), let extra = userInfo.nseExtra, extra.isUrgent {
                            /// 加急展示即时通知样式
                            newContent.interruptionLevel = .timeSensitive
                        }
                        let newRequest = UNNotificationRequest(identifier: request.identifier, content: newContent, trigger: notificationRequest.trigger)
                        DispatchQueue.main.async {
                            NotificationManager
                            .shared
                            .addOrUpdateNotification(
                                request: newRequest,
                                withCompletionHandler: { [weak self] (error) in
                                    self?.logger.info("Notification complete, identifier: \(request.identifier), error: \(error.debugDescription)")
                                }
                            )
                        }
                    }
                }
            }
        })
    }
}

extension RustPB.Basic_V1_Notification {
    fileprivate func transformIdentifier() -> String {
        /// identifier 生成规则：https://bytedance.larkoffice.com/wiki/wikcn34M5fz7Zonnjnce4PdqbCg
        return self.id
    }

    fileprivate func transformThreadIdentifier() -> String {
        if self.messageData.hasThreadID {
            return self.messageData.threadID
        }
        return self.messageData.chatID
    }

    fileprivate func transformPushChannel() -> PushChannel {
        if self.messageData.chatMode == .thread || self.messageData.chatMode == .threadV2 {
            return .thread
        }
        if self.messageData.hasThreadID {
            return .msg_thread
        }
        return .chat
    }

    fileprivate func transformPosition() -> Int32 {
        if self.messageData.hasPosition {
            return self.messageData.position
        }
        if self.messageData.hasThreadMessagePosition {
            return self.messageData.threadMessagePosition
        }
        return 0
    }

    fileprivate func transformNotificationUserInfo(userResolver: UserResolver) -> UserInfo? {
        guard let passportService = try? userResolver.resolver.resolve(type: PassportService.self) else {
            return nil
        }
        let user = passportService.getUser(String(self.messageData.targetUserID))
        var title = self.title
        let appName = LanguageManager.bundleDisplayName
        if !self.messageData.isShowDetail {
            /// 通知设置，推送不展示详情，title应该展示app name
            title = appName
        } else {
            /// 展示详情请看，需要拼接租户名称，当前用户不会收到在线notification，所以这里默认都是需要拼接租户名称
            title = title.isEmpty ? appName : title
            title = LarkNSEContentProcessor.process(prefixString: title, tenantName: user?.tenant.tenantName ?? "")
        }
        let notificationAlert = Alert(title: title, subtitle: self.subTitle, body: self.content)
        let identifier = self.transformIdentifier()
        var notificationUserInfo = UserInfo(group: self.messageData.chatID, identifier: identifier, alert: notificationAlert)
        let nseExtra = LarkNSEExtra(Sid: self.messageData.chatID,
                                    time: UInt64(self.messageData.createTime),
                                    direct: .pushToMessage,
                                    command: 0,
                                    contentMutable: true,
                                    mutableBadge: true,
                                    notIncreaceBadge: true,
                                    chatId: Int64(self.messageData.chatID),
                                    userId: String(self.messageData.targetUserID),
                                    position: self.transformPosition(),
                                    threadId: Int64(self.messageData.threadID),
                                    messageID: Int64(self.messageData.messageID),
                                    originDict: [:],
                                    quickReply: self.messageData.quickReplyCategory,
                                    imageUrl: self.messageData.avatarPath,
                                    channel: self.transformPushChannel(),
                                    biz: .lark,
                                    isRecall: self.messageData.hasRecallerID,
                                    isUrgent: self.messageData.type == .urgent,
                                    isShowDetail: self.messageData.isShowDetail,
                                    chatDigestId: self.messageData.chatID,
                                    senderDigestId: self.messageData.fromChatterID,
                                    senderName: self.messageData.fromChatterName,
                                    groupName: self.messageData.channelName,
                                    tenantName: user?.tenant.tenantName ?? "",
                                    isReply: false,
                                    groupSize: 10, /// 这个没啥用
                                    isMentioned: self.messageData.type == .at,
                                    pruneOutline: !self.messageData.notCommNotification,
                                    isNotComm: self.messageData.notCommNotification,
                                    messageType: -1,
                                    soundUrl: self.messageData.soundURL,
                                    isRemote: false)
        notificationUserInfo.nseExtra = nseExtra
        return notificationUserInfo
    }
}
