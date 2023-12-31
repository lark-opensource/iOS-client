//
//  NotificationApplicationDelegate.swift
//  LarkNotificationAssembly
//
//  Created by liuwanlin on 2018/12/4.
//  Copyright © 2018 Bytedance.Inc. All rights reserved.
//

import UIKit
import Foundation
import AppContainer
import LKCommonsLogging
import EENotification
import NotificationUserInfo
import LarkAccountInterface
import RxSwift
import UserNotifications
import LarkTracker
import LarkReleaseConfig
import LarkContainer
import Homeric
import LKCommonsTracker
import EENavigator
import LarkAppConfig
import LarkFoundation
import LarkRustClient
import UserNotificationsUI
import LarkNotificationContentExtension
import UniverseDesignDialog
import LarkNavigator
import BootManager
import LarkDialogManager

typealias I18N = BundleI18n.LarkNotificationAssembly

public final class NotificationApplicationDelegate: ApplicationDelegate {
    static public let config = Config(name: "Notification", daemon: true)

    static let logger = Logger.log(NotificationApplicationDelegate.self, category: "LarkNotificationAssembly")

    var notificationBackgroundTaskId: UIBackgroundTaskIdentifier?

    @InjectedSafeLazy var passportService: PassportService // Global

    let notificationSubject = PublishSubject<Void>()

    lazy var notificationObservable: Observable<Void> = {
        return notificationSubject.asObservable()
    }()

    lazy var rustAPI: NotificationRustAPI = {
        NotificationRustAPI()
    }()

    required public init(context: AppContext) {
        context.dispatcher.add(observer: self) { [weak self] (_, message: DidReceiveNotification) in
            guard let `self` = self else { return Observable<Void>.just(()) }
            self.didReceiveNotification(message)
            return self.notificationObservable
        }

        context.dispatcher.add(observer: self) { [weak self] (_, _: WillEnterForeground) in
            self?.removeNotifications()
        }

        context.dispatcher.add(observer: self) { [weak self] (_, message: DidReceiveBackgroundNotification) in
            self?.didReceiveNotification(message)
            return Observable<Void>.just(())
        }

        /// 跨租户推送会转local notification，在前台时候弹出
        context.dispatcher.add(observer: self) { [weak self] (_, message: DidReceiveNotificationFront) in
            let userID = self?.passportService.foregroundUser?.userID
            let extra = LarkNCEExtra.getExtraDict(from: message.request.content.userInfo)
            if let e = extra,
               !e.userId.isEmpty,
               e.userId != userID {
                Self.logger.info("alert background user notification: \(String(e.userId))")
                let options: UNNotificationPresentationOptions = .alert
                return .just([options, .sound])
            }
            if extra?.userId == userID {
                Self.logger.info("ignore foregroundUser notification")
            } else {
                Self.logger.info("igonre notification. \(String(describing: extra))")
            }
            return .just([])
        }
        
        self.removeNotifications()
    }
    
    private func removeNotifications() {
        // 只移除当前租户的推送
        NotificationManager.shared.getAllNotifications { [weak self] reqs in
            Self.logger.info("get all notification count: \(reqs.count)")
            guard let userID = self?.passportService.foregroundUser?.userID else {
                Self.logger.info("foregroundUser is nil")
                return
            }
            reqs.forEach { req in
                let extra = LarkNCEExtra.getExtraDict(from: req.userInfo)
                if extra?.userId == userID {
                    Self.logger.info("remove notification from EnterForeground: \(req.identifier)")
                    NotificationManager.shared.removeNotification(identifier: req.identifier)
                }
            }
        }
    }

    private func didReceiveNotification(_ message: DidReceiveNotification) {
        Self.logger.info("Did Receive Notification")
        self.handle(message)

        self.didReceive(message.response) { [weak self] _ in
            self?.notificationSubject.onNext(())
        }
        return
    }

    /// watchOS 回复走这里
    private func didReceive(_ response: UNNotificationResponse,
                            completionHandler completion: @escaping (UNNotificationContentExtensionResponseOption?) -> Void) {
        guard let extra = LarkNCEExtra.getExtraDict(from: response.notification.request.content.userInfo),
              !extra.userId.isEmpty else {
            completion(.dismiss)
            return
        }

        let currentUserID = self.passportService.foregroundUser?.userID ?? ""
        let type: UserScopeType = currentUserID == extra.userId ? .foreground : .background
        let userResolver = try? Container.shared.getUserResolver(userID: extra.userId, type: type)
        guard let rustService = try? userResolver?.resolver.resolve(type: RustService.self) else {
            return
        }

        self.rustAPI.sendReadMessage(extra.messageID, rustService: rustService, userId: extra.userId, chatID: extra.chatId)

        let subUserId = extra.userId
        let ifCrossTenant = currentUserID == subUserId

        if response.actionIdentifier == "replyAction" {
            guard let res = response as? UNTextInputNotificationResponse else {
                completion(.dismiss)
                return
            }

            self.rustAPI.sendReplyMessage(res.userText,
                                          rustService: rustService,
                                          userId: extra.userId,
                                          messageID: extra.messageID,
                                          chatID: extra.chatId) { success in
                completion(.dismiss)
                if success {
                    NotificationTracker.msgSend(msgId: extra.messageID,
                                                userId: subUserId,
                                                ifCrossTenant: ifCrossTenant,
                                                isWatch: true,
                                                isRemote: extra.isRemote)
                }
            }

            timeout(completionHandler: completion)
        } else if response.actionIdentifier == "okAction" {
            self.rustAPI.sendReaction("OK",
                                      rustService: rustService,
                                      userId: extra.userId,
                                      messageID: extra.messageID) { success in
                completion(.dismiss)
                if success {
                    NotificationTracker.okSend(msgId: extra.messageID,
                                               userId: subUserId,
                                               ifCrossTenant: ifCrossTenant,
                                               isWatch: true,
                                               isRemote: extra.isRemote)
                }
            }
            timeout(completionHandler: completion)
        }
    }

    private func timeout(completionHandler completion: @escaping (UNNotificationContentExtensionResponseOption?) -> Void) {
        DispatchQueue.global().asyncAfter(deadline: .now() + 2) {
            Self.logger.info("Time out")
            completion(.dismiss)
        }
    }

    private func handle(_ message: DidReceiveNotification) {
        let notification = message.notification
        Self.logger.info("Handle Receive Notification")
        guard let userInfo = UserInfo(dict: notification.userInfo as? [String: Any] ?? [:]) else {
            Self.logger.error("Notification UserInfo is empty")
            return
        }
        let userID = passportService.foregroundUser?.userID
        let navigator: Navigatable = userID.flatMap {
            try? Container.shared.getUserResolver(userID: $0).navigator
        } ?? Navigator.shared
        Self.logger.info("URLInterceptorManager handle Notification")
        let extra = LarkNCEExtra.getExtraDict(from: message.request.content.userInfo)
        if let urlString = userInfo.extra?.content.url, !urlString.isEmpty, let url = URL(string: urlString) {
            if let extra = extra,
               extra.userId != userID,
               !extra.userId.isEmpty {
                handleReply(message, url: url, navigator: navigator)
            } else {
                handleRoute(message, url: url, navigator: navigator)
            }
        }
        let currentUserId = self.passportService.foregroundUser?.userID ?? ""
        NotificationTracker.clickBanner(userInfo: userInfo,
                                        userId: extra?.userId,
                                        currentUserID: currentUserId,
                                        msgId: extra?.messageID,
                                        navigator: navigator)
        notificationSubject.onNext(())
    }

    func handleReply(_ message: DidReceiveNotification, url: URL, navigator: Navigatable) {
        func _handleReplyVC() {
            guard let mainSceneWindow = navigator.mainSceneWindow else {
                return
            }
            /// 非当前用户推送，需要弹出快捷回复页面
            guard let userInfo = UserInfo(dict: message.notification.userInfo as? [String: Any] ?? [:]) else {
                Self.logger.error("Notification UserInfo is empty")
                return
            }
            guard let userID = passportService.foregroundUser?.userID else {
                return
            }
            guard let userResolver = try? Container.shared.getUserResolver(userID: userID, type: .foreground) else {
                return
            }
            let notificationVM = NotificationViewModel(userInfo: userInfo, currentUserId: userID)
            let replyVC = NotificationReplyViewController(vm: notificationVM, userResolver: userResolver)
            if #available(iOS 13.0, *) {
                /// 通过该属性设置，可以避免点蒙层关闭弹窗
                replyVC.isModalInPresentation = true
            }
            replyVC.modalPresentationStyle = .overFullScreen
            if #available(iOS 13.0, *), NotificationReplyViewController.isAlert(window: mainSceneWindow)  {
                /// iPad 全屏alert采用 formSheet ，否则宽度无法跟在它之后的弹窗宽度对齐
                replyVC.modalPresentationStyle = .pageSheet
            }
            let dialogManager = try? userResolver.resolve(type: DialogManagerService.self)
            dialogManager?.addTask(task:  DialogTask(onShow: { 
                replyVC.switchHandler = { [weak self] in
                    self?.handleRoute(message, url: url, navigator: navigator)
                    dialogManager?.onDismiss()
                }
                replyVC.dismissHandler = {
                    dialogManager?.onDismiss()
                }
                userResolver.navigator.present(replyVC, from: mainSceneWindow, animated: true)
            }))
        }
        if NewBootManager.shared.context.hasFirstRender {
            _handleReplyVC()
        } else {
            NewBootManager.shared.registerTask(taskAction: {
                _handleReplyVC()
            }, triggerMoment: .afterFirstRender)
        }
    }

    func handleRoute(_ message: DidReceiveNotification, url: URL, navigator: Navigatable) {
        func _handleRoute() {
            Self.logger.info("URLInterceptorManager handle, url: \(url.absoluteString)")
            if #available(iOS 13.0, *),
               let scene = message.response.targetScene as? UIWindowScene {
                URLInterceptorManager.shared.handle(url, from: scene)
            } else if let mainSceneWindow = navigator.mainSceneWindow { // Global
                URLInterceptorManager.shared.handle(url, from: mainSceneWindow)
            }
        }
        if NewBootManager.shared.context.hasFirstRender {
            _handleRoute()
        } else {
            NewBootManager.shared.registerTask(taskAction: {
                _handleRoute()
            }, triggerMoment: .afterFirstRender)
        }
    }

    private func didReceiveNotification(_ message: DidReceiveBackgroundNotification) {
        guard UIApplication.shared.applicationState != .active else {
            return
        }
        Self.logger.info("Did Receive Background Notification")
        self.handle(message)
    }

    private func handle(_ message: DidReceiveBackgroundNotification) {
        let notification = message.notification
        guard self.notificationBackgroundTaskId == nil,
              let extraString = notification.userInfo["extra_str"] as? String,
              let data = extraString.data(using: .utf8),
              let dict = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
              let payload = dict["payload"] as? String,
              let base64 = Data(base64Encoded: payload) else {
            message.completionHandler?(.noData)
            return
        }
        DispatchQueue.global().async {
            self.notificationBackgroundTaskId = UIApplication.shared.beginBackgroundTask(withName: "NotificationBackgroundTask",
                                                                                         expirationHandler: { [weak self] in
                                                                                            self?.endBackgroundTask()
                                                                                            message.completionHandler?(.noData)
            })

            Self.logger.info("notification enter background task id: \(String(describing: self.notificationBackgroundTaskId))")
            guard let rustService = try? Container.shared.getCurrentUserResolver().resolve(assert: RustService.self) else {
                return
            }
            self.rustAPI.handleOfflinePushData(base64, rustService: rustService) { [weak self] isFinish in
                if isFinish {
                    self?.endBackgroundTask()
                    message.completionHandler?(.newData)
                } else {
                    self?.endBackgroundTask()
                    message.completionHandler?(.noData)
                }
            }
        }
    }

    private func endBackgroundTask() {
        guard let notificationBackgroundTaskId = self.notificationBackgroundTaskId else { return }
        Self.logger.info("notification end background task id: \(notificationBackgroundTaskId)")
        UIApplication.shared.endBackgroundTask(notificationBackgroundTaskId)
        self.notificationBackgroundTaskId = nil
    }
}
