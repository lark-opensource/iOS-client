//
//  GroupEdit.swift
//  LarkFeed
//
//  Created by 夏汝震 on 2021/5/13.
//

import Foundation
import LKCommonsTracker
import Homeric
import RustPB
import LarkModel

/// 「「消息筛选器编辑页面」页面相关埋点
extension FeedTracker {
    struct GroupEdit {}
}

///「消息筛选器编辑页面」的展示
extension FeedTracker.GroupEdit {
    /// 「消息筛选器编辑页面」的展示
    static func View() {
        Tracker.post(TeaEvent(Homeric.FEED_GROUPING_EDIT_VIEW))
    }
}

///「消息筛选器编辑页面」的动作事件
extension FeedTracker.GroupEdit {
    struct Click {
        /// 点击消息筛选器开关
        static func Toggle() {
            var params: [AnyHashable: Any] = [:]
            params["click"] = "feed_grouping_edit_filter_toggle"
            params["target"] = "none"
            Tracker.post(TeaEvent(Homeric.FEED_GROUPING_EDIT_CLICK, params: params))
        }

        ///点击保存
        static func Save(displayRuleChanged: Bool, labelSecondaryRuleChanged: Bool) {
            var params: [AnyHashable: Any] = [:]
            params["click"] = "feed_grouping_edit_save"
            params["target"] = "none"
            params["is_filter_display_rule_change"] = displayRuleChanged ? 1 : 0
            params["is_tag_display_rule_change"] = labelSecondaryRuleChanged ? 1 : 0
            Tracker.post(TeaEvent(Homeric.FEED_GROUPING_EDIT_CLICK, params: params))
        }

        ///点击叉号关闭
        static func Close() {
            var params: [AnyHashable: Any] = [:]
            params["click"] = "feed_grouping_edit_close"
            params["target"] = "none"
            Tracker.post(TeaEvent(Homeric.FEED_GROUPING_EDIT_CLICK, params: params))
        }

        /// 点击tab左边的减号
        static func Minus() {
            var params: [AnyHashable: Any] = [:]
            params["click"] = "feed_grouping_edit_minus"
            params["target"] = "none"
            Tracker.post(TeaEvent(Homeric.FEED_GROUPING_EDIT_CLICK, params: params))
        }

        ///点击tab左边的加号
        static func Plus() {
            var params: [AnyHashable: Any] = [:]
            params["click"] = "feed_grouping_edit_plus"
            params["target"] = "none"
            Tracker.post(TeaEvent(Homeric.FEED_GROUPING_EDIT_CLICK, params: params))
        }

        /// 主设置页的消息免打扰开关标识
        static func MuteToggle(status: Bool) {
            var params: [AnyHashable: Any] = [:]
            params["click"] = "efficiency_mute_toggle"
            params["target"] = "none"
            params["status"] = status ? "on" : "off"
            Tracker.post(TeaEvent(Homeric.SETTING_DETAIL_CLICK, params: params))
        }

        /// 主设置页的消息筛选器开关
        static func FilterToggle(status: Bool) {
            var params: [AnyHashable: Any] = [:]
            params["click"] = "efficiency_feed_grouping_edit_filter_toggle"
            params["target"] = "none"
            params["status"] = status ? "on" : "off"
            Tracker.post(TeaEvent(Homeric.SETTING_DETAIL_CLICK, params: params))
        }
    }
}
