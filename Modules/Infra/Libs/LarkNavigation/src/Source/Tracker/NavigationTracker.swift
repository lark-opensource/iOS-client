//
//  NavigationTracker.swift
//  LarkNavigation
//
//  Created by Meng on 2019/10/23.
//

import Foundation
import LKCommonsTracker
import Homeric
import AnimatedTabBar
import LarkUIKit
import LarkTab

final class NavigationTracker {
    enum TabLocation: String {
        case primary
        case quick
        case recent
        case temporary
    }
    static func didClickTab(_ tab: Tab, tabType: TabType) {
        guard let location = tabType.location,
              let index = tabType.index else {
            assertionFailure()
            return
        }
        trackNavClickWithType("click",
                              tab: tab,
                              location: location,
                              index: index)
    }

    static func didDoubleClickTab(_ tab: Tab, tabType: TabType) {
        guard let location = tabType.location,
              let index = tabType.index else {
            assertionFailure()
            return
        }
        trackNavClickWithType("double_click", tab: tab, location: location, index: index)
    }

    static func trackNavClickWithType(_ type: String, tab: Tab, location: TabLocation, index: Int) {
        Tracker.post(TeaEvent(Homeric.NAV_APPLICATION_CLICK, params: [
                                "application": tab.key,
                                "app_id": tab.appid ?? "",
                                "appname": tab.tabName,
                                "application_type": self.getAppTypeForTab(tab),
                                "badge_number": TabRegistry.resolve(tab)?.badge?.value.count ?? 0,
                                "clicktype": type,
                                "location": location.rawValue,
                                "order": index])
        )
    }

    static func getAppTypeForTab(_ tab: Tab) -> String {
        if tab.appType == .gadget {
            return "MP"
        } else if tab.appType == .webapp {
            return "H5"
        } else if tab.appType == .native {
            return "native"
        }
        return ""
    }

    static func didShowQuickNavigation(slide: Bool) {
        Tracker.post(TeaEvent(Homeric.QUICK_NAVIGATION, params: ["callType": slide ? "slide" : "click"]))
    }

    static func didGetNavigationConfig(newVersion: String) {
        Tracker.post(TeaEvent(Homeric.GET_ADMIN_NAVIGATION_CHANGE, params: ["new_version": newVersion]))
    }

    static func didShowNavigationAlert(newVersion: String) {
        Tracker.post(TeaEvent(Homeric.ADMIN_NAVIGATION_NOTIFICATION, params: ["new_version": newVersion]))
    }

    static func pinTab(main: Int, temporary: Int) {
        Tracker.post(TeaEvent("navigation_msg_tab_top_status",
                              params: ["nav_fixed_show_tab_cnt": main,
                                       "nav_temp_tab_cnt": temporary]))
    }

    static func closeTemporary(by isWithdraw: Bool) {
        Tracker.post(TeaEvent(Homeric.NAVIGATION_TEMPORARY_CLEAR_ALL_CLICK,
                              params: ["click": isWithdraw ? "withdraw" : "close"]))
    }
}

extension TabType {
    var index: Int? {
        if case .mainTab(let index) = self {
            return index
        }
        if case .quickTab(let index) = self {
            return index
        }
        if case .recentUsed(let index) = self {
            return index
        }
        if case .temporaryTab(let index) = self {
            return index
        }
        return nil
    }

    var location: NavigationTracker.TabLocation? {
        if case .mainTab = self {
            return .primary
        }
        if case .quickTab = self {
            return .quick
        }
        if case .recentUsed = self {
            return .recent
        }
        if case .temporaryTab = self {
            return .temporary
        }
        return nil
    }
}

extension NavigationTracker {
    static func trackTabInitialize(tab: Tab, cost: CFTimeInterval) {
        let metric = [tab.urlString: cost]
        Tracker.post(SlardarEvent(name: "Tab_SwitchCost_Initialize",
                                  metric: metric,
                                  category: [:],
                                  extra: [:]))
    }

    static func trackTabViewDidAppear(tab: Tab, cost: CFTimeInterval) {
        let metric = [tab.urlString: cost]
        Tracker.post(SlardarEvent(name: "Tab_SwitchCost_ViewDidAppear",
                                  metric: metric,
                                  category: [:],
                                  extra: [:]))
    }

    static func trackNavClickTab(_ tab: Tab, tabType: TabType, style: TabbarStyle) {
        // 开平的应用商城需要一个单独的点击埋点，由于应用商城的tab比较特殊，点击后会被guard掉，所以需要放在前面
        if tab.key == Tab.asKey {
            Tracker.post(TeaEvent(Homeric.PUBLIC_TAB_CONTAINER_CLICK))
        }
        guard let location = tabType.location, let index = tabType.index else { return }
        // fixed_show(固定应用展示区)，more_fixed_app（更多固定应用），recent(最近使用)
        var from = "unknown"
        switch tabType {
        case .mainTab(_):
            from = "fixed_show"
        case .quickTab(_):
            from = "more_fixed_app"
        case .recentUsed(_):
            from = "recent"
        case .temporaryTab(_):
            from = "temporary"
        default:
            from = "unknown"
        }
        var appType = "unknown"
        switch tab.appType {
        case .native:
            appType = "lark_native"
        case .gadget:
            appType = "mini"
        case .webapp:
            appType = "web"
        case .appTypeOpenApp:
            appType = "open_app"
        case .appTypeURL:
            appType = "custom_url"
        case .appTypeCustomNative:
            appType = "custom_native"
        default:
            appType = "unknown"
        }
        var bizType = "unknown"
        switch tab.bizType {
        case .CCM:
            bizType = "CCM"
        case .MINI_APP:
            bizType = "MINI_APP"
        case .WEB_APP:
            bizType = "WEB_APP"
        case .MEEGO:
            bizType = "MEEGO"
        case .WEB:
            bizType = "WEB"
        default:
            bizType = "unknown"
        }
        var source = "unknown"
        switch tab.source {
        case .tenantSource:
            source = "tenant"
        case .userSource:
            source = "user"
        default:
            source = "unknown"
        }
        
        var params: [AnyHashable: Any] = [:]
        params["click"] = "application"
        params["target"] = "none"
        params["key"] = tab.key
        params["location"] = from
        params["order"] = index + 1
        params["tab_bar_style"] = style == .bottom ? "bottom" : "edge"
        params["app_type"] = appType
        params["hash_u"] = tab.urlString.md5()
        params["add_from"] = source
        params["biz_type"] = bizType
        params["click_type"] = "left_click"
        
        // 最近使用的话不需要上报这些数据
        if let tabItem = TabRegistry.resolve(tab) {
            params["badge_number"] = tabItem.badge?.value.count ?? 0
            let badgeType = tabItem.badge?.value ?? .none
            var isReminderStr = "true"
            if case let .none = badgeType {
                isReminderStr = "false"
            }
            params["is_reminder"] = isReminderStr // 是否允许通知
            let badgeStyle = tabItem.badgeStyle?.value
            var badgeTypeStr = "none"
            if case let .dot = badgeType {
                badgeTypeStr = "red_dot"
            } else {
                if case let .strong = badgeStyle {
                    badgeTypeStr = "red_number"
                } else if case let .weak = badgeStyle {
                    badgeTypeStr = "grey_number"
                }
            }
            params["badge_type"] = badgeTypeStr
        }

        Tracker.post(TeaEvent(Homeric.NAVIGATION_MAIN_CLICK, params: params))
    }
}
