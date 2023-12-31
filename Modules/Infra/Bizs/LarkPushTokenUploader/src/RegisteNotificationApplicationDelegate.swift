//
//  NotificationApplicationDelegate.swift
//  Lark
//
//  Created by liuwanlin on 2018/12/4.
//  Copyright © 2018 Bytedance.Inc. All rights reserved.
//

import Foundation
import AppContainer
import LKCommonsLogging
import EENotification
import LarkAccountInterface
import RxSwift
import UserNotifications
import LarkTracker
import LarkReleaseConfig
import LarkContainer
import LKCommonsTracker

public final class RegisteNotificationApplicationDelegate: ApplicationDelegate {
    static public let config = Config(name: "RemoteNotification", daemon: true)

    let logger = Logger.log(RegisteNotificationApplicationDelegate.self, category: "LarkNotification")

    lazy var apnsSubject: PublishSubject<String?> = {
        PublishSubject<String?>()
    }()

    lazy var apnsObservable: Observable<String?> = {
        return apnsSubject.asObservable()
    }()

    required public init(context: AppContext) {
        context.dispatcher.add(observer: self) { [weak self] (_, message: DidRegisterForRemoteNotifications) in
            guard let `self` = self else { return }
            let passportService = try? BootLoader.container.resolve(type: PassportService.self)
            guard let userID = passportService?.foregroundUser?.userID else {
                self.logger.error("user state is error, did not get userID")
                return
            }
            let userResolver = try? BootLoader.container.getUserResolver(userID: userID)
            let uploaderService = try? userResolver?.resolve(type: LarkPushTokenUploaderService.self)
            uploaderService?.subscribeApnsObservable(self.apnsObservable)
            self.didRegisterForRemoteNotifications(message)
        }

        context.dispatcher.add(observer: self) { [weak self] (_, message) in
            self?.didFailToRegisterForRemoteNotifications(message)
        }
    }

    private func didRegisterForRemoteNotifications(_ message: DidRegisterForRemoteNotifications) {
        self.logger.info("Receive system ApnsToken")
        let apnsToken = message.deviceToken
            .map { String(format: "%02.2hhx", $0) }
            .joined()

        apnsSubject.onNext(apnsToken)
    }

    private func didFailToRegisterForRemoteNotifications(_ message: DidFailToRegisterForRemoteNotifications) {
        apnsSubject.onNext(nil)
        self.logger.error("Fail to register for remote notifications", error: message.error)
    }
}
