//
//  NotificationPassportDelegate.swift
//  LarkNotificationAssembly
//
//  Created by aslan on 2023/11/28.
//

import Foundation
import RxSwift
import LKCommonsLogging
import Swinject
import LarkAccountInterface
import LarkContainer
import EENotification
import NotificationUserInfo
import LarkNotificationContentExtension

public final class NotificationPassportDelegate: PassportDelegate {
    public let name: String = "NotificationPassportDelegate"

    private let logger = Logger.log(NotificationPassportDelegate.self, category: "LarkNotificationAssembly")

    private let resolver: Resolver
    private var userResolver: UserResolver?

    public init(resolver: Resolver) {
        self.resolver = resolver
    }

    /// 登录、退出需要消费掉该用户的推送
    func removeUserNotification(userId: String) {
        NotificationManager.shared.getAllNotifications { [weak self] reqs in
            self?.logger.info("get all notification count: \(reqs.count)")
            reqs.forEach { req in
                self?.logger.info("req.identifier: \(req.identifier)")
                let extra = LarkNCEExtra.getExtraDict(from: req.userInfo)
                if userId == extra?.userId {
                    self?.logger.info("remove notification: \(req.identifier)")
                    NotificationManager.shared.removeNotification(identifier: req.identifier)
                }
            }
        }
    }

    public func userDidOnline(state: PassportState) {
        guard state.loginState == .online,
              let userId = state.user?.userID else { return }
        logger.info("userDidOnline: \(userId)")
        self.removeUserNotification(userId: userId)
    }

    public func userDidOffline(state: PassportState) {
        guard state.loginState == .offline,
              let userId = state.user?.userID else { return }
        logger.info("userDidOffline: \(userId)")
        self.removeUserNotification(userId: userId)
    }

    public func backgroundUserDidOffline(state: PassportState) {
        guard state.loginState == .offline,
              let userId = state.user?.userID else { return }
        logger.info("backgroundUser did offline \(userId)")
        self.removeUserNotification(userId: userId)
    }
}
