//
//  GroupAction.swift
//  LarkFeed
//
//  Created by xiaruzhen on 2022/11/10.
//

import Foundation
import LKCommonsTracker
import Homeric
import LarkModel
import RustPB

extension FeedTracker {
    struct GroupAction {}
}

extension FeedTracker.GroupAction {
    // 长按某个分组后出现的页面上的展示
    static func View(showMute: Bool, showClearBadge: Bool, muteAtAll: Bool, remindAtAll: Bool) {
        var params = ["is_has_clean_badge_icon": showClearBadge ? "true" : "false",
                      "is_has_mute_icon": showMute ? "true" : "false",
                      "is_has_close_at_all_icon": muteAtAll ? "true" : "false",
                      "is_has_open_at_all_icon": remindAtAll ? "true" : "false"]
        Tracker.post(TeaEvent("feed_tab_press_detail_view",
                              params: params))
    }

    static func ConfirmView() {
        Tracker.post(TeaEvent("feed_clean_badge_confirm_view"))
    }

    static func ConfirmView(openAtAll: Bool, type: FilterGroupAction) {
        let groupName: String
        let id: String
        let mode: String
        switch type {
        case .firstLevel(let filter):
            groupName = FeedTracker.Group.Name(groupType: filter)
            id = String(filter.rawValue)
            mode = "feed"
        case .secondLevel(let tab):
            groupName = FeedTracker.Group.Name(groupType: tab.type)
            if tab.type == .team {
                mode = "team"
            } else if tab.type == .tag {
                mode = "label"
            } else {
                mode = "unknown"
            }
            id = String(tab.tabId)
        }
        let params = ["tab_name": groupName,
                      "entity_id": id,
                      "type": mode]

        let key: String
        if openAtAll {
            key = "feed_open_at_all_notification_view"
        } else {
            key = "feed_close_at_all_notification_view"
        }
        Tracker.post(TeaEvent(key,
                              params: params))
    }
}

extension FeedTracker.GroupAction {
    struct Click {
        // 弹窗确认页面（包括长按/右键导航栏导航栏消息tab、一级分组tab、团队/标签二级分组tab 触发）
        static func fixedTabLongPressClick(_ type: Feed_V1_FeedFilter.TypeEnum) {
            let groupName = FeedTracker.Group.Name(groupType: type)
            let params = ["tab_name": groupName,
                          "click": "press_tab",
                          "target": "feed_tab_press_detail_view"]
             Tracker.post(TeaEvent(Homeric.FEED_FIXED_GROUP_CLICK,
                                   params: params))
        }

        static func TryClearBadge() {
            let params = ["target": "feed_clean_badge_confirm_view",
                          "click": "clean_badge"]
             Tracker.post(TeaEvent("feed_tab_press_detail_click",
                                   params: params))
        }

        static func ConfirmClearBadge(type: Feed_V1_FeedFilter.TypeEnum,
                                      unmute: Int,
                                      mute: Int) {
            let groupName = FeedTracker.Group.Name(groupType: type)
            let params = ["clean_badge_mute": "\(mute)",
                          "clean_badge_unmute": "\(unmute)",
                          "clean_tab_name": groupName,
                          "target": "none",
                          "click": "confirm"]
             Tracker.post(TeaEvent("feed_clean_badge_confirm_click",
                                   params: params))
        }
        static func ClearBadgeMsgTab(showClearBadge: Bool) {
            var params: [AnyHashable: Any] = [:]
            params["is_has_clean_badge_icon"] = showClearBadge ? "true" : "false"
            Tracker.post(TeaEvent(Homeric.NAVIGATION_MAIN_CLICK, params: params))
        }

        static func FirstOpenAtAll(openAtAll: Bool, filter: Feed_V1_FeedFilter.TypeEnum) {
            let groupName = FeedTracker.Group.Name(groupType: filter)
            let params = ["tab_name": groupName,
                          "click": openAtAll ? "open_at_all" : "close_at_all",
                          "target": openAtAll ? "feed_open_at_all_notification_view" : "feed_close_at_all_notification_view"]
             Tracker.post(TeaEvent("feed_tab_press_detail_click",
                                   params: params))
        }

        static func ShowMsgDisplayRule(filter: Feed_V1_FeedFilter.TypeEnum) {
            let groupName = FeedTracker.Group.Name(groupType: filter)
            let params = ["click": "msg_display_rule",
                          "target": "feed_msg_display_rule_view",
                          "tab_name": groupName]
            Tracker.post(TeaEvent("feed_tab_press_detail_click", params: params))
        }

        static func SaveMsgDisplayRule(filter: Feed_V1_FeedFilter.TypeEnum, ruleChanged: Bool) {
            let groupName = FeedTracker.Group.Name(groupType: filter)
            var params: [AnyHashable: Any] = [:]
            params["click"] = "save"
            params["target"] = "none"
            params["is_filter_display_rule_change"] = ruleChanged ? 1 : 0
            params["is_tag_display_rule_change"] = 0
            params["tab_name"] = groupName
            Tracker.post(TeaEvent("feed_msg_display_rule_click", params: params))
        }

        static func ConfirmOpenAtAll(openAtAll: Bool, type: FilterGroupAction) {
            let groupName: String
            let id: String
            let mode: String
            switch type {
            case .firstLevel(let filter):
                groupName = FeedTracker.Group.Name(groupType: filter)
                id = String(filter.rawValue)
                mode = "feed"
            case .secondLevel(let tab):
                groupName = FeedTracker.Group.Name(groupType: tab.type)
                if tab.type == .team {
                    mode = "team"
                } else if tab.type == .tag {
                    mode = "label"
                } else {
                    mode = "unknown"
                }
                id = String(tab.tabId)
            }
            let params = ["tab_name": groupName,
                          "entity_id": id,
                          "click": "confirm",
                          "target": "none",
                          "type": mode]

            let key: String
            if openAtAll {
                key = "feed_open_at_all_notification_click"
            } else {
                key = "feed_close_at_all_notification_click"
            }
            Tracker.post(TeaEvent(key,
                                  params: params))
        }
    }
}
