//
//  BootManagerDependency.swift
//  LarkMessengerDemo
//
//  Created by KT on 2020/7/4.
//  Copyright © 2020 Bytedance.Inc. All rights reserved.
//

import Foundation
import BootManager
import AnimatedTabBar
import AppContainer
import NotificationUserInfo
//import LarkMonitor
import LarkTab

class BootManagerDependency: BootDependency {
    func tabStringToBizScope(_ tabString: String) -> BizScope? {
        // 小程序、H5没有固定url，判断prefix
        if tabString.hasPrefix(Tab.gadgetPrefix) || tabString.hasPrefix(Tab.webAppPrefix) {
            return .openplatform
        }

        switch tabString {
        case Tab.feed.urlString,
             Tab.contact.urlString,
             Tab.thread.urlString:
            return .messenger
        case Tab.calendar.urlString:
            return .calendar
        case Tab.mail.urlString:
            return .mail
        case Tab.appCenter.urlString:
            return .openplatform
        case Tab.byteview.urlString:
            return .vc
        case Tab.doc.urlString, Tab.wiki.urlString:
            return .docs

        default:
//            assertionFailure("unknow Tab -> BizScope")
            return nil
        }
    }

    func launchOptionToBizScope(_ launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> BizScope? {

        /// 通知进入
        if let notification = launchOptions?[.notification] as? AppContainer.Notification,
            let dic = notification.userInfo as? [String: Any],
            let userInfo = UserInfo(dict: dic) {
            switch userInfo.extra?.type {
            case .openAppChat, .chatApplication: return .openplatform
            case .docs: return .docs
            case .mail: return .mail
            case .calendar: return .calendar
            case .call, .video: return .vc
            case .unknow,
                 .none,
                 .message,
                 .badge,
                 .reaction,
                 .active,
                 .chatApply,
                 .urgent,
                 .urgentAck,
                 .openApp:
                return .messenger
            @unknown default: assertionFailure("unknow type")
            }
        }
        return .specialLaunch
    }

    var eventObserver: EventMonitorProtocol? {
        return nil
    }
}
