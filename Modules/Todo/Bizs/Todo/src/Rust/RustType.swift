//
//  RustType.swift
//  TodoInterface
//
//  Created by 张威 on 2020/11/11.
//

import RustPB
import LarkRustClient
import ServerPB

// MARK: - Detail Response

extension Rust {

    struct DetailRes {
        var todo: Rust.Todo?
        var parentTodo: Rust.SimpleTodo?
        var ancestors: [Rust.SimpleTodo]?
        var subtasks: [Rust.Todo]?
        var relatedTaskLists: [Rust.TaskContainer]?
        var sectionRefResult: [String: Rust.SectionRefResult]?
        var ownedSection: Rust.ContainerSection?
        var containerTaskFieldAssocList = [ContainerTaskFieldAssoc]()
        // 任务依赖的全量数据
        var dependentTaskMap: [String: Rust.Todo]?
    }

}

extension Rust.DetailRes {

    static func getAncestors(
        in map: [String: Rust.SimpleTodo],
        with guid: String?,
        to list: inout [Rust.SimpleTodo]) {
            guard let guid = guid, let ancestor = map[guid] else {
                return
            }
            getAncestors(in: map, with: ancestor.ancestorGuid, to: &list)
            list.append(ancestor)
        }

    static func getRelatedTaskList(
        in map: [String: Rust.TaskContainer],
        with taskListIds: [String]?,
        to list: inout [Rust.TaskContainer]) {
            guard let taskListIds = taskListIds else { return }
            taskListIds.forEach { id in
                if let taskList = map[id] {
                    list.append(taskList)
                }
            }
        }

    static func getAssocList(
        in map: [String: Todo_V1_ContainerTaskFieldAssociations],
        with guid: String?
    ) -> [Rust.ContainerTaskFieldAssoc] {
        guard let guid = guid, let item = map[guid] else { return [] }
        return item.associations
    }
}

extension Rust {
    typealias ListView = Todo_V1_TodoListView
    typealias ListViewType = Todo_V1_TodoListView.TypeEnum
    typealias Todo = Todo_V1_Todo
    typealias CreateTodoRes = Todo_V1_CreateTodoResponse
    typealias SimpleTodo = Todo_V1_SimpleTodo
    typealias Owner = Todo_V1_TodoOwner
    typealias Assignee = Todo_V1_TodoAssignee
    typealias Follower = Todo_V1_TodoFollower
    typealias User = Todo_V1_TodoUser
    typealias Chatter = Basic_V1_Chatter
    typealias Reminder = Todo_V1_TodoReminder
    typealias CompleteType = Todo_V1_MarkTodoCompletedRequest.TypeEnum

    typealias DraftScene = Todo_V1_DraftScene
    typealias DraftSceneType = Todo_V1_DraftScene.Scene
    typealias TodoSource = Todo_V1_TodoSource

    typealias TodoChangeset = Todo_V1_ChangedTodoCollection
    typealias TodoEditRecord = Todo_V1_Record

    typealias TodoExtraInfo = Todo_V1_TodoExtraInfo
    typealias TodoCommentCount = Todo_V1_TodoCommentCount
    typealias TodoProgressChange = Todo_V1_ProgressChange
    typealias TodoProgress = Todo_V1_Progress
    typealias SubTaskRanksChange = Todo_V1_SubTaskRanksChange

    typealias RichText = Basic_V1_RichText
    typealias RichContent = Basic_V1_RichContent

    typealias RefResource = Todo_V1_TodoReferResource

    typealias Attachment = Todo_V1_TodoAttachment

    typealias Comment = Todo_V1_TodoComment
    typealias CreateCommentInfo = Todo_V1_CreateCommentInfo

    typealias RecommendedUser = (chatter: Basic_V1_Chatter, department: String)

    typealias ImageSet = Basic_V1_ImageSet

    typealias TodoSetting = Todo_V1_TodoSetting
    typealias ListViewSetting = Todo_V1_TodoListViewSetting
    typealias ListViewSortType = Todo_V1_TodoSortType
    typealias ListLaunchScreen = Todo_V1_TodoLaunchScreen
    typealias ListBadgeConfig = Todo_V1_TodoBadgeConfig
    typealias ListBadgeType = Todo_V1_TodoBadgeConfig.BadgeType

    typealias DetailAuthScene = Todo_V1_AuthScene
    typealias DetailPermissions = Todo_V1_TodoItemPermission

    typealias ChatTodo = Todo_V1_ChatTodoInfo
    typealias Reaction = Todo_V1_TodoCommentReaction

    typealias AppConfig = Basic_V1_AppConfig

    typealias SourceBlock = Todo_V1_TodoSourceBlock

    typealias PushReminder = Todo_V1_PushTodoReminder

    typealias TodoOrigin = Todo_V1_TodoOrigin

    typealias PagingSubTaskResponse = Todo_V1_GetPagingSubTaskResponse

    // task center v3
    typealias TaskCenterResponse = Todo_V1_GetTaskCenterResponse
    typealias TaskContainer = Todo_V1_TaskContainer
    typealias TaskView = Todo_V1_TaskView
    typealias TaskSection = Todo_V1_TaskSection
    typealias BatchSection = Todo_V1_TaskSectionUpdateEntity
    typealias ContainerTaskRefs = Todo_V1_TaskContainerRefs
    typealias ContainerTaskRef = Todo_V1_TaskContainerRef
    typealias ViewCondition = Todo_V1_FilterCondition
    typealias ViewGroup = Todo_V1_TaskViewGroup
    typealias ViewSort = Todo_V1_TaskViewSort
    typealias TaskField = Todo_V1_TaskField
    typealias ViewFilterConjunction = Todo_V1_FilterConjunction
    typealias ContainerSection = Todo_V1_ContainerSection
    typealias ViewUpdateField = Todo_V1_UpdateTaskViewRequest.UpdateField

    typealias ViewFilters = Todo_V1_TaskViewFilters
    typealias ViewGroups = Todo_V1_TaskViewGroups
    typealias ViewSorts = Todo_V1_TaskViewSorts

    typealias FieldFilterValue = Todo_V1_FieldFilterValue
    typealias CompleteStatusValue = Todo_V1_TaskCompleteStatusFieldFilterValue.TaskCompleteStatus

    typealias TaskMode = Todo_V1_TaskMode
    typealias ThreadInfo = Todo_V1_ShareTodoMessageRequestThreadInfo

    typealias ActivityRecord = Todo_V1_ActivityRecord
    typealias ActivityRecordsRes = Todo_V1_GetPagingActivityRecordsResponse
    typealias ActivityScene = Todo_V1_GetPagingActivityRecordsRequest.SceneType

    // custom fields
    typealias TaskFieldValue = Todo_V1_TaskFieldValue
    typealias ContainerTaskFieldAssoc = Todo_V1_ContainerTaskFieldAssoc
    typealias TaskMember = Todo_V1_TaskItemMember
    typealias SelectFieldOption = Todo_V1_SelectFieldOption
    typealias NumberFieldSettings = Todo_V1_NumberFieldSettings
    typealias DateFieldSettings = Todo_V1_DatetimeFieldSettings
    // 任务依赖
    typealias TaskDependent = Todo_V1_TaskDependent
    typealias TaskDepRef = Todo_V1_TaskDependentRef
}

// MARK: - Task List

extension Rust {
    typealias ArchivedType = Todo_V1_ArchivedType
    typealias TaskListRes = Todo_V1_GetPagingTaskListsResponse
    typealias ContainerMetaData = Todo_V1_ContainerMetaData
    typealias TaskRefInfo = Todo_V1_TaskContainerInfo
    typealias TaskListMembersRes = Todo_V1_GetPagingTaskListMembersResponse
    typealias UpdateTaskListMemberRes = ServerPB_Todos_UpdateTaskListMembersResponse
    typealias TaskListMember = Todo_V1_TaskListMember
    typealias TaskMemberType = Todo_V1_TodoItemMemberType
    typealias EntityTaskListMember = ServerPB_Todo_entities_TaskListMember
    typealias EntityTodoChat = ServerPB_Todo_entities_TodoChat
    typealias ContianerPermission = ServerPB_Todo_entities_TaskContainerPermission
    typealias PermissionAction = Todo_V1_TaskContainerPermission.Action
    typealias ContainerPermission = Todo_V1_TaskContainerPermission
    typealias RefSectionRes = Todo_V1_GetServerTaskRefAndSectionsResponse
    typealias SectionRefResult = Todo_V1_GetServerTaskRefAndSectionsResponse.TaskSectionsAndRefsResult
    typealias OwnedSectionRefRes = Todo_V1_GetOwnedContainerTaskRefAndSectionsResponse
    typealias MemberRole = Todo_V1_TodoItemMemberRole
    typealias EntityType = ServerPB.ServerPB_Todo_entities_TodoItemMemberType
    typealias TaskListSectionRef = Todo_V1_TaskContainerSectionRef
    typealias TaskListSection = Todo_V1_TaskContainerSection
    typealias TaskListTabFilter = Todo_V1_TaskContainerFilter.TabFilter.TaskContainerTabCategory
    typealias TaskListStatusFilter = Todo_V1_TaskContainerFilter.StatusFilter.TaskContainerArchiveCategory
    typealias TaskListSectionItem = Todo_V1_TaskContainerSectionItem
    typealias PageReq = Todo_V1_PageParam
    typealias PageRes = Todo_V1_PageResult
    typealias PagingTaskListRelatedRes = Todo_V1_GetPagingTaskContainerRelatedDataResponse
    typealias ContainerIconInfo = Todo_V1_IconInfo
}

extension Rust.RichText {
    typealias Element = Basic_V1_RichTextElement
    typealias AnchorHangEntity = Basic_V1_UrlPreviewEntity
    typealias AnchorHangPoint = Basic_V1_UrlPreviewHangPoint
}
