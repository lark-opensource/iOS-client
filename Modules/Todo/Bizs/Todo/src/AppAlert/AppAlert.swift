//
//  AppAlert.swift
//  Todo
//
//  Created by wangwanxin on 2021/9/1.
//

import Foundation

struct AppAlert { }

extension AppAlert {
    enum Track {}
}

extension AppAlert.Track: TrackerConvertible {
    /// 埋点 event
    enum TrackerEvent: String, TrackerEventKeyConvertible {
        /// 应用内任务提醒页
        case view = "todo_event_notification_view"

        /// 在「应用内任务提醒页」发生动作事件
        case click = "todo_event_notification_click"

        var eventKey: String { rawValue }
    }

    /// 应用内任务提醒页
    static func view(with guid: String) {
        var params = [
            "task_id": guid
        ]
        trackEvent(.view, with: params)
    }

    /// 点击查看详情
    static func clickDetail(with guid: String) {
        var params = [
            "task_id": guid,
            "click": "check_more_detail",
            "target": "todo_task_detail_view"
        ]
        trackEvent(.click, with: params)
    }

    /// 点击关闭
    static func clickClose(with guid: String) {
        var params = [
            "task_id": guid,
            "click": "close",
            "target": "none"
        ]
        trackEvent(.click, with: params)
    }

}
