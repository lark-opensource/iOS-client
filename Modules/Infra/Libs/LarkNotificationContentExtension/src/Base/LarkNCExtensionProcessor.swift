//
//  LarkNotificationContentExtensionProcessor.swift
//  LarkNotificationContentExtension
//
//  Created by yaoqihao on 2022/4/6.
//

import UIKit
import Foundation
import UserNotifications
import UserNotificationsUI

public enum LarkNotificationContentSource {
    case iOS
    case watchOS
}

public protocol LarkNotificationContentExtensionProcessor {
    static var category: String { get }

    var notificationViewController: UIViewController? { get set }
    var updateBlock: ((UIView?) -> Void)? { get set }

    static func registerCategory() -> UNNotificationCategory

    // Init Processor
    init()

    // This will be called to send the notification to be displayed by
    // the extension. If the extension is being displayed and more related
    // notifications arrive (eg. more messages for the same conversation)
    // the same method will be called for each new notification.
    func didReceive(_ notification: UNNotification, context: NSExtensionContext?)

    // If implemented, the method will be called when the user taps on one
    // of the notification actions. The completion handler can be called
    // after handling the action to dismiss the notification and forward the
    // action to the app if necessary.
    func didReceive(_ response: UNNotificationResponse,
                    from: LarkNotificationContentSource,
                    context: NSExtensionContext?,
                    completionHandler completion: @escaping (UNNotificationContentExtensionResponseOption?) -> Void)

    func getContentView() -> UIView?

    func getInputView(_ response: UNNotificationResponse?) -> UIView?

    func getInputViewHeight(_ response: UNNotificationResponse?) -> CGFloat
}
