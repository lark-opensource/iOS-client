//
//  Press.swift
//  LarkFeed
//
//  Created by 夏汝震 on 2022/6/12.
//

import Foundation
import LKCommonsTracker
import Homeric
import LarkOpenFeed
import LarkModel

extension FeedTracker {
    struct Press {}
}

extension FeedTracker.Press {
    /// 长按 Feed 的展示埋点
    static func View() {
        Tracker.post(TeaEvent(Homeric.FEED_PRESS_VIEW,
                              category: "chat"))
    }
}

extension FeedTracker.Press {
    struct Click {
        /// 点击 Feed 长按菜单 item 的埋点
        static func Item(itemValue: String,
                         feedPreview: FeedPreview,
                         basicData: IFeedPreviewBasicData?) {
            var params: [AnyHashable: TeaDataType] = [
                "click": itemValue,
                "target": "none"]
            params += FeedTracker.FeedCard.BaseParams(
                feedPreview: feedPreview,
                basicData: basicData,
                bizData: nil)
            Tracker.post(TeaEvent(Homeric.FEED_PRESS_CLICK,
                                  category: "chat",
                                  params: params))
        }

        /// 操作Feed标签
        static func CreateOrEditLabel(
            mode: SettingLabelMode,
            hasRelation: Bool,
            feedPreview: FeedPreview,
            basicData: IFeedPreviewBasicData?) {
            switch mode {
            case .create:
                // 点击 Feed 长按标签(用户没有创建标签)
                var params: [AnyHashable: TeaDataType] = ["click": "create_label_mobile",
                              "target": "feed_create_label_view"]
                params += FeedTracker.FeedCard.BaseParams(
                    feedPreview: feedPreview,
                    basicData: basicData,
                    bizData: nil)
                Tracker.post(TeaEvent(Homeric.FEED_PRESS_CLICK, params: params))
            case .edit:
                if hasRelation {
                    // 点击 Feed 长按标签(有标签，feed也关联了标签)
                    var params: [AnyHashable: TeaDataType] = ["click": "label_mobile",
                                  "target": "feed_mobile_label_setting_view"]
                    params += FeedTracker.FeedCard.BaseParams(
                        feedPreview: feedPreview,
                        basicData: basicData,
                        bizData: nil)
                    Tracker.post(TeaEvent(Homeric.FEED_PRESS_CLICK,
                                          params: params))
                } else {
                    // 点击 Feed 长按标签(有标签，feed没有关联任何标签)
                    var params: [AnyHashable: TeaDataType] = ["click": "edit_label_mobile",
                                  "target": "feed_mobile_label_setting_view"]
                    params += FeedTracker.FeedCard.BaseParams(
                        feedPreview: feedPreview,
                        basicData: basicData,
                        bizData: nil)
                    Tracker.post(TeaEvent(Homeric.FEED_PRESS_CLICK, params: params))
                }
            @unknown default:
                break
            }
        }

        /// 操作Feed标记处理/取消标记
        static func Flag(feedPreview: FeedPreview,
                         basicData: IFeedPreviewBasicData?) {
            if feedPreview.basicMeta.isFlaged {
                var params: [AnyHashable: TeaDataType] = ["chat_type": feedPreview.chatSubType,
                              "chat_id": feedPreview.id,
                              "click": "unmark",
                              "target": "none"]
                params += FeedTracker.FeedCard.BaseParams(
                    feedPreview: feedPreview,
                    basicData: basicData,
                    bizData: nil)
                Tracker.post(TeaEvent(Homeric.FEED_PRESS_CLICK,
                                      params: params))
            } else {
                var params: [AnyHashable: TeaDataType] = ["chat_type": feedPreview.chatSubType,
                              "chat_id": feedPreview.id,
                              "click": "mark",
                              "target": "none"]
                params += FeedTracker.FeedCard.BaseParams(
                    feedPreview: feedPreview,
                    basicData: basicData,
                    bizData: nil)
                Tracker.post(TeaEvent(Homeric.FEED_PRESS_CLICK,
                                      params: params))
            }
        }

        static func ClearSingleBadge(feedPreview: FeedPreview,
                                     unreadCount: Int,
                                     isRemind: Bool,
                                     basicData: IFeedPreviewBasicData?) {
            var unread = 0
            var muteUnread = 0
            if isRemind {
                unread = unreadCount
            } else {
                muteUnread = unreadCount
            }
            var params: [AnyHashable: TeaDataType] = ["click": "clean_badge",
                          "target": "none",
                          "clean_badge_mute": "\(muteUnread)",
                          "clean_badge_unmute": "\(unread)"]
            params += FeedTracker.FeedCard.BaseParams(
                feedPreview: feedPreview,
                basicData: basicData,
                bizData: nil)
            Tracker.post(TeaEvent(Homeric.FEED_PRESS_CLICK, params: params))
        }
    }
}
