//
//  EENotificationManager.swift
//  EENotification
//
//  Created by 姚启灏 on 2018/12/6.
//

import UIKit
import Foundation
import UserNotifications
import LKCommonsLogging

public enum NotificationAuthorizationState {
    case none
    case authorized
    case denied
}

public final class NotificationManager {

    private static let logger = Logger.log(NotificationManager.self, category: "LarkNotification.NotificationManager")

    private let removeQueue: DispatchQueue = DispatchQueue(label: "EENotification.NotificationManager")

    public static let shared = NotificationManager()

    public var authorizationState: NotificationAuthorizationState = .none

    public init() {}

    public func registerRemoteNotification() {
        let application = UIApplication.shared
        UNUserNotificationCenter.current().requestAuthorization(options: [.badge, .sound, .alert]) { (granted, _) in
            NotificationManager.logger.info("Notification request authorization granted: \(granted)")
            NotificationManager.shared.authorizationState = granted ? .authorized : .denied
            DispatchQueue.main.async {
                application.registerForRemoteNotifications()
            }
        }
    }

    public func unregisterRemoteNotification() {
        UIApplication.shared.unregisterForRemoteNotifications()
        UIApplication.shared.applicationIconBadgeNumber = 0
    }

    public func addOrUpdateNotification(request: NotificationRequest,
                                        withCompletionHandler completionHandler: ((Error?) -> Void)? = nil) {
        if let notificationRequest = request.transformNotificationRequest() {
            UNUserNotificationCenter.current().add(notificationRequest,
                                                   withCompletionHandler: completionHandler)
        }
    }

    public func addOrUpdateNotification(request: UNNotificationRequest,
                                         withCompletionHandler completionHandler: ((Error?) -> Void)? = nil) {
        UNUserNotificationCenter.current().add(request,
                                               withCompletionHandler: completionHandler)
    }

    public func addOrUpdateNotifications(requests: [NotificationRequest],
                                         withCompletionHandler completionHandler: ((Error?) -> Void)? = nil) {
        requests.forEach { (request) in
            self.addOrUpdateNotification(request: request,
                                         withCompletionHandler: completionHandler)
        }
    }

    public func getDeliveredNotifications(completionHandler: @escaping (([NotificationRequest]) -> Void)) {

        var notifications: [NotificationRequest] = []
        UNUserNotificationCenter.current().getDeliveredNotifications { (unNotifications) in
            notifications = unNotifications.map({ (notification) -> NotificationRequest in
                return notification.transformEENotificationRequest()
            })
            completionHandler(notifications)
        }
    }

    public func getPendingNotifications(completionHandler: @escaping (([NotificationRequest]) -> Void)) {

        var notifications: [NotificationRequest] = []
        UNUserNotificationCenter.current().getPendingNotificationRequests { (requests) in
            notifications = requests.map({ (request) -> NotificationRequest in
                return request.transformEENotificationRequest()
            })
            completionHandler(notifications)
        }
    }

    public func getAllNotifications(completionHandler: @escaping (([NotificationRequest]) -> Void)) {

        //iOS 10.0之后不能直接得到全部Notification
        var notifications: [NotificationRequest] = []

        let getNotificationGroup = DispatchGroup()

        getNotificationGroup.enter()
        UNUserNotificationCenter.current().getDeliveredNotifications { (deliveredNotifications) in
            deliveredNotifications.forEach({ (notification) in
                notifications.append(notification.transformEENotificationRequest())
            })
            getNotificationGroup.leave()
        }

        getNotificationGroup.enter()
        UNUserNotificationCenter.current().getPendingNotificationRequests { (requests) in
            requests.forEach({ (request) in
                notifications.append(request.transformEENotificationRequest())
            })
            getNotificationGroup.leave()
        }

        getNotificationGroup.notify(queue: DispatchQueue.main) {
            completionHandler(notifications)
        }
    }

    public func removeNotification(identifier: String) {
       UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: [identifier])
       UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
    }

    public func removeNotifications(group: String, withCompletionHandler completionHandler: (() -> Void)? = nil) {
        let deliveredSemaphore = DispatchSemaphore(value: 0)
        let pendingSemaphore = DispatchSemaphore(value: 0)
        removeQueue.async {
            let deliveredWaitResult = deliveredSemaphore.wait(timeout: .now() + 2)
            let pendingWaitResult = pendingSemaphore.wait(timeout: .now() + 2)
            NotificationManager.logger.info("Notification Remove Result: deliveredWaitResult: \(deliveredWaitResult), pendingWaitResult: \(pendingWaitResult)")
            completionHandler?()
        }

        DispatchQueue.main.async {
            UNUserNotificationCenter.current().getDeliveredNotifications { (notifications) in
                let removeidentifiers = notifications.map({ (notification) -> String in
                    if let groupInfo = notification.request.content.userInfo[NotificationUserInfoKey.group] as? String, groupInfo == group {
                        return notification.request.identifier
                    } else {
                        return ""
                    }
                }).filter({ return !$0.isEmpty })
                UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: removeidentifiers)
                deliveredSemaphore.signal()
            }

            UNUserNotificationCenter.current().getPendingNotificationRequests { (requests) in
                let removeidentifiers = requests.map({ (request) -> String in
                    if let groupInfo = request.content.userInfo[NotificationUserInfoKey.group] as? String,
                        groupInfo == group {
                        return request.identifier
                    } else {
                        return ""
                    }
                }).filter({ return !$0.isEmpty })
                UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: removeidentifiers)
                pendingSemaphore.signal()
            }
        }
    }

    public func removeDeliveredNotifications() {
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
    }

    public func removePendingNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }

    //iOS10只有 removePendingNotifications 和 removeDeliveredNotifications
    public func removeAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
    }
}
