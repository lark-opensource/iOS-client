//
//  ActivityRecord.swift
//  Todo
//
//  Created by wangwanxin on 2023/4/12.
//

import LKCommonsLogging
import LKCommonsTracker

/// Home域
struct ActivityRecord { }

// MARK: - Tracker

extension ActivityRecord {
    enum Track {}
}

// MARK: - Logger

extension ActivityRecord {
    static let logger = Logger.log(ActivityRecord.self, category: "Todo.ActivityRecord")
}

extension ActivityRecord.Track: TrackerConvertible {

    /// 埋点 event
    enum TrackerEvent: String, TrackerEventKeyConvertible {
        case listView = "todo_task_list_progress_view"

        var eventKey: String { rawValue }
    }

}

extension ActivityRecord.Track {

    static func viewTaskList(with taskListId: String?) {
        var param: [String: Any] = [:]
        if let taskListId = taskListId {
            param["list_id"] = taskListId
        }
        trackEvent(.listView, with: param)
    }
}
