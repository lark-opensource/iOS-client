//
//  ChatterPicker.swift
//  Todo
//
//  Created by wangwanxin on 2022/8/10.
//

import Foundation

struct OwnerPicker {}

extension OwnerPicker {
    enum Track {}
}

extension OwnerPicker.Track: TrackerConvertible {

    /// Home埋点 event
    enum TrackerEvent: String, TrackerEventKeyConvertible {
        /// "（进入选人页面即上报，不限制单多选）"
        case viewOwnerPicker = "todo_task_owner_select_view"
        /// 在「负责人选人」页，发生动作时上报
        case ownerPickerClick = "todo_task_owner_select_click"

        var eventKey: String { rawValue }
    }
}

extension OwnerPicker.Track {

    // "在「负责人选人」页，展示时上报
    // "create_task：创建任务时多选负责人; edit_task：编辑任务时多选负责人
    static func view(with guid: String, isSubTask: Bool, isEdit: Bool) {
        var param = [
            "task_id": guid.isEmpty ? "" : guid
        ]
        if isSubTask {
            param["location"] = isEdit ? "edit_subtask" : "create_subtask"
        } else {
            param["location"] = isEdit ? "edit_task" : "create_task"
        }
        trackEvent(.viewOwnerPicker, with: param)
    }

    static func confirmClick(with guid: String, isEdit: Bool, isSubTask: Bool) {
        pickerClick(with: "copy", guid: guid, isEdit: isEdit, isSubTask: isSubTask)
    }

    static func multiSelectClick(with guid: String, isEdit: Bool, isSubTask: Bool) {
        pickerClick(with: "multi_select", guid: guid, isEdit: isEdit, isSubTask: isSubTask)
    }

   /// final_add：确认添加（pc端上报时机为选人页面关闭时，移动端为点击选人页面确认按钮）
    static func finalAddClick(with guid: String, isEdit: Bool, isSubTask: Bool) {
        pickerClick(with: "final_add", guid: guid, isEdit: isEdit, isSubTask: isSubTask)
    }

    static func changeDoneClick(with guid: String, isEdit: Bool, isSubTask: Bool) {
        pickerClick(with: "change_done_type", guid: guid, isEdit: isEdit, isSubTask: isSubTask)
    }

    private static func pickerClick(with action: String, guid: String, isEdit: Bool, isSubTask: Bool) {
        let location: String
        if isSubTask {
            location = isEdit ? "edit_subtask" : "create_subtask"
        } else {
            location = isEdit ? "edit_task" : "create_task"
        }
        let param = [
            "task_id": guid.isEmpty ? "" : guid,
            "click": action,
            "location": location
        ]
        trackEvent(.ownerPickerClick, with: param)
    }

}
