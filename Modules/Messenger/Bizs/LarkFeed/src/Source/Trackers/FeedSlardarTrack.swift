//
//  FeedSlardarTrack.swift
//  LarkFeed
//
//  Created by 袁平 on 2020/7/16.
//

import Foundation
import LKCommonsTracker
import LarkPerf
import RustPB
import LarkSDKInterface

/// Feed Slardar打点
final class FeedSlardarTrack {
    /// 启动页消失 判断Feed是否展示
    static func trackFeedTransitionDisappear(_ feedsCount: Int) {
        let category = ["hasFeed": feedsCount > 0]
        Tracker.post(SlardarEvent(name: "feed_launchTransition_disappear",
                                  metric: [:],
                                  category: category,
                                  extra: [:]))
    }

    /// feed cell UIUserInterfaceStyle报警
    @available(iOS 12.0, *)
    static func trackFeedCellUserInterfaceStyle(_ style: UIUserInterfaceStyle, appStyle: UIUserInterfaceStyle, description: String) {
        let extra: [String: Any] = ["style": style.rawValue,
                                    "appStyle": appStyle.rawValue,
                                    "description": description]
        Tracker.post(SlardarEvent(name: "feed_cell_userInterfaceStyle",
                                  metric: [:],
                                  category: [:],
                                  extra: extra))
    }

    /// 监听从服务器加载 short cut 时间
    fileprivate static let feedLoadShortcutTime = "lark_feed_shortcut_load_time"
    fileprivate static var feedLoadShortCutTimeTracking = false
    static func trackFeedLoadShortcutTimeStart() {
        feedLoadShortCutTimeTracking = true
        TimeMonitorHelper.shared.startTrack(
            task: feedLoadShortcutTime,
            callback: { result in
                Tracker.post(SlardarEvent(
                    name: feedLoadShortcutTime,
                    metric: [:],
                    category: ["value": result.duration],
                    extra: result.params ?? [:])
                )
            })
    }

    static func trackFeedLoadShortcutTimeEnd() {
        if !feedLoadShortCutTimeTracking { return }
        feedLoadShortCutTimeTracking = false
        TimeMonitorHelper.shared.endTrack(
            task: feedLoadShortcutTime
        )
    }
}
