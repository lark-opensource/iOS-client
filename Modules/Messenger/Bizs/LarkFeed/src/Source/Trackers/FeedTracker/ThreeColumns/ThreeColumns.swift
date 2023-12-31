//
//  ThreeColumns.swift
//  LarkFeed
//
//  Created by liuxianyu on 2022/5/7.
//

import Foundation
import LKCommonsTracker
import Homeric
import RustPB

/// 三栏相关埋点
extension FeedTracker {
    struct ThreeColumns {}
}

extension FeedTracker.ThreeColumns {
    struct View {
        static func onboardView() {
            Tracker.post(TeaEvent(Homeric.FEED_GROUP_ONBOARDING_VIEW))
        }

        static func mobileGroupViewByClick() {
            let params = ["evoke_type": "click"]
            Tracker.post(TeaEvent(Homeric.FEED_MOBILE_GROUP_VIEW,
                                  params: params))
        }

        static func mobileGroupViewBySlide() {
            let params = ["evoke_type": "slide"]
            Tracker.post(TeaEvent(Homeric.FEED_MOBILE_GROUP_VIEW,
                                  params: params))
        }
    }
}

extension FeedTracker.ThreeColumns {
    struct Click {
        static func menuClick() {
            let params = ["click": "menu",
                          "target": "feed_mobile_group_view"]
             Tracker.post(TeaEvent(Homeric.FEED_FIXED_GROUP_CLICK,
                                   params: params))
        }

        static func fixedTabClick(_ type: Feed_V1_FeedFilter.TypeEnum) {
            let clickValue = FeedTracker.Group.Name(groupType: type)
            let params = ["tab_name": clickValue,
                          "click": "press_tab",
                          "target": "none"]
             Tracker.post(TeaEvent(Homeric.FEED_FIXED_GROUP_CLICK,
                                   params: params))
        }

        static func settingClick() {
            let params = ["click": "setting",
                          "target": "feed_grouping_edit_view"]
             Tracker.post(TeaEvent(Homeric.FEED_MOBILE_GROUP_CLICK,
                                   params: params))
        }

        static func firstLevelTabClick(type: Feed_V1_FeedFilter.TypeEnum,
                                       tabOrder: String,
                                       isSecondLevelTabUnfold: Bool?) {
            let tabName = FeedTracker.Group.Name(groupType: type)
            var params = ["click": "first_level_tab",
                          "target": "none",
                          "tab_name": tabName,
                          "tab_order": tabOrder]
            if let isSecondLevelTabUnfold = isSecondLevelTabUnfold {
                let isUnfold = isSecondLevelTabUnfold ? "true" : "false"
                params["is_second_level_tab_unfold"] = isUnfold
            }
            Tracker.post(TeaEvent(Homeric.FEED_MOBILE_GROUP_CLICK,
                                  params: params))
        }

        static func secondLevelTabClick(tabName: String) {
            let params = ["click": "second_level_tab",
                          "target": "none",
                          "belonged_tab_name": tabName]
             Tracker.post(TeaEvent(Homeric.FEED_MOBILE_GROUP_CLICK,
                                   params: params))
        }
    }
}

struct FeedSideBarClick {
   static let tag: String = "Menu"
}
