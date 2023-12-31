//
//  MailNotificationPushHandler.swift
//  LarkMail
//
//  Created by 龙伟伟 on 2022/1/30.
//

import Foundation
import RustPB
import LarkRustClient
import LarkContainer
import LarkSDKInterface
import LKCommonsLogging
import MailSDK

class MailNotificationPushHandler: UserPushHandler {
    static let logger = Logger.log(MailNotificationPushHandler.self, category: "MailNotificationPushHandler")

    func process(push: MailPushNotificationResponse) throws {
        MailNotificationPushHandler.logger.info("[mail_client_push] receive notification push, message id: \(push.id)")
        mailClientNewMailPush(message: push)
    }

    private func mailClientNewMailPush(message: MailPushNotificationResponse) {
        guard MailSettingManagerInterface.mailClient && message.shouldNotify && !message.mailData.threadID.isEmpty else { return }
        let content = UNMutableNotificationContent()
        content.title = "📮" + message.mailData.fromChatterID
        content.subtitle = message.title
        content.body = message.content
        content.badge = NSNumber(value: message.mailData.newMessageCount)
        content.userInfo = ["Sid": message.mailData.threadID,
                            "Time": message.mailData.createTime,
                            "direct": 1,
                            "mutable_content": message.mailData.newMessageCount > 1,
                            "mutable_badge": message.mailData.newMessageCount > 1,
                            "extra_str": "//client/mail/home",
                            "channel": message.mailData.channel.id,
                            "biz": "mail",
                            "type": "PUSH_MAIL_NEW_MESSAGE",
                            "data": ["t_id": message.mailData.threadID,
                                     "m_id": message.mailData.messageID,
                                     "ma_id": message.mailData.mailAccountID,
                                     "f_id": message.mailData.labelID],
                                     "fc_id": message.mailData.feedCardID]
        MailNotificationPushHandler.logger.info("[mail_client_push] content info, message id: \(message.mailData.messageID), threadID: \(message.mailData.threadID), feedID: \(message.mailData.feedCardID)")
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 2, repeats: false)
        let requestIdentifer = "MailClientUNNotificationRequest_\(message.mailData.threadID)"
        let request = UNNotificationRequest(identifier: requestIdentifer, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request, withCompletionHandler: { error in
            MailNotificationPushHandler.logger.info("[mail_client_push] sendLocalNotification -- completed, err: \(String(describing: error))")
        })
        MailNotificationPushHandler.logger.info("[mail_client_push] scheduleLocalNotification -- localNotice threadID: \(message.mailData.threadID)")
    }
}
