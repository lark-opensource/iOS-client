//
//  V3Home.swift
//  Todo
//
//  Created by wangwanxin on 2022/8/16.
//

import LKCommonsLogging
import LKCommonsTracker

/// Home域
struct V3Home { }

extension V3Home {
    static let drawerTag: String = "Todo_Menu"
}

// MARK: - Logger

extension V3Home {
    static let logger = Logger.log(V3Home.self, category: "Todo.V3Home")
}

// MARK: - Assert

extension V3Home {

    enum AssertType: String {
        /// 未定义（默认）
        case `default`
        /// 逻辑错误
        case logic
    }

    static func assertionFailure(
        _ message: @autoclosure () -> String = String(),
        type: AssertType = .default,
        extra: [AnyHashable: Any] = .init(),
        file: String = #fileID,
        line: Int = #line
    ) {
        let msg = message()
        V3Home.logger.error("msg: \(msg), type: \(type), extra: \(extra)", file: file, line: line)
        let assertConfig = AssertReporter.AssertConfig(scene: "V3Home", event: type.rawValue)
        AssertReporter.report(msg, extra: extra, config: assertConfig, file: file, line: line)
    }

}

// MARK: - Tracker

extension V3Home {

    /// 旧埋点 event，数据分析团队计划是2021年9月都下掉，到时候需要把之前埋点都删除掉
    enum OldTrackerEvent: String {
        /// 任务从未完成状态到完成状态的转变
        case statusDone = "todo_task_status_done"
        /// 任务从完成状态到未完成状态的转变
        case statusNotDone = "todo_task_status_not_done"
        /// 在页面内部切换视图时
        case switchFilter = "todo_switch_click"
        /// 列表页被展示
        case viewList = "todo_view"
        /// 分享 todo
        case shareTodo = "todo_task_share"
        /// 任务中心任务列表页面
        case todo_list_view = "todo_center_task_list_view"
    }

    static func trackEvent(_ eventKey: OldTrackerEvent, with params: [AnyHashable: Any] = [:]) {
        Tracker.post(TeaEvent(eventKey.rawValue, params: params))
    }

}
