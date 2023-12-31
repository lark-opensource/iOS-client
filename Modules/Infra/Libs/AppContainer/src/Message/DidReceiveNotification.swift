//
//  DidReceiveNotification.swift
//  AppContainer
//
//  Created by liuwanlin on 2018/11/20.
//

import UserNotifications
import UIKit
import Foundation
import RxSwift

public struct Notification {
    public let isRemote: Bool
    public let userInfo: [AnyHashable: Any]

    public init(isRemote: Bool, userInfo: [AnyHashable: Any] = [:]) {
        self.isRemote = isRemote
        self.userInfo = userInfo
    }
}

public struct DidReceiveNotification: Message {
    public static let name = "DidReceiveNotification"
    public let notification: Notification
    public let context: AppContext
    public let actionIdentifier: String
    public let request: UNNotificationRequest
    public let response: UNNotificationResponse
    public let date: Date
    public typealias HandleReturnType = Observable<Void>

    public init(notification: Notification,
                context: AppContext,
                actionIdentifier: String,
                request: UNNotificationRequest,
                response: UNNotificationResponse,
                date: Date) {
        self.notification = notification
        self.context = context
        self.actionIdentifier = actionIdentifier
        self.request = request
        self.response = response
        self.date = date
    }
}

public struct DidReceiveBackgroundNotification: Message {
    public static let name = "DidReceiveBackgroundNotification"
    public let notification: Notification
    public let context: AppContext
    public var completionHandler: ((UIBackgroundFetchResult) -> Void)?
    public typealias HandleReturnType = Observable<Void>
}

extension UIApplication.LaunchOptionsKey {
    public static let notification = UIApplication.LaunchOptionsKey(rawValue: "remote_or_local_notification")
}
