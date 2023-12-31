//
//  Label.swift
//  LarkFeed
//
//  Created by 夏汝震 on 2022/5/6.
//

import Foundation
import LKCommonsTracker
import Homeric
import LarkModel
import RustPB

/// [标签] 相关埋点
extension FeedTracker {
    struct Label {}
}

extension FeedTracker.Label {
    struct Click {
        // 创建标签
        static func CreatLabelInFooter() {
            let params = ["target": "feed_create_label_view",
                          "click": "create_label"]
             Tracker.post(TeaEvent("feed_label_mobile_click",
                                   params: params))
        }

        static func CreatLabelInEmpty() {
            let params = ["target": "feed_create_label_view",
                          "click": "create_label_icon"]
             Tracker.post(TeaEvent("feed_label_mobile_click",
                                   params: params))
        }

        static func ShowMsgDisplayRule(labelId: String) {
            let params = ["click": "msg_display_rule",
                          "target": "feed_label_msg_display_rule_view",
                          "label_id": labelId]
            Tracker.post(TeaEvent(Homeric.FEED_LABEL_MANAGE_MOBILE_CLICK,
                                  params: params))
        }

        static func SaveMsgDisplayRule(labelId: String, ruleChanged: Bool) {
            var params: [AnyHashable: Any] = [:]
            params["click"] = "save"
            params["target"] = "none"
            params["label_id"] = labelId
            params["is_tag_display_rule_change"] = ruleChanged ? 1 : 0
            params["is_filter_display_rule_change"] = 0
            Tracker.post(TeaEvent("feed_msg_display_rule_click", params: params))
        }

        static func BatchClearLabelBadge(labelId: String, unreadCount: Int, muteUnreadCount: Int) {
            let params = ["click": "clean_badge",
                          "target": "feed_clean_badge_confirm_view",
                          "clean_badge_mute": "\(muteUnreadCount)",
                          "clean_badge_unmute": "\(unreadCount)",
                          "label_id": labelId]
            Tracker.post(TeaEvent(Homeric.FEED_LABEL_MANAGE_MOBILE_CLICK,
                                  params: params))
        }

        static func BatchClearLabelBadgeConfirm() {
            let params = ["click": "confirm",
                          "target": "none"]
            Tracker.post(TeaEvent(Homeric.FEED_CLEAN_BADGE_CONFIRM_CLICK,
                                  params: params))
        }

        static func BatchMuteLabelFeeds(labelId: String, mute: Bool) {
            var params = ["target": "feed_clean_badge_confirm_view",
                          "label_id": labelId]
            if mute {
                params["click"] = "all_mute"
                params["target"] = "feed_all_mute_confirm_view"
            } else {
                params["click"] = "all_unmute"
                params["target"] = "feed_all_unmute_confirm_view"
            }
            Tracker.post(TeaEvent(Homeric.FEED_LABEL_MANAGE_MOBILE_CLICK,
                                  params: params))
        }

        static func BatchMuteLabelFeedsConfirm(mute: Bool) {
            let params = ["click": "confirm",
                          "target": "none"]
            if mute {
                Tracker.post(TeaEvent(Homeric.FEED_ALL_MUTE_CONFIRM_CLICK,
                                      params: params))
            } else {
                Tracker.post(TeaEvent(Homeric.FEED_ALL_UNMUTE_CONFIRM_CLICK,
                                      params: params))
            }
        }

        static func FirstOpenAtAll(labelId: String, openAtAll: Bool) {
            var params = ["label_id": labelId]
            if openAtAll {
                params["click"] = "open_at_all"
                params["target"] = "feed_open_at_all_notification_view"
            } else {
                params["click"] = "close_at_all"
                params["target"] = "feed_close_at_all_notification_view"
            }
            Tracker.post(TeaEvent("feed_label_manage_mobile_click",
                                  params: params))
        }
    }
}
