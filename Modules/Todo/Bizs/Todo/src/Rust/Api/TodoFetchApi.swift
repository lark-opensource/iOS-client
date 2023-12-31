//
//  TodoFetchApi.swift
//  TodoInterface
//
//  Created by 张威 on 2020/11/11.
//

import RxSwift
import RustPB

/// Todo 获取相关的 Api

protocol TodoFetchApi {

    /// 根据 guid 获取 todo
    /// - Parameter guid: 指定 guid
    func getTodo(guid: String) -> Observable<Rust.DetailRes>

    /// 从服务端获取Todo
    func getServerTodo(byId guid: String) -> Observable<Rust.DetailRes>

    /// 获取全部Todos
    func getAllTasks() -> Observable<[Rust.Todo]>

    /// 根据 chatterId 拉取 Users
    /// - Parameter chatterIds: chatterIds
    func getUsers(byIds chatterIds: [String]) -> Observable<[Rust.User]>

    /// IM, PIN模块获取todo详情, 非自己的todo也会返回
    /// - Parameter guids: 指定 guid
    /// - Parameter authScene: 鉴权字段
    func getSharedTodo(byId guid: String, authScene: Rust.DetailAuthScene) -> Observable<Rust.DetailRes>

    /// 获取推荐的 assignees
    /// - Parameter count: 获取的数量
    func getRecommendedUsers(byCount count: Int) -> Observable<[Rust.RecommendedUser]>

    /// 获取 Todo 的引用资源
    ///
    /// - Parameter resourceIds: 资源 ids
    func getTodoRefResources(byIds resourceIds: [String]) -> Observable<[Rust.RefResource]>

    /// 请求 Setting
    func getSetting(_ forceServer: Bool) -> Observable<Rust.TodoSetting>

    /// 获取badge
    func getTodoBadgeNumber() -> Observable<Int32>

    /// 获取挂载到 anchor 的 entities
    func getAnchorHangEntities(
        forPoints points: [Rust.RichText.AnchorHangPoint],
        with sourceId: String
    ) -> Observable<[Rust.RichText.AnchorHangEntity]>

    func generateAnchorHangEntity(by urlStr: UrlStr) -> Observable<Rust.RichText.AnchorHangEntity?>

    func getPagingSubTasks(guid: String, count: Int32, token: String?) -> Observable<Rust.PagingSubTaskResponse>

    func getTaskCenter() -> Observable<Rust.TaskCenterResponse>

    func getOwnedSections(with taskGuid: String?) -> Observable<Rust.OwnedSectionRefRes>

    func searchTasks(by query: String) -> Observable<[Rust.Todo]>
}

extension RustApiImpl: TodoFetchApi {

    func getAllTasks() -> Observable<[Rust.Todo]> {
        var ctx = Self.generateContext()
        ctx.cmd = .getTasks
        ctx.logReq("getAllTodos")

        var request = Todo_V1_GetTasksRequest()
        return client.sendAsyncRequest(request)
            .map(Transform<Todo_V1_GetTasksResponse>.toKeyPath(\.tasks))
            .log(with: ctx) { "get all todos count: \($0.count)" }
    }

    func getTodo(guid: String) -> Observable<Rust.DetailRes> {
        var ctx = Self.generateContext()
        ctx.cmd = .getTodo
        ctx.logReq("\(guid)")

        var request = Todo_V1_GetTodoRequest()
        request.guid = guid
        return client.sendAsyncRequest(request)
            .map { (res: Todo_V1_GetTodoResponse) -> Rust.DetailRes in
                var ancestors: [Rust.SimpleTodo] = []
                Rust.DetailRes.getAncestors(
                    in: res.ancestors,
                    with: res.todo.ancestorGuid,
                    to: &ancestors
                )
                var taskLists = [Rust.TaskContainer]()
                res.todo.relatedTaskListGuids.forEach { guid in
                    if let value = res.relatedTaskLists.first(where: { $0.guid == guid }) {
                        taskLists.append(value)
                    }
                }
                return Rust.DetailRes(
                    todo: res.todo,
                    ancestors: ancestors,
                    relatedTaskLists: taskLists
                )
            }
            .log(with: ctx) {
                "todo: \($0.todo?.logInfo), ancestors: \($0.ancestors?.map(\.logInfo).joined(separator: ",")), relatedTaskLists: \($0.relatedTaskLists?.count)"
            }
    }

    func getServerTodo(byId guid: String) -> Observable<Rust.DetailRes> {
        var ctx = Self.generateContext()
        ctx.cmd = .mgetServerTodos
        ctx.logReq("\(guid)")

        var request = Todo_V1_MGetServerTodosRequest()
        request.guids = [guid]
        return client.sendAsyncRequest(request)
            .map { (res: Todo_V1_MGetServerTodosResponse) -> Rust.DetailRes in
                var ancestors: [Rust.SimpleTodo] = []
                Rust.DetailRes.getAncestors(
                    in: res.ancestors,
                    with: res.todos.first?.ancestorGuid,
                    to: &ancestors
                )
                var relatedTaskLists: [Rust.TaskContainer] = []
                Rust.DetailRes.getRelatedTaskList(
                    in: res.relatedTaskLists,
                    with: res.todos.first?.relatedTaskListGuids,
                    to: &relatedTaskLists
                )
                let assocList = Rust.DetailRes.getAssocList(
                    in: res.containerFieldAssociations,
                    with: res.todos.first?.guid
                )
                return Rust.DetailRes(
                    todo: res.todos.first,
                    parentTodo: res.guidToParentTodo[guid],
                    ancestors: ancestors,
                    relatedTaskLists: relatedTaskLists,
                    containerTaskFieldAssocList: assocList,
                    dependentTaskMap: res.dependentTodos
                )
            }
            .log(with: ctx) {
                """
                todo: \($0.todo?.logInfo ?? ""),
                parentTodo: \($0.parentTodo?.guid ?? ""),
                ancestors: \($0.ancestors?.map(\.logInfo).joined(separator: ",") ?? ""),
                relatedTaskLists: \($0.relatedTaskLists?.count ?? 0),
                assocListCount: \($0.containerTaskFieldAssocList.count),
                dependentCount: \($0.dependentTaskMap?.count ?? 0))
                """
            }
    }

    func getUsers(byIds chatterIds: [String]) -> Observable<[Rust.User]> {
        var ctx = Self.generateContext()
        ctx.cmd = .getTodoUsersByChatterIds
        ctx.logReq("\(chatterIds)")

        var request = Todo_V1_GetTodoUsersByChatterIdsRequest()
        request.chatterIds = chatterIds
        return client.sendAsyncRequest(request)
            .map { (res: Todo_V1_GetTodoUsersByChatterIdsResponse) -> [RustPB.Todo_V1_TodoUser] in
                var sortedList = [RustPB.Todo_V1_TodoUser]()
                chatterIds.forEach { chatterId in
                    if let user = res.users.first(where: { $0.userID == chatterId }) {
                        sortedList.append(user)
                    }
                }
                return sortedList
            }
            .log(with: ctx) { "users:\($0.map({ Member.user(User(pb: $0)).logInfo }))" }
    }

    func getSharedTodo(byId guid: String, authScene: Rust.DetailAuthScene) -> Observable<Rust.DetailRes> {
        var ctx = Self.generateContext()
        ctx.cmd = .getSharedTodos
        ctx.logReq("\(guid)")

        var request = Todo_V1_GetSharedTodosRequest()
        request.guids = [guid]
        request.authScene = authScene
        return client.sendAsyncRequest(request)
            .map { (res: Todo_V1_GetSharedTodosResponse) -> Rust.DetailRes in
                var ancestors: [Rust.SimpleTodo] = []
                Rust.DetailRes.getAncestors(
                    in: res.ancestors,
                    with: res.todos.first?.ancestorGuid,
                    to: &ancestors
                )
                var relatedTaskLists: [Rust.TaskContainer] = []
                Rust.DetailRes.getRelatedTaskList(
                    in: res.relatedTaskLists,
                    with: res.todos.first?.relatedTaskListGuids,
                    to: &relatedTaskLists
                )
                return Rust.DetailRes(
                    todo: res.todos.first,
                    ancestors: ancestors,
                    relatedTaskLists: relatedTaskLists
                )
            }
            .log(with: ctx) {
                "todo: \($0.todo?.logInfo), ancestors: \($0.ancestors?.map(\.logInfo).joined(separator: ",")), relatedTaskLists: \($0.relatedTaskLists?.count)"
            }
    }

    func getRecommendedUsers(byCount count: Int) -> Observable<[Rust.RecommendedUser]> {
        var ctx = Self.generateContext()
        ctx.cmd = .getRecommendedContents
        ctx.logReq("\(count)")

        var request = Todo_V1_GetRecommendedContentsRequest()
        request.count = Int32(count)
        return client.sendAsyncRequest(request)
            .map { (response: Todo_V1_GetRecommendedContentsResponse) -> [Rust.RecommendedUser] in
                let chatters = response.chatters
                return response.recommendContents.compactMap { content -> Rust.RecommendedUser? in
                    guard let chatter = chatters[content.id] else { return nil }
                    return (chatter, content.department)
                }
            }
            .log(with: ctx) { "chatterIds: \($0.map(\.chatter.id))" }
    }

    func getTodoRefResources(byIds resourceIds: [String]) -> Observable<[Rust.RefResource]> {
        var ctx = Self.generateContext()
        ctx.cmd = .getTodoReferResources
        ctx.logReq("\(resourceIds)")
        var request = Todo_V1_GetTodoReferResourcesRequest()
        request.resourceIds = resourceIds
        return client.sendAsyncRequest(request)
            .map(Transform<Todo_V1_GetTodoReferResourcesResponse>.toKeyPath(\.resources))
            .log(with: ctx) { "\($0.map({ "\($0.id)-\($0.type.rawValue)" }))" }
    }

    func getSetting(_ forceServer: Bool = false) -> Observable<Rust.TodoSetting> {
        var ctx = Self.generateContext()
        ctx.cmd = .getTodoSetting
        ctx.logReq("")

        var request = Todo_V1_GetTodoSettingRequest()
        request.strategy = forceServer ? .forceServer : .tryLocal

        return client.sendAsyncRequest(request)
            .map(Transform<Todo_V1_GetTodoSettingResponse>.toKeyPath(\.setting))
            .log(with: ctx) { $0.logInfo }
    }

    func getTodoBadgeNumber() -> Observable<Int32> {
        var ctx = Self.generateContext()
        ctx.cmd = .getTodoBadge
        ctx.logReq("")

        var request = Todo_V1_GetTodoBadgeRequest()
        return client.sendAsyncRequest(request)
            .map(Transform<Todo_V1_GetTodoBadgeResponse>.toKeyPath(\.count))
            .log(with: ctx) { "\($0)" }
    }

    func getAnchorHangEntities(
        forPoints points: [Rust.RichText.AnchorHangPoint],
        with sourceId: String
    ) -> Observable<[Rust.RichText.AnchorHangEntity]> {
        var ctx = Self.generateContext()
        ctx.cmd = .getMessagePreviews
        let previewIds = points.map(\.previewID)
        ctx.logReq("pids: \(previewIds.map({ "\($0)" }).joined(separator: ",")), sid: \(sourceId))")

        var request = Im_V1_GetMessagePreviewsRequest()
        request.syncDataStrategy = .tryLocal
        var previewIdsWrapper = Im_V1_GetMessagePreviewsRequest.PreviewPair()
        previewIdsWrapper.previewIds = previewIds
        request.messagePreviewMap = [sourceId: previewIdsWrapper]
        return client.sendAsyncRequest(request)
            .map { (response: Im_V1_GetMessagePreviewsResponse) -> [Rust.RichText.AnchorHangEntity] in
                if let list = response.previewEntities[sourceId]?.previewEntity.values {
                    return Array(list)
                }
                return []
            }
            .log(with: ctx) { "\($0.map(\.previewID).joined(separator: ","))" }
    }

    func generateAnchorHangEntity(by urlStr: UrlStr) -> Observable<Rust.RichText.AnchorHangEntity?> {
        var ctx = Self.generateContext()
        ctx.cmd = .generateURLPreviewEntity
        ctx.logReq("get anchor hang entity: \(urlStr)")

        var request = Im_V1_GenerateUrlPreviewEntityRequest()
        request.url = urlStr
        return client.sendAsyncRequest(request)
            .map { (response: Im_V1_GenerateUrlPreviewEntityResponse) in
                let entity = response.previewEntity
                guard
                    !entity.serverTitle.isEmpty
                        || !entity.sdkTitle.isEmpty
                        || !entity.serverIconKey.isEmpty
                        || !entity.sdkIconURL.isEmpty
                else {
                    return nil
                }
                return response.previewEntity
            }
            .log(with: ctx) { $0?.previewID ?? "entity is empty" }
    }

    func getPagingSubTasks(guid: String, count: Int32, token: String?) -> Observable<Rust.PagingSubTaskResponse> {
        var ctx = Self.generateContext()
        ctx.cmd = .getPagingSubTask
        ctx.logReq("get paging sub tasks guid: \(guid) count: \(count) token: \(token)")

        var request = Todo_V1_GetPagingSubTaskRequest()
        request.guid = guid
        request.count = count
        if let token = token {
            request.lastToken = token
        }
        return client.sendAsyncRequest(request).log(with: ctx) {
            "sub tasks count: \($0.subTasks.map { $0.guid }), hasMore: \($0.hasMore_p), token: \($0.lastToken)"
        }
    }

    func getTaskCenter() -> Observable<Rust.TaskCenterResponse> {
        var ctx = Self.generateContext()
        ctx.cmd = .getTaskCenter
        ctx.logReq("get task center")

        let request = Todo_V1_GetTaskCenterRequest()
        return client.sendAsyncRequest(request)
            .map { (res: Rust.TaskCenterResponse) -> Rust.TaskCenterResponse in
                let followedContainerID = res.containers.first(where: { $0.key == ContainerKey.followed.rawValue })?.guid
                var newRes = res
                newRes.views = res.views.map { view -> Rust.TaskView in
                    var newView = view
                    if view.containerGuid == followedContainerID {
                        newView.viewFilters.conditions = view.viewFilters.conditions.filter { condition in
                            if condition.fieldKey == FieldKey.completeStatus.rawValue ||
                                condition.fieldKey == FieldKey.follower.rawValue {
                                return true
                            }
                            return false
                        }
                    }
                    return newView
                }
                return newRes
            }
            .log(with: ctx) {
            """
            task center, containers: \($0.containers.map { $0.logInfo }),
            view ids: \($0.views.map { $0.guid }),
            section ids: \($0.sections.map { $0.guid }),
            refs: \($0.taskContainerRefs.logInfo)
            """
            }
    }

    func getOwnedSections(with taskGuid: String?) -> Observable<Rust.OwnedSectionRefRes> {
        var ctx = Self.generateContext()
        ctx.cmd = .getOwnedContainerTaskRefAndSections
        ctx.logReq("get owned sections guid: \(taskGuid ?? "")")

        var request = Todo_V1_GetOwnedContainerTaskRefAndSectionsRequest()
        if let taskGuid = taskGuid {
            request.todoGuid = taskGuid
        }
        return client.sendAsyncRequest(request).log(with: ctx) {
            "ref: \($0.ref.logInfo), containerId: \($0.containerGuid), sections: \($0.sections.count)"
        }
    }

    func searchTasks(by query: String) -> Observable<[Rust.Todo]> {
        var ctx = Self.generateContext()
        ctx.cmd = .searchTasks
        ctx.logReq("start search tasks. len = \(query.count)")

        var req = Todo_V1_SearchTaskRequest()
        req.query = query
        req.count = 100
        req.token = ""
        req.range = .canRead

        return client.sendAsyncRequest(req)
            .map { (res: Todo_V1_SearchTaskResponse) -> [Rust.Todo] in
                return res.todos
            }
            .log(with: ctx, transform: { todos in
                return "end search tasks. len = \(todos.count)"
            })
    }

}
