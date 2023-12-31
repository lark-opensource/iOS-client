//
//  Tracker.swift
//  LarkMeegoStrategy
//
//  Created by shizhengyu on 2023/4/19.
//

import Foundation
import LKCommonsTracker
import LarkMeegoStorage

enum TrackerAction: String {
    case exposeEntrance = "expose_entrance"
    case exposeScene = "expose_scene"
    case preRequestUseCache = "pre_request_use_cache"
    case preRequestUsePool = "pre_request_use_pool"
    case preRequest = "pre_request"
    case preRequestSuccess = "pre_request_success"
    case preRequestFailed = "pre_request_failed"
}

enum StrategyTracker {
    static func userTrack(
        larkScene: LarkScene,
        meegoScene: MeegoScene,
        userActivity: UserActivity,
        url: String
    ) {
        if let trackerAction = TrackerAction(rawValue: userActivity.rawValue) {
            signpost(
                larkScene: larkScene,
                meegoScene: meegoScene,
                action: trackerAction,
                url: url
            )
        }
    }

    static func signpost(
        larkScene: LarkScene,
        meegoScene: MeegoScene,
        action: TrackerAction,
        url: String,
        latency: Int? = nil,
        errorMsg: String? = nil
    ) {
        var metric: [AnyHashable: Any] = [:]
        var extra: [AnyHashable: Any] = ["url": url]
        if let latency = latency {
            metric["latency"] = latency
        }
        if let errorMsg = errorMsg {
            extra["error"] = errorMsg
        }

        let event = SlardarEvent(
            name: "meego_user_track",
            metric: metric,
            category: ["lark_scene": larkScene.rawValue, "scene": meegoScene.rawValue, "action": action.rawValue],
            extra: extra
        )
        Tracker.post(event)
    }

    static func monitor(with unknownLarkScene: String, url: String) {
        let event = SlardarEvent(
            name: "meego_strategy_record_missing",
            metric: [:],
            category: ["lark_scene": unknownLarkScene],
            extra: ["url": url]
        )
        Tracker.post(event)
    }
}
