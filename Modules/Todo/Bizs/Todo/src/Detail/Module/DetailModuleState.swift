//
//  DetailModuleState.swift
//  Todo
//
//  Created by 白言韬 on 2021/1/22.
//

import RxSwift
import RxCocoa
import LarkAccountInterface

struct DetailModuleState: RxStoreState {
    let scene: Scene

    var todo: Rust.Todo?

    /// 权限
    var permissions = DetailPermissions()

    /// 当前用户的角色
    var selfRole = MemberRole()

    /// 活跃的 chatterIds
    var activeChatters = Set<String>()

    /// 引用的资源状态
    var refResourceStates = [RefResourceState]()

    /// 完成状态
    var completedState = CompleteState.outsider(isCompleted: false)

    var richSummary = Rust.RichContent()
    var richNotes = Rust.RichContent()
    var assigner: UserType?
    var assignees = [Assignee]()
    var followers = [Follower]()
    /// 后备 assignee
    var reserveAssignee: Assignee?
    var startTime: Int64?
    var dueTime: Int64?
    var reminder: Reminder?
    var isAllDay = false
    // 模式
    var mode: Rust.TaskMode = .taskComplete
    // 重复
    var rrule: String?
    // 是否设置里程碑
    var isMilestone: Bool = false
    // 任务依赖
    var dependentsMap: [String: Rust.Todo]?
    var dependents: [Rust.TaskDepRef]?
    // 是否从sdk 获取的数据
    var parentTodo: ParentTodo?
    // 父任务
    var ancestors: [Rust.SimpleTodo]?
    // 子任务
    var subtasksState = SubtasksState.initData(subtasks: [])
    // 任务清单
    var relatedTaskLists: [Rust.TaskContainer]?
    // 关联的分组，用于新建
    var sectionRefResult: [String: Rust.SectionRefResult]?
    // 我负责的下分组
    var ownedSection: Rust.ContainerSection?
    // 附件
    var attachments = [Rust.Attachment]()
    var uploadingAttachments = [AttachmentInfo]()
    // 自定义字段-数据
    var customFieldValues = [String: Rust.TaskFieldValue]()
    // 自定义字段-基座
    var containerTaskFieldAssocList = [Rust.ContainerTaskFieldAssoc]()
}

extension DetailModuleState {
    
    var taskListForCreateReq: [Rust.ContainerSection]? {
        guard let relatedTaskLists = relatedTaskLists, let sectionRefResult = sectionRefResult else {
            return nil
        }
        return relatedTaskLists.compactMap { taskList in
            guard let sectionRef = sectionRefResult[taskList.guid] else { return nil }
            var param = Rust.ContainerSection()
            param.containerGuid = taskList.guid
            param.sectionGuid = sectionRef.ref.sectionGuid
            param.rank = sectionRef.ref.rank
            return param
        }
    }

    // 是否是子任务
    var isSubTask: Bool {
        guard let ancestors = ancestors else { return false }
        return !ancestors.isEmpty
    }

    // 当前任务是否是任务树叶子层，如果是的话不能再创建子任务了
    var isAtMaxLeafLayer: Bool {
        guard let ancestors = ancestors else { return false }
        // PM规定最大5层, 当处于第五层的是不才能创建
        return ancestors.count >= 4
    }

    enum Scene {
        case create(source: TodoCreateSource)
        case edit(guid: String, source: TodoEditSource)

        var taskListGuid: String? {
            switch self {
            case .create(let source):
                return source.taskListGuid
            case .edit:
                return nil
            }
        }

        var sectionRankForCreate: (rank: String, sectionID: String)? {
            switch self {
            case .create(let source):
                return source.sectionRankForCreate
            case .edit:
                return nil
            }
        }

        var editSource: TodoEditSource? {
            switch self {
            case .create:
                return nil
            case .edit(_, let source):
                return source
            }
        }

        var createSource: TodoCreateSource? {
            if case .create(let source) = self {
                return source
            }
            return nil
        }

        var isForListCreating: Bool {
            switch self {
            case .create(let source): return source.isFromList
            case .edit: return false
            }
        }

        var isForSubTaskCreating: Bool {
            switch self {
            case .create(let source): return source.isFromSubTask
            case .edit: return false
            }
        }

        var isForCreating: Bool {
            switch self {
            case .create: return true
            case .edit: return false
            }
        }

        var isForEditing: Bool {
            switch self {
            case .create: return false
            case .edit: return true
            }
        }

        var todoId: String? {
            if case .edit(let guid, _) = self {
                return guid
            } else {
                return nil
            }
        }

        var chatId: String? {
            switch self {
            case .create(let createSource):
                switch createSource {
                case .chat(let chatContext):
                    return chatContext.chatId
                case .list, .subTask, .inline:
                    return nil
                }
            case .edit(_, let editSource):
                return editSource.chatId
            }
        }

        // 新建按钮标题
        var createBtnTitle: String {
            var title = I18N.Todo_Task_Create
            switch self {
            case .create(let createSource):
                switch createSource {
                case .chat(let chatContext):
                    switch chatContext.fromContent {
                    case .chatSetting:
                        title = I18N.Todo_Task_CreateAndSendButton
                    default:
                        break
                    }
                case .list, .subTask, .inline:
                    break
                }
            case .edit:
                break
            }
            return title
        }

        var isShowSendToChat: Bool {
            var result = false
            switch self {
            case .create(let source):
                switch source {
                case .chat(let context):
                    switch context.fromContent {
                    case .chatSetting:
                        break
                    default:
                        result = true
                    }
                default:
                    break
                }
            case .edit:
                break
            }
            return result
        }

        var sendToChatCheckboxTitle: String {
            var title = I18N.Todo_Task_SendTaskToChatShortcut
            switch self {
            case .create(let createSource):
                switch createSource {
                case .chat(let chatContext):
                    if let threadId = chatContext.threadId, !threadId.isEmpty {
                        title = I18N.Todo_SendTaskToTopic_Checkbox
                    }
                case .list, .subTask, .inline:
                    break
                }
            case .edit:
                break
            }
            return title
        }

    }

    enum RefResourceSource {
        case message(messageIds: [String], chatId: String, needsMerge: Bool)
        case thread(threadId: String)
    }

    enum RefResourceState {
        /// 待转化（还只是 messenger 业务域的资源，需要转换为 todo 业务域的资源）
        case untransformed(RefResourceSource)
        /// 正常
        case normal(id: String)
        /// 已删除
        case deleted(id: String)
    }

    enum SubtasksState {
        case initData(subtasks: [Rust.Todo])
        case dataCallback(() -> [Rust.Todo])
    }
}

extension DetailModuleState: CustomDebugStringConvertible {
    var debugDescription: String {
        return ""
    }
}

struct DetailPermissions: Equatable {
    private(set) var summary = PermissionOption.none
    private(set) var notes = PermissionOption.none
    private(set) var refMessage = PermissionOption.none
    private(set) var assignee = PermissionOption.none
    private(set) var follower = PermissionOption.none
    private(set) var dueTime = PermissionOption.none
    private(set) var rrule = PermissionOption.none
    private(set) var origin = PermissionOption.none
    private(set) var subTask = PermissionOption.none
    private(set) var comment = PermissionOption.readable
    private(set) var attachment = PermissionOption.readable
    private(set) var customFields = PermissionOption.readable
}

extension DetailPermissions {
    mutating func upgradePermissions(by dic: [Int32: Bool], permission: PermissionOption) {
        guard !dic.isEmpty else { return }
        self.comment = permission
        dic.forEach {
            guard let type = PbPermissionType(rawValue: $0.key), $0.value else { return }
            switch type {
            case .TODO_RICH_SUMMARY:
                summary = permission
            case .TODO_RICH_DESCRIPTION:
                notes = permission
            case .TODO_REFER_RESOURCE_IDS:
                refMessage = permission
            case .TODO_ASSIGNEES:
                assignee = permission
            case .TODO_FOLLOWERS:
                follower = permission
            case .TODO_DUE_TIME, .TODO_TIME:
                dueTime = permission
            case .TODO_RRULE:
                rrule = permission
            case .TODO_ORIGIN:
                origin = permission
            case .TODO_SUB_TASK:
                subTask = permission
            case .TODO_ATTACHMENT:
                attachment = permission
            case .TODO_CUSTOM_FIELDS:
                customFields = permission
            }
        }
    }

    // 完全 copy 自 sdk 的枚举：https://bytedance.feishu.cn/docs/doccngEVcRbJDiRypit3wHeElQc
    private enum PbPermissionType: Int32 {
//        case TODO_COMPLETED_TIME = 9
        case TODO_RICH_SUMMARY = 17
        case TODO_RICH_DESCRIPTION = 18
        case TODO_REFER_RESOURCE_IDS = 19
        case TODO_ASSIGNEES = 5
        case TODO_FOLLOWERS = 20
        case TODO_ORIGIN = 21
        case TODO_DUE_TIME = 7
        case TODO_RRULE = 26
        case TODO_SUB_TASK = 30
        case TODO_ATTACHMENT = 33
        case TODO_TIME = 34
        case TODO_CUSTOM_FIELDS = 601
    }
}

// MARK: - Detail Module Action

enum DetailModuleAction: RxStoreAction {

    // MARK: Summary
    case updateSummary(Rust.RichContent)

    // MARK: Notes
    case updateNotes(Rust.RichContent)

    // MARK: RefResource
    case updateRefResources([DetailModuleState.RefResourceState])

    // MARK: Time
    case updateTime(TimeComponents)
    case clearTime

    // MARK: Assignee
    case updateReserveAssignee(Assignee)
    case removeReserveAssignee(Assignee)
    case appendAssignees([Assignee])
    case removeAssignees([Assignee])
    case clearAssignees
    case resetAssignees([Assignee])
    // MARK: Gantt
    case updateMilestone(Bool)
    case updateDependents([Rust.TaskDepRef], [String: Rust.Todo])

    // MARK: Follower
    /// 新增 followers
    case appendFollowers([Follower])
    /// 移除 followers
    case removeFollowers([Follower])
    /// 更新当前用户的 follow 状态
    case updateFollowing(Bool)

    // MARK: TaskList
    case updateTaskList([Rust.TaskContainer]?, [String: Rust.SectionRefResult]?)

    case updateOwnSection(Rust.ContainerSection?)

    // MARK: Complete
    /// 更新当前用户的完成状态
    case updateCurrentUserCompleted(fromState: CompleteState, role: CompleteRole)
    /// 更新其他执行人（不包括当前用户）的完成状态
    case updateOtherAssigneeCompleted(identifier: String, isCompleted: Bool)

    // MARK: Subtasks
    case updateSubtasksState(state: DetailModuleState.SubtasksState)

    // MARK: Permission
    case updatePermissions(DetailPermissions)

    // MARK: Attachment
    case removeAttachments([Rust.Attachment])
    case localUpdateAttachments([Rust.Attachment])
    case updateUploadingAttachments([AttachmentInfo])

    // MARK: Custom Fields
    case updateCustomFields(Rust.TaskFieldValue)

    // 更新mode
    case updateMode(Rust.TaskMode)
}

extension DetailModuleAction: LogConvertible {

    var logInfo: String {
        switch self {
        case .updateMode(let mode):
            return "new mode: \(mode.rawValue)"
        case .updateDependents(let dependents, let map):
            return "update dependents. \(dependents.count), map: \(map.count)"
        case .updateMilestone(let state):
            return "update mile stone \(state)"
        case let .updateSummary(c):
            return "updateSummary. \(c.richText.logInfo)"
        case let .updateNotes(c):
            return "updateNotes. \(c.richText.logInfo)"
        case .updateRefResources:
            return "updateRefResources"
        case let .updateTime(t):
            return "updateTime, dt: \(t.dueTime), d: \(t.isAllDay), r: \(t.reminder), rule: \(t.rrule)"
        case .clearTime:
            return "clearTime"
        case let .updateReserveAssignee(a):
            return "updateReserveAssignee, id: \(a.identifier)"
        case let .removeReserveAssignee(a):
            return "removeReserveAssignee, id: \(a.identifier)"
        case let .appendAssignees(arr):
            return "appendAssignees, ids: \(arr.map(\.identifier))"
        case let .removeAssignees(arr):
            return "removeAssignees, ids: \(arr.map(\.identifier))"
        case .clearAssignees:
            return "clearAssignees"
        case let .resetAssignees(arr):
            return "resetAssignees, ids: \(arr.map(\.identifier))"
        case let .updateCurrentUserCompleted(fromState, role):
            return "updateCurrentUserCompleted(fromState: \(fromState), role: \(role))"
        case let .updateOtherAssigneeCompleted(identifier, isCompleted):
            return "updateOtherAssigneeCompleted(\(identifier), \(isCompleted))"
        case let .appendFollowers(arr):
            return "appendFollowers, ids: \(arr.map(\.identifier))"
        case let .updateFollowing(b):
            return "updateFollow: \(b))"
        case let .removeFollowers(arr):
            return "removeFollowers, ids: \(arr.map(\.identifier))"
        case .updateTaskList(let taskLists, _):
            return "update task list, ids: \(taskLists?.map(\.guid))"
        case .updateOwnSection(let containerSection):
            return "update container seciton, \(containerSection?.logInfo)"
        case .updateSubtasksState:
            return "update subtasks state"
        case let .updatePermissions(permission):
            return "update permission, isEditable: \(permission.summary.isEditable)"
        case let .removeAttachments(attachments):
            return "removeAttachments, val: \(attachments.map(\.logInfo))"
        case let .localUpdateAttachments(attachments):
            return "localUpdateAttachments, val: \(attachments.map(\.logInfo))"
        case let .updateUploadingAttachments(infos):
            return "updateUploadingAttachments, val: \(infos.map { $0.uploadInfo.uploadKey ?? "" })"
        case let .updateCustomFields(value):
            return "updateCustomFields, val: \(value.logInfo)"
        }
    }

}
