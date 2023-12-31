//
//  NotificationViewController.swift
//  NotificationContentExtension
//
//  Created by yaoqihao on 2022/3/31.
//  Copyright © 2022 Bytedance.Inc. All rights reserved.
//

import UIKit
import UserNotifications
import UserNotificationsUI
import LarkNotificationContentExtension
import LarkNotificationContentExtensionSDK
#if canImport(HeimdallrForExtension)
import HeimdallrForExtension
#endif
import LarkExtensionServices

final class NotificationViewController: UIViewController, UNNotificationContentExtension {
    private var processors: [String: LarkNotificationContentExtensionProcessor] = [:]
    private var categoryIdentifier: String = ""

    private var orginWidth: CGFloat = 375

    private var inputKeyboard: UIView?

    private var registerProcessor = false

    override var canBecomeFirstResponder: Bool {
        // Need to become first responder to have custom input view.
        return true
    }

    override var inputAccessoryView: UIView? {
        return self.inputKeyboard
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.orginWidth = self.view.frame.width

        #if DEBUG
        let groupID: String = "group.com.bytedance.ee.lark.yzj"
        #else
        let groupID: String = AppConfig.AppGroupName ?? ""
        #endif

        #if canImport(HeimdallrForExtension)
        DispatchQueue.main.async {
            HMDInjectedInfo.default().userID = ExtensionAccountService.currentAccountID ?? ""
            HMDExtensionCrashTracker.shared().start(withGroupID: groupID)
        }
        #endif

        if !registerProcessor {
            registerProcessor = true

            LarkNCExtensionFactory.shared.register(LarkNCExtensionMessengerProcessor.self)
        }
    }

    func didReceive(_ notification: UNNotification) {
        let categoryIdentifier = notification.request.content.categoryIdentifier
        self.categoryIdentifier = categoryIdentifier
        guard let processor = self.getProcessorBy(categoryIdentifier) else {
            return
        }
        setInputKeyboard(processor)
        processor.didReceive(notification, context: extensionContext)

        if let contentView = processor.getContentView() {
            let scaledRatio = orginWidth / contentView.frame.size.width
            preferredContentSize = CGSize(width: scaledRatio * contentView.frame.size.width,
                                          height: scaledRatio * contentView.frame.size.height)
            self.view = contentView
        }
    }

    func didReceive(_ response: UNNotificationResponse, completionHandler completion: @escaping (UNNotificationContentExtensionResponseOption) -> Void) {
        let categoryIdentifier = response.notification.request.content.categoryIdentifier
        self.categoryIdentifier = categoryIdentifier
        guard let processor = self.getProcessorBy(categoryIdentifier) else {
            return
        }
        setInputKeyboard(processor, response: response)
        processor.didReceive(response, from: .iOS, context: extensionContext) { option in
            completion(option ?? .dismiss)
        }
    }

    private func getProcessorBy(_ categoryIdentifier: String) -> LarkNotificationContentExtensionProcessor? {
        if processors[categoryIdentifier] == nil {
            var processor = LarkNCExtensionFactory.shared.createBy(category: categoryIdentifier)
            processor?.notificationViewController = self
            processor?.updateBlock = { [weak self] (view) in
                guard let `self` = self, let contentView = view else { return }
                let scaledRatio = self.orginWidth / contentView.frame.size.width
                self.preferredContentSize = CGSize(width: scaledRatio * contentView.frame.size.width,
                                                   height: scaledRatio * contentView.frame.size.height)
                self.view = contentView
                self.view.frame.size = self.preferredContentSize
            }
            processors[categoryIdentifier] = processor
        }

        return processors[categoryIdentifier]
    }

    private func setInputKeyboard(_ processor: LarkNotificationContentExtensionProcessor?, response: UNNotificationResponse? = nil) {
        self.inputKeyboard = processor?.getInputView(response)
        let height = processor?.getInputViewHeight(response) ?? 0

        if let inputKeyboard = self.inputKeyboard {
            inputKeyboard.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                inputKeyboard.heightAnchor.constraint(greaterThanOrEqualToConstant: height)
            ])
        }
    }
}
