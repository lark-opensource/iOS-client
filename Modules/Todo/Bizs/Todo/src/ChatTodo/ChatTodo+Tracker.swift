//
//  ChatTodo+Tracker.swift
//  Todo
//
//  Created by wangwanxin on 2021/5/19.
//

import Foundation

extension ChatTodo {
    enum Track {}
}

extension ChatTodo.Track: TrackerConvertible {

    /// Home埋点 event
    enum TrackerEvent: String, TrackerEventKeyConvertible {
        /// 「会话中任务中心」页面展示（ PC端在侧边栏， 移动端在会话设置页）
        case viewList = "todo_im_chat_todo_list_view"
        /// 「会话中任务中心」页面发生动作事件
        case listClick = "todo_im_chat_todo_list_click"

        var eventKey: String { rawValue }
    }
}

extension ChatTodo.Track {

    /// 会话中任务中心的页面展示（ PC端在侧边栏， 移动端在会话设置页）
    static func viewList(with chatId: String) {
        trackEvent(.viewList, with: ["chat_id": chatId])
    }

    /// add_task：添加任务
    static func addTodo(with chatId: String) {
        var param = TrackerUtil.getAddTodoParam()
        param["chat_id"] = chatId
        trackEvent(.listClick, with: param)
    }

    /// 点击Check Box
    static func clickCheckBox(with todo: Rust.Todo, chatId: String, fromState: CompleteState) {
        var param = TrackerUtil.getClickCheckBoxParam(with: todo.guid, fromState: fromState, role: .todo)
        param["chat_id"] = chatId
        trackEvent(.listClick, with: param)
    }

    /// 点击任务
    static func clickCell(with guid: String, chatId: String) {
        var param = TrackerUtil.getClickCellParam(with: guid)
        param["chat_id"] = chatId
        trackEvent(.listClick, with: param)
    }

    /// leave_task：离开任务（包括删除任务&不再参与任务)
    static func clickLeave(with guid: String, chatId: String) {
        var param = TrackerUtil.getLeaveTaskParam(with: guid)
        param["chat_id"] = chatId
        trackEvent(.listClick, with: param)
    }

    /// jump_to_chat: 跳转至会话
    static func clickJumpToChat(with guid: String, chatId: String) {
        let param = [
            "task_id": guid,
            "chat_id": chatId,
            "click": "jump_to_chat",
            "target": "im_chat_main_view"
        ]
        trackEvent(.listClick, with: param)
    }

    /// jump_to_center: 跳转至任务中心
    static func clickJumpToCenter() {
        let param = [
            "click": "check_more",
            "target": "todo_center_task_list_view"
        ]
        trackEvent(.listClick, with: param)
    }
}
