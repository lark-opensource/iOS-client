//
//  Detail+Tracker.swift
//  Todo
//
//  Created by wangwanxin on 2021/5/19.
//

import Foundation

extension Detail {
    enum Track {}
}

extension Detail.Track: TrackerConvertible {

    /// Home埋点 event
    enum TrackerEvent: String, TrackerEventKeyConvertible {
        /// 「详细创建任务」页面展示
        case viewCreate = "todo_create_view"
        /// 在「创建任务页面」，发生动作事件
        case createClick = "todo_create_click"
        /// 「消息菜单栏创建任务-确认是否发送到原会话」页面展示
        case viewMsgCreateConfirm = "todo_msg_create_confirm_view"
        /// 在「消息菜单栏创建任务-确认是否发送到原会话」页面发生动作事件
        case clickMsgCreateConfirm = "todo_msg_create_confirm_click"
        /// 任务详情页面
        case viewDetail = "todo_task_detail_view"
        /// 在「任务详情页面」，发生动作事件
        case detailClick = "todo_task_detail_click"
        /// 「查看任务历史记录」页面展示时上报
        case viewHistory = "todo_task_history_view"
        ///  任务日期选择页面
        case viewDateSelect = "todo_date_select_view"
        /// 在「任务日期选择页面」上发生动作事件
        case clickDateSelect = "todo_date_select_click"
        /// 任务协作者列表页面的动作点击
        case collaborator = "todo_collaborator_detail_click"

        var eventKey: String { rawValue }
    }
}

extension Detail.Track {

    static func viewCreate() {
        trackEvent(.viewCreate)
    }

    /// create：点击「创建」
    static func clickSave(
        with todo: Rust.Todo,
        isNotInDetailSection: Bool,
        isSendToChat: Bool,
        source: TodoCreateSource
    ) {
        var params = TrackerUtil.getClickSaveParam(
            with: todo,
            isQuickCreate: false,
            isNotInDetailSection: isNotInDetailSection,
            isSendToChat: isSendToChat
        )
        TrackerUtil.fillChatCommenParams(&params, with: source)
        trackEvent(.createClick, with: params)
    }

}

extension Detail.Track {

    /// 「查看任务历史记录」页面展示时上报
    /// - Parameters:
    ///   - guid: todo id
    ///   - chatId: 参数无取值时，统一上报字符串”none"
    static func viewHistory(with guid: String, chatId: String?) {
        let params = [
            "task_id": guid,
            "chat_id": chatId ?? "none"
        ]
        trackEvent(.viewHistory, with: params)
    }

    /// 查看日期选择
    static func viewDateSelect(with guid: String?) {
        let params = [
            "task_id": guid ?? ""
        ]
        trackEvent(.viewDateSelect, with: params)
    }

    /// 点击日期保存
    static func clickSaveDate(with guid: String?, tuple: DueRemindTuple) {
        let params = [
            "task_id": guid ?? "",
            "click": "save",
            "target": "none",
            "is_set_start_date": ((tuple.startTime ?? 0) > 0 && tuple.isAllDay).description,
            "is_set_start_time": ((tuple.startTime ?? 0) > 0 && !tuple.isAllDay).description,
            "is_set_due_date": ((tuple.dueTime ?? 0) > 0 && tuple.isAllDay).description,
            "is_set_due_time": ((tuple.dueTime ?? 0) > 0 && !tuple.isAllDay).description,
            "is_set_remind_time": (tuple.reminder?.hasReminder ?? false).description,
            "is_set_repeat_task": (!(tuple.rrule?.isEmpty ?? true)).description
        ]
        trackEvent(.clickDateSelect, with: params)
    }

}

extension Detail.Track {

    /// 任务详情页面，包括会话、任务中心（或后续新增场景）场景下的任务详情页面展示
    static func viewDetail(with guid: String) {
        trackEvent(.viewDetail, with: ["task_id": guid])
    }

    /// 点击Check Box
    static func clickCheckBox(with todo: Rust.Todo, fromState: CompleteState, role: CompleteRole) {
        let params = TrackerUtil.getClickCheckBoxParam(with: todo.guid, fromState: fromState, role: role)
        trackEvent(.detailClick, with: params)
    }

    // copy 任务ID
    static func clickCopyId(with guid: String) {
        let params = [
            "task_id": guid,
            "click": "copy_id"
        ]
        trackEvent(.detailClick, with: params)
    }

    static func clickMileStone(with guid: String, isMark: Bool) {
        let params = [
            "task_id": guid,
            "click": isMark ? "mark_milestone" : "unmark_milestone",
            "target": "none"
        ]
        trackEvent(.detailClick, with: params)
    }

    static func clickNaviMoreDep(with guid: String, type: Rust.TaskDependent.TypeEnum, isAddFinal: Bool) {
        let params = [
            "task_id": guid,
            "click": type == .prev ? "add_pre_requisite_task" : "add_subsequent_task",
            "location": "more",
            "target": "none",
            "click_type": isAddFinal ? "final_add" : "click_button"
        ]
        trackEvent(.detailClick, with: params)
    }

    static func clickListAddDep(with guid: String, type: Rust.TaskDependent.TypeEnum, isAddFinal: Bool) {
        let params = [
            "task_id": guid,
            "click": type == .prev ? "add_pre_requisite_task" : "add_subsequent_task",
            "location": type == .prev ? "pre_requisite_task_list" : "subsequent_task_list",
            "target": "none",
            "click_type": isAddFinal ? "final_add" : "click_button"
        ]
        trackEvent(.detailClick, with: params)
    }

    static func clickViewListDep(with guid: String, type: Rust.TaskDependent.TypeEnum) {
        let params = [
            "task_id": guid,
            "click": type == .prev ? "check_pre_requisite_task" : "check_subsequent_task",
            "target": "none"
        ]
        trackEvent(.detailClick, with: params)
    }

    static func clickRemoveDep(with guid: String, type: Rust.TaskDependent.TypeEnum) {
        let params = [
            "task_id": guid,
            "click": type == .prev ? "cancel_pre_requisite_task" : "cancel_subsequent_task",
            "target": "none"
        ]
        trackEvent(.detailClick, with: params)
    }

    //  check_parent_task：点击跳转到父任务
    static func clickAncestor(with guid: String) {
        let params = [
            "task_id": guid,
            "click": "check_parent_task",
            "target": "todo_task_detail_view"
        ]
        trackEvent(.detailClick, with: params)
    }

    // check_subtask：点击跳转子任务详情
    static func clickSubTask(with guid: String) {
        let params = [
            "task_id": guid,
            "click": "check_subtask",
            "target": "todo_task_detail_view"
        ]
        trackEvent(.detailClick, with: params)
    }

    // follow：关注任务
    static func clickSubscribe(with guid: String) {
        let params = [
            "task_id": guid,
            "click": "follow",
            "target": "none"
        ]
        trackEvent(.detailClick, with: params)
    }

    // add_follower：成功添加关注者
    static func clickAddFollower(with guid: String) {
        let params = [
            "task_id": guid,
            "click": "add_follower",
            "target": "none"
        ]
        trackEvent(.detailClick, with: params)
    }

    // delete_follower：成功删除关注者
    static func clickDeleteFollower(with guid: String) {
        let params = [
            "task_id": guid,
            "click": "delete_follower",
            "target": "none"
        ]
        trackEvent(.detailClick, with: params)
    }

    // add_collaborator：成功添加协作者
    static func clickAddCollaborator(with guid: String) {
        let params = [
            "task_id": guid,
            "click": "add_collaborator",
            "target": "none"
        ]
        trackEvent(.detailClick, with: params)
    }

    // delete_collaborator：成功删除协作者
    static func clickDeleteCollaborator(with guid: String) {
        let params = [
            "task_id": guid,
            "click": "delete_collaborator",
            "target": "none"
        ]
        trackEvent(.detailClick, with: params)
    }

    /// leave_task：离开任务（包括删除任务&不再参与任务)
    static func clickLeave(with guid: String) {
        trackEvent(.detailClick, with: TrackerUtil.getLeaveTaskParam(with: guid))
    }

    /// share_task：点击「分享」
    static func clickShare(with guid: String) {
        trackEvent(.detailClick, with: TrackerUtil.getShareParam(with: guid))
    }

    /// more：点击“…”
    static func clickMore(with guid: String) {
        let params = [
            "task_id": guid,
            "click": "more",
            "target": "todo_task_more_option_view"
        ]
        trackEvent(.detailClick, with: params)
    }

    /// click：comment：
    static func clickComment(with guid: String) {
        let params = [
            "task_id": guid,
            "click": "comment",
            "target": "todo_task_detail_comment_view"
        ]
        trackEvent(.detailClick, with: params)
    }

    /// view_history：查看历史记录
    static func clickViewHistory(with guid: String) {
        let params = [
            "task_id": guid,
            "click": "view_history",
            "target": "todo_task_history_view"
        ]
        trackEvent(.detailClick, with: params)
    }

    static func clickSourceFromChat(with guid: String) {
        let params = [
            "task_id": guid,
            "click": "source_link_from_chat",
            "target": "im_chat_main_view"
        ]
        trackEvent(.detailClick, with: params)
    }

    static func clickSourceFromDoc(with guid: String) {
        let params = [
            "task_id": guid,
            "click": "source_link_from_docs",
            "target": "ccm_docs_page_view"
        ]
        trackEvent(.detailClick, with: params)
    }

    static func clickCompleteAssignee(with guid: String, isCompleted: Bool) {
        let params = [
            "task_id": guid,
            "click": "done_other_task",
            "target": "none",
            "status": isCompleted ? "undone_to_done" : "done_to_undone"
        ]
        trackEvent(.detailClick, with: params)
    }

    static func clickRemoveAssignee(with guid: String) {
        let params = [
            "task_id": guid,
            "click": "delete_executor",
            "target": "none"
        ]
        trackEvent(.detailClick, with: params)
    }

    // add_list：成功添加进清单
    static func clickAddTaskList(with guid: String?) {
        let params = [
            "task_id": guid ?? "",
            "click": "add_list",
            "target": "none"
        ]
        trackEvent(.detailClick, with: params)
    }

    // create_new_list：成功创建清单
    static func clickCreateTaskList(with guid: String, _ taskListGuid: String, _ isCreateScene: Bool) {
        let params = [
            "task_id": guid,
            "list_id": taskListGuid,
            "click": "create_new_list",
            "target": "none"
        ]
        trackEvent(isCreateScene ? .createClick : .detailClick, with: params)
    }

    // create_new_task_section：成功创建新的自定义分组
    static func clickCrateNewSection(with guid: String?) {
        let params = [
            "task_id": guid ?? "",
            "click": "create_new_task_section",
            "target": "none"
        ]
        trackEvent(.createClick, with: params)
    }

    // create_new_list_section：成功创建新的清单分组
    static func clickCreateListSection(with guid: String?) {
        let params = [
            "task_id": guid ?? "",
            "click": "create_new_list_section",
            "target": "none"
        ]
        trackEvent(.createClick, with: params)
    }

    // edit_section：成功修改分组
    static func clickEditSection(with guid: String?, isNew: Bool) {
        let params = [
            "task_id": guid ?? "",
            "click": "edit_section",
            "is_new_section": isNew.description,
            "target": "none"
        ]
        trackEvent(.detailClick, with: params)
    }

    // edit_task_section：我负责的自定义分组
    static func clickOwnedSection(with guid: String?, isNew: Bool) {
        let params = [
            "task_id": guid ?? "",
            "click": "edit_task_section",
            "is_new_section": isNew.description,
            "target": "none"
        ]
        trackEvent(.detailClick, with: params)
    }

    // check_list_detail: 点击查看任务清单详情
    static func clickTaskListDetail(with guid: String?) {
        let params = [
            "task_id": guid ?? "",
            "click": "check_list_detail",
            "target": "todo_task_list_detail_view"
        ]
        trackEvent(.detailClick, with: params)
    }

    // delete_list：成功删除清单关联
    static func clickDeleteTaskList(with guid: String?) {
        let params = [
            "task_id": guid ?? "",
            "click": "delete_list",
            "target": "none"
        ]
        trackEvent(.detailClick, with: params)
    }

    // expand_list_field & collapse_list_field： 展开收起自定义字段
    static func toggleCustomFieldsList(guid: String?, isCollapsed: Bool) {
        let params = [
            "task_id": guid ?? "",
            "click": isCollapsed ? "collapse_list_field" : "expand_list_field",
            "target": "none"
        ]
        trackEvent(.detailClick, with: params)
    }

    // edit_list_field：编辑清单字段内容（编辑成功时上报）
    static func editCustomField(with guid: String?) {
        let params = [
            "task_id": guid ?? "",
            "click": "edit_list_field",
            "target": "none"
        ]
        trackEvent(.detailClick, with: params)
    }

}

extension Detail.Track {

    // batch_assign：一键派发
    static func clickBatchAssign(with guid: String) {
        let params = [
            "task_id": guid,
            "click": "batch_assign",
            "target": "todo_batch_create_subtask_view"
        ]
        trackEvent(.collaborator, with: params)
    }

}
