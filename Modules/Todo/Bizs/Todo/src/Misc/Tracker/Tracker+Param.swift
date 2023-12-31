//
//  Tracker+Param.swift
//  Todo
//
//  Created by wangwanxin on 2021/5/19.
//

import Foundation

// MARK: - List Param

extension TrackerUtil {

    static func getClickCellParam(with guid: String) -> [AnyHashable: Any] {
        return [
            "task_id": guid,
            "click": "click_task",
            "target": "todo_task_detail_view"
        ]
    }

    static func getAddTodoParam() -> [AnyHashable: Any] {
        return [
            "click": "add_task",
            "target": "todo_quick_create_view"
        ]
    }

}

// MARK: - Todo Param

extension TrackerUtil {

    static func getClickCheckBoxParam(with guid: String, fromState: CompleteState, role: CompleteRole) -> [AnyHashable: Any] {
        let click: String
        let doneToUnDone: Bool
        switch fromState {
        case .outsider:
            return [:]
        case let .assignee(isCompleted):
            click = "done_my_task"
            doneToUnDone = isCompleted
        case let .creator(isCompleted):
            click = "done_all_task"
            doneToUnDone = isCompleted
        case let .creatorAndAssignee(isTodoCompleted, isSelfCompleted):
            switch role {
            case .`self`:
                click = "done_my_task"
                doneToUnDone = isSelfCompleted
            case .todo:
                click = "done_all_task"
                doneToUnDone = isTodoCompleted
            }
        case let .classicMode(isCompleted, _):
            click = "done_all_task"
            doneToUnDone = isCompleted
        }
        return [
            "task_id": guid,
            "click": click,
            "target": "none",
            "status": doneToUnDone ? "done_to_undone" : "undone_to_done"
        ]
    }

    static func getLeaveTaskParam(with guid: String) -> [AnyHashable: Any] {
        return [
            "task_id": guid,
            "click": "leave_task",
            "target": "none"
        ]
    }

    static func getShareParam(with guid: String) -> [AnyHashable: Any] {
        return [
            "task_id": guid,
            "click": "share",
            "target": "public_share_view"
        ]
    }
}

// MARK: - Create Par

extension TrackerUtil {

    static func getClickSaveParam(
        with todo: Rust.Todo,
        isQuickCreate: Bool,
        isNotInDetailSection: Bool,
        isSendToChat: Bool
    ) -> [AnyHashable: Any] {
        var param = [
            "task_id": todo.guid,
            "click": "create",
            "target": "none"
        ]
        let summary = todo.richSummary.richText
        param["is_title_at_someone"] = (!summary.atIds.isEmpty).description
        param["is_set_repeat_task"] = (todo.isRRuleValid).description
        param["mention_user_cnt"] = "\(summary.atIds.count)"
        let atIds = summary.elements.map { (_, value) in
            return value.property.at.userID
        }
        let count = atIds.filter({ id in
            return todo.assignees.contains(where: { $0.assigneeID == id })
        }).count
        param["mention_collaborator_cnt"] = "\(count)"
        param["is_in_not_default_section"] = isNotInDetailSection.description
        param["add_list_cnt"] = "\(todo.relatedTaskListGuids.count)"

        if !isQuickCreate {
            let notes = todo.richDescription.richText
            param["is_have_remark"] = (!notes.isEmpty).description
            param["is_remark_at_someone"] = (!notes.atIds.isEmpty).description
            param["is_remark_have_doc"] = notes.anchorIds.contains(where: { anchorId -> Bool in
                return notes.elements.contains(where: { (key: String, value: Rust.RichText.Element) in
                    return key == anchorId && value.tag == .a
                })
            }).description
            param["is_sent_to_chat"] = isSendToChat.description
            param["is_add_follower"] = (!todo.followers.isEmpty).description
            param["is_add_collaborator"] = (!todo.assignees.isEmpty).description
        }
        return param
    }

    static func fillChatCommenParams(_ params: inout [AnyHashable: Any], with source: TodoCreateSource) {
        switch source {
        case .chat(let chatContext):
            if let chatCommonParams = chatContext.chatCommonParams {
                chatCommonParams.forEach { (key, value) in params[key] = value }
            }
        default:
            break
        }
    }

    // MARK: for 旧埋点

    static func fillCreatingTodoParams(_ params: inout [AnyHashable: Any], with source: TodoCreateSource) {
        switch source {
        case .chat(let chatContext):
            switch chatContext.fromContent {
            case .chatKeyboard:
                params["source"] = "message_toolbar"
                params["chat_id"] = chatContext.chatId
            case .chatSetting:
                params["source"] = "chat_todo_list"
                params["chat_id"] = chatContext.chatId
            case .textMessage, .postMessage, .needsMergeMessage, .unknownMessage:
                params["source"] = "message_add"
                params["chat_id"] = chatContext.chatId
                params["message_id"] = chatContext.chatId
                params["sub_source"] = "single_message"
            case .mergeForwardMessage:
                params["source"] = "message_add"
                params["message_id"] = chatContext.chatId
                params["sub_source"] = "message_after_forwarding"
            case .multiSelectMessages(let messageIds, _):
                params["source"] = "message_add"
                params["message_id"] = chatContext.chatId
                params["sub_source"] = "multiple_messages"
            case .threadMessage:
                break
            }
            // 「单条消息」「多选消息」「帖子」都有可能携带 extra
            let dict = chatContext.extra
            if let source = dict?["source"] as? String {
                params["source"] = source
            }
            if let subSource = dict?["sub_source"] as? String {
                params["sub_source"] = subSource
            }
        case .list:
            params["source"] = "my_task_all"
        // 旧埋点，不用了
        case .subTask, .inline:
            break
        }
    }

    static func fillCreatingTodoParams(_ params: inout [AnyHashable: Any], with todo: Rust.Todo) {
        params["task_id"] = todo.guid
        let notes = todo.richDescription
        params["if_note_included"] = !notes.richText.isEmpty
        params["if_note_include_text"] = notes.richText.elements.values.contains(where: { ele -> Bool in
            return ele.tag == .text && !ele.property.text.content.isEmpty
        })
        params["if_note_include_doc"] = notes.richText.anchorIds.contains(where: { anchorId -> Bool in
            return notes.richText.elements.contains(where: { (key: String, value: Rust.RichText.Element) in
                return key == anchorId && value.tag == .a
            })
        })
        params["if_note_include_at"] = !notes.richText.atIds.isEmpty
    }

}
