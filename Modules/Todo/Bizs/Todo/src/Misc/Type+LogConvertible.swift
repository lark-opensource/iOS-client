//
//  Type+LogConvertible.swift
//  Todo
//
//  Created by 张威 on 2021/6/4.
//

import Foundation
import LarkModel

// MARK: - Setting

extension SettingState: LogConvertible {

    var logInfo: String {
        return """
        lb: \(listBadgeConfig.enable),\(listBadgeConfig.type)
        dy: \(enableDailyRemind)
        ro: \(dueReminderOffset)
        ls: \(listViewSettings.map { "\($0.key):[\($0.value.logInfo)]" })
        lsc: \(listLaunchScreen.map { "\($0.logInfo)" })
        """
    }

}

// MARK: - Launch Screen

extension Rust.ListLaunchScreen: LogConvertible {

    var logInfo: String {
        return "\(type)-\(status)"
    }

}

// MARK: - ViewType
extension Rust.ListViewType: LogConvertible {

    var logInfo: String {
        return "list view is \(rawValue)"
    }

}

// MARK: - Source Filter
extension Rust.TodoSource: LogConvertible {

    var logInfo: String {
        return "source filter is \(rawValue)"
    }

}

// MARK: - V3 List View Data

extension V3ListViewData {
    var logInfo: String {
        let ret = """
            {
            "duration": "\(duration)",
            "sectionCnt": \(data.count),
            "itemCnt": "\(data.map({ $0.items.count }))",
            "footer": "\(data.map(\.footer.isHidden))",
            "hasSkeleton": "\(data.last?.isSkeleton ?? false)"
            }
            """
            .replacingOccurrences(of: "\n", with: "")
            assert(debug_check_json_valid(ret), "bad json str: \(ret)")
        return ret
    }
}

// MARK: - Member

extension Member: LogConvertible {
    var logInfo: String {
        switch self {
        case .group(let chatId):
            return "{\"gid\": \"\(chatId)\"}"
        case .user(let user):
            return "{\"uid\": \"\(user.chatterId)\"}"
        case .unknown(let id):
            return "{\"id\": \"\(id)\"}"
        }
    }
}

// MARK: - RichText

extension Rust.RichText.Element: LogConvertible {
    // 富文本 log 信息。不记录涉密信息，譬如文本内容，但会记录文本长度
    var logInfo: String {
        switch tag {
        case .text:
            return "{\"text\":{\"content\":\"\(property.text.content.count)\"}}"
        case .at:
            return "{\"at\":{\"content\":\"\(property.at.content.count)\"}}"
        case .mention:
            return "{\"mention\":{\"content\":\"\(property.mention.content.count)\"}}"
        case .emotion:
            return "{\"emotion\":{\"key\":\"\(property.emotion.key)\"}}"
        case .p:
            return "{\"p\":{\"childIds\":[\(childIds.map({ "\"\($0)\"" }).joined(separator: ","))]}}"
        case .a:
            let content = String(property.anchor.textContent.count)
            let href = String(property.anchor.href.count)
            return "{\"a\": {\"content\": \"\(content)\", \"href\": \"\(href)\"}}"
        case .img:
            return "{\"img\":{\"originKey\":\"\(property.image.originKey)\"}}"
        case .figure:
            return "{\"figure\":{\"childIds\":[\(childIds.map({ "\"\($0)\"" }).joined(separator: ","))]}}"
        @unknown default:
            return "{\"unknown\":{}}"
        }
    }
}

extension Rust.RichText: LogConvertible {
    var logInfo: String {
        var idStr = elementIds.map({ "\"\($0)\"" }).joined(separator: ",")
        let eleStr = elements.keys
            .map { id in "{\"id\":\"\(id)\",\"ele\":\(elements[id]?.logInfo ?? "unknown")}" }
            .joined(separator: ",")
        return "{\"elementIds\":[\(idStr)],\"elements\":[\(eleStr)]}"
    }
}

// MARK: - Todo

extension Rust.Todo: LogConvertible {
    var logInfo: String {
        let ret = """
        {
        "id": "\(guid)",
        "mode": "\(mode.rawValue)",
        "summary": \(richSummary.richText.logInfo),
        "notes": \(richDescription.richText.logInfo),
        "assignees": [\(assignees.map({ $0.asMember().logInfo }).joined(separator: ","))],
        "followers": [\(followers.map({ $0.asMember().logInfo }).joined(separator: ","))],
        "createTime": "\(createMilliTime)",
        "completedTime": "\(completedMilliTime)",
        "deletedTime": "\(deletedMilliTime)",
        "startTime": "\(startMilliTime)",
        "dueTime": "\(dueTime)-\(dueTimezone)-\(isAllDay)",
        "reminders": [\(reminders.map({ "\"\($0.time)-\($0.type)\"" }).joined(separator: ","))],
        "commentCount": "\(commentCount)",
        "attaCount": "\(attachments.count)"
        }
        """
        .replacingOccurrences(of: "\n", with: "")
        assert(debug_check_json_valid(ret), "bad json str: \(ret)")
        return ret
    }
}

extension Rust.CreateTodoRes: LogConvertible {
    var logInfo: String {
        return "todo: \(todo.logInfo), ref: \(taskContainerRef.logInfo), taskList: \(taskListContainerRefs.map(\.logInfo).joined(separator: ","))"
    }
}

extension Rust.SimpleTodo: LogConvertible {

    var logInfo: String {
        let ret = """
        {
        "guid": "\(guid)",
        "ancestor": "\(ancestorGuid)",
        "comTime": "\(completedMilliTime)",
        "delTime": "\(deletedMilliTime)"
        }
        """
        .replacingOccurrences(of: "\n", with: "")
        assert(debug_check_json_valid(ret), "bad json str: \(ret)")
        return ret
    }

}

extension Rust.ChatTodo: LogConvertible {
    var logInfo: String {
        let ret = """
        {
        "todo": \(todo.logInfo),
        "senderId": "\(sender.id)",
        "sendTime": "\(sendTime)",
        "position": "\(messagePosition)",
        "messageId": "\(messageID)"
        }
        """
        .replacingOccurrences(of: "\n", with: "")
        assert(debug_check_json_valid(ret), "bad json str: \(ret)")
        return ret
    }
}

extension Rust.TodoExtraInfo: LogConvertible {
    var logInfo: String {
        switch self.type {
        case .commentCount:
            return "type: commentCount, guid: \(commentCount.guid), count: \(commentCount.count)"
        case .ancestorChange:
            return "type: ancestor, ancestorGuids: \(ancestorChange.ancestors.map { $0.guid })"
        case .progress:
            return "type: progress, guid: \(progressChange.guid), val: \(progressChange.progress.completed) / \(progressChange.progress.total)"
        case .unknown:
            return "type: unknown"
//        case .relatedTaskListChange:
//            return "type: related task list, guid: \(relatedTaskListChange.taskGuid), relatedTaskGuids: \(relatedTaskListChange.relatedTaskListGuids)"
        case .subTaskRanks:
            return "type: subTaskRanks, guid: \(subTaskRanksChange.guid), ids: \(subTaskRanksChange.subTaskRanks.keys)"
        default: return ""
        }
    }
}

// MARK: - Comment

extension Rust.Attachment: LogConvertible {
    var logInfo: String {
        let ret = """
        {
        "guid": "\(guid)",
        "fileToken": "\(fileToken)",
        "fileSize": "\(fileSize)",
        "type": \(type.rawValue),
        "uploaderUser": "\(uploaderUserID)",
        "position": "\(position)",
        "image": "\(imageSet.key)",
        "canDelete": "\(canDelete)",
        "uploadMilliTime": "\(uploadMilliTime)"
        }
        """
        .replacingOccurrences(of: "\n", with: "")
        assert(debug_check_json_valid(ret), "bad json str: \(ret)")
        return ret
    }
}

extension Rust.Reaction: LogConvertible {
    var logInfo: String {
        let userStr = users.map { "\"\($0.userID)\"" }.joined(separator: ",")
        return "{ \"type\": \"\(type)\", \"users\": [\(userStr)] }"
    }
}

extension Rust.Comment: LogConvertible {
    var logInfo: String {
        let ret = """
        {
        "id": "\(id)",
        "cid": "\(cid)",
        "richText": \(richContent.richText.logInfo),
        "type": "\(type.rawValue)",
        "fromUser": "\(fromUser.userID)",
        "status": "\(status.rawValue)",
        "createTime": "\(createMilliTime)",
        "updateTime": "\(updateMilliTime)",
        "replyRoot": "\(replyRootID)",
        "replyParent": "\(replyParentID)",
        "position": "\(position)",
        "attachments": [\(attachments.map(\.logInfo).joined(separator: ","))],
        "reactions": [\(reactions.map(\.logInfo).joined(separator: ","))]
        }
        """
        .replacingOccurrences(of: "\n", with: "")
        assert(debug_check_json_valid(ret), "bad json str: \(ret)")
        return ret
    }
}

// MARK: - Setting

extension Rust.TodoSetting: LogConvertible {
    var logInfo: String {
        return "{\"dailyRemind\": \"\(enableDailyRemind)\", \"tabs\": \(tabViewSettings.map(\.logInfo))}"
    }
}

extension Rust.ListViewSetting: LogConvertible {
    var logInfo: String {
        return "{\"viewType\": \"\(view.rawValue)\", \"sortType\": \"\(sortType.rawValue)\"}"
    }
}

// MARK: - ChangeSet

extension Rust.TodoChangeset: LogConvertible {
    var logInfo: String {
        let ret = """
        {
        "addIds": [\(addedTodoIdents.map({ "\"\($0)\"" }).joined(separator: ","))],
        "deleteIds": [\(deletedTodoIdents.map({ "\"\($0)\"" }).joined(separator: ","))],
        "uptateIds": [\(updatedTodoIdents.map({ "\"\($0)\"" }).joined(separator: ","))],
        "todos": [\(todos.count)]
        }
        """
        .replacingOccurrences(of: "\n", with: "")
        assert(debug_check_json_valid(ret), "bad json str: \(ret)")
        return ret
    }
}
// MARK: - Anchor Render State

extension RichLabelAnchorRenderState: LogConvertible {
    var logInfo: String {
        switch self {
        case .needsUpdate: return "needsUpdate"
        case .completed: return "completed"
        case .needsFix: return "needsFix"
        }
    }

}

// MARK: - Auth Scene

extension Rust.DetailAuthScene: LogConvertible {

    var logInfo: String {
        switch type {
        case .message: return "message"
        case .`default`: return "default"
        default: return ""
        }
    }

}

// MARK: - TodoContent

extension TodoContent: LogConvertible {
    var logInfo: String {
        let pb = pbModel
        let todo = pb.todoDetail
        let comment = pb.todoCommentDetail
        let ret = """
        {
        "isFromBot": "\(isFromBot)",
        "chatId": "\(chatId)",
        "messageId": "\(messageId)",
        "senderId": "\(senderId)",
        "operatorId": "\(pb.operator.userID)",
        "operationType": "\(pb.operationType.rawValue)",
        "msgStatus": "\(pb.msgStatus.rawValue)",
        "dailyRemindGuids": "\(pb.dailyRemind.todos.reduce("") { $0 + $1.guid + "," })",
        "todoGuid": "\(todo.guid)",
        "assigneeIds": "\(todo.assignees.reduce("") { $0 + $1.assigneeID + "," })",
        "startTime": "\(todo.startMilliTime)"
        "dueTime": "\(todo.dueTime)",
        "isAllDay": "\(todo.isAllDay)",
        "richText": \(todo.richSummary.richText.logInfo),
        "followersIds": "\(todo.followers.reduce("") { $0 + $1.followerID + "," })",
        "creatorId": "\(todo.creator.userID)",
        "completedTime": "\(todo.completedMilliTime)",
        "deletedTime": "\(todo.deletedMilliTime)",
        "source": "\(todo.source.rawValue)",
        "commentID": "\(comment.commentID)",
        "richText": \(comment.richContent.richText.logInfo),
        "position": "\(comment.position)",
        "attachmentTypes": "\(comment.attachments.reduce("") { $0 + String($1.type.rawValue) + "," })",
        "reactions": \(comment.newlyAddedReaction.logInfo)
        }
        """
        .replacingOccurrences(of: "\n", with: "")
        assert(debug_check_json_valid(ret), "bad json str: \(ret)")
        return ret
    }
}

// MARK: - DueRemindTuple

extension DueRemindTuple: LogConvertible {
    var logInfo: String {
        return "dueTime: \(dueTime) isAllDay: \(isAllDay) reminder: \(reminder)"
    }
}

// MARK: - CompleteState

extension CompleteState: LogConvertible {
    var logInfo: String {
        switch self {
        case .outsider(let b):
            return "outsider(b)"
        case .assignee(let b):
            return "assignee_\(b)"
        case .creator(let b):
            return "creator_\(b)"
        case .creatorAndAssignee(let b1, let b2):
            return "creatorAndAssignee_\(b1)_\(b2)"
        case .classicMode(let b, let i):
            return "classicMode_\(b)_\(i)"
        }
    }
}

// MARK: - task center v3

extension Rust.ContainerTaskRef: LogConvertible {
    var logInfo: String {
        "cid:\(containerGuid)-tid:\(taskGuid)-sid:\(sectionGuid)-r:\(rank)-ut:\(version)-dt:\(deleteMilliTime)"
    }
}

extension Rust.ContainerTaskRefs: LogConvertible {
    var logInfo: String {
        taskContainerRefs.map { $0.logInfo }.joined(separator: ",")
    }
}

extension Rust.TaskContainer: LogConvertible {
    var logInfo: String {
        """
        "id:\(guid)
        -k:\(key)
        -p:\(currentUserPermission.permissions)
        -dt:\(deleteMilliTime)
        -at:\(archivedMilliTime)
        -cg:\(category.rawValue)
        -v:\(version)"
        """.replacingOccurrences(of: "\n", with: "")
    }
}

// MARK: - Task Section

extension Rust.TaskSection: LogConvertible {
    var logInfo: String {
        return "guid: \(guid), containerId: \(containerID), rank: \(rank)"
    }
}

// MARK: - Container Section

extension Rust.ContainerSection: LogConvertible {
    var logInfo: String {
        return "containerId: \(containerGuid), sectionId: \(sectionGuid), rank: \(rank)"
    }
}

extension InlineContainerSection: LogConvertible {
    var logInfo: String {
        switch self {
        case .container(let containerSection, let task):
            return "\(containerSection.logInfo) todo: \(task.logInfo)"
        case .taskList(let todo, let rank):
            return "\(todo.logInfo), rank: \(rank)"
        }
    }
}

// MARK: - Container Meta 

extension Rust.ContainerMetaData: LogConvertible {
    var logInfo: String {
        let ret = """
        {
        "containerId": "\(container.guid)",
        "sections": "\(sections.map(\.logInfo).joined(separator: ","))",
        "views": "\(views.map(\.guid).joined(separator: ","))"
        }
        """
        .replacingOccurrences(of: "\n", with: "")
        assert(debug_check_json_valid(ret), "bad json str: \(ret)")
        return ret
    }
}

extension Rust.TaskRefInfo: LogConvertible {
    var logInfo: String {
        return "task is \(task.logInfo), ref is \(ref.logInfo)"
    }
}

extension Rust.TaskListMembersRes: LogConvertible {
    var logInfo: String {
        return "members count \(taskListMembers.count), hasMore \(hasMore_p), cursor \(lastToken)"
    }
}

extension Rust.ThreadInfo: LogConvertible {
    var logInfo: String {
        "cid:\(chatID), tid:\(threadID) irit:\(isReplyInThread)"
    }
}

extension Rust.TaskFieldValue: LogConvertible {
    var logInfo: String {
        return "key: \(fieldKey), type: \(fieldType.rawValue), taskGuid: \(taskGuid)"
    }
}

extension Rust.ContainerTaskFieldAssoc: LogConvertible {
    var logInfo: String {
        return "key: \(taskField.key), type: \(taskField.type.rawValue), category: \(taskField.category.rawValue), containerGuid: \(containerGuid)"
    }
}

extension Rust.PagingTaskListRelatedRes: LogConvertible {

    var logInfo: String {
        return "containerGuids: \(containers.map(\.guid)), sectionGuids: \(taskContainerSections.keys), page: \(pageResult.logInfo)"
    }
}

extension Rust.PageReq: LogConvertible {
    var logInfo: String {
        return "token: \(pageToken), count: \(pageCount)"
    }
}

extension Rust.PageRes: LogConvertible {
    var logInfo: String {
        return "hasMore: \(hasMore_p), token: \(lastToken)"
    }
}

extension Rust.TaskListSection: LogConvertible {
    var logInfo: String {
        return """
            "id: \(guid)
            -rank: \(rank)
            -dt: \(deleteMilliTime)
            -v: \(version)"
            """
            .replacingOccurrences(of: "\n", with: "")
    }
}

extension Rust.TaskListSectionRef: LogConvertible {
    var logInfo: String {
        return """
            "cid: \(containerGuid)
            -sid: \(sectionGuid)
            -rank: \(rank)
            -v: \(version)"
            """
            .replacingOccurrences(of: "\n", with: "")
    }
}

extension Rust.TaskListSectionItem {
    var logInfo: String {
        return "container: \(container.logInfo), refs: \(refs.map(\.logInfo))"
    }
}

@inline(__always)
private func debug_check_json_valid(_ str: String) -> Bool {
    #if DEBUG
    guard let data = str.data(using: .utf8) else { return false }
    do {
        _ = try JSONSerialization.jsonObject(with: data, options: [])
    } catch {
        return false
    }
    #endif
    return true
}
