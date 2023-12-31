//
//  FeedDataSyncTracker.swift
//  LarkFeed
//
//  Created by 夏汝震 on 2021/8/11.
//

import Foundation
import Homeric
import LKCommonsTracker
import RustPB
import LarkSDKInterface
import LarkPerf
import LarkModel
import LKCommonsLogging

/// Feed 异常 打点
final class FeedDataSyncTracker {

    /// 双击 消息 tab 找未读，无法跳转的异常
    static func trackFindUnreadFeed(
        filterType: Feed_V1_FeedFilter.TypeEnum,
        allFeeds: [FeedCardCellViewModel],
        response: NextUnreadFeedCardsResult,
        filterBadgeCount: Int?) {
            let filter = FiltersModel.tabName(filterType)
            guard let filterBadgeCount = filterBadgeCount,
                  response.previews.filter({ $0.basicMeta.isRemind && $0.basicMeta.unreadCount > 0 }).isEmpty else { return }

            var listCount = 0
            allFeeds.filter({ $0.feedPreview.basicMeta.isRemind && $0.feedPreview.basicMeta.unreadCount > 0 }).forEach({ listCount += $0.feedPreview.basicMeta.unreadCount })

            guard filterBadgeCount != listCount else { return }
            let params = [
                "tab": filter,
                "total_badge": filterBadgeCount,
                "list_badge": listCount] as [String: Any]
            Tracker.post(TeaEvent(Homeric.IM_FEED_NEXT_UNREAD_BADGE_DEV, params: params))
            FeedContext.log.error("feedlog/monitor/dataSync/feed_next_unread_badge. \(params)")
        }

    /// 某个filter tab下，拉全列表时 ，检测到 feed 数量和 tab 上数量是否不一致，不一致会上报
    static func trackListBadgeWhenLoadAllFeed(
        filterType: Feed_V1_FeedFilter.TypeEnum,
        listBadge: Int,
        filterBadgeCount: Int?) {
            guard let filterBadgeCount = filterBadgeCount else { return }
            guard filterBadgeCount != listBadge else { return }
            let filter = FiltersModel.tabName(filterType)
            let params = [
                "tab": filter,
                "total_badge": filterBadgeCount,
                "list_badge": listBadge] as [String: Any]
            Tracker.post(TeaEvent(Homeric.IM_FEED_MONITOR_BADGE_DEV, params: params))
            FeedContext.log.error("feedlog/monitor/dataSync/feed_monitor_badge. \(params)")
    }

    /// feed数据userID比较错误的数据上报
    static func trackFeedPreviewCheckError(feedId: String, currentUserId: String, feedUserId: String) {
        var params: [AnyHashable: Any] = [:]
        params["feed_id"] = feedId
        params["current_user_id"] = currentUserId
        params["feed_user_id"] = feedUserId
        Tracker.post(TeaEvent(Homeric.IM_FEED_NEXT_UNREAD_BADGE_DEV,
                              params: params,
                              md5AllowList: ["current_user_id", "feed_user_id"]))
    }
}
