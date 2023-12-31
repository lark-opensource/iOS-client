//
//  VoIPApplicationDelegate.swift
//  ByteViewMod
//
//  Created by kiri on 2022/3/21.
//  Copyright © 2022 Bytedance.Inc. All rights reserved.
//

import Foundation
import AppContainer
import LKCommonsLogging
import NotificationUserInfo
import EENavigator

final class VoIPApplicationDelegate: ApplicationDelegate {
    static let config = Config(name: "ByteVoIP", daemon: true)
    private static let logger = Logger.log(VoIPApplicationDelegate.self, category: "VoIP.Application")

    init(context: AppContext) {
        context.dispatcher.add(observer: self) { [weak self] (_, message) in
            self?.didReceiveNotificationFront(message) ?? .just([])
        }

        context.dispatcher.add(observer: self) { [weak self] (_, message) in
            self?.didReceiveNotification(message) ?? .just(Void())
        }
    }

    private func didReceiveNotification(_ message: DidReceiveNotification) -> DidReceiveNotification.HandleReturnType {
        handleAPNSNotification(notification: message.notification)
        return .just(Void())
    }

    private func didReceiveNotificationFront(_ message: DidReceiveNotificationFront)
    -> DidReceiveNotificationFront.HandleReturnType {
        handleAPNSNotification(notification: message.notification)
        return .just([])
    }

    private func handleAPNSNotification(notification: AppContainer.Notification) {
        guard notification.isRemote, let dict = notification.userInfo as? [String: Any],
              let userInfo = UserInfo(dict: dict), let extra = userInfo.extra, extra.type == .call, extra.pushAction != .removeThenNotice,
              let content = extra.content as? CallContent, let data = content.extraStr.data(using: .utf8),
              let callDict = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let callId = callDict["call_id"] as? String, !callId.isEmpty else {
            return
        }

        /// no ui
        Self.logger.info("pushTime = \(userInfo.pushTime), open PullVoIPCallBody")
        Navigator.currentUserNavigator.open(body: PullVoIPCallBody(), from: UINavigationController())
    }
}
