//
//  QuickCreate+Tracker.swift
//  Todo
//
//  Created by wangwanxin on 2021/5/19.
//

import Foundation

extension QuickCreate {
    enum Track {}
}

extension QuickCreate.Track: TrackerConvertible {

    /// Home埋点 event
    enum TrackerEvent: String, TrackerEventKeyConvertible {
        /// 「便捷创建任务」页面展示
        case viewQuickCreate = "todo_quick_create_view"
        /// 在「便捷创建任务」页面，发生动作事件
        case clickQuickCreate = "todo_quick_create_click"

        var eventKey: String { rawValue }
    }
}

extension QuickCreate.Track {
    /// 「便捷创建任务」页面展示
    static func viewQuickCreate() {
        trackEvent(.viewQuickCreate)
    }

    /// 便捷创建任务
    static func clickSave(with todo: Rust.Todo, isNotInDetailSection: Bool) {
        trackEvent(.clickQuickCreate, with: TrackerUtil.getClickSaveParam(
            with: todo,
            isQuickCreate: true,
            isNotInDetailSection: isNotInDetailSection,
            isSendToChat: false
        ))
    }

    /// unfold：点击「展开」
    static func clickExpand() {
        let param = [
            "click": "unfold",
            "target": "todo_create_view"
        ]
        trackEvent(.clickQuickCreate, with: param)
    }

}
