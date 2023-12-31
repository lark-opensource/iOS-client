//
//  TaskListApi.swift
//  Todo
//
//  Created by wangwanxin on 2022/11/10.
//

import RxSwift
import RustPB
import ServerPB
import LarkLocalizations

/// Task List 获取相关的 Api

protocol TaskListApi {

    /// 分页获取任务清单
    /// - Parameters:
    ///   - cursor: 启示位置
    ///   - count: 每页个数
    /// - Returns: result
    func getPagingTaskLists(by cursor: Int64?, count: Int, type: Rust.ArchivedType) -> Observable<Rust.TaskListRes>

    /// 获取任务清单中Container相关数据
    /// - Parameters:
    ///   - containerGuid: container id
    /// - Returns: result
    func getContainerMetaData(by containerGuid: String, needSection: Bool) -> Observable<Rust.ContainerMetaData>

    /// 获取任务清单中所有任务
    /// - Parameters:
    ///   - containerGuid: 任务清单
    ///   - view: view
    ///   - timeZone: 时区
    ///   - count: 数字
    /// - Returns: 首屏幕task+guids+refs
    func getTaskContainerGroupInfo(by containerGuid: String, view: Rust.TaskView, timeZone: TimeZone, count: Int) -> Observable<ListMetaData>

    /// 获取清单下任务
    /// - Parameters:
    ///   - containerGuid: 清单
    ///   - taskGuids: 任务ids
    /// - Returns: tasks+refs
    func getContainerTasks(by containerGuid: String, taskGuids: [String]) -> Observable<ListMetaData>

    /// 获取任务在清单的所属section  清单的全部 sections
    /// - Parameter taskGuid: 任务ID
    /// - Returns: sections
    func getSections(by taskGuid: String) -> Observable<Rust.RefSectionRes>

    /// 搜索清单
    /// - Parameter query: 条件
    /// - Returns: 返回
    func queryTaskList(by query: String) -> Observable<([Rust.TaskContainer], [String: Rust.SectionRefResult])>

    /// 更新TaskContainerRef
    /// - Parameters:
    ///   - new: new
    ///   - old: old
    /// - Returns: new
    func updateTaskContainerRef(new: Rust.ContainerTaskRef, old: Rust.ContainerTaskRef?) -> Observable<Rust.ContainerTaskRef>

    /// 新建、更新清单
    /// - Parameters:
    ///   - new: 新清单
    ///   - old: 旧清单(新建场景下传 nil)
    /// - Returns: ContainerMetaData
    func upsertContainer(new: Rust.TaskContainer, old: Rust.TaskContainer?) -> Observable<Rust.ContainerMetaData>

    /// 在分组中新建清单
    func createContainer(new: Rust.TaskContainer, with ref: Rust.TaskListSectionRef?) -> Observable<(Rust.TaskListSectionItem, Rust.ContainerMetaData)>

    /// 删除容器
    /// - Parameters:
    ///   - containerGuid: 容器
    ///   - removeNoOwner: 是否移除没有负责人的数据
    /// - Returns: null
    func deleteContainer(by containerGuid: String, removeNoOwner: Bool) -> Observable<Void>

    /// 获取清单协作信息
    func getPagingTaskListMembers(with taskListID: String, cursor: String?, count: Int) -> Observable<Rust.TaskListMembersRes>

    /// 增/删/改协作者权限
    func updateTaskListMember(with taskListID: String, updatedMembers: [Int64: Rust.EntityTaskListMember], isSendNote: Bool?, note: String?) -> Observable<Rust.UpdateTaskListMemberRes>

    /// 申请清单权限
    func applyTaskPermission(with taskListID: String, todoMemberRole: Rust.MemberRole, note: String?) -> Observable<Void>

    /// 根据过滤条件分页拉取清单相关数据接口
    func getPagingTaskListRelated(
        tab: Rust.TaskListTabFilter,
        status: Rust.TaskListStatusFilter,
        page: Rust.PageReq
    ) -> Observable<Rust.PagingTaskListRelatedRes>

    /// 增删改清单分组
    func upsertTaskListSection(with: Rust.TaskListSection) -> Observable<Rust.TaskListSection>

    /// 增删改清单ref
    func upsertTaskListSectionRefs(with containerGuid: String, refs: [Rust.TaskListSectionRef]) -> Observable<[Rust.TaskListSectionRef]>
    
    /// 任务动态，清单动态，全局动态
    func getPagingActvityRecords(with guid: String?, scene: Rust.ActivityScene, and pageReq: Rust.PageReq) -> Observable<Rust.ActivityRecordsRes>
}

extension RustApiImpl: TaskListApi {

    func getPagingTaskLists(by cursor: Int64?, count: Int, type: Rust.ArchivedType) -> Observable<Rust.TaskListRes> {
        var ctx = Self.generateContext()
        ctx.cmd = .getPagingTaskLists
        ctx.logReq("start by \(cursor ?? 0)-\(count)-\(type.rawValue)")

        var request = Todo_V1_GetPagingTaskListsRequest()
        request.count = Int32(count)
        request.archivedType = type
        if let cursor = cursor {
            request.lastToken = cursor
        }
        return client.sendAsyncRequest(request)
            .log(with: ctx) { "end with hasMore: \($0.hasMore_p), cursor: \($0.lastToken), list: \($0.taskLists.map(\.logInfo).joined(separator: ","))" }
    }

    func getContainerMetaData(by containerGuid: String, needSection: Bool) -> Observable<Rust.ContainerMetaData> {
        var ctx = Self.generateContext()
        ctx.cmd = .mgetTaskContainerMetaData
        ctx.logReq("start with \(containerGuid)")

        var req = Todo_V1_MGetTaskContainerMetaDataRequest()
        req.containerGuids = [containerGuid]
        req.needSections = needSection
        return client.sendAsyncRequest(req)
            .map { (res: Todo_V1_MGetTaskContainerMetaDataResponse) -> Rust.ContainerMetaData in
                if let metaData = res.metaData[containerGuid] {
                    return metaData
                }
                return .init()
            }
            .log(with: ctx) { "end with \($0.logInfo)" }
    }

    func getTaskContainerGroupInfo(by containerGuid: String, view: Rust.TaskView, timeZone: TimeZone, count: Int) -> Observable<ListMetaData> {
        var ctx = Self.generateContext()
        ctx.cmd = .getTaskContainerGroupInfo
        ctx.logReq("start with \(containerGuid) timeZone: \(timeZone), count: \(count)")

        var req = Todo_V1_GetTaskContainerGroupInfoRequest()
        req.containerGuid = containerGuid
        req.viewGroups = view.viewGroups
        req.viewSorts = view.viewSorts
        req.viewFilters = view.viewFilters
        req.timezone = timeZone.identifier
        // 低端机的情况下，仍然保持分页获取
        req.enableAllTask = !Utils.DeviceStatus().isLowDevice
        req.nextCount = Int32(count)

        return client.sendAsyncRequest(req)
            .map { (res: Todo_V1_GetTaskContainerGroupInfoResponse) -> ListMetaData in
                let firstSceenTasks = res.positionedTasks.map { $0.task }
                let firstSceenRefs = res.positionedTasks.map { $0.ref }
                var taskGuids = [String](), sections = [Rust.TaskSection]()
                // 默认分组
                sections.append(res.defaultSection)
                res.groupDataList.forEach { groupData in
                    taskGuids.append(contentsOf: groupData.taskSortedInfos.map(\.guid))
                    groupData.groupInfos.forEach { groupInfo in
                        if case .section(let section) = groupInfo.resource.resource, section.guid != res.defaultSection.guid {
                            sections.append(section)
                        }
                    }
                }
                let data = ListMetaData()
                data.sections = sections
                data.refs = firstSceenRefs
                data.tasks = firstSceenTasks
                data.taskGuids = taskGuids
                return data
            }
            .log(with: ctx) { "end with \($0.logInfo)" }

    }

    func getContainerTasks(by containerGuid: String, taskGuids: [String]) -> Observable<ListMetaData> {
        var ctx = Self.generateContext()
        ctx.cmd = .mgetServerContainerTasks
        ctx.logReq("start with \(containerGuid) and \(taskGuids)")

        var req = Todo_V1_MGetServerContainerTasksRequest()
        req.containerGuid = containerGuid
        req.taskGuids = taskGuids
        return client.sendAsyncRequest(req)
            .map { (res: Todo_V1_MGetServerContainerTasksResponse) -> ListMetaData in
                let data = ListMetaData()
                data.refs = res.tasks.map { $0.ref }
                data.tasks = res.tasks.map { $0.task }
                return data
            }
            .log(with: ctx) { "end with \($0.logInfo)" }
    }

    func getSections(by taskGuid: String) -> Observable<Rust.RefSectionRes> {
        var ctx = Self.generateContext()
        ctx.cmd = .getServerTaskRefAndSections
        ctx.logReq("start with \(taskGuid)")

        var req = Todo_V1_GetServerTaskRefAndSectionsRequest()
        req.taskGuid = taskGuid
        return client.sendAsyncRequest(req)
            .log(with: ctx) { "end by \($0.results.count)" }
    }

    func queryTaskList(by query: String) -> Observable<([Rust.TaskContainer], [String: Rust.SectionRefResult])> {
        var ctx = Self.generateContext()
        ctx.serverCmd = .searchTaskLists
        ctx.logReq("start with \(query)")

        var req = ServerPB_Todos_SearchTaskListsRequest()
        req.query = query
        req.scene = .editable
        req.count = 100

        return client.sendPassThroughAsyncRequest(req, serCommand: .searchTaskLists)
            .map { (res: ServerPB_Todos_SearchTaskListsResponse) -> ([Rust.TaskContainer], [String: Rust.SectionRefResult])  in
                var taskLists = [Rust.TaskContainer](), sectionRefs = [String: Rust.SectionRefResult]()
                res.metaData.forEach { metaData in
                    let taskListGuid = metaData.container.guid
                    let taskList: Rust.TaskContainer = {
                        var taskList = Rust.TaskContainer()
                        taskList.guid = metaData.container.guid
                        taskList.name = metaData.container.name
                        taskList.key = metaData.container.key
                        taskList.rank = metaData.container.rank
                        taskList.category = .init(rawValue: metaData.container.category.rawValue) ?? .unknown
                        taskList.currentUserJoinMilliTime = metaData.container.currentUserJoinMilliTime
                        taskList.deleteMilliTime = metaData.container.deleteMilliTime
                        taskList.currentUserPermission = {
                            var permission = Rust.ContainerPermission()
                            permission.permissions = metaData.container.currentUserPermission.permissions
                            return permission
                        }()
                        taskList.version = metaData.container.version
                        return taskList
                    }()
                    taskLists.append(taskList)

                    let sections = metaData.sections.map { (serverSection: ServerPB_Todo_entities_TaskSection) in
                        var section = Rust.TaskSection()
                        section.guid = serverSection.guid
                        section.rank = serverSection.rank
                        section.isDefault = serverSection.isDefault
                        section.containerID = serverSection.containerID
                        section.deleteMilliTime = serverSection.deleteMilliTime
                        section.name = serverSection.name
                        section.version = serverSection.version
                        return section
                    }

                    guard let defaultSection = metaData.sections.first(where: { $0.isDefault }) else {
                        return
                    }
                    var ref = Rust.ContainerTaskRef()
                    ref.taskGuid = ""
                    ref.sectionGuid = defaultSection.guid
                    ref.containerGuid = taskListGuid
                    ref.rank = Utils.Rank.defaultMinRank

                    sectionRefs[taskListGuid] = {
                        var sectionRef = Rust.SectionRefResult()
                        sectionRef.ref = ref
                        sectionRef.sections = sections
                        return sectionRef
                    }()

                }
                return (taskLists, sectionRefs)
            }
            .log(with: ctx) { "end query. taskListCnt: \($0.0.count), sectionRefs: \($0.1.count)" }
    }

    func updateTaskContainerRef(new: Rust.ContainerTaskRef, old: Rust.ContainerTaskRef?) -> Observable<Rust.ContainerTaskRef> {
        var ctx = Self.generateContext()
        ctx.cmd = .updateTaskContainerRef
        ctx.logReq("old: \(old?.logInfo), new: \(new.logInfo)")

        var req = Todo_V1_UpdateTaskContainerRefRequest()
        if let old = old {
            req.oldTaskContainerRef = old
        }
        req.newTaskContainerRef = new
        return client.sendAsyncRequest(req)
            .map { (res: Todo_V1_UpdateTaskContainerRefResponse) -> Rust.ContainerTaskRef in
                return res.taskContainerRef
            }
            .log(with: ctx) { "end with \($0.logInfo)" }
    }

    func upsertContainer(new: Rust.TaskContainer, old: Rust.TaskContainer?) -> Observable<Rust.ContainerMetaData> {
        var ctx = Self.generateContext()
        ctx.cmd = .upsertTaskContainer
        ctx.logReq("old: \(old?.logInfo ?? ""), new: \(new.logInfo)")

        var req = Todo_V1_UpsertTaskContainerRequest()
        if let old = old {
            req.oldContainer = old
        }
        req.newContainer = new
        return client.sendAsyncRequest(req)
            .map { (res: Todo_V1_UpsertTaskContainerResponse) -> Rust.ContainerMetaData in
                res.containerMetaData
            }
            .log(with: ctx) { "end with \($0.logInfo)" }
    }

    func createContainer(new: Rust.TaskContainer, with ref: Rust.TaskListSectionRef?) -> Observable<(Rust.TaskListSectionItem, Rust.ContainerMetaData)> {
        var ctx = Self.generateContext()
        ctx.cmd = .upsertTaskContainer
        ctx.logReq("start create container : \(new.logInfo), ref: \(ref?.logInfo)")

        var req = Todo_V1_UpsertTaskContainerRequest()
        req.newContainer = new
        if let ref = ref {
            req.containerSectionRefs = [ref]
        }
        return client.sendAsyncRequest(req)
            .map { (res: Todo_V1_UpsertTaskContainerResponse) -> (Rust.TaskListSectionItem, Rust.ContainerMetaData) in
                var item = Rust.TaskListSectionItem()
                item.container = res.containerMetaData.container
                item.refs = res.containerSectionRefs
                return (item, res.containerMetaData)
            }
            .log(with: ctx) { "end with \($0.0.logInfo), \($0.1.logInfo)" }
    }


    func deleteContainer(by containerGuid: String, removeNoOwner: Bool) -> Observable<Void> {
        var ctx = Self.generateContext()
        ctx.cmd = .deleteTaskContainer
        ctx.logReq("start with \(containerGuid) and \(removeNoOwner)")

        var req = Todo_V1_DeleteTaskContainerRequest()
        req.containerGuid = containerGuid
        req.removeNoOwnerTask = removeNoOwner
        return client.sendAsyncRequest(req)
            .map(Transform<Todo_V1_DeleteTaskContainerResponse>.toVoid())
            .log(with: ctx) { "end" }
    }

    func getPagingTaskListMembers(with taskListID: String, cursor: String?, count: Int) -> Observable<Rust.TaskListMembersRes> {
        var ctx = Self.generateContext()
        ctx.cmd = .getPagingTaskListMembers
        ctx.logReq("start with \(taskListID) cursor \(cursor) count \(count)")

        var req = Todo_V1_GetPagingTaskListMembersRequest()
        req.taskListGuid = taskListID
        req.count = Int64(count)
        if let cursor = cursor {
            req.lastToken = cursor
        }
        req.enableMemberType = [.user, .group, .docs]
        return client.sendAsyncRequest(req)
            .log(with: ctx) { "end with \($0.logInfo)" }
    }

    func updateTaskListMember(with taskListID: String, updatedMembers: [Int64: Rust.EntityTaskListMember], isSendNote: Bool?, note: String?) -> Observable<Rust.UpdateTaskListMemberRes> {
        var ctx = Self.generateContext()
        ctx.serverCmd = .updateTaskListMembers
        ctx.logReq("start taskListID:\(taskListID)")

        var req = ServerPB_Todos_UpdateTaskListMembersRequest()
        req.taskListGuid = taskListID
        req.updatedMember = updatedMembers
        if let isSendNote = isSendNote {
            req.sendNote = isSendNote
        } else {
            req.sendNote = true
        }
        if let note = note {
            req.note = note
        }
        return client.sendPassThroughAsyncRequest(req, serCommand: .updateTaskListMembers)
            .log(with: ctx) { _ in "end update task list member" }
    }

    func applyTaskPermission(with taskListID: String, todoMemberRole: Rust.MemberRole, note: String?) -> RxSwift.Observable<Void> {
        var ctx = Self.generateContext()
        ctx.serverCmd = .applyTaskPermission
        ctx.logReq("start with taskListID:\(taskListID) todoMemberRole:\(todoMemberRole) note:\(note)")

        var req = ServerPB_Todos_ApplyTaskListPermissionRequest()
        req.taskListGuid = taskListID
        // 此处申请的权限只包含编辑和阅读
        switch todoMemberRole {
        case .writer:
            req.role = .writer
        case .reader:
            req.role = .reader
        @unknown default:
            req.role = .reader
        }
        if let note = note {
            req.note = note
        }
        return client.sendPassThroughAsyncRequest(req, serCommand: .applyTaskPermission)
            .log(with: ctx) { "end apply task permission" }
    }
    
    func getPagingActvityRecords(with guid: String?, scene: Rust.ActivityScene, and pageReq: Rust.PageReq) -> Observable<Rust.ActivityRecordsRes> {
        var ctx = Self.generateContext()
        ctx.cmd = .getPagingActivityRecords
        ctx.logReq("start with guid: \(guid), pageReq: \(pageReq.logInfo)")
        
        var req = Todo_V1_GetPagingActivityRecordsRequest()
        req.sceneType = scene
        if let guid = guid {
            req.targetGuid = guid
        }
        req.param = pageReq
        req.languageType = LanguageManager.currentLanguage.sdkLanguageType
        return client.sendAsyncRequest(req)
            .log(with: ctx) { "end with count: \($0.activityRecords.count), pageRes: \($0.pageResult.logInfo)" }
    }

    // 根据过滤条件分页拉取清单相关数据接口
    func getPagingTaskListRelated(
        tab: Rust.TaskListTabFilter,
        status: Rust.TaskListStatusFilter,
        page: Rust.PageReq
    ) -> Observable<Rust.PagingTaskListRelatedRes> {
        var ctx = Self.generateContext()
        ctx.cmd = .getPagingTaskContainerRelatedData
        ctx.logReq("tasklist reated start with \(tab.rawValue), \(status.rawValue), page: \(page.logInfo)")

        var req = Todo_V1_GetPagingTaskContainerRelatedDataRequest()
        req.filter = {
            var filter = Todo_V1_TaskContainerFilter()
            filter.tabFilter = {
                var tabFilter = Todo_V1_TaskContainerFilter.TabFilter()
                tabFilter.tabCategory = tab
                return tabFilter
            }()
            filter.statusFilter = {
                var statusFilter = Todo_V1_TaskContainerFilter.StatusFilter()
                statusFilter.archiveCategory = status
                return statusFilter
            }()
            return filter
        }()
        req.dataCategories = [.containers, .sections, .sectionRefs]
        req.pageParam = page

        return client.sendAsyncRequest(req)
            .log(with: ctx) { "end with result \($0.logInfo)" }
    }

    func upsertTaskListSection(with section: Rust.TaskListSection) -> Observable<Rust.TaskListSection> {
        var ctx = Self.generateContext()
        ctx.cmd = .upsertTaskContainerSection
        ctx.logReq("start upsert tasklist section \(section.logInfo)")

        var req = Todo_V1_UpsertTaskContainerSectionRequest()
        req.containerSection = section
        return client.sendAsyncRequest(req)
            .map { (res: Todo_V1_UpsertTaskContainerSectionResponse) -> Rust.TaskListSection in
                return res.containerSection
            }
            .log(with: ctx) { "new tasklist section \($0.logInfo)" }
    }

    /// 增删改清单ref
    func upsertTaskListSectionRefs(with containerGuid: String, refs: [Rust.TaskListSectionRef]) -> Observable<[Rust.TaskListSectionRef]> {
        var ctx = Self.generateContext()
        ctx.cmd = .upsertTaskContainerSectionRefs
        ctx.logReq("start upsert tasklist section ref \(refs.map(\.logInfo)), in \(containerGuid)")

        var req = Todo_V1_UpsertTaskContainerSectionRefsRequest()
        req.containerGuid = containerGuid
        req.updatedRefs = refs
        return client.sendAsyncRequest(req)
            .map { (res: Todo_V1_UpsertTaskContainerSectionRefsResponse) -> [Rust.TaskListSectionRef] in
                return res.updatedRefs
            }
            .log(with: ctx) { "new tasklist section refs \($0.map(\.logInfo))" }
    }


}
