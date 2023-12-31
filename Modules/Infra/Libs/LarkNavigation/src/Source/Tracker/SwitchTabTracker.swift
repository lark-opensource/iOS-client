//
//  SwitchTabTracker.swift
//  LarkNavigation
//
//  Created by 李晨 on 2020/10/15.
//

import Foundation
import UIKit
import AppReciableSDK
import AnimatedTabBar
import LarkTab

final class SwitchTabTracker {

    static let shared: SwitchTabTracker = SwitchTabTracker()
    var enterBackground: Bool = false

    init() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(SwitchTabTracker.applicationDidEnterBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
    }

    func start(tabURL: String, isInitialize: Bool) -> DisposedKey? {
        reset()
        if let biz = biz(for: tabURL),
           let scene = scene(for: tabURL),
           let page = page(for: tabURL) {
            let extra = Extra(
                isNeedNet: false,
                category: ["is_initialize": isInitialize ? 1 : 0]
            )
            return AppReciableSDK.shared.start(
                biz: biz,
                scene: scene,
                event: .switchTab,
                page: page,
                extra: extra
            )
        }
        return nil
    }

    func end(disposeKey: DisposedKey?) {
        if let disposeKey = disposeKey {
            let extra = Extra(category: ["is_in_background": enterBackground ? 1 : 0])
            AppReciableSDK.shared.end(key: disposeKey, extra: extra)
            reset()
        }
    }

    private func reset() {
        self.enterBackground = false
    }

    @objc
    func applicationDidEnterBackground() {
        self.enterBackground = true
    }

    private func biz(for tabURL: String) -> Biz? {
        // 小程序、H5没有固定url，判断prefix
        if tabURL.hasPrefix(Tab.gadgetPrefix) || tabURL.hasPrefix(Tab.webAppPrefix) {
            return nil
        }

        switch tabURL {
        case Tab.feed.urlString,
             Tab.contact.urlString:
            return .Messenger
        case Tab.calendar.urlString:
            return .Calendar
        case Tab.mail.urlString:
            return .Mail
        case Tab.appCenter.urlString:
            return .OpenPlatform
        case Tab.byteview.urlString:
            return .VideoConference
        case Tab.minutes.urlString:
            return .VideoConference
        case Tab.doc.urlString, Tab.wiki.urlString, Tab.base.urlString:
            return .Docs
        case Tab.todo.urlString:
            return .Todo
        case Tab.moment.urlString:
            return .Moments
        default:
            return .Unknown
        }
    }

    private func scene(for tabURL: String) -> Scene? {
        // 小程序、H5没有固定url，判断prefix
        if tabURL.hasPrefix(Tab.gadgetPrefix) || tabURL.hasPrefix(Tab.webAppPrefix) {
            return nil
        }

        switch tabURL {
        case Tab.feed.urlString:
            return .Feed
        case Tab.contact.urlString:
            return .Contact
        case Tab.calendar.urlString:
            return .CalDiagram
        case Tab.mail.urlString:
            return .MailFMP
        case Tab.appCenter.urlString:
            return .Unknown
        case Tab.byteview.urlString:
            return .VCOnTheCall
        case Tab.minutes.urlString:
            return .MinutesList
        case Tab.doc.urlString, Tab.wiki.urlString, Tab.base.urlString:
            return .Unknown
        case Tab.todo.urlString:
            return .TodoCenter
        case Tab.moment.urlString:
            return .Moments
        default:
            assertionFailure("unknow Tab -> BizScope")
            return .Unknown
        }
    }

    private func page(for tabURL: String) -> String? {
        // 小程序、H5没有固定url，判断prefix
        if tabURL.hasPrefix(Tab.gadgetPrefix) || tabURL.hasPrefix(Tab.webAppPrefix) {
            return nil
        }

        switch tabURL {
        case Tab.feed.urlString:
            return "FeedViewController"
        case Tab.contact.urlString:
            return "ContactViewController"
        case Tab.calendar.urlString:
            return "CalendarViewController"
        case Tab.mail.urlString:
            return "mail"
        case Tab.appCenter.urlString:
            return "appCenter"
        case Tab.byteview.urlString:
            return "byteview"
        case Tab.minutes.urlString:
            return "minutes"
        case Tab.doc.urlString, Tab.wiki.urlString, Tab.base.urlString:
            return "doc"
        case Tab.todo.urlString:
            return "todo"
        case Tab.moment.urlString:
            return "moment"
        default:
            assertionFailure("unknow Tab -> BizScope")
            return "unknow"
        }
    }
}
