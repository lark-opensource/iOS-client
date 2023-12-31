//
//  QuickCreate.swift
//  Todo
//
//  Created by wangwanxin on 2021/3/29.
//

import LKCommonsLogging
import LKCommonsTracker

struct QuickCreate {}

// MARK: - Logger
extension QuickCreate {
    static let logger = Logger.log(QuickCreate.self, category: "Todo.QuickCreate")
}

// MARK: - Tracker
extension QuickCreate {

    enum TrackerEventKey: String {
        case create = "todo_create"
        case create_suspend = "todo_create_suspend"
        case create_confirm = "todo_create_confirm"
        case select_time = "todo_date_click"
        case expand_to_detail = "todo_input_box_expand_click"
    }

    static func trackEvent(key eventKey: TrackerEventKey, params: [AnyHashable: Any] = [:]) {
        Tracker.post(TeaEvent(eventKey.rawValue, params: params))
    }
}
