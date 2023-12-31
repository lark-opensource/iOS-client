//
//  Main.swift
//  LarkFeed
//
//  Created by 夏汝震 on 2021/5/12.
//

import Foundation
import LKCommonsTracker
import Homeric
import RustPB
import LarkModel
import LarkFeedBase
import LarkOpenFeed

/// 「feed流」主页面相关埋点
public extension FeedTracker {
    struct Main {}
}

//「feed流」主页面的展示
public extension FeedTracker.Main {
    static func View(filtersCount: Int, isFilterShow: Bool) {
        var params: [AnyHashable: TeaDataType] = [:]
        // 当前feed流的消息筛选框展示的tab数量
        params["feed_grouping_tab_num"] = filtersCount
        // 是否有消息筛选栏（关闭消息筛选器则不展示）
        params["is_feed_grouping_tab_show"] = isFilterShow ? "true" : "false"
        Tracker.post(TeaEvent(Homeric.FEED_MAIN_VIEW, params: params))
    }
}

/// feed流」主页面的动作事件
public extension FeedTracker.Main {
    struct Click {
        /// 点击消息筛选栏的tab
        static func Tab(tabOrder: Int,
                        tabType: String,
                        belongedTab: Feed_V1_FeedFilter.TypeEnum?,
                        targetTab: Feed_V1_FeedFilter.TypeEnum?) {
            guard let tab1 = belongedTab, let tab2 = targetTab else { return }
            var params: [AnyHashable: Any] = [:]
            params["click"] = "feed_grouping_tab"
            params["target"] = "none"
            params["tab_order"] = tabOrder //点击的tab在消息筛选栏中所属的顺序
            params["tab_type"] = tabType //tab类型
            params["is_more_tab"] = "false" //此tab是否在更多下
            params += FeedTracker.Group.Groups(belongedTab: tab1, targetTab: tab2)
            Tracker.post(TeaEvent(Homeric.FEED_MAIN_CLICK, params: params))
        }

        /// 点击消息筛选栏的设置入口
        static func Setting(filter: Feed_V1_FeedFilter.TypeEnum) {
            var params: [AnyHashable: Any] = [:]
            params["click"] = "feed_more_tab_mobile"
            params["target"] = "feed_grouping_edit_view"
            params += FeedTracker.Group.Groups(belongedTab: filter, targetTab: filter)
            Tracker.post(TeaEvent(Homeric.FEED_MAIN_CLICK, params: params))
        }

        /// 点击某条会话feed
        public static func Chat(feed: FeedPreview, filter: Feed_V1_FeedFilter.TypeEnum?, iPadStatus: String?) {
            guard let tab = filter else { return }
            var params: [AnyHashable: Any] = [:]
            params["click"] = "feed_leftclick_chat"
            params["target"] = "im_chat_main_view"
//            params["feed_type"] = FeedTracker.Base.FeedType(feed.basicData.feedPreviewPBType)
            params["chat_id"] = feed.id
            params["is_ai"] = feed.preview.chatData.isP2PAi
            params["is_temporary_top"] = feed.basicMeta.onTopRankTime > 0 ? 1 : 0
            if let iPadStatus = iPadStatus {
                params["status_ipad"] = iPadStatus
            }
            params += FeedTracker.Group.Groups(belongedTab: tab, targetTab: tab)
            Tracker.post(TeaEvent(Homeric.FEED_MAIN_CLICK, params: params))
        }

        /// 点击某条会话feed
        public static func Chat(teamId: String, feed: FeedPreview, filter: Feed_V1_FeedFilter.TypeEnum?) {
            guard let tab = filter else { return }
            var params: [AnyHashable: Any] = [:]
            params["click"] = "feed_leftclick_chat"
            params["target"] = "im_chat_main_view"
//            params["feed_type"] = FeedTracker.Base.FeedType(feed.basicData.feedPreviewPBType)
            params["chat_id"] = feed.id
            params["is_ai"] = feed.preview.chatData.isP2PAi
            params["team_id"] = teamId
            params += FeedTracker.Group.Groups(belongedTab: tab, targetTab: tab)
            Tracker.post(TeaEvent(Homeric.FEED_MAIN_CLICK, params: params))
        }

        /// 点击某条文档feed
        public static func Doc(feed: FeedPreview, filter: Feed_V1_FeedFilter.TypeEnum?, iPadStatus: String?) {
            guard let tab = filter else { return }
            var params: [AnyHashable: Any] = [:]
            params["click"] = "feed_leftclick_doc"
            params["target"] = "ccm_docs_page_view"
            params["file_id"] = feed.preview.docData.lastDocMessageID
            if let iPadStatus = iPadStatus {
                params["status_ipad"] = iPadStatus
            }
            params += FeedTracker.Group.Groups(belongedTab: tab, targetTab: tab)
            Tracker.post(TeaEvent(Homeric.FEED_MAIN_CLICK, params: params, md5AllowList: ["file_id"]))
        }

        /// 左滑某条feed
        static func Leftslide(filter: Feed_V1_FeedFilter.TypeEnum, _ iPadStatus: String?) {
            guard filter != .unknown else { return }
            var params: [AnyHashable: Any] = [:]
            params["click"] = "feed_leftslide"
            params["target"] = "feed_leftslide_detail_view"
            params += FeedTracker.Group.Groups(belongedTab: filter, targetTab: filter)
            if let iPadStatus = iPadStatus {
                params["status_ipad"] = iPadStatus
            }
            Tracker.post(TeaEvent(Homeric.FEED_MAIN_CLICK, params: params))
        }

        /// 右滑某条feed
        static func Rightslide(filter: Feed_V1_FeedFilter.TypeEnum, _ iPadStatus: String?) {
            guard filter != .unknown else { return }
            var params: [AnyHashable: Any] = [:]
            params["click"] = "feed_rightslide"
            params["target"] = "feed_rightslide_detail_view"
            params += FeedTracker.Group.Groups(belongedTab: filter, targetTab: filter)
            if let iPadStatus = iPadStatus {
                params["status_ipad"] = iPadStatus
            }
            Tracker.post(TeaEvent(Homeric.FEED_MAIN_CLICK, params: params))
        }

        /// 移动端右滑「完成」某条feed
        static func Done(filter: Feed_V1_FeedFilter.TypeEnum, isSmallSlide: Bool, _ iPadStatus: String?) {
            guard filter != .unknown else { return }
            var params: [AnyHashable: Any] = [:]
            params["click"] = "feed_done_mobile"
            params["target"] = "feed_rightslide_detail_view"
            params["rightslide_type"] = isSmallSlide ? "small" : "big"
            params += FeedTracker.Group.Groups(belongedTab: filter, targetTab: filter)
            if let iPadStatus = iPadStatus {
                params["status_ipad"] = iPadStatus
            }
            Tracker.post(TeaEvent(Homeric.FEED_MAIN_CLICK, params: params))
        }

        /// 长按点击出菜单
        static func FeedPress(_ iPadStatus: String?) {
            var params: [AnyHashable: Any] = ["click": "feed_press", "target": "feed_press_view"]
            if let iPadStatus = iPadStatus {
                params["status_ipad"] = iPadStatus
            }
            Tracker.post(TeaEvent(Homeric.FEED_MAIN_CLICK, params: params))
        }
    }
}
