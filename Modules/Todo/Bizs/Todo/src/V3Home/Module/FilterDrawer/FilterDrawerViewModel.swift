//
//  FilterDrawerViewModel.swift
//  Todo
//
//  Created by baiyantao on 2022/8/17.
//

import Foundation
import UniverseDesignIcon
import RxSwift
import RxCocoa
import UIKit
import LarkContainer
import ThreadSafeDataStructure

final class FilterDrawerViewModel: UserResolverWrapper {

    // dependencies
    var userResolver: LarkContainer.UserResolver
    private let context: V3HomeModuleContext
    private let disposeBag = DisposeBag()
    @ScopedInjectedLazy private var listApi: TaskListApi?
    @ScopedInjectedLazy private var fetchApi: TodoFetchApi?
    @ScopedInjectedLazy private var listNoti: TaskListNoti?

    // view drivers
    let reloadNoti = PublishRelay<Void>()
    let loadMoreNoti = PublishRelay<Void>()
    let rxLoadMoreState = BehaviorRelay<ListLoadMoreState>(value: .none)

    // data
    private var sections = [FilterDrawerSectionData]()
    private lazy var taskListSection = initTaskListSection()

    private(set) var taskCenterMetaDatas: SafeDictionary<String, Rust.ContainerMetaData> = [:] + .readWriteLock
    private(set) var taskListContainers: SafeDictionary<String, Rust.TaskContainer> = [:] + .readWriteLock

    // internal state
    private var pageInfo: (cursor: Int64, hasMore: Bool) = (0, false)
    private var seletedContainerId: String?
    private let pageCount = 20
    private var loadState = LoadState.unarchivedPaging

    init(resolver: UserResolver, context: V3HomeModuleContext) {
        self.userResolver = resolver
        self.context = context
        guard !FeatureGating(resolver: resolver).boolValue(for: .organizableTaskList) else {
            return
        }
        initFechData()
        addListener()
    }

    private func initFechData() {
        switch context.scene {
        case .center:
            initFetchTaskCenter()
            initFetchTaskLists()
        case .onePage(let guid):
            initFetchMetaData(by: guid)
        }
    }

    private func initFetchTaskCenter() {
        // getAllTasks 后面需要移走
        guard let fetchApi = fetchApi else { return }
        Observable.zip(fetchApi.getTaskCenter(), fetchApi.getAllTasks())
            .take(1).asSingle()
            .subscribe(
                onSuccess: { [weak self] (res, tasks) in
                    guard let self = self else { return }
                    // taskCenterRes2MetaDataDic 必须setupPersistData之前。PersistData 依赖metaData这个数据
                    self.taskCenterMetaDatas.replaceInnerData(by: self.taskCenterRes2MetaDataDic(res))
                    let listMetaData = ListMetaData()
                    listMetaData.tasks = tasks
                    listMetaData.sections = res.sections
                    listMetaData.refs = res.taskContainerRefs.taskContainerRefs
                    self.context.bus.post(.setupPersistData(listMetaData))

                    // containers2TaskCenterSections 的构建需要在 seletedContainerId 这个之后。不然没有默认选中
                    if let owned = self.getTaskCenterMetaDataByKey(.owned) {
                        self.seletedContainerId = owned.container.guid
                        self.context.store.dispatch(.changeContainer(.metaData(owned)))
                    }
                    self.sections = self.makeSections(by: res)
                    self.reloadNoti.accept(void)
                }, onError: { [weak self] err in
                    self?.context.bus.post(.fetchContainerFailed)
                    FilterTab.logger.error("fetch TaskCenter failed. err: \(err)")
                })
            .disposed(by: disposeBag)
    }

    private func makeSections(by res: Rust.TaskCenterResponse) -> [FilterDrawerSectionData] {
        var sections = [FilterDrawerSectionData]()
        sections = containers2TaskCenterSections(containers: res.containers)
        sections.append({
            let guid = DrawerSectionKey.activityGuid
            let item = FilterDrawerNormalCellData(
                containerGuid: guid,
                icon: UDIcon.historyOutlined.ud.withTintColor(UIColor.ud.iconN2),
                title: I18N.Todo_Updates_Title,
                isSelected: seletedContainerId == guid
            )
            return FilterDrawerSectionData(sectionKey: .activity, items: [.normal(data: item)])
        }())
        sections.append(taskListSection)
        return sections.sorted(by: { $0.sectionKey.rawValue < $1.sectionKey.rawValue })
    }

    private func taskCenterRes2MetaDataDic(_ res: Rust.TaskCenterResponse) -> [String: Rust.ContainerMetaData] {
        let viewDic = Dictionary(grouping: res.views, by: { $0.containerGuid })
        let sectionDic = Dictionary(grouping: res.sections, by: { $0.containerID })
        var dic = [String: Rust.ContainerMetaData]()
        for container in res.containers {
            var metaData = Rust.ContainerMetaData()
            metaData.container = container
            metaData.views = viewDic[container.guid] ?? []
            metaData.sections = sectionDic[container.guid] ?? []
            dic[container.guid] = metaData
        }
        return dic
    }

    private func getTaskCenterMetaDataByKey(_ key: ContainerKey) -> Rust.ContainerMetaData? {
        if let data = taskCenterMetaDatas.values.first(where: {
            $0.container.key == key.rawValue
        }) {
            return data
        }
        return nil
    }

    private func containers2TaskCenterSections(
        containers: [Rust.TaskContainer]
    ) -> [FilterDrawerSectionData] {
        let containers = containers.filter { $0.category != .taskList }
        let dic = Dictionary(grouping: containers, by: { $0.category })
        return dic.compactMap { (category, containers) in
            guard !containers.isEmpty else { return nil }
            var headerData: FilterDrawerSectionHeaderData?
            var items = [FilterDrawerCellData]()

            // 快速访问
            if let title = category2HeaderTitle[category] {
                headerData = .init(title: title, isExpanded: true)
                items = containers.compactMap { container in
                    guard let cellTitle = FilterTab.containerKey2Title(container.key) else {
                        return nil
                    }
                    let data = FilterDrawerSubItemCellData(
                        containerGuid: container.guid,
                        title: cellTitle,
                        isSelected: seletedContainerId == container.guid
                    )
                    return .subItem(data: data)
                }
            }
            // 我负责的 + 我关注的
            else {
                assert(containers.count == 1)
                items = containers.compactMap { container in
                    guard let cellTitle = FilterTab.containerKey2Title(container.key),
                          let cellIcon = key2CellIcon[container.key] else {
                        return nil
                    }
                    let data = FilterDrawerNormalCellData(
                        containerGuid: container.guid,
                        icon: cellIcon,
                        title: cellTitle,
                        isSelected: seletedContainerId == container.guid
                    )
                    return .normal(data: data)
                }
            }
            return FilterDrawerSectionData(
                sectionKey: .init(category: category),
                headerData: headerData,
                items: items
            )
        }
    }

    private func initFetchTaskLists() {
        self.loadState = .unarchivedPaging // 重置状态
        let archivedType = loadState2ArchivedType(loadState)
        listApi?.getPagingTaskLists(by: nil, count: pageCount, type: archivedType)
            .take(1).asSingle()
            .subscribe(
                onSuccess: { [weak self] res in
                    guard let self = self else { return }
                    let taskLists = res.taskLists.filter { $0.isValid }
                    self.taskListContainers.replaceInnerData(by: Dictionary(
                        taskLists.map { ($0.guid, $0) },
                        uniquingKeysWith: { $1 }
                    ))
                    self.taskListSection.items = self.containers2taskListItems(taskLists)
                    self.pageInfo = (res.lastToken, res.hasMore_p)
                    self.rxLoadMoreState.accept(res.hasMore_p ? .hasMore : .noMore)

                    if !res.hasMore_p && archivedType == .notArchived {
                        self.loadState = .unarchivedDone(hasArchived: false)
                        self.checkHasArchived(hasArchived: false)
                    }
                    self.reloadNoti.accept(void)
                },
                onError: { err in
                    FilterTab.logger.error("initFetchTaskLists err: \(err)")
                }
            )
            .disposed(by: disposeBag)
    }

    private func checkHasArchived(hasArchived: Bool) {
        listApi?.getPagingTaskLists(by: nil, count: pageCount, type: .archived)
            .take(1).asSingle()
            .subscribe(
                onSuccess: { [weak self] res in
                    guard let self = self else { return }
                    FilterTab.logger.info("checkHasArchived: \(res.taskLists.isEmpty)")
                    let newHasArchived = !res.taskLists.isEmpty
                    if hasArchived != newHasArchived {
                        self.loadState = .unarchivedDone(hasArchived: newHasArchived)
                        self.reloadNoti.accept(void)
                    }
                },
                onError: { err in
                    FilterTab.logger.error("checkHasArchived err: \(err)")
                }
            )
            .disposed(by: disposeBag)
    }

    private func containers2taskListItems(_ containers: [Rust.TaskContainer]) -> [FilterDrawerCellData] {
        return containers.map { container in
            let archivedTime = container.archivedMilliTime
            let isArchived = container.isArchived
            let data = FilterDrawerSubItemCellData(
                containerGuid: container.guid,
                joinTime: container.currentUserJoinMilliTime,
                archivedTime: archivedTime,
                title: container.name,
                isSelected: seletedContainerId == container.guid,
                accessoryType: isArchived ? .archivedBtn : .moreBtn
            )
            return .subItem(data: data)
        }.sortedForTasklist()
    }

    private func initFetchMetaData(by containerId: String) {
        containerMetaData(by: containerId) { [weak self] metaData in
            guard let self = self else { return }
            self.taskListContainers.replaceInnerData(by: [metaData.container.guid: metaData.container])
            self.context.store.dispatch(.changeContainer(.metaData(metaData)))
        } onError: { [weak self] err in
            self?.context.bus.post(.fetchContainerFailed)
            FilterTab.logger.error("initFetchMetaData failed. err: \(err)")
        }
    }

    private func containerMetaData(by containerID: String, onSuccess: @escaping (Rust.ContainerMetaData) -> Void, onError: @escaping (Error) -> Void) {
        listApi?.getContainerMetaData(by: containerID, needSection: false)
            .observeOn(MainScheduler.asyncInstance)
            .take(1).asSingle()
            .subscribe(onSuccess: onSuccess, onError: onError)
            .disposed(by: disposeBag)
    }

    private func addListener() {
        context.store.rxValue(forKeyPath: \.sideBarItem)
            .distinctUntilChanged { $0?.container?.guid == $1?.container?.guid }
            .subscribe(onNext: { [weak self] item in
                guard let guid = item?.container?.guid else { return }
                self?.doReloadSelectedItem(with: guid)
            })
            .disposed(by: disposeBag)

        context.bus.subscribe { [weak self] event in
            guard let self = self else { return }
            switch event {
            case .changeContainerByKey(let key):
                guard let item = self.getTaskCenterMetaDataByKey(key) else { return }
                V3Home.Track.clickListContainer(with: item.container)
                self.context.store.dispatch(.changeContainer(.metaData(item)))
            case .refetchAllTask:
                self.initFechData()
            case .calculateInProgressCount(let handler):
                var dic = [Rust.TaskContainer: Rust.TaskView]()
                if let data = self.getTaskCenterMetaDataByKey(.owned),
                   let view = data.views.first(where: { $0.type == .table }) {
                    dic[data.container] = view
                }
                if let data = self.getTaskCenterMetaDataByKey(.followed),
                   let view = data.views.first(where: { $0.type == .table }) {
                    dic[data.container] = view
                }
                guard !dic.isEmpty, let countDic = handler(dic) else {
                    FilterTab.logger.error("in progress count is empty")
                    return
                }
                self.reloadCount(with: countDic)
            case .localUpdateTaskView(let containerGuid, let view):
                guard var metaData = self.taskCenterMetaDatas[containerGuid] else {
                    return
                }
                metaData.views = [view]
                self.taskCenterMetaDatas[containerGuid] = metaData
            default:
                break
            }
        }.disposed(by: disposeBag)

        listNoti?.rxTaskListUpdate
            .subscribe(onNext: { [weak self] (containers, isRefreshAll)  in
                guard let self = self  else { return }
                if isRefreshAll {
                    self.initFetchTaskLists()
                    return
                }
                self.appendToTaskLists(containers)
            })
            .disposed(by: disposeBag)
    }

    private func appendToTaskLists(_ containers: [Rust.TaskContainer]) {
        let needDeleteArchived = !loadState.isArchived
        FilterTab.logger.info("appendToTaskLists ids: \(containers.map { $0.guid }), deleteArchi: \(needDeleteArchived)")

        if case .unarchivedDone(let hasArchived) = loadState {
            if hasArchived {
                if containers.contains(where: { $0.isDeleted && $0.isArchived }) {
                    FilterTab.logger.info("appendToTaskLists checkHasArchived")
                    checkHasArchived(hasArchived: true)
                }
            } else {
                if containers.contains(where: { $0.isArchived }) {
                    FilterTab.logger.info("appendToTaskLists has Archived")
                    loadState = .unarchivedDone(hasArchived: true)
                }
            }
        }

        guard !containers.isEmpty else { return }
        var deletedMap = [String: Rust.TaskContainer]()
        var updateIds = Set<String>()
        var addIds = Set<String>()
        var updatePairs = [(old: Rust.TaskContainer, new: Rust.TaskContainer)]()
        let currentContainerID = context.store.state.container?.guid
        for container in containers {
            // 需要删除存档的前提下，删除掉已归档的 item
            if needDeleteArchived && container.isArchived {
                if let old = taskListContainers[container.guid] {
                    updatePairs.append((old: old, new: container))
                }
                deletedMap[container.guid] = container
                taskListContainers.removeValue(forKey: container.guid)
            }
            // delete 或者没有阅读权限的
            else if !container.isValid {
                deletedMap[container.guid] = container
                taskListContainers.removeValue(forKey: container.guid)
            }
            // update
            else if let old = taskListContainers[container.guid] {
                guard container.version >= old.version else { continue }
                updateIds.insert(container.guid)
                updatePairs.append((old: old, new: container))
                taskListContainers[container.guid] = container
            }
            // add
            else {
                addIds.insert(container.guid)
                taskListContainers[container.guid] = container
                // 如果推送来的是当前选中的 container，且本地没有存，也需要推送更新
                if container.guid == currentContainerID {
                    updatePairs.append((old: container, new: container))
                }
            }
        }
        updateTaskListItems(Set<String>(deletedMap.keys), updateIds, addIds)

        if let pair = updatePairs.first(where: { $0.old.guid == currentContainerID }) {
            currentConntainerChanged(old: pair.old, new: pair.new)
        }
        if let id = currentContainerID, deletedMap.keys.contains(id) {
            if let item = getTaskCenterMetaDataByKey(.owned) {
                guard let container = deletedMap[id], !container.isValid else { return }
                // cneter 场景下需要会到我负责的
                context.store.dispatch(.changeContainer(.metaData(item)))
                let toast = container.isDeleted ? I18N.Todo_ListCard_ListHasBeenDeleted_Empty : I18N.Todo_ListCard_NoPermission_Text
                context.bus.post(.containerUpdated(toast: toast))
            } else {
                // 独立页面需要刷新当前
                currentConntainerChanged(forceChange: id)
            }
        }

        // 新增的数据在center场景下不需要处理，但可以在独立页面需要
        if let id = currentContainerID, addIds.contains(id), case .onePage = context.scene {
            currentConntainerChanged(forceChange: id)
        }
    }

    /// 当前container接收到push后，需要按照权限变化做不同的操作
    private func currentConntainerChanged(forceChange containerID: String? = nil, old: Rust.TaskContainer? = nil, new: Rust.TaskContainer? = nil) {
        let action = { [weak self] (guid: String) in
            self?.containerMetaData(by: guid) { [weak self] metaData in
                guard let self = self else { return }
                self.context.store.dispatch(.changeContainer(.metaData(metaData)))
                // 有可能拉下来的 container 是最新的，且 sdk 漏掉推送了，这里补一下
                if let old = self.taskListContainers[metaData.container.guid], metaData.container.version > old.version {
                    self.appendToTaskLists([metaData.container])
                }
            } onError: { err in
                FilterTab.logger.error("updated container failed. err: \(err)")
            }
        }
        if let containerID = containerID {
            FilterTab.logger.info("force change container : \(containerID)")
            action(containerID)
            return
        }
        guard let new = new, let old = old else { return }
        FilterTab.logger.info("container permission updated, new: \(new.currentUserPermission), old \(old.currentUserPermission)")

        if !old.isTaskListOwner, new.isTaskListOwner {
            // 变成负责人需要toast
            action(new.guid)
            let text = I18N.Todo_TaskList_PermissionChange_Toast(I18N.Todo_TaskList_PermissionChangeAsOwner_Toast)
            context.bus.post(.containerUpdated(toast: text))
            return
        }

        if old.isReadOnly == new.isReadOnly, old.canEdit == new.canEdit {
            /// 权限没有发生变化, 比如只有名字发生变化
            action(new.guid)
            return
        }
        switch (old.isReadOnly, old.canEdit, new.isReadOnly, new.canEdit) {
        case (false, _, true, false), (_, true, true, false):
            // 无权限到阅读权限；编辑权限到阅读权限
            action(new.guid)
            let text = I18N.Todo_TaskList_PermissionChange_Toast(I18N.Todo_ListCard_GroupMembersCanView_Text)
            context.bus.post(.containerUpdated(toast: text))
        case (false, _, _, true), (true, _, _, true):
            // 无权限到编辑权限；阅读权限到编辑权限
            action(new.guid)
            let text = I18N.Todo_TaskList_PermissionChange_Toast(I18N.Todo_ListCard_GroupMembersCanEdit_Text)
            context.bus.post(.containerUpdated(toast: text))
        default: break
        }
    }

    private func updateTaskListItems(
        _ deleteIds: Set<String>,
        _ updateIds: Set<String>,
        _ addIds: Set<String>
    ) {
        FilterTab.logger.info("updateTaskListItems dids: \(deleteIds), uids: \(updateIds), aids: \(addIds)")
        if deleteIds.isEmpty && updateIds.isEmpty && addIds.isEmpty { return }

        var items = taskListSection.items

        if !deleteIds.isEmpty {
            items = items.filter { !deleteIds.contains($0.containerGuid) }
        }
        if !updateIds.isEmpty {
            for (index, item) in items.enumerated() {
                guard updateIds.contains(item.containerGuid),
                      let container = taskListContainers[item.containerGuid] else {
                    continue
                }
                items[index].reset(by: container)
            }
        }
        if !addIds.isEmpty {
            let addContainers: [Rust.TaskContainer] = addIds.compactMap { taskListContainers[$0] }
            items.append(contentsOf: containers2taskListItems(addContainers))
        }

        taskListSection.items = items.sortedForTasklist()
        let hasArchivedItem = items.contains(where: { $0.sortType == .archivedTime })
        if case .archivedDone = loadState, !hasArchivedItem {
            FilterTab.logger.info("updateTaskListItems no more Archived")
            loadState = .unarchivedDone(hasArchived: false)
        }
        self.reloadNoti.accept(void)
    }

    private func reloadCount(with dic: [String: String]) {
        for (section, sectionVal) in sections.enumerated() {
            for (row, item) in sectionVal.items.enumerated() {
                if case .normal(var data) = item,
                   let metaData = taskCenterMetaDatas[data.containerGuid],
                   let countText = dic[metaData.container.key] {
                    data.countText = countText
                    sections[section].items[row] = .normal(data: data)
                }
            }
        }
        reloadNoti.accept(void)
    }

    private func loadState2FooterData(_ state: LoadState) -> FilterDrawerSectionFooterData? {
        switch state {
        case .unarchivedPaging, .archivedPaging:
            return nil
        case .unarchivedDone(let hasArchived):
            return hasArchived ? .init(isExpanded: false) : nil
        case .archivedDone:
            return .init(isExpanded: true)
        }
    }

    private func loadState2ArchivedType(_ state: LoadState) -> Rust.ArchivedType {
        switch state {
        case .unarchivedPaging:
            return .notArchived
        case .unarchivedDone:
            assertionFailure()
            return .notArchived
        case .archivedPaging:
            return .archived
        case .archivedDone:
            assertionFailure()
            return .archived
        }
    }

    private func initTaskListSection() -> FilterDrawerSectionData {
        let headerData = FilterDrawerSectionHeaderData(
            title: I18N.Todo_List_Menu,
            isExpanded: true,
            hasAddBtn: true
        )
        return FilterDrawerSectionData(
            sectionKey: .taskList,
            headerData: headerData,
            footerData: nil
        )
    }
}

// MARK: - View Action

extension FilterDrawerViewModel {
    func doLoadMoreTaskLists() {
        guard pageInfo.hasMore else { return }
        let archivedType = loadState2ArchivedType(loadState)
        rxLoadMoreState.accept(.loading)
        listApi?.getPagingTaskLists(by: pageInfo.cursor, count: pageCount, type: archivedType)
            .take(1).asSingle()
            .subscribe(
                onSuccess: { [weak self] res in
                    guard let self = self else { return }
                    if !res.hasMore_p {
                        var needCheck = false
                        if archivedType == .notArchived {
                            self.loadState = .unarchivedDone(hasArchived: false)
                            self.checkHasArchived(hasArchived: false)
                            needCheck = true
                        } else if archivedType == .archived {
                            self.loadState = .archivedDone
                            needCheck = true
                        }

                        // sdk 的 hasMore 状态有问题，有可能上一次请求返回的 hasMore 是 true，但是下一次拉是空的
                        // 而归档按钮的刷新是依赖列表刷新的，列表为空的话就不会发刷新通知，这里单独发一次
                        if needCheck, res.taskLists.isEmpty {
                            self.reloadNoti.accept(void)
                        }
                    }

                    self.appendToTaskLists(res.taskLists)
                    self.pageInfo = (res.lastToken, res.hasMore_p)

                    if self.rxLoadMoreState.value != .none {
                        self.rxLoadMoreState.accept(res.hasMore_p ? .hasMore : .noMore)
                    }
                },
                onError: { [weak self] err in
                    self?.rxLoadMoreState.accept(.hasMore)
                    FilterTab.logger.error("loadMoreTaskLists err: \(err)")
                }
            )
            .disposed(by: disposeBag)
    }

    func doToggleArchivedBtn() {
        switch loadState {
        case .unarchivedPaging, .archivedPaging:
            assertionFailure()
        case .unarchivedDone(let hasArchived):
            guard hasArchived else {
                assertionFailure()
                return
            }
            FilterTab.logger.info("do expand archived list")
            HomeSidebar.Track.toggleArchivedList(currentIsExpanded: false)
            pageInfo = (0, true)
            loadState = .archivedPaging
            rxLoadMoreState.accept(.hasMore)
            loadMoreNoti.accept(void)
        case .archivedDone:
            HomeSidebar.Track.toggleArchivedList(currentIsExpanded: true)
            loadState = .unarchivedDone(hasArchived: true)
            let archivedContainers = taskListSection.items
                .filter { $0.sortType == .archivedTime }
                .compactMap { taskListContainers[$0.containerGuid] }
            FilterTab.logger.info("do fold archived list, count: \(archivedContainers.count)")
            appendToTaskLists(archivedContainers)
        }
    }

    func doToggleSection(_ section: Int) {
        guard safeCheck(section: section), var headerData = sections[section].headerData else { return }
        FilterTab.logger.info("doToggleSection, s:\(section), tc:\(headerData.title.count)")
        headerData.isExpanded = !headerData.isExpanded
        sections[section].headerData = headerData

        // 任务清单 section 且 展开状态
        if sections[section].sectionKey == .taskList, headerData.isExpanded {
            rxLoadMoreState.accept(pageInfo.hasMore ? .hasMore : .noMore)
        } else {
            rxLoadMoreState.accept(.none)
        }

        reloadNoti.accept(void)
    }

    func doSelect(at index: IndexPath) {
        guard safeCheck(indexPath: index) else { return }
        let containerGuid = sections[index.section].items[index.row].containerGuid
        doReloadSelectedItem(with: containerGuid)

        if taskListContainers[containerGuid] != nil {
            containerMetaData(by: containerGuid) { [weak self] metaData in
                HomeSidebar.Track.clickItem(with: metaData.container)
                self?.context.store.dispatch(.changeContainer(.metaData(metaData)))
            } onError: { err in
                FilterTab.logger.error("drawer fetch container meta data failed, err: \(err)")
            }
        } else if let metaData = taskCenterMetaDatas[containerGuid] {
            HomeSidebar.Track.clickItem(with: metaData.container)
            context.store.dispatch(.changeContainer(.metaData(metaData)))
        } else if DrawerSectionKey.activityGuid == containerGuid {
            HomeSidebar.Track.clickWholeActivity()
            context.store.dispatch(.changeContainer(.custom(.activity)))
        } else {
            assertionFailure()
        }
    }

    func doCreateTaskList(title: String, completion: @escaping (UserResponse<String?>) -> Void) {
        var container = Rust.TaskContainer()
        container.guid = UUID().uuidString.lowercased()
        container.name = title
        container.category = .taskList
        listApi?.upsertContainer(new: container, old: nil)
            .observeOn(MainScheduler.asyncInstance)
            .subscribe(
                onNext: { [weak self] data in
                    HomeSidebar.Track.finalCreateTasklist(with: container, and: true)
                    self?.appendToTaskLists([data.container])
                    self?.context.store.dispatch(.changeContainer(.metaData(data)))
                    completion(.success(I18N.Todo_TaskListRenameSaved_Toast))
                },
                onError: { err in
                    FilterTab.logger.error("doCreateTaskList err: \(err)")
                    completion(.failure(.init(error: err, message: I18N.Todo_common_ActionFailedTryAgainLater)))
                }
            )
            .disposed(by: disposeBag)
    }

    private func doReloadSelectedItem(with guid: String) {
        guard !guid.isEmpty, guid != seletedContainerId else { return }
        seletedContainerId = guid
        for (section, sectionVal) in sections.enumerated() {
            for (row, item) in sectionVal.items.enumerated() {
                if item.isSelected {
                    sections[section].items[row].isSelected = false
                }
                if item.containerGuid == guid {
                    sections[section].items[row].isSelected = true
                }
            }
        }
        reloadNoti.accept(void)
    }
}

// MARK: - UITableView

extension FilterDrawerViewModel {
    func numberOfSections() -> Int {
        return sections.count
    }

    func numberOfItems(in section: Int) -> Int? {
        guard safeCheck(section: section) else { return nil }
        let sectionData = sections[section]
        if let headerData = sectionData.headerData, !headerData.isExpanded {
            return 0
        } else {
            return sectionData.items.count
        }
    }

    func headerInfo(in section: Int) -> FilterDrawerSectionHeaderData? {
        guard safeCheck(section: section) else { return nil }
        return sections[section].headerData
    }

    func footerInfo(in section: Int) -> FilterDrawerSectionFooterData? {
        guard safeCheck(section: section),
              let headerData = sections[section].headerData,
              headerData.isExpanded,
              sections[section].sectionKey == .taskList else {
            return nil
        }
        return loadState2FooterData(loadState)
    }

    func cellInfo(in indexPath: IndexPath) -> FilterDrawerCellData? {
        guard safeCheck(indexPath: indexPath) else { return nil }
        return sections[indexPath.section].items[indexPath.row]
    }

    private func safeCheck(section: Int) -> Bool {
        guard section >= 0 && section < sections.count else {
            var text = "check section failed. section: \(section)"
            text += " sectionCount: \(sections.count)"
            assertionFailure(text)
            return false
        }
        return true
    }

    private func safeCheck(indexPath: IndexPath) -> Bool {
        let (section, row) = (indexPath.section, indexPath.row)
        guard section >= 0
                && section < sections.count
                && row >= 0
                && row < sections[section].items.count
        else {
            var text = "check indexPath failed. indexPath: \(indexPath)"
            text += " sectionCount: \(sections.count)"
            if section >= 0 && section < sections.count {
                text += " itemCount: \(sections[section].items.count)"
            }
            assertionFailure(text)
            return false
        }
        return true
    }
}

// MARK: - Others

extension FilterDrawerViewModel {
    enum LoadState: Equatable {
        case unarchivedPaging
        case unarchivedDone(hasArchived: Bool)
        case archivedPaging
        case archivedDone

        var isArchived: Bool {
            switch self {
            case .unarchivedPaging, .unarchivedDone:
                return false
            case .archivedPaging, .archivedDone:
                return true
            }
        }
    }

    private var category2HeaderTitle: [Rust.TaskContainer.Category: String] {
        [.savedSearchTasks: I18N.Todo_New_QuickAccess_TabTitle]
    }
    private var key2CellIcon: [String: UIImage] {
        [ContainerKey.owned.rawValue: UDIcon.memberOutlined.ud.withTintColor(UIColor.ud.iconN2),
         ContainerKey.followed.rawValue: UDIcon.subscribeAddOutlined.ud.withTintColor(UIColor.ud.iconN2)]
    }
}

enum DrawerSectionKey: Int {
    case owned = 1
    case followed
    case activity
    case savedSearch
    case taskList
    case unknown = 100

    init(category: Rust.TaskContainer.Category) {
        switch category {
        case .ownedTasks: self = .owned
        case .followedTasks: self = .followed
        case .savedSearchTasks: self = .savedSearch
        case .taskList: self = .taskList
        case .unknown: self = .unknown
        @unknown default: self = .unknown
        }
    }

    var title: String? {
        switch self {
        case .owned: return I18N.Todo_New_OwnedByMe_TabTitle
        case .followed: return I18N.Todo_New_SubscribedByMe_TabTitle
        case .activity: return I18N.Todo_Updates_Title
        case .savedSearch: return I18N.Todo_New_QuickAccess_TabTitle
        case .taskList: return I18N.Todo_List_Menu
        case .unknown: return nil
        }
    }

    static let activityGuid = UUID().uuidString
}

// 故意设计为 class
class FilterDrawerSectionData {

    var sectionKey: DrawerSectionKey
    var headerData: FilterDrawerSectionHeaderData?
    var footerData: FilterDrawerSectionFooterData?
    var items: [FilterDrawerCellData] = []

    init(sectionKey: DrawerSectionKey,
         headerData: FilterDrawerSectionHeaderData? = nil,
         footerData: FilterDrawerSectionFooterData? = nil,
         items: [FilterDrawerCellData] = []
    ) {
        self.sectionKey = sectionKey
        self.headerData = headerData
        self.footerData = footerData
        self.items = items
    }
}

enum FilterDrawerCellData {
    case normal(data: FilterDrawerNormalCellData)
    case subItem(data: FilterDrawerSubItemCellData)
}

extension FilterDrawerCellData {
    enum SortType: Hashable {
        case joinTime
        case archivedTime
    }

    var sortType: SortType {
        switch self {
        case .normal:
            assertionFailure()
            return .joinTime
        case .subItem(let data):
            return data.archivedTime > 0 ? .archivedTime : .joinTime
        }
    }

    var sortHelper: Int64 {
        guard case .subItem(let data) = self else { return 0 }
        switch sortType {
        case .joinTime:
            return data.joinTime
        case .archivedTime:
            return data.archivedTime
        }
    }

    var containerGuid: String {
        switch self {
        case .normal(let data): return data.containerGuid
        case .subItem(let data): return data.containerGuid
        }
    }

    var isSelected: Bool {
        get {
            switch self {
            case .normal(let data): return data.isSelected
            case .subItem(let data): return data.isSelected
            }
        }
        set {
            switch self {
            case .normal(var data):
                data.isSelected = newValue
                self = .normal(data: data)
            case .subItem(var data):
                data.isSelected = newValue
                self = .subItem(data: data)
            }
        }
    }

    var height: CGFloat {
        let (normalHeight, subItemHeight) = (CGFloat(48), CGFloat(44))
        switch self {
        case .normal: return normalHeight
        case .subItem: return subItemHeight
        }
    }

    mutating func reset(by container: Rust.TaskContainer) {
        assert(container.category == .taskList)
        switch self {
        case .normal:
            assertionFailure()
        case .subItem(var data):
            let archivedTime = container.archivedMilliTime
            let isArchived = container.isArchived
            data.containerGuid = container.guid
            data.joinTime = container.currentUserJoinMilliTime
            data.archivedTime = archivedTime
            data.title = container.name
            data.accessoryType = isArchived ? .archivedBtn : .moreBtn
            self = .subItem(data: data)
        }
    }
}

fileprivate extension Array where Element == FilterDrawerCellData {
    func sortedForTasklist() -> [FilterDrawerCellData] {
        let group = Dictionary(grouping: self) { $0.sortType }
        let joinTimeList = (group[.joinTime] ?? []).sorted(by: { $0.sortHelper > $1.sortHelper })
        let archivedTimeList = (group[.archivedTime] ?? []).sorted(by: { $0.sortHelper > $1.sortHelper })
        return joinTimeList + archivedTimeList
    }
}
