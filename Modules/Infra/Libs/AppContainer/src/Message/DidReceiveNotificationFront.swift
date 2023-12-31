//
//  DidReceiveNotificationFront.swift
//  AppContainer
//
//  Created by 强淑婷 on 2020/2/20.
//

import UserNotifications
import Foundation
import RxSwift

public struct DidReceiveNotificationFront: Message {
    public static let name = "DidReceiveNotificationFront"
    public let notification: Notification
    public let context: AppContext
    public let request: UNNotificationRequest
    public let date: Date
    public typealias HandleReturnType = Observable<UNNotificationPresentationOptions>
}
