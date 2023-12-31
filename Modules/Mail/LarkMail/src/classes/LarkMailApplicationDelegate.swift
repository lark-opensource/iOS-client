//
//  LarkMailAppDelegate.swift
//  LarkMail
//
//  Created by 龙伟伟 on 2022/2/7.
//

import Foundation
import AppContainer
import EENavigator
import NotificationUserInfo
import MailSDK
import LKCommonsLogging
import Swinject
import LarkSceneManager
import BootManager
import LarkAccountInterface
import LarkUIKit
import LarkTab

final class LarkMailApplicationDelegate: ApplicationDelegate {
    static let config = Config(name: "LarkMail", daemon: true)
    static let logger = Logger.log(LarkMailApplicationDelegate.self, category: "LarkMailApplicationDelegate")

    init(context: AppContext) {
        context.dispatcher.add(observer: self) { [weak self] (_, message) in
            self?.didReceiveNotification(message) ?? .just(Void())
        }
    }

    private func didReceiveNotification(_ message: DidReceiveNotification) -> DidReceiveNotification.HandleReturnType {
        LarkMailApplicationDelegate.logger.info("[mail_client_push] didReceiveNotification isRemote: \(message.notification.isRemote)")
        if !message.notification.isRemote {
            // 本地直接走处理
            handleLocalNotification(notification: message.notification)
            return .just(Void())
        }
        return .just(Void())
    }

    private func handleLocalNotification(notification: AppContainer.Notification) {
        LarkMailApplicationDelegate.logger.info("[mail_client_push] handleAPNSNotification notification: \(notification.userInfo)")
        guard let notiInfo = notification.userInfo["data"] as? [String: Any] else {
            LarkMailApplicationDelegate.logger.error("[mail_client_push] notification.userInfo data is nil")
            return
        }
        let currentResolver = Container.shared.getCurrentUserResolver()
        guard let service = try? currentResolver.resolve(assert: LarkMailService.self) else {
            LarkMailApplicationDelegate.logger.error("[mail_client_push] LarkMailTabHelper resolver is nil")
            return
        }
        let labelId = notiInfo["f_id"] as? String ?? ""
        let messageId = notiInfo["m_id"] as? String ?? ""
        let threadId = notiInfo["t_id"] as? String ?? ""
        let accountId = notiInfo["ma_id"] as? String ?? ""
        let feedCardId = notiInfo["fc_id"] as? String ?? ""
        let navi = LkNavigationController()
        navi.view.backgroundColor = UIColor.ud.primaryOnPrimaryFill
        let currentNavigator = currentResolver.navigator
        let routerInfo = MailDetailRouterInfo(threadId: threadId,
                                              messageId: messageId,
                                              sendMessageId: nil,
                                              sendThreadId: nil,
                                              labelId: labelId,
                                              accountId: accountId,
                                              cardId: nil,
                                              ownerId: nil,
                                              tab: Tab.mail.url,
                                              from: currentNavigator.mainSceneWindow?.fromViewController ?? navi,
                                              multiScene: false,
                                              statFrom: "notification",
                                              feedCardId: feedCardId)
        service.mail.showMailDetail(routerInfo: routerInfo)
    }
}
