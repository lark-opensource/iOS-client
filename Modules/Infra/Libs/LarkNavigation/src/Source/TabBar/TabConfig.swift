//
//  TabConfig.swift
//  LarkNavigation
//
//  Created by Meng on 2019/10/16.
//

import Foundation
import UIKit
import AnimatedTabBar
import LarkTab
import LarkFeatureGating
import LarkLocalizations

public struct TabConfig {
    public let key: String

    public var name: String?
    public var icon: UIImage?
    public var selectedIcon: UIImage?
    public var quickTabIcon: UIImage?

    public init(key: String) {
        self.key = key
    }

    public init(key: String, name: String?, icon: UIImage?, selectedIcon: UIImage?, quickTabIcon: UIImage?) {
        self.key = key
        self.name = name
        self.icon = icon
        self.selectedIcon = selectedIcon
        self.quickTabIcon = quickTabIcon
    }

    public static var tabConfigDic: [String: TabConfig] = [:]

    public static func regsiter(config: TabConfig, for key: String) {
        tabConfigDic[key] = config
    }

    public static func config(for key: String) -> TabConfig? {
        tabConfigDic[key]
    }
}

extension TabConfig {

    static func defaultConfig(for key: String, of type: AppType) -> TabConfig {
        var config = TabConfig(key: key)
        // gadget
        if type == .gadget {
            config.name = BundleI18n.LarkNavigation.Lark_Legacy_MiniProgram
            config.icon = Resources.LarkNavigation.MainTab.tabbar_microApp_shadow
            config.selectedIcon = Resources.LarkNavigation.MainTab.tabbar_microApp_light
            config.quickTabIcon = Resources.LarkNavigation.QuickTab.quicktab_microApp
            return config
        }
        // h5
        if type == .webapp {
            config.name = BundleI18n.LarkNavigation.Lark_Legacy_WebApp
            config.icon = Resources.LarkNavigation.MainTab.tabbar_microApp_shadow
            config.selectedIcon = Resources.LarkNavigation.MainTab.tabbar_microApp_light
            config.quickTabIcon = Resources.LarkNavigation.QuickTab.quicktab_microApp
            return config
        }
        // native
        switch key {
        case Tab.feed.key:
            config.name = BundleI18n.LarkNavigation.Lark_Legacy_MessengerTab
            config.icon = Resources.LarkNavigation.MainTab.tabbar_feed_shadow
            config.selectedIcon = Resources.LarkNavigation.MainTab.tabbar_feed_light
            config.quickTabIcon = Resources.LarkNavigation.QuickTab.quicktab_feed
        case Tab.calendar.key:
            config.name = BundleI18n.LarkNavigation.Lark_Legacy_CalendarTab
            config.icon = Resources.LarkNavigation.MainTab.tabbar_calendar_shadow
            config.selectedIcon = Resources.LarkNavigation.MainTab.tabbar_calendar_light
            config.quickTabIcon = Resources.LarkNavigation.QuickTab.quicktab_calendar
        case Tab.appCenter.key:
            config.name = BundleI18n.LarkNavigation.Lark_Legacy_AppCenter
            config.icon = Resources.LarkNavigation.MainTab.tabbar_appcenter_shadow
            config.selectedIcon = Resources.LarkNavigation.MainTab.tabbar_appcenter_light
            config.quickTabIcon = Resources.LarkNavigation.QuickTab.quicktab_appcenter
        case Tab.doc.key:
            config.name = BundleI18n.LarkNavigation.Lark_Legacy_Docs
            config.icon = Resources.LarkNavigation.MainTab.tabbar_docs_shadow
            config.selectedIcon = Resources.LarkNavigation.MainTab.tabbar_docs_light
            config.quickTabIcon = Resources.LarkNavigation.QuickTab.quicktab_space
        case Tab.contact.key:
            config.name = BundleI18n.LarkNavigation.Lark_Contacts_Contacts
            config.icon = Resources.LarkNavigation.MainTab.tabbar_contacts_shadow
            config.selectedIcon = Resources.LarkNavigation.MainTab.tabbar_contacts_light
            config.quickTabIcon = Resources.LarkNavigation.QuickTab.quicktab_contact
        case Tab.mail.key:
            config.name = BundleI18n.LarkNavigation.Lark_Legacy_MailTab
            config.icon = Resources.LarkNavigation.MainTab.tabbar_mail_shadow
            config.selectedIcon = Resources.LarkNavigation.MainTab.tabbar_mail_light
            config.quickTabIcon = Resources.LarkNavigation.QuickTab.quicktab_mail
        case Tab.wiki.key:
            config.name = BundleI18n.LarkNavigation.Lark_Legacy_WikiTab
            config.icon = Resources.LarkNavigation.MainTab.tabbar_wiki_shadow
            config.selectedIcon = Resources.LarkNavigation.MainTab.tabbar_wiki_light
            config.quickTabIcon = Resources.LarkNavigation.QuickTab.quicktab_wiki
        case Tab.byteview.key:
            config.name = BundleI18n.LarkNavigation.Lark_Legacy_VideoMeetingsSideBarNew
            config.icon = Resources.LarkNavigation.MainTab.tabbar_byteview_shadow
            config.selectedIcon = Resources.LarkNavigation.MainTab.tabbar_byteview_light
            config.quickTabIcon = Resources.LarkNavigation.QuickTab.quicktab_video_conference
        case Tab.minutes.key:
            config.name = BundleI18n.LarkNavigation.Lark_View_Minutes
            config.icon = Resources.LarkNavigation.MainTab.tabbar_minutes_shadow
            config.selectedIcon = Resources.LarkNavigation.MainTab.tabbar_minutes_light
            config.quickTabIcon = Resources.LarkNavigation.QuickTab.quicktab_minutes
        case Tab.todo.key:
            config.name = BundleI18n.LarkNavigation.Todo_Task_Tasks
            config.icon = Resources.LarkNavigation.MainTab.tabbar_todo_shadow
            config.selectedIcon = Resources.LarkNavigation.MainTab.tabbar_todo_light
            config.quickTabIcon = Resources.LarkNavigation.QuickTab.quicktab_todo
        case Tab.moment.key:
            config.name = BundleI18n.LarkNavigation.Lark_Community_Moments
            config.icon = Resources.LarkNavigation.MainTab.tabbar_moment_shadow
            config.selectedIcon = Resources.LarkNavigation.MainTab.tabbar_moment_light
            config.quickTabIcon = Resources.LarkNavigation.QuickTab.quicktab_moment
        case Tab.base.key:
            config.name = BundleI18n.LarkNavigation.Bitable_Workspace_Base_Title
            config.icon = Resources.LarkNavigation.MainTab.tabbar_bitable_shadow
            config.selectedIcon = Resources.LarkNavigation.MainTab.tabbar_bitable_light
            config.quickTabIcon = Resources.LarkNavigation.QuickTab.quicktab_bitable
        default:
            if let config = TabConfig.tabConfigDic[key] {
                return config
            }
        }
        return config
    }

    static func defaultName(for key: String, of type: AppType, languageName: String) -> String? {
        let lang: Lang = Lang(rawValue: languageName)
        var name: String?
        // gadget
        if type == .gadget {
            name = BundleI18n.LarkNavigation.Lark_Legacy_MiniProgram(lang: lang)
            return name
        }
        // h5
        if type == .webapp {
            name = BundleI18n.LarkNavigation.Lark_Legacy_WebApp(lang: lang)
            return name
        }
        // native
        switch key {
        case Tab.feed.key:
            name = BundleI18n.LarkNavigation.Lark_Legacy_MessengerTab(lang: lang)
        case Tab.calendar.key:
            name = BundleI18n.LarkNavigation.Lark_Legacy_CalendarTab(lang: lang)
        case Tab.appCenter.key:
            name = BundleI18n.LarkNavigation.Lark_Legacy_AppCenter(lang: lang)
        case Tab.doc.key:
            name = BundleI18n.LarkNavigation.Lark_Legacy_Docs(lang: lang)
        case Tab.contact.key:
            name = BundleI18n.LarkNavigation.Lark_Contacts_Contacts(lang: lang)
        case Tab.mail.key:
            name = BundleI18n.LarkNavigation.Lark_Legacy_MailTab(lang: lang)
        case Tab.wiki.key:
            name = BundleI18n.LarkNavigation.Lark_Legacy_WikiTab(lang: lang)
        case Tab.byteview.key:
            name = BundleI18n.LarkNavigation.Lark_Legacy_VideoMeetingsSideBarNew(lang: lang)
        case Tab.minutes.key:
            name = BundleI18n.LarkNavigation.Lark_View_Minutes(lang: lang)
        case Tab.todo.key:
            name = BundleI18n.LarkNavigation.Todo_Task_Tasks(lang: lang)
        case Tab.moment.key:
            name = BundleI18n.LarkNavigation.Lark_Community_Moments(lang: lang)
        case Tab.base.key:
            name = BundleI18n.LarkNavigation.Bitable_Workspace_Base_Title(lang: lang)
        default:
            name = nil
        }
        return name
    }
}
