//
//  TodoOperateApi.swift
//  TodoInterface
//
//  Created by 张威 on 2020/11/11.
//

import RxSwift
import RustPB
import LarkLocalizations

/// Todo 操作相关的 Api

protocol TodoOperateApi {
    /// 新建 Todo
    /// - Parameters:
    ///   - todo: todo
    ///   - chatToSend: 要分享到群的 chatId
    /// - Returns: 保存落库后的 todo; ref 目前用于我负责的; refs 用于任务清单
    func createTodo(
        _ todo: Rust.Todo,
        with subTasks: [Todo_V1_Todo],
        and cs: Rust.ContainerSection?,
        or taskList: [Rust.ContainerSection]?
    ) -> Observable<Rust.CreateTodoRes>

    /// 新建子任务
    /// - Parameters:
    ///   - ancestorId: 父任务id
    ///   - subTasks: 子任务数据
    /// - Returns: 子任务数据
    func createSubTask(in ancestorId: String, with subTasks: [Todo_V1_Todo]) -> Observable<[Rust.Todo]>

    /// 更新 Todo
    /// - Parameters:
    ///   - oldTodo: 旧数据
    ///   - newTodo: 新数据
    /// - Returns:
    ///   - 更新后的 todo
    func updateTodo(from oldTodo: Rust.Todo, to newTodo: Rust.Todo, with containerID: String?) -> Observable<Rust.Todo>

    /// 标记整个 Todo 为「已完成」
    /// - Parameter guid: todo 的 guid
    func markTodoAsCompleted(forId guid: String, source: Rust.TodoSource, containerID: String?) -> Observable<Rust.Todo>

    /// 标记整个 Todo 为「进行中」
    /// - Parameter guid: todo 的 guid
    func markTodoAsInProcess(forId guid: String, source: Rust.TodoSource, containerID: String?) -> Observable<Rust.Todo>

    /// 标记执行人为「已完成」
    func markAssigneeAsCompleted(forId userId: String, todoId: String, source: Rust.TodoSource, containerID: String?) -> Observable<Rust.Todo>

    /// 标记执行人为「进行中」
    func markAssigneeAsInProcess(forId userId: String, todoId: String, source: Rust.TodoSource, containerID: String?) -> Observable<Rust.Todo>

    /// 删除指定 Todo
    /// - Parameter guid: todo 的 guid
    func deleteTodo(forId guid: String, source: Rust.TodoSource) -> Observable<Void>

    /// 不再参与 Todo
    /// - Parameter guid: todo 的 guid
    func quitTodo(forId guid: String, source: Rust.TodoSource) -> Observable<Void>

    /// （分页）获取 Todo 的历史记录
    /// - Parameters:
    ///   - guid: todo 的 guid
    ///   - cursor: nil 表示首屏
    ///   - count: 分页数量
    /// - Returns: records - 修改记录；nextCursor - `nil` 表示到最后一页
    func getTodoEditRecords(byId guid: String, cursor: String?, count: Int)
        -> Observable<(records: [Rust.TodoEditRecord], nextCursor: String?)>

    /// 将 messages 转化为 todo 的 referResource
    /// - Parameters:
    ///   - messageIds: 消息 ids
    ///   - chatId: 会话 id
    ///   - needsMerge: 是否需要 merge
    /// - Returns: resource
    func mergeMessagesAsResources(withMessageIds messageIds: [String], chatId: String, needsMerge: Bool)
        -> Observable<Rust.RefResource>

    /// 将 Thread 转化为 todo 的 referResource
    /// - Parameters:
    ///   - threadId: 话题 id
    func transformThreadAsResources(withThreadId threadId: String)
        -> Observable<(resourceId: String, resource: Rust.RefResource)>

    /// 关注 / 取消关注 Todo
    /// - Parameters:
    ///   - guid: todo 的 guid
    ///   - isFollow: 关注 / 取消关注
    ///   - authScene: 鉴权字段
    func followTodo(forId guid: String, isFollow: Bool, authScene: Rust.DetailAuthScene?)
        -> Observable<Rust.Todo>

    /// 修改 Setting
    func updateSetting(from setting: Rust.TodoSetting) -> Observable<Void>

    /// update launch
    func updateLaunchScreen(from launchScreen: Rust.ListLaunchScreen) -> Observable<Void>

    /// 修改 viewSetting
    func updateListViewSetting(viewSetting: Rust.ListViewSetting) -> Observable<Void>

    /// 根据场景获取任务草稿
    /// - Parameter scene: 场景:  任务中心、聊天
    func getTodoDraft(byScene scene: Rust.DraftScene) -> Observable<Rust.Todo?>

    /// 保存任务草稿
    /// - Parameters:
    ///   - todo: 要保存的todo
    ///   - scene: 具体的场景
    func saveTodoDraft(_ todo: Rust.Todo, scene: Rust.DraftScene) -> Observable<Void>

    /// 删除任务草稿
    /// - Parameter scene: 删除场景下的todo
    func deleteTodoDraft(byScene scene: Rust.DraftScene) -> Observable<Void>

    func updateTaskView(view: Rust.TaskView, updateFields: [Rust.ViewUpdateField]) -> Observable<Void>
    /// 新增or更新section
    func upsertSection(old: Rust.TaskSection?, new: Rust.TaskSection) -> Observable<Rust.TaskSection>
    /// 删除section
    func deleteSection(guid: String, containerID: String) -> Observable<Void>
    /// 批量操作section
    func batchUpsertSection(_ entity: [Rust.BatchSection]) -> Observable<[Rust.TaskSection]>
}

extension RustApiImpl: TodoOperateApi {

    func createTodo(_ todo: Rust.Todo, with subTasks: [Todo_V1_Todo], and cs: Rust.ContainerSection?, or taskList: [Rust.ContainerSection]?) -> Observable<Rust.CreateTodoRes> {
        var ctx = Self.generateContext()
        ctx.cmd = .createTodo
        ctx.logReq("todo:  \(todo.logInfo), subTask: \(subTasks.map(\.logInfo).joined(separator: ",")), cs: \(cs?.logInfo), taskList: \(taskList?.map(\.logInfo).joined(separator: ","))")

        var request = Todo_V1_CreateTodoRequest()
        request.todo = todo
        request.subTasks = subTasks
        if let cs = cs {
            request.containerSection = cs
        }
        if let taskList = taskList {
            request.taskListSections = taskList
        }
        return client.sendAsyncRequest(request)
            .log(with: ctx) { $0.logInfo }
    }

    func createSubTask(in ancestorId: String, with subTasks: [Todo_V1_Todo]) -> Observable<[Rust.Todo]> {
        var ctx = Self.generateContext()
        ctx.cmd = .createSubTasks
        ctx.logReq("ancestorId: \(ancestorId), subTask: \(subTasks.map(\.logInfo).joined(separator: ","))")

        var request = Todo_V1_CreateSubTasksRequest()
        request.ancestorGuid = ancestorId
        request.subTasks = subTasks
        return client.sendAsyncRequest(request)
            .map(Transform<Todo_V1_CreateSubTasksResponse>.toKeyPath(\.subTasks))
            .log(with: ctx) { "\($0.map(\.logInfo).joined(separator: ","))" }
    }

    func updateTodo(from oldTodo: Rust.Todo, to newTodo: Rust.Todo, with containerID: String?) -> Observable<Rust.Todo> {
        var ctx = Self.generateContext()
        ctx.cmd = .updateTodo
        ctx.logReq("from: \(oldTodo.logInfo), to: \(newTodo.logInfo), containerId: \(containerID)")

        var request = Todo_V1_UpdateTodoRequest()
        request.oldTodo = oldTodo
        request.todo = newTodo
        if let containerID = containerID {
            request.containerID = containerID
        }
        return client.sendAsyncRequest(request)
            .map(Transform<Todo_V1_UpdateTodoResponse>.toKeyPath(\.todo))
            .log(with: ctx) { $0.logInfo }
    }

    func deleteTodo(forId guid: String, source: Rust.TodoSource) -> Observable<Void> {
        var ctx = Self.generateContext()
        ctx.cmd = .deleteTodos
        ctx.logReq("guid: \(guid), source: \(source)")

        var request = Todo_V1_DeleteTodosRequest()
        request.todoGuids = [guid]
        request.source = source
        return client.sendAsyncRequest(request)
            .map(Transform<Todo_V1_DeleteTodosResponse>.toVoid())
            .log(with: ctx) { "succeed" }
    }

    func quitTodo(forId guid: String, source: Rust.TodoSource) -> Observable<Void> {
        var ctx = Self.generateContext()
        ctx.cmd = .quitTodo
        ctx.logReq("guid: \(guid), source: \(source)")

        var request = Todo_V1_QuitTodoRequest()
        request.todoGuid = guid
        request.source = source
        return client.sendAsyncRequest(request)
            .map(Transform<Todo_V1_QuitTodoResponse>.toVoid())
            .log(with: ctx) { "succeed" }
    }

    func followTodo(forId guid: String, isFollow: Bool, authScene: Rust.DetailAuthScene?) -> Observable<Rust.Todo> {
        var ctx = Self.generateContext()
        ctx.cmd = .followTodo
        ctx.logReq("guid: \(guid) isFollow: \(isFollow) authType: \(authScene?.type) authId: \(authScene?.id)")

        var request = Todo_V1_FollowTodoRequest()
        request.todoGuid = guid
        request.isFollow = isFollow
        if let authScene = authScene {
            request.authScene = authScene
        }
        return client.sendAsyncRequest(request)
            .map(Transform<Todo_V1_FollowTodoResponse>.toKeyPath(\.todo))
            .log(with: ctx) { $0.logInfo }
    }

    private func doMarkTodo(forId guid: String, completed: Bool, source: Rust.TodoSource, containerID: String?) -> Observable<Rust.Todo> {
        var ctx = Self.generateContext()
        ctx.cmd = .markTodoCompleted
        ctx.logReq("mark todo completed. \(guid), \(completed)")

        var request = Todo_V1_MarkTodoCompletedRequest()
        request.guid = guid
        request.isCompleted = completed
        request.source = source
        request.type = .todo
        if let containerID = containerID {
            request.containerID = containerID
        }
        return client.sendAsyncRequest(request)
            .map(Transform<Todo_V1_MarkTodoCompletedResponse>.toKeyPath(\.todo))
            .log(with: ctx) { $0.logInfo }
    }

    func markTodoAsCompleted(forId guid: String, source: Rust.TodoSource, containerID: String?) -> Observable<Rust.Todo> {
        return doMarkTodo(forId: guid, completed: true, source: source, containerID: containerID)
    }

    func markTodoAsInProcess(forId guid: String, source: Rust.TodoSource, containerID: String?) -> Observable<Rust.Todo> {
        return doMarkTodo(forId: guid, completed: false, source: source, containerID: containerID)
    }

    private func doMarkAssignee(
        forId userId: String,
        todoId: String,
        completed: Bool,
        source: Rust.TodoSource,
        containerID: String?
    ) -> Observable<Rust.Todo> {
        var ctx = Self.generateContext()
        ctx.cmd = .markTodoCompleted
        ctx.logReq("mark assignee completed. \(todoId), \(completed)")

        var request = Todo_V1_MarkTodoCompletedRequest()
        request.guid = todoId
        request.isCompleted = completed
        request.source = source
        request.type = .user
        request.targetUserIds = [userId]
        if let containerID = containerID, !containerID.isEmpty {
            request.containerID = containerID
        }
        return client.sendAsyncRequest(request)
            .map(Transform<Todo_V1_MarkTodoCompletedResponse>.toKeyPath(\.todo))
            .log(with: ctx) { $0.logInfo }
    }

    func markAssigneeAsCompleted(forId userId: String, todoId: String, source: Rust.TodoSource, containerID: String?) -> Observable<Rust.Todo> {
        return doMarkAssignee(forId: userId, todoId: todoId, completed: true, source: source, containerID: containerID)
    }

    func markAssigneeAsInProcess(forId userId: String, todoId: String, source: Rust.TodoSource, containerID: String?) -> Observable<Rust.Todo> {
        return doMarkAssignee(forId: userId, todoId: todoId, completed: false, source: source, containerID: containerID)
    }

    func getTodoEditRecords(byId guid: String, cursor: String?, count: Int)
    -> Observable<(records: [Rust.TodoEditRecord], nextCursor: String?)> {
        var ctx = Self.generateContext()
        ctx.cmd = .getTodoHistoryRecords
        ctx.logReq("\(guid),\(cursor),\(count)")

        var request = Todo_V1_GetTodoHistoryRecordsRequest()
        request.guid = guid
        if let cursor = cursor {
            request.cursor = cursor
            request.scene = .nextPage
        } else {
            request.scene = .firstScreen
        }
        request.count = Int32(count)
        request.languageType = LanguageManager.currentLanguage.sdkLanguageType
        return client.sendAsyncRequest(request)
            .map { (response: Todo_V1_GetTodoHistoryRecordsResponse)
                -> (records: [Rust.TodoEditRecord], nextCursor: String?) in
                let nextCursor: String?
                if response.hasMore_p && !response.nextCursor.isEmpty {
                    nextCursor = response.nextCursor
                } else {
                    nextCursor = nil
                }
                return (response.records, nextCursor)
            }
            .log(with: ctx) { (records, nextCursor) in
                return "\(nextCursor), \(records.map(\.recordType.rawValue))"
            }
    }

    func mergeMessagesAsResources(withMessageIds messageIds: [String], chatId: String, needsMerge: Bool)
        -> Observable<Rust.RefResource> {
        var ctx = Self.generateContext()
        ctx.cmd = .mergeMessagesAsTodoResource
        ctx.logReq("\(messageIds),\(chatId)")

        var request = Todo_V1_MergeMessagesAsTodoResourceRequest()
        request.chatID = chatId
        request.msgIds = messageIds
        request.shouldMerge = needsMerge
        return client.sendAsyncRequest(request)
            .map(Transform<Todo_V1_MergeMessagesAsTodoResourceResponse>.toKeyPath(\.resource))
            .log(with: ctx) { "\($0.id)" }
    }

    func transformThreadAsResources(withThreadId threadId: String)
        -> Observable<(resourceId: String, resource: Rust.RefResource)> {
        var ctx = Self.generateContext()
        ctx.cmd = .mergeTopicAsTodoResource
        ctx.logReq("\(threadId)")

        var request = Todo_V1_MergeTopicAsTodoResourceRequest()
        request.threadID = threadId
        return client.sendAsyncRequest(request)
            .map { (response: Todo_V1_MergeTopicAsTodoResourceResponse)
                -> (resourceId: String, resource: Rust.RefResource) in
                return (resourceId: response.resource.id, resource: response.resource)
            }
            .log(with: ctx) { "\($0.resourceId)" }
    }

    func updateSetting(from setting: Rust.TodoSetting) -> Observable<Void> {
        var ctx = Self.generateContext()
        ctx.cmd = .updateTodoSetting
        ctx.logReq(setting.logInfo)

        var request = Todo_V1_UpdateTodoSettingRequest()
        request.setting = setting
        request.type = .todoSetting
        return client.sendAsyncRequest(request)
            .map(Transform<Todo_V1_UpdateTodoSettingResponse>.toVoid())
            .log(with: ctx) { "succeed" }
    }

    func updateLaunchScreen(from launchScreen: Rust.ListLaunchScreen) -> Observable<Void> {
        var ctx = Self.generateContext()
        ctx.cmd = .updateTodoSetting
        ctx.logReq(launchScreen.logInfo)

        var request = Todo_V1_UpdateTodoSettingRequest()
        request.launchScreen = launchScreen
        request.type = .launchScreen
        return client.sendAsyncRequest(request)
            .map(Transform<Todo_V1_UpdateTodoSettingResponse>.toVoid())
            .log(with: ctx) { "succeed" }
    }

    func updateListViewSetting(viewSetting: Rust.ListViewSetting) -> Observable<Void> {
        var ctx = Self.generateContext()
        ctx.cmd = .updateTodoSetting
        ctx.logReq(viewSetting.logInfo)

        var request = Todo_V1_UpdateTodoSettingRequest()
        request.type = .viewSetting
        request.viewSetting = viewSetting
        return client.sendAsyncRequest(request)
            .map(Transform<Todo_V1_UpdateTodoSettingResponse>.toVoid())
            .log(with: ctx) { "succeed" }
    }

    func getTodoDraft(byScene scene: Rust.DraftScene) -> Observable<Rust.Todo?> {
        var ctx = Self.generateContext()
        ctx.cmd = .getTodoDraft
        ctx.logReq("\(scene)")

        var request = Todo_V1_GetTodoDraftRequest()
        request.scene = scene
        return client.sendAsyncRequest(request)
            .map { (response: Todo_V1_GetTodoDraftResponse) -> Rust.Todo? in
                guard response.found else { return nil }
                return response.todo
            }
            .log(with: ctx) { $0?.logInfo ?? "draft not found. sceneId: \(scene.sceneID)" }
    }

    func saveTodoDraft(_ todo: Rust.Todo, scene: Rust.DraftScene) -> Observable<Void> {
        var ctx = Self.generateContext()
        ctx.cmd = .saveTodoDraft
        ctx.logReq(todo.logInfo)

        var request = Todo_V1_SaveTodoDraftRequest()
        request.todo = todo
        request.scene = scene
        return client.sendAsyncRequest(request)
            .map(Transform<Todo_V1_SaveTodoDraftResponse>.toVoid())
            .log(with: ctx) { "succeed" }
    }

    func deleteTodoDraft(byScene scene: Rust.DraftScene) -> Observable<Void> {
        var ctx = Self.generateContext()
        ctx.cmd = .deleteTodoDraft
        ctx.logReq("\(scene)")

        var request = Todo_V1_DeleteTodoDraftRequest()
        request.scene = scene
        return client.sendAsyncRequest(request)
            .map(Transform<Todo_V1_DeleteTodoDraftResponse>.toVoid())
            .log(with: ctx) { "succeed" }
    }

    func updateTaskView(view: Rust.TaskView, updateFields: [Rust.ViewUpdateField]) -> Observable<Void> {
        var ctx = Self.generateContext()
        ctx.cmd = .updateTaskView
        ctx.logReq("view guid: \(view.guid), fileds: \(updateFields.map { $0.rawValue })")

        var request = Todo_V1_UpdateTaskViewRequest()
        request.view = view
        request.updateFields = updateFields

        return client.sendAsyncRequest(request)
            .map(Transform<Todo_V1_UpdateTaskViewResponse>.toVoid())
            .log(with: ctx) { "succeed" }
    }

    func upsertSection(old: Rust.TaskSection?, new: Rust.TaskSection) -> Observable<Rust.TaskSection> {
        var ctx = Self.generateContext()
        ctx.cmd = .upsertTaskSection
        ctx.logReq("upsert task section. old \(old?.logInfo), new: \(new.logInfo)")

        var request = Todo_V1_UpsertTaskSectionRequest()
        if let old = old {
            request.oldSection = old
        }
        request.newSection = new
        return client.sendAsyncRequest(request)
            .map { (response: Todo_V1_UpsertTaskSectionResponse) -> Rust.TaskSection in
                response.section
            }
            .log(with: ctx) { "succeed new: \($0.logInfo)" }
    }

    func batchUpsertSection(_ entity: [Rust.BatchSection]) -> Observable<[Rust.TaskSection]> {
        var ctx = Self.generateContext()
        ctx.cmd = .upsertTaskSections
        ctx.logReq("batch upsert task section. old: \(entity.map(\.oldSection.logInfo)), new: \(entity.map(\.newSection.logInfo))")

        var req = Todo_V1_UpsertTaskSectionsRequest()
        req.updateEntities = entity
        return client.sendAsyncRequest(req)
            .map { (response: Todo_V1_UpsertTaskSectionsResponse) -> [Rust.TaskSection] in
                response.sections
            }
            .log(with: ctx) { "succeed new count: \($0.count)" }
    }

    func deleteSection(guid: String, containerID: String) -> Observable<Void> {
        var ctx = Self.generateContext()
        ctx.cmd = .quitTodo
        ctx.logReq("guid: \(guid)")

        var request = Todo_V1_DeleteTaskSectionRequest()
        request.sectionGuid = guid
        request.containerGuid = containerID
        return client.sendAsyncRequest(request)
            .map(Transform<Todo_V1_DeleteTaskSectionResponse>.toVoid())
            .log(with: ctx) { "succeed" }
    }
}
