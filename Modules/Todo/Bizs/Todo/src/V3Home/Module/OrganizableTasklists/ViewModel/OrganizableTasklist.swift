//
//  OrganizableTasklist.swift
//  Todo
//
//  Created by wangwanxin on 2023/11/2.
//

import Foundation

/// 域
struct OrganizableTasklist { }

extension OrganizableTasklist {
    enum Track {}
}

extension OrganizableTasklist.Track: TrackerConvertible {

    /// 埋点 event
    enum TrackerEvent: String, TrackerEventKeyConvertible {
        case view = "todo_task_list_front_page_view"
        case click = "todo_task_list_front_page_click"

        var eventKey: String { rawValue }
    }
    
}

/// Organizable Task List
extension OrganizableTasklist.Track {

    static func view() {
        trackEvent(.view)
    }

    static func clickTab(tab: Rust.TaskListTabFilter, isArchived: Bool) {
        let param: [String: Any] = [
            "target": "none",
            "click": "tab",
            "tab_type": tab.tracker,
            "is_archived": isArchived.description
        ]
        trackEvent(.click, with: param)
    }

    static func clickArchived(tab: Rust.TaskListTabFilter) {
        let param: [String: Any] = [
            "target": "none",
            "click": "archived",
            "tab_type": tab.tracker,
        ]
        trackEvent(.click, with: param)
    }

    static func clickItem(guid: String, tab: Rust.TaskListTabFilter, isArchived: Bool) {
        let param: [String: Any] = [
            "click": "check_list_detail",
            "target": "todo_task_list_detail_view",
            "list_id": guid,
            "tab_type": tab.tracker,
            "is_archived": isArchived.description
        ]
        trackEvent(.click, with: param)
    }

    static func clickCreateButton() {
        let param: [String: Any] = [
            "target": "none",
            "click": "create_list",
            "click_type": "click_create_button"
        ]
        trackEvent(.click, with: param)
    }

    static func clickFinalCreate(guid: String) {
        let param: [String: Any] = [
            "target": "none",
            "click": "create_list",
            "click_type": "final_create",
            "list_id": guid
        ]
        trackEvent(.click, with: param)
    }
}
