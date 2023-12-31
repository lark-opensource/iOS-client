//
//  HomeSidebar.swift
//  Todo
//
//  Created by wangwanxin on 2023/11/2.
//

import Foundation

/// 域
struct HomeSidebar { }

extension HomeSidebar {
    enum Track {}
}

extension HomeSidebar.Track: TrackerConvertible {

    /// 埋点 event
    enum TrackerEvent: String, TrackerEventKeyConvertible {
        case view = "todo_mobile_container_menu_view"
        case click = "todo_mobile_container_menu_click"

        var eventKey: String { rawValue }
    }

}

extension HomeSidebar.Track {

    static func view() {
        trackEvent(.view)
    }

    static func clickItem(with container: Rust.TaskContainer) {
        let param: [String: Any] = [
            "click": "container",
            "target": "todo_center_task_list_view"
        ]
        click(container: container, param: param)
    }

    static func clickWholeActivity() {
        let param: [String: Any] = [
            "click": "check_whole_progress",
            "target": "none"
        ]
        click(container: nil, param: param)
    }

    static func clickOrganizableTasklist() {
        let param: [String: Any] = [
            "click": "check_lists",
            "target": "todo_task_list_front_page_view"
        ]
        click(container: nil, param: param)
    }

    static func willCreateTasklist(with container: Rust.TaskContainer?, and isInDefaultSection: Bool) {
        let param: [String: Any] = [
            "click": "create_list",
            "target": "none",
            "click_type": "click_create_button",
            "location": isInDefaultSection ? "integrated_plus_button" : "list_section_plus_button"
        ]
        click(container: container, param: param)
    }

    static func finalCreateTasklist(with container: Rust.TaskContainer, and isInDefaultSection: Bool) {
        let param: [String: Any] = [
            "click": "create_list",
            "target": "none",
            "click_type": "final_create",
            "list_id": container.guid,
            "location": isInDefaultSection ? "integrated_plus_button" : "list_section_plus_button"
        ]
        click(container: container, param: param)
    }


    static func renameTaskList(with container: Rust.TaskContainer) {
        let param: [String: Any] = [
            "click": "rename_list",
            "target": "none"
        ]
        click(container: container, param: param)
    }

    static func shareTasklist(with container: Rust.TaskContainer) {
        let param: [String: Any] = [
            "click": "share_list",
            "target": "todo_task_list_share_view"
        ]
        click(container: container, param: param)
    }

    static func deleteTasklist(with container: Rust.TaskContainer, _ isDeleteNoOwner: Bool) {
        let param: [String: Any] = [
            "click": "delete_list",
            "is_delete_task": isDeleteNoOwner.description,
            "target": "none"
        ]
        click(container: container, param: param)
    }

    static func archiveTasklist(with container: Rust.TaskContainer) {
        let param: [String: Any] = [
            "click": "archive",
            "type": container.isArchived ? "cancel" : "done",
            "target": "none"
        ]
        click(container: container, param: param)
    }

    static func removeFromSection(with container: Rust.TaskContainer) {
        let param: [String: Any] = [
            "click": "remove_list_from_this_location",
            "list_id": container.guid,
            "target": "none"
        ]
        click(container: container, param: param)
    }

    static func renameSection() {
        let param: [String: Any] = [
            "click": "rename_list_section",
            "target": "none"
        ]
        click(container: nil, param: param)
    }

    static func deleteSection() {
        let param: [String: Any] = [
            "click": "delete_list_section",
            "target": "none"
        ]
        click(container: nil, param: param)
    }

    static func createSection(_ isBottomAdd: Bool) {
        let param: [String: Any] = [
            "click": "create_list_section",
            "location": isBottomAdd ? "bottom_button" : "integrated_plus_button"
        ]
        click(container: nil, param: param)
    }

    // 随着todo.organizable_task_list全量下线
    static func toggleArchivedList(currentIsExpanded: Bool) {
        let param: [String: Any] = [
            "click": "show_archived_list",
            "type": currentIsExpanded ? "collapse" : "show",
            "target": "none"
        ]
        trackEvent(.click, with: param)
    }

    private static func click(container: Rust.TaskContainer?, param: [String: Any]) {
        var p = param
        if let container = container {
            p["container_key"] = container.key
            p["container_category"] = "\(container.category.rawValue)"
            p["container_id"] = container.guid
        }
        trackEvent(.click, with: p)
    }


}
