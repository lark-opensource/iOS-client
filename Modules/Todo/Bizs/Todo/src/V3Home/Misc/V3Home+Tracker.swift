//
//  V3Home+Tracker.swift
//  Todo
//
//  Created by wangwanxin on 2022/8/16.
//

import Foundation

// MARK: - Tracker

extension V3Home {
    enum Track {}
}

extension V3Home.Track: TrackerConvertible {

    /// 埋点 event
    enum TrackerEvent: String, TrackerEventKeyConvertible {
        case listView = "todo_center_task_list_view"
        case listClick = "todo_center_task_list_click"
        case taskListView = "todo_task_list_detail_view"
        case taskListSharePanel = "todo_task_list_share_view"
        case taskListShareClick = "todo_task_list_share_click"

        var eventKey: String { rawValue }
    }

}

extension V3Home.Track {

    static func viewTaskList(with container: Rust.TaskContainer?, isOnePage: Bool) {
        guard let container = container else { return }
        let param: [String: Any] = [
            "container_key": container.key,
            "container_category": "\(container.category.rawValue)",
            "container_id": container.guid,
            "location": isOnePage ? "independent_window" : "center_view",
            "is_archive": container.isArchived.description
        ]
        trackEvent(.taskListView, with: param)
    }

}

extension V3Home.Track {

    static func viewList(with container: Rust.TaskContainer?) {
        guard let container = container else { return }
        let param: [String: Any] = [
            "container_key": container.key,
            "container_category": "\(container.category.rawValue)",
            "container_id": container.guid
        ]
        trackEvent(.listView, with: param)
    }
}

// listClick 专场
extension V3Home.Track {

    /// check_list_progress：点击查看某一清单的动态
    static func clickActivity(with container: Rust.TaskContainer?) {
        let param: [String: Any] = [
            "click": "check_list_progress",
            "target": "todo_task_list_progress_view",
            "view_type": "list"
        ]
        clickList(container: container, param: param)
    }

    static func clickDragTask(with container: Rust.TaskContainer?) {
        let param: [String: Any] = [
            "click": "drag_task",
            "target": "none"
        ]
        clickList(container: container, param: param)
    }

    static func clickDragSection(with container: Rust.TaskContainer?) {
        let param: [String: Any] = [
            "click": "drag_section",
            "target": "none"
        ]
        clickList(container: container, param: param)
    }

    static func clickSwipeItem(_ isLeft: Bool) {
        let param: [String: Any] = [
            "click": isLeft ? "left_swipe" : "right_swipe",
            "target": "none"
        ]
        clickList(container: nil, param: param)
    }

    static func clickListContainer(with container: Rust.TaskContainer) {
        let param: [String: Any] = [
            "click": "container",
            "target": "todo_center_task_list_view"
        ]
        clickList(container: container, param: param)
    }

    static func clickListContainerMenu(with container: Rust.TaskContainer?) {
        let param: [String: Any] = [
            "click": "container_menu",
            "target": "todo_mobile_container_menu_view"
        ]
        clickList(container: container, param: param)
    }

    static func clickListCancelContainer(with container: Rust.TaskContainer?) {
        let param: [String: Any] = [
            "click": "cancel_container",
            "target": "todo_center_task_list_view"
        ]
        clickList(container: container, param: param)
    }

    static func clickListSearch(with container: Rust.TaskContainer?) {
        let param: [String: Any] = [
            "click": "search",
            "target": "asl_search_show"
        ]
        clickList(container: container, param: param)
    }

    static func clickListSetting() {
        let param: [String: Any] = [
            "click": "setting",
            "target": "setting_todo_view"
        ]
        clickList(container: nil, param: param)
    }

    static func clickListHelp() {
        let param: [String: Any] = [
            "click": "help",
            "target": "none"
        ]
        clickList(container: nil, param: param)
    }

    static func clickListMore() {
        let param: [String: Any] = [
            "click": "more",
            "target": "todo_center_task_list_more_view"
        ]
        clickList(container: nil, param: param)
    }

    static func clickListToolbar(with container: Rust.TaskContainer?) {
        let param: [String: Any] = [
            "click": "toolbar",
            "target": "none"
        ]
        clickList(container: container, param: param)
    }

    static func clickListWholeAddTask(with container: Rust.TaskContainer?) {
        let param: [String: Any] = [
            "click": "whole_add_task",
            "target": "todo_create_view"
        ]
        clickList(container: container, param: param)
    }

    static func clickListCompleteStatus(with container: Rust.TaskContainer?, completeType: FilterTab.StatusField) {
        var param: [String: Any] = [
            "click": "complete_status",
            "target": "todo_center_task_list_view"
        ]
        switch completeType {
        case .uncompleted:
            param["type"] = "undone"
        case .completed:
            param["type"] = "done"
        case .all:
            param["type"] = "all"
        }
        clickList(container: container, param: param)
    }

    static func clickListGroup(with container: Rust.TaskContainer?) {
        let param: [String: Any] = [
            "click": "group",
            "target": "todo_center_task_list_view"
        ]
        clickList(container: container, param: param)
    }

    static func clickListSort(with container: Rust.TaskContainer?) {
        let param: [String: Any] = [
            "click": "sort",
            "target": "todo_center_task_list_view"
        ]
        clickList(container: container, param: param)
    }

    static func clickListDragTask(with container: Rust.TaskContainer) {
        let param: [String: Any] = [
            "click": "drag_task",
            "target": "none"
        ]
        clickList(container: container, param: param)
    }

    static func clickListDragSection(with container: Rust.TaskContainer) {
        let param: [String: Any] = [
            "click": "drag_section",
            "target": "none"
        ]
        clickList(container: container, param: param)
    }

    static func clickListEditSection(with container: Rust.TaskContainer?, type: V3ListViewModel.SectionMoreAction) {
        var param: [String: Any] = [
            "click": "edit_section",
            "target": "none"
        ]
        switch type {
        case .backwardCreate:
            param["type"] = "down_add"
        case .forwardCreate:
            param["type"] = "up_add"
        case .rename:
            param["type"] = "rename"
        case .reorder: break
        }
        clickList(container: container, param: param)
    }

    static func clickListEditSectionDelete(with container: Rust.TaskContainer?) {
        var param: [String: Any] = [
            "click": "edit_section",
            "target": "none"
        ]
        param["type"] = "delete"
        clickList(container: container, param: param)
    }

    static func clickListListAddTask(with container: Rust.TaskContainer?) {
        var param: [String: Any] = [
            "click": "list_add_task",
            "target": "todo_create_view"
        ]
        param["is_add_multi_task"] = "false"
        clickList(container: container, param: param)
    }

    static func clickListClickTask(with container: Rust.TaskContainer?, guid: String) {
        var param: [String: Any] = [
            "click": "click_task",
            "target": "todo_task_detail_view"
        ]
        param["task_id"] = guid
        clickList(container: container, param: param)
    }

    static func clickCheckBox(with container: Rust.TaskContainer?, guid: String, fromState: CompleteState) {
        clickList(container: container, param: TrackerUtil.getClickCheckBoxParam(with: guid, fromState: fromState, role: .todo))
    }

    static func clickListSlideToComplete(with container: Rust.TaskContainer?, guid: String, isDone2Undone: Bool) {
        var param: [String: Any] = [
            "click": "slide_to_complete",
            "target": "none"
        ]
        param["task_id"] = guid
        param["status"] = isDone2Undone ? "done_to_undone" : "undone_to_done"
        clickList(container: container, param: param)
    }

    static func clickListSlideToEditDue(with container: Rust.TaskContainer?, guid: String) {
        var param: [String: Any] = [
            "click": "slide_to_edit_due",
            "target": "none"
        ]
        param["task_id"] = guid
        clickList(container: container, param: param)
    }

    static func clickListShare(with container: Rust.TaskContainer?, guid: String) {
        var param: [String: Any] = [
            "click": "share_task",
            "target": "public_share_view"
        ]
        param["task_id"] = guid
        clickList(container: container, param: param)
    }

    // share_list：分享清单
    static func shareTasklistInView(with container: Rust.TaskContainer?) {
        let param: [String: Any] = [
            "click": "share_list",
            "target": "todo_task_list_share_view",
            "location": "view"
        ]
        clickList(container: container, param: param)
    }

    static func clickListLeaveTask(with container: Rust.TaskContainer?, guid: String) {
        var param: [String: Any] = [
            "click": "leave_task",
            "target": "none"
        ]
        param["task_id"] = guid
        clickList(container: container, param: param)
    }

    static func clickShareListInMore(with container: Rust.TaskContainer) {
        let param: [String: Any] = [
            "click": "share_list",
            "target": "todo_task_list_share_view",
            "location": "more"
        ]
        clickList(container: container, param: param)
    }

    static func clickDeleteListInMore(with container: Rust.TaskContainer, _ isDeleteNoOwner: Bool) {
        let param: [String: Any] = [
            "click": "delete_list",
            "target": "none",
            "location": "more",
            "is_delete_task": isDeleteNoOwner.description
        ]
        clickList(container: container, param: param)
    }

    static func clickRenameListInMore(with container: Rust.TaskContainer) {
        let param: [String: Any] = [
            "click": "rename_list",
            "target": "none",
            "location": "more"
        ]
        clickList(container: container, param: param)
    }

    static func clickArchiveListInMore(with container: Rust.TaskContainer) {
        let param: [String: Any] = [
            "click": "archive",
            "target": "none",
            "location": "more",
            "type": container.isArchived ? "cancel" : "done"
        ]
        clickList(container: container, param: param)
    }

    static func clickArchiveListInView(with container: Rust.TaskContainer) {
        let param: [String: Any] = [
            "click": "archive",
            "target": "none",
            "location": "view",
            "type": container.isArchived ? "cancel" : "done"
        ]
        clickList(container: container, param: param)
    }

    private static func clickList(container: Rust.TaskContainer?, param: [AnyHashable: Any]) {
        var p = param
        if let container = container {
            p["container_key"] = container.key
            p["container_category"] = "\(container.category.rawValue)"
            p["container_id"] = container.guid
            if container.isTaskList {
                p["is_archive"] = container.isArchived.description
            }
        }
        trackEvent(.listClick, with: p)
    }
}

extension V3Home.Track {
    /// 任务清单分享页面的曝光
    static func viewShareListPanel(with container: Rust.TaskContainer?) {
        let param: [String: Any] = [
            "list_id": container?.guid
        ]
        trackEvent(.taskListSharePanel, with: param)
    }

    /// 以下为任务清单分享页面的点击
    static func clickListInvite(with container: Rust.TaskContainer?) {
        let param: [String: Any] = [
            "click": "invite",
            "target": "none"
        ]
        clickShareList(container: container, param: param)
    }

    static func clickListManage(with container: Rust.TaskContainer?) {
        let param: [String: Any] = [
            "click": "manage",
            "target": "none"
        ]
        clickShareList(container: container, param: param)
    }

    static func clickListSendToChat(with container: Rust.TaskContainer?) {
        let param: [String: Any] = [
            "click": "send_to_chat",
            "target": "none"
        ]
        clickShareList(container: container, param: param)
    }

    static func clickListCopyLink(with container: Rust.TaskContainer?) {
        let param: [String: Any] = [
            "click": "copy_link",
            "target": "none"
        ]
        clickShareList(container: container, param: param)
    }

    private static func clickShareList(container: Rust.TaskContainer?, param: [String: Any]) {
        var p = param
        if let container = container {
            p["list_id"] = container.guid
        }
        trackEvent(.taskListShareClick, with: p)
    }
}
