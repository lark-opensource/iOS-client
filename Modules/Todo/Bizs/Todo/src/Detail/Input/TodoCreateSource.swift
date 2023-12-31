//
//  TodoCreateSource.swift
//  Todo
//
//  Created by 白言韬 on 2021/4/30.
//

import Foundation
import TodoInterface
import RustPB

enum TodoCreateSource {
    case chat(context: TodoCreateBody.ChatSourceContext)
    case list(container: Rust.ContainerSection?, task: Rust.Todo?)
    // ipad 编辑页创建子任务, ancestorGuid当前任务Id ancestorIsSubTask当前任务是否是子任务
    case subTask(ancestorGuid: String, ancestorIsSubTask: Bool, chatId: String?)
    // 行内创建
    case inline(param: InlineContainerSection)
}

/// Inline创建所需要container section
enum InlineContainerSection {
    case container(Rust.ContainerSection, Rust.Todo)
    case taskList(Rust.Todo, Rust.ContainerSection)
}

struct TodoCreateCallbacks {
    /// 创建成功时回调，返回保存的数据
    var createHandler: ((Rust.CreateTodoRes) -> Void)?
    /// 放弃保存时回调，会把页面当前的数据，以 pb todo 的方式返回 （目前仅完整详情页支持）,
    ///  [Rust.Todo] 是子任务
    var cancelHandler: ((Rust.Todo, [Rust.Todo]?, [Rust.TaskContainer]?, [String: Rust.SectionRefResult]?, Rust.ContainerSection?) -> Void)?
    /// 创建成功以后Toast操作，用于跳转详情页
    var successToastHandler: ((Rust.Todo) -> Void)?
}

extension TodoCreateSource: LogConvertible {

    var taskForCreate: Rust.Todo? {
        switch self {
        case .list(_, let task):
            return task
        default: return nil
        }
    }

    var containerSection: Rust.ContainerSection? {
        switch self {
        case .list(let container, let task):
            guard let task = task, task.relatedTaskListGuids.isEmpty else {
                return nil
            }
            return container
        case .inline(let param):
            if case .container(let cs, let task) = param {
                guard task.relatedTaskListGuids.isEmpty else {
                    return nil
                }
                return cs
            }
        default: return nil
        }
        return nil
    }
    /// 是否自动填充负责人
    var autoFillOwner: Bool {
        /*
         来自任务中心 & 不是来自清单
         来自行内创建 & 不是来自清单
         来自会话
         */
        return (isFromList && !isFromTaskList) || (isFromInline && !isFromTaskListInline) || isFromChat
    }

    var taskListGuid: String? {
        switch self {
        case .list(_, let task):
            return task?.relatedTaskListGuids.first
        case .inline(let param):
            if case .taskList(let task, _) = param {
                return task.relatedTaskListGuids.first
            }
        default: return nil
        }
        return nil
    }

    var sectionRankForCreate: (rank: String, sectionID: String)? {
        switch self {
        case .list(let containerSection, let task):
            guard let task = task, task.relatedTaskListGuids.isEmpty else {
                return (containerSection?.rank ?? Utils.Rank.defaultMinRank, containerSection?.sectionGuid ?? "")
            }
            return (Utils.Rank.defaultMinRank, "")
        case .inline(let param):
            if case .taskList(_, let containerSection) = param {
                return (containerSection.rank, containerSection.sectionGuid)
            }
        default: return nil
        }
        return nil
    }

    // 是否是子任务场景
    var isFromSubTask: Bool {
        if case .subTask = self {
            return true
        }
        return false
    }

    // 描述是否是会话场景
    var isFromChat: Bool {
        if case .chat = self {
            return true
        }
        return false
    }

    // 是否行内创建
    var isFromInline: Bool {
        if case .inline = self {
            return true
        }
        return false
    }

    /// 来自清单的行内创建
    var isFromTaskListInline: Bool {
        if case .inline(let param) = self, case .taskList = param {
            return true
        }
        return false
    }

    // 任务中心创建但是来自清单
    var isFromTaskList: Bool {
        if case .list(_, let task) = self, let task = task, !task.relatedTaskListGuids.isEmpty {
            return true
        }
        return false
    }

    // 是否列表中心
    var isFromList: Bool {
        if case .list = self {
            return true
        }
        return false
    }

    func isEnableDraft() -> Bool {
        switch self {
        case .chat(let context):
            switch context.fromContent {
            case .chatKeyboard, .chatSetting:
                return true
            default:
                return false
            }
        case .subTask, .inline:
            return false
        case .list(_, let task):
            // 表示外面传入的Task有内容，则不用草稿
            if let task = task, (!task.relatedTaskListGuids.isEmpty || task.isValidDraft) {
                return false
            }
            return true
        }
    }

    func getDraftScene() -> Rust.DraftScene {
        var draftScene = Rust.DraftScene()
        switch self {
        case .chat(let chatContext):
            draftScene.sceneID = chatContext.chatId
            if case .chatSetting = chatContext.fromContent {
                draftScene.scene = .chatSidebar
            } else {
                draftScene.scene = .chat
            }
        case .list:
            draftScene.scene = .todoCenter
        case .subTask, .inline:
            draftScene.scene = .unknownScene
        }
        return draftScene
    }

    var logInfo: String {
        switch self {
        case .chat(let context):
            return "type: chat, chatId: \(context.chatId), messageId: \(context.messageId), isThread: \(context.isThread), fromContent: \(context.fromContent.dubugInfo())"
        case .list(let filter):
            return "type: list, filter: \(filter)"
        case .subTask(let ancestorGuid, let ancestorIsSubTask, _):
            return "type: ancestorGuid: \(ancestorGuid), ancestorIsSubTask: \(ancestorIsSubTask)"
        case .inline(let param):
            return "type: cs: \(param.logInfo)"
        }
    }

}

extension TodoCreateBody.ChatSourceContext {

    private func fixedRichContent(_ content: Rust.RichContent, downgrade: Bool = true) -> Rust.RichContent {
        var fixed = content
        if downgrade {
            Utils.RichText.degradeElements(in: &fixed.richText)
        }
        Utils.RichText.fixAnchorContent(in: &fixed)
        return fixed
    }

    func extractRichSummary(_ limitCount: Int? = nil) -> Rust.RichContent? {
        let buildFromText = { (text: String) -> Rust.RichContent in
            var richContent = Rust.RichContent()
            richContent.richText = Utils.RichText.makeRichText(from: text)
            return richContent
        }
        let isExceedLimit = { (richContent: Rust.RichContent?) -> Bool in
            guard let limitCount = limitCount, let richContent = richContent else { return false }
            return NSAttributedString(string: richContent.richText.lc.summerize()).length > limitCount
        }
        switch fromContent {
        case .textMessage(let richContent):
            let content = fixedRichContent(richContent)
            if isExceedLimit(content) {
                let title = isThread ? I18N.Todo_Task_FromTopic(chatName) : I18N.Todo_Task_FromChat(chatName)
                return buildFromText(title)
            } else {
                return content
            }
        case .postMessage(let title, let richContent):
            if title.isEmpty {
                let content = fixedRichContent(richContent)
                if isExceedLimit(content) {
                    let title = isThread ? I18N.Todo_Task_FromTopic(chatName) : I18N.Todo_Task_FromChat(chatName)
                    return buildFromText(title)
                } else {
                    return content
                }
            } else {
                return buildFromText(title)
            }
        case .threadMessage(let title, let richContent, _):
            if let content = richContent {
                let content = fixedRichContent(content)
                if isExceedLimit(content) {
                    let title = isThread ? I18N.Todo_Task_FromTopic(chatName) : I18N.Todo_Task_FromChat(chatName)
                    return buildFromText(title)
                } else {
                    return content
                }
            } else if !title.isEmpty {
                return buildFromText(title)
            } else {
                let title = isThread ? I18N.Todo_Task_FromTopic(chatName) : I18N.Todo_Task_FromChat(chatName)
                return buildFromText(title)
            }
        case .chatKeyboard(let richContent):
            guard let richContent = richContent else { return nil }
            let content = fixedRichContent(richContent)
            if isExceedLimit(content) {
                let title = isThread ? I18N.Todo_Task_FromTopic(chatName) : I18N.Todo_Task_FromChat(chatName)
                return buildFromText(title)
            } else {
                return content
            }
        case .needsMergeMessage(_, let title):
            return buildFromText(title)
        case .mergeForwardMessage(_, let chatName), .multiSelectMessages(_, let chatName):
            let title = isThread ? I18N.Todo_Task_FromTopic(chatName) : I18N.Todo_Task_FromChat(chatName)
            return buildFromText(title)
        default:
            return nil
        }
    }
}
