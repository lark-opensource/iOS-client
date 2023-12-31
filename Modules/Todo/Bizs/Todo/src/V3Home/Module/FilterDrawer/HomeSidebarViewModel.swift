//
//  HomeSidebarViewModel.swift
//  Todo
//
//  Created by wangwanxin on 2023/10/10.
//

import Foundation
import LarkContainer
import RxSwift
import RxCocoa
import LKCommonsLogging
import UniverseDesignIcon
import LarkDocsIcon
import LarkStorage

final class HomeSidebarViewModel: UserResolverWrapper {

    var userResolver: UserResolver
    var sections: [HomeSidebarSectionData] = []
    let rxListUpdate = BehaviorRelay(value: void)
    let logger = Logger.log(HomeSidebarViewModel.self, category: "Todo.HomeSidebar")

    private let context: V3HomeModuleContext
    private let disposeBag = DisposeBag()

    @ScopedInjectedLazy private var fetchApi: TodoFetchApi?
    @ScopedInjectedLazy private var listNoti: TaskListNoti?
    @ScopedInjectedLazy private var listApi: TaskListApi?

    private var cacheData: HomeSidebarMetaData?
    // 当前选中的item
    private var curSelectedGuid: String?

    // kv
    private lazy var tasklistViewStore = KVStores.udkv(
        space: .user(id: userResolver.userID),
        domain: Domain.biz.todo
    )

    init(resolver: UserResolver, context: V3HomeModuleContext) {
        self.userResolver = resolver
        self.context = context
        guard FeatureGating(resolver: resolver).boolValue(for: .organizableTaskList) else {
            return
        }
        fechData()
        addEventListener()
    }

    private func fechData() {
        switch context.scene {
        case .center:
            fetchInitializationCenterData()
        case .onePage(let guid):
            fetchInitilaztionTaskList(by: guid)
        }
    }

    private func fetchInitializationCenterData() {
        // getAllTasks 放这里只是为了能一起组合成ListMetaData
        guard let fetchApi = fetchApi else { return }
        Observable.zip(fetchApi.getTaskCenter(), fetchApi.getAllTasks())
            .take(1).asSingle()
            .subscribe(
                onSuccess: { [weak self] (res, tasks) in
                    guard let self = self else { return }
                    self.addPushListerner()
                    self.cacheData = HomeSidebarMetaData(with: res)
                    self.sections = self.makeViewData(from: res)
                    let listMetaData = ListMetaData()
                    listMetaData.tasks = tasks
                    listMetaData.sections = res.sections
                    listMetaData.refs = res.taskContainerRefs.taskContainerRefs
                    self.context.bus.post(.setupPersistData(listMetaData))
                    // set default current selected item
                    if let owedMetaData = self.cacheData?.getDefaultMetaData(by: .owned) {
                        self.curSelectedGuid = owedMetaData.container.guid
                        self.context.store.dispatch(.changeContainer(.metaData(owedMetaData)))
                    }
                    self.rxListUpdate.accept(void)
                }, onError: { [weak self] err in
                    self?.context.bus.post(.fetchContainerFailed)
                    self?.logger.error("fetch TaskCenter failed. err: \(err)")
                })
            .disposed(by: disposeBag)
    }

    private func fetchInitilaztionTaskList(by taskListGuid: String) {
        taskListMetaData(by: taskListGuid) { [weak self] metaData in
            guard let self = self else { return }
            self.addOnePageListener()
            let newMetaData = self.replaceLocalView(from: metaData)
            self.context.store.dispatch(.changeContainer(.metaData(newMetaData)))
        } onError: { [weak self] error in
            self?.context.bus.post(.fetchContainerFailed)
            self?.logger.error("fetch tasklist meta data failed. \(error)")
        }
    }

    private func addPushListerner() {
        addOnePageListener()
        listNoti?.rxTaskListSectionUpdate
            .subscribe(onNext: { [weak self] sections in
                guard let self = self else { return }
                self.receiveSection(sections)
            })
            .disposed(by: disposeBag)
        listNoti?.rxTaskListSectionRefUpdate
            .subscribe(onNext: { [weak self] sectionItems  in
                guard let self = self  else { return }
                self.receiveSectionItems(sectionItems)
            })
            .disposed(by: disposeBag)
    }

    private func addEventListener() {
        // 侧边栏选中发生变化
        context.store.rxValue(forKeyPath: \.sideBarItem)
            .observeOn(MainScheduler.asyncInstance)
            .distinctUntilChanged { $0?.container?.guid == $1?.container?.guid }
            .subscribe(onNext: { [weak self] item in
                guard let guid = item?.container?.guid else { return }
                self?.setSelected(guid)
            })
            .disposed(by: disposeBag)

        context.bus.subscribe { [weak self] event in
            guard let self = self else { return }
            switch event {
            case .changeContainerByKey(let key):
                guard let item = self.cacheData?.getDefaultMetaData(by: key) else { return }
                V3Home.Track.clickListContainer(with: item.container)
                self.context.store.dispatch(.changeContainer(.metaData(item)))
            case .refetchAllTask:
                self.fechData()
            case .calculateInProgressCount(let handler):
                guard case .center = self.context.scene else { return }
                var dic = [Rust.TaskContainer: Rust.TaskView]()
                if let data = self.cacheData?.getDefaultMetaData(by: .owned),
                   let view = data.views.first(where: { $0.type == .table }) {
                    dic[data.container] = view
                }
                if let data = self.cacheData?.getDefaultMetaData(by: .followed),
                   let view = data.views.first(where: { $0.type == .table }) {
                    dic[data.container] = view
                }
                guard !dic.isEmpty else {
                    self.logger.error("side bar count is empty")
                    return
                }
                guard let countDic = handler(dic) else {
                    self.logger.error("handler is empty")
                    return
                }
                self.setTailingCount(with: countDic)
            case .localUpdateTaskView(let containerGuid, let view):
                self.cacheData?.updateDefaultMetaDataView(view, in: containerGuid)
                if let data = try? view.serializedData() {
                    self.tasklistViewStore.set(data, forKey: containerGuid)
                } else {
                    self.logger.error("serialize view data failed")
                }
            default:
                break
            }
        }.disposed(by: disposeBag)
    }

    private func addOnePageListener() {
        listNoti?.rxTaskListUpdate
            .subscribe(onNext: { [weak self] (containers, _)  in
                guard let self = self  else { return }
                self.receiveTaskList(containers)
            })
            .disposed(by: disposeBag)
    }

    private func taskListMetaData(
        by taskListGuid: String,
        onSuccess: @escaping (Rust.ContainerMetaData) -> Void,
        onError: @escaping (Error) -> Void
    ) {
        listApi?.getContainerMetaData(by: taskListGuid, needSection: false)
            .observeOn(MainScheduler.asyncInstance)
            .take(1).asSingle()
            .subscribe(onSuccess: onSuccess, onError: onError)
            .disposed(by: disposeBag)
    }

    private func replaceLocalView(from metaData: Rust.ContainerMetaData) -> Rust.ContainerMetaData {
        var newMetaData = metaData
        if let data: Data = self.tasklistViewStore.value(forKey: metaData.container.guid),
           let storeView = try? Rust.TaskView(serializedData: data) {
            newMetaData = HomeSidebarMetaData.replaceView(storeView, in: metaData)
        }
        return newMetaData
    }

    private func makeViewData(from res: Rust.TaskCenterResponse) -> [HomeSidebarSectionData] {
        var viewData = [HomeSidebarSectionData]()
        // 我负责的+我关注的+动态
        do {
            let ownedAndFollowed = res.containers.compactMap { container -> HomeSidebarItemData? in
                guard let title = FilterTab.containerKey2Title(container.key),
                      let icon = HomeSidebarSectionData.containerKeyToIcon[container.key] else {
                    return nil
                }
                return HomeSidebarItemData(
                    identifier: container.guid,
                    leadingIconBuilder: iconBuild(by: icon),
                    userResolver: userResolver,
                    title: title,
                    isSelected: curSelectedGuid == container.guid
                )
            }
            let activityGuid = HomeSidebarItemData.Config.activityGuid
            let activity = HomeSidebarItemData(
                identifier: activityGuid,
                leadingIconBuilder: iconBuild(by: UDIcon.historyOutlined.ud.withTintColor(UIColor.ud.iconN2)),
                userResolver: userResolver,
                title: SideBarItem.CustomCategory.activity.title ?? "",
                isSelected: curSelectedGuid == activityGuid
            )
            var section = HomeSidebarSectionData()
            section.items = {
                var items = [HomeSidebarItemData]()
                items.append(contentsOf: ownedAndFollowed)
                items.append(activity)
                return items
            }()
            viewData.append(section)
        }
        // 快速访问
        do {
            var section = HomeSidebarSectionData()
            let category = HomeSidebarHeaderData.Category.savedSearch
            section.header = HomeSidebarHeaderData(
                category: category,
                leadingIcon: category.leadingIcon,
                title: I18N.Todo_New_QuickAccess_TabTitle
            )
            section.items = res.containers
                .filter { container in
                    // 过滤掉我负责的+我关注的
                    guard HomeSidebarSectionData.containerKeyToIcon[container.key] == nil else {
                        return false
                    }
                    return true
                }
                .compactMap { container -> HomeSidebarItemData? in
                guard let title = FilterTab.containerKey2Title(container.key) else { return nil }
                return HomeSidebarItemData(
                    identifier: container.guid,
                    category: .subItem(.simple),
                    title: title,
                    isSelected: curSelectedGuid == container.guid
                )
            }
            viewData.append(section)
        }
        // 协作清单
        do {
            var section = HomeSidebarSectionData()
            let category = HomeSidebarHeaderData.Category.taskLists
            let guid = HomeSidebarHeaderData.Config.taskListsGuid
            section.header = HomeSidebarHeaderData(
                identifier: guid,
                category: category,
                leadingIcon: category.leadingIcon,
                title: SideBarItem.CustomCategory.taskLists(tab: .taskContainerAll, isArchived: false).title ?? "",
                tailingIcon: category.tailingIcon,
                isSelected: curSelectedGuid == guid
            )
            section.footer = HomeSidebarFooterData(isHidden: true)
            viewData.append(section)
        }
        //清单分组
        do {
            if let tasklistSections = makeTasklistSection(by: res.taskContainerSections, and: res.containerSectionItems) {
                viewData.append(contentsOf: tasklistSections)
            }
        }
        // 新建分组
        do {
            var sectionData = HomeSidebarSectionData()
            sectionData.header = {
                let category = HomeSidebarHeaderData.Category.add
                return HomeSidebarHeaderData(
                    identifier: HomeSidebarHeaderData.Config.addSectionGuid,
                    category: category,
                    leadingIcon: category.leadingIcon,
                    title: I18N.Todo_TaskList_NewSection_Button
                )
            }()
            viewData.append(sectionData)
        }
        return viewData
    }

    private func iconBuild(by icon: UIImage, and container: Rust.TaskContainer? = nil) -> IconBuilder {
        return IconBuilder(
            bizIconType: .iconInfo(
                iconType: Int(container?.iconInfo.type ?? 0),
                iconKey: container?.iconInfo.key ?? "",
                textColor: nil
            ),
            iconExtend: .init(
                shape: .SQUARE,
                placeHolderImage: icon
            )
        )
    }

    private func makeTasklistSection(by sections: [Rust.TaskListSection]?, and items: [Rust.TaskListSectionItem]?) -> [HomeSidebarSectionData]? {
        guard let sections = sections, let items = items else { return nil }

        var sectionDatas = sections
            .map { section -> HomeSidebarSectionData in
                var sectionData = HomeSidebarSectionData()
                let category = HomeSidebarHeaderData.Category.section(section)
                if !section.isDefault {
                    // 非默认清单才有分组
                    sectionData.header = {
                        return HomeSidebarHeaderData(
                            identifier: section.guid,
                            category: category,
                            leadingIcon: category.leadingIcon,
                            title: section.displayName,
                            tailingIcon: category.tailingIcon,
                            isCollapsed: cacheData?.getCollapsed(section.guid) ?? false
                        )
                    }()
                } else {
                    sectionData.header = HomeSidebarHeaderData(category: category)
                }
                sectionData.items = {
                    var items = items
                        .compactMap { item -> HomeSidebarItemData? in
                            guard let ref = item.validRef(by: section.guid) else {
                                return nil
                            }
                            let isArchived = item.container.isArchived
                            return HomeSidebarItemData(
                                identifier: item.guid,
                                category: section.isDefault ? .subItem(.withoutSection(ref: ref)) : .subItem(.inSection(ref: ref, isLastItem: false)),
                                leadingIconBuilder: iconBuild(by: UDIcon.getIconByKey(.tasklistOutlined, iconColor: UIColor.ud.iconN3), and: item.container),
                                userResolver: userResolver,
                                isDefaultIcon: item.container.iconInfo.type == 0,
                                title: item.container.name,
                                accessory: .icon(
                                    archived: isArchived ? HomeSidebarItemData.Category.tailingIcon(true) : nil,
                                    more: HomeSidebarItemData.Category.tailingIcon(false)
                                ),
                                isSelected: curSelectedGuid == item.guid
                            )
                        }
                        .sorted { s1, s2 in
                            guard let ref1 = s1.category.ref, let ref2 = s2.category.ref else { return false }
                            return ref1.rank < ref2.rank
                        }
                    // 标记最后一个，UI上特殊一些
                    if var last = items.popLast() {
                        if case .subItem(let type) = last.category,
                           case .inSection(let ref, _) = type {
                            last.category = .subItem(.inSection(ref: ref, isLastItem: true))
                        }
                        items.append(last)
                    }
                    return items
                }()
                return sectionData
            }
            .sorted { s1, s2 in
                return HomeSidebarSectionData.customSectionSorter(s1, s2)
            }
        if let defaultSection = sectionDatas.first(where: { $0.header.sectionRawData?.isDefault ?? false }) {
            sectionDatas.removeAll(where: { $0.header.sectionRawData?.isDefault ?? false })
            sectionDatas.insert(defaultSection, at: 0)
        }
        return sectionDatas
    }

}

extension HomeSidebarViewModel {

    private func receiveSection(_ sections: [Rust.TaskListSection]) {
        guard !sections.isEmpty else { return }
        cacheData?.updateTasklistSection(sections)
        let tuple = cacheData?.getTasklistData()
        let newSections = makeTasklistSection(by: tuple?.0, and: tuple?.1)
        DispatchQueue.main.async { [weak self] in
            // 替换UI，刷新
            self?.replaceUISections(with: newSections)
        }
    }

    private func receiveSectionItems(_ newItems: [Rust.TaskListSectionItem]) {
        guard !newItems.isEmpty else { return }
        cacheData?.updateTasklistSectionItem(newItems)
        let tuple = cacheData?.getTasklistData()
        let newSections = makeTasklistSection(by: tuple?.0, and: tuple?.1)
        DispatchQueue.main.async { [weak self] in
            // 替换UI，刷新
            self?.replaceUISections(with: newSections)
            if let selectedGuid = self?.curSelectedGuid {
                // 由于转为主线程操作，有时候rxValue(forKeyPath: \.sideBarItem)会比它快导致没有选中
                // 这里额外补一次选中
                self?.setSelected(selectedGuid)
            }
        }
    }

    private func receiveTaskList(_ containers: [Rust.TaskContainer]) {
        guard !containers.isEmpty else { return }
        if containers.count < Utils.Logger.limmit {
            logger.info("receive new tasklist \(containers.map(\.logInfo))")
        }
        let oldContainers = cacheData?.getTasklistData().1
        cacheData?.updateTasklistContainer(containers)
        let tuple = cacheData?.getTasklistData()
        let newSections = makeTasklistSection(by: tuple?.0, and: tuple?.1)
        DispatchQueue.main.async { [weak self] in
            // 替换UI，刷新
            self?.replaceUISections(with: newSections)
            // 只有在清单下才需要处理
            guard let container = self?.context.store.state.container, container.isTaskList else {
                return
            }
            // 当前页面的数据
            let curContainerGuid = container.guid
            let oldContainer = oldContainers?.first(where: { $0.container.guid == curContainerGuid })?.container
            self?.handleContinerPush(curContainerGuid, with: oldContainer)
        }
    }

    private func replaceUISections(with newSections: [HomeSidebarSectionData]?) {
        // 替换UI，刷新
        if let start = sections.firstIndex(where: { $0.header.category.isTaskLists }),
           let end = sections.firstIndex(where: { $0.header.category.isAdd }),
           end >= (start + 1), let newSections = newSections {
            sections.replaceSubrange((start + 1)..<end, with: newSections)
            rxListUpdate.accept(void)
        }
    }

    private func handleContinerPush(_ curContainerGuid: String?, with oldContainer: Rust.TaskContainer?) {
        guard let curContainerGuid = curContainerGuid else { return }
        if let new = cacheData?.getTaskListItem(curContainerGuid)?.container {
            if !new.isValid {
                // 无权限
                setInvalidContainer(curContainerGuid, isDeleted: false)
                return
            }
            guard let old = oldContainer, new.version > old.version else { return }
            logger.info("permission updated. new\(new.currentUserPermission), old \(old.currentUserPermission)")
            if !old.isTaskListOwner, new.isTaskListOwner {
                // 变成负责人需要toast
                forceUpdateTasklist(new.guid)
                let text = I18N.Todo_TaskList_PermissionChange_Toast(I18N.Todo_TaskList_PermissionChangeAsOwner_Toast)
                context.bus.post(.containerUpdated(toast: text))
                return
            }

            if old.isReadOnly == new.isReadOnly, old.canEdit == new.canEdit {
                /// 权限没有发生变化, 比如只有名字发生变化
                forceUpdateTasklist(new.guid)
                return
            }
            switch (old.isReadOnly, old.canEdit, new.isReadOnly, new.canEdit) {
            case (false, _, true, false), (_, true, true, false):
                // 无权限到阅读权限；编辑权限到阅读权限
                forceUpdateTasklist(new.guid)
                let text = I18N.Todo_TaskList_PermissionChange_Toast(I18N.Todo_ListCard_GroupMembersCanView_Text)
                context.bus.post(.containerUpdated(toast: text))
            case (false, _, _, true), (true, _, _, true):
                // 无权限到编辑权限；阅读权限到编辑权限
                forceUpdateTasklist(new.guid)
                let text = I18N.Todo_TaskList_PermissionChange_Toast(I18N.Todo_ListCard_GroupMembersCanEdit_Text)
                context.bus.post(.containerUpdated(toast: text))
            default: break
            }
        } else {
            setInvalidContainer(curContainerGuid, isDeleted: true)
            // 删除
            if let ownedItem = cacheData?.getDefaultMetaData(by: .owned) {
                // cneter 场景下需要会到我负责的, 只有center才会有default meta
                context.store.dispatch(.changeContainer(.metaData(ownedItem)))
                context.bus.post(.containerUpdated(toast: I18N.Todo_ListCard_ListHasBeenDeleted_Empty))
            } else {
                forceUpdateTasklist(curContainerGuid)
            }
        }
    }

    private func setInvalidContainer(_ containerGuid: String?, isDeleted: Bool) {
        // 删除
        if let ownedItem = cacheData?.getDefaultMetaData(by: .owned) {
            // cneter 场景下需要会到我负责的, 只有center才会有default meta
            context.store.dispatch(.changeContainer(.metaData(ownedItem)))
            let toast = isDeleted ? I18N.Todo_ListCard_ListHasBeenDeleted_Empty : I18N.Todo_ListCard_NoPermission_Text
            context.bus.post(.containerUpdated(toast: toast))
        } else {
            forceUpdateTasklist(containerGuid)
        }
        if isDeleted, let containerGuid = containerGuid {
            logger.info("remove local value for \(containerGuid)")
            tasklistViewStore.removeValue(forKey: containerGuid)
        }
    }

    private func forceUpdateTasklist(_ containerGuid: String?) {
        guard let containerGuid = containerGuid else { return }
        logger.info("force update container \(containerGuid)")
        taskListMetaData(by: containerGuid) { [weak self] metaData in
            guard let self = self else { return }
            self.context.store.dispatch(.changeContainer(.metaData(metaData)))
            // 有可能拉下来的 container 是最新的，且 sdk 漏掉推送了，这里补一下
            if let oldItem = self.cacheData?.getTaskListItem(containerGuid), metaData.container.version > oldItem.container.version {
                self.receiveTaskList([metaData.container])
            }
        } onError: { [weak self] error in
            self?.logger.error("upate container failed. \(error)")
        }
    }

    private func setTailingCount(with dic: [String: String]) {
        for (key, value) in dic {
            if let containerKey = ContainerKey(rawValue: key), let metaData = cacheData?.getDefaultMetaData(by: containerKey) {
                outLoop: for (section, sectionData) in sections.enumerated() {
                    for (row, item) in sectionData.items.enumerated() {
                        if item.identifier == metaData.container.guid {
                            sections[section].items[row].accessory = .count(value)
                            break outLoop
                        }
                    }
                }
            }
        }
        rxListUpdate.accept(void)
    }
}

extension HomeSidebarViewModel {

    func needMaskItem(at item: HomeSidebarItemData) -> (corners: CACornerMask, cornerSize: CGSize) {
        // 非默认分组类型才需要标记
        guard case .subItem(let type) = item.category, case .inSection(_, let isLastItem) = type, isLastItem else {
            return ([], .zero)
        }
        return (
            [.layerMinXMaxYCorner, .layerMaxXMaxYCorner],
            CGSize(
                width: HomeSidebarItemData.Config.cornerRadius,
                height: HomeSidebarItemData.Config.cornerRadius
            )
        )
    }

    func needMaskHeader(at header: HomeSidebarHeaderData, with itemsIsEmpty: Bool) -> (corners: CACornerMask, cornerSize: CGSize) {
        guard header.category.isSection else {
            return ([], .zero)
        }
        var corners: CACornerMask = []
        corners.insert([.layerMinXMinYCorner, .layerMaxXMinYCorner])
        if header.isCollapsed || itemsIsEmpty {
            corners.insert([.layerMinXMaxYCorner, .layerMaxXMaxYCorner])
        }
        return (
            corners,
            CGSize(
                width: HomeSidebarItemData.Config.cornerRadius,
                height: HomeSidebarItemData.Config.cornerRadius
            )
        )
    }

    func doSelectItem(at index: IndexPath, completion: (() -> Void)? = nil) {
        guard let (section, row) = Utils.safeCheckIndexPath(at: index, with: sections) else {
            logger.info("did select sidebar item failed")
            return
        }
        let item = sections[section].items[row], guid = item.identifier
        guard guid != curSelectedGuid else {
            logger.info("did tap selected item")
            completion?()
            return
        }
        let lastGuid = curSelectedGuid
        setSelected(guid)
        // post event
        if item.category.isTaskListItem {
            // 清单数据
            // 先等 UI 刷新一下再退出
            let time = 0.1
            DispatchQueue.main.asyncAfter(deadline: .now() + time) {
                completion?()
            }
            taskListMetaData(by: guid) { [weak self] metaData in
                guard let self = self else { return }
                var newMetaData = self.replaceLocalView(from: metaData)
                HomeSidebar.Track.clickItem(with: newMetaData.container)
                self.context.store.dispatch(.changeContainer(.metaData(newMetaData)))
            } onError: { [weak self] err in
                if let lastGuid = lastGuid {
                    self?.setSelected(lastGuid)
                }
                self?.logger.error("fetch tasklist meta data failed. error \(err)")
            }
        } else {
            if let metaData = cacheData?.getDefaultMetaData(by: guid) {
                HomeSidebar.Track.clickItem(with: metaData.container)
                context.store.dispatch(.changeContainer(.metaData(metaData)))
                completion?()
            } else if guid == HomeSidebarItemData.Config.activityGuid {
                HomeSidebar.Track.clickWholeActivity()
                context.store.dispatch(.changeContainer(.custom(.activity)))
                completion?()
            } else {
                V3Home.assertionFailure()
            }
        }
    }

    func doTapSectionHeader(at indexPath: IndexPath, completion: ((HomeSidebarHeaderData.Category?) -> Void)? = nil) {
        guard let section = Utils.safeCheckSection(in: indexPath.section, with: sections) else { return }
        let header = sections[section].header
        switch header.category {
        case .savedSearch, .section:
            sections[section].header.isCollapsed = !header.isCollapsed
            cacheData?.setSection(header.identifier, isCollapsed: !header.isCollapsed)
            rxListUpdate.accept(void)
        case .taskLists:
            guard header.identifier != curSelectedGuid else {
                completion?(nil)
                return
            }
            HomeSidebar.Track.clickOrganizableTasklist()
            setSelected(header.identifier)
            context.store.dispatch(.changeContainer(.custom(.taskLists(tab: .taskContainerAll, isArchived: false))))
            completion?(nil)
        case .add:
            completion?(.add)
        default: break
        }

    }

    func getCreateSectionInput(_ text: String?) -> PaddingTextField.TextFieldInput {
        let isEmpty = text?.isEmpty ?? true
        return PaddingTextField.TextFieldInput(
            text: isEmpty ? nil : text,
            title: isEmpty ? I18N.Todo_TaskList_NewSection_Title : I18N.Todo_TaskListSection_Rename_DropDown_Button,
            placeholder: I18N.Todo_TaskList_NewSection_SectionName_Placeholder
        )
    }

    func getDefaultSection() -> Rust.TaskListSection? {
        return cacheData?.getTasklistData().0?.first(where: { $0.isDefault })
    }

    func getFirstItemRef(in sectionGuid: String) -> Rust.TaskListSectionRef? {
        return cacheData?.getTasklistData().1?
            .compactMap({ item in
                return item.validRef(by: sectionGuid)
            })
            .min(by: { $0.rank < $1.rank })
    }

    func getLastSection() -> Rust.TaskListSection? {
        let sections = cacheData?.getTasklistData().0?.sorted(by: { $0.rank < $1.rank })
        return sections?.last
    }

    func getNewSection(from last: Rust.TaskListSection?) -> Rust.TaskListSection? {
        var newSection = Rust.TaskListSection()
        newSection.guid = UUID().uuidString.lowercased()
        if let last = last {
            newSection.rank = Utils.Rank.next(of: last.rank)
        } else {
            newSection.rank = Utils.Rank.defaultRank
        }
        return newSection
    }

    func getContainer(by conainerGuid: String) -> Rust.TaskContainer? {
        return cacheData?.getTaskListItem(conainerGuid)?.container
    }

    func doCreateTaskList(with name: String, in section: Rust.TaskListSection?, completion: @escaping (UserResponse<String?>) -> Void) {
        guard let section = section else {
            logger.error("must have section when create task list")
            return
        }
        let container = {
            var container = Rust.TaskContainer()
            container.guid = UUID().uuidString.lowercased()
            container.name = name
            container.category = .taskList
            return container
        }()
        let ref: Rust.TaskListSectionRef? = {
            var ref = Rust.TaskListSectionRef()
            ref.sectionGuid = section.guid
            ref.containerGuid = container.guid
            ref.rank = {
                if let first = getFirstItemRef(in: section.guid) {
                    return Utils.Rank.pre(of: first.rank)
                }
                return Utils.Rank.defaultClientRank
            }()
            return ref
        }()

        listApi?.createContainer(new: container, with: ref)
            .observeOn(MainScheduler.asyncInstance)
            .subscribe(
                onNext: { [weak self] (item, metaData) in
                    HomeSidebar.Track.finalCreateTasklist(with: metaData.container, and: section.isDefault)
                    self?.context.store.dispatch(.changeContainer(.metaData(metaData)))
                    self?.receiveSectionItems([item])
                    completion(.success(nil))
                },
                onError: { [weak self] err in
                    self?.logger.error("doCreateTaskList err: \(err)")
                    completion(.failure(.init(error: err, message: I18N.Todo_common_ActionFailedTryAgainLater)))
                }
            )
            .disposed(by: disposeBag)
    }
    
    func upsertSection(_ section: Rust.TaskListSection, completion: @escaping (UserResponse<String?>) -> Void) {
        listApi?.upsertTaskListSection(with: section)
            .observeOn(MainScheduler.asyncInstance)
            .subscribe(
                onNext: { [weak self] newSection in
                    completion(.success(I18N.Todo_CollabTask_Successful))
                    self?.receiveSection([newSection])
                },
                onError: { [weak self] err in
                    let toast = Rust.displayMessage(from: err)
                    completion(.failure(.init(error: err, message: toast)))
                    self?.logger.error("upsertSection err: \(err)")
                }
            )
            .disposed(by: disposeBag)
    }

    private func setSelected(_ selectedGuid: String) {
        curSelectedGuid = selectedGuid
        for (section, sectionData) in sections.enumerated() {
            for (row, item) in sectionData.items.enumerated() {
                if item.isSelected {
                    sections[section].items[row].isSelected = false
                }
                if item.identifier == selectedGuid {
                    sections[section].items[row].isSelected = true
                }
            }
            if sectionData.header.isSelected {
                sections[section].header.isSelected = false
            }
            if sectionData.header.identifier == selectedGuid {
                sections[section].header.isSelected = true
            }
        }
        rxListUpdate.accept(void)
    }
}
