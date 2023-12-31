//
//  V3ListViewModel+Data.swift
//  Todo
//
//  Created by wangwanxin on 2022/8/27.
//

import Foundation
import LarkAccountInterface
import LarkUIKit
import RustPB

// MARK: - Make Data

extension V3ListViewModel {

    /// 构建viewData, 目前用于我负责的、我关注的、快速访问
    func makeListViewData(hasMore: Bool = false) -> V3ListViewData? {
        guard let listMetaData = curListMetaData else {
            V3Home.logger.error("local data is nil")
            return nil
        }
        return makeTaskListViewData(
            by: listMetaData,
            view: curView,
            hasMore: hasMore
        )
    }

    /// 构建List数据
    private func makeTaskListViewData(by metaData: ListMetaData?, view: TaskView?, hasMore: Bool) -> V3ListViewData {
        let beginTime = CFAbsoluteTimeGetCurrent()
        let filterTasks = filterTasks(by: view?.metaData?.viewFilters, from: metaData?.tasks)
        let cellDatas = makeCellData(filterTasks)
        let sortedData = sortedItems(cellDatas, type: view?.sort, refs: metaData?.mapRefs)
        var sections = makeSections(sortedData, type: view?.group, sections: metaData?.sections, refs: metaData?.refs)
        if hasMore {
            sections.append(makeSkeletonSection())
        }
        var viewData = V3ListViewData()
        viewData.afterTransition = afterTransition(&sections)
        viewData.data = sections
        V3Home.logger.info("make view data consume: \(CFAbsoluteTimeGetCurrent() - beginTime), viewData: \(viewData.logInfo)")
        return viewData
    }

    private func makeSkeletonSection() -> V3ListSectionData {
        var items = [V3ListCellData]()
        for _ in 0..<Utils.List.oneSceenItemCnt {
            var cellData = V3ListCellData(with: Rust.Todo(), completeState: .outsider(isCompleted: false))
            cellData.contentType = .skeleton
            items.append(cellData)
        }
        var section = V3ListSectionData()
        section.items = items
        section.isSkeleton = true
        return section
    }

    private func makeCellData(_ todos: [Rust.Todo]?) -> [V3ListCellData] {
        let beginTime = CFAbsoluteTimeGetCurrent()
        defer {
            V3Home.logger.info("make cell data consume: \(CFAbsoluteTimeGetCurrent() - beginTime), count: \(todos?.count ?? 0)")
        }
        guard let todos = todos else {
            V3Home.logger.info("todo is empty when make cell data")
            return []
        }
        let timeContext = curTimeContext, isEditable = isTaskEditableInContainer
        return todos
            .lf_unique { $0.guid }
            .map { todo in
                let completeState = completeService?.state(for: todo) ?? .outsider(isCompleted: false)
                var cellData = V3ListCellData(with: todo, completeState: completeState)
                let contentData = V3ListContentData(
                    todo: todo,
                    isTaskEditableInContainer: isEditable,
                    completeState: (completeState, false),
                    richContentService: richContentService,
                    timeContext: timeContext
                )
                cellData.contentType = .content(data: contentData)
                cellData.isFocused = todo.guid == newCreatedGuid
                return cellData
            }
    }

    private func afterTransition(_ sections: inout [V3ListSectionData]) -> ListAfterTransition {
        var row: Int?
        let sectionIndex = sections.firstIndex { section in
            if let rowIndex = section.items.firstIndex(where: { $0.isFocused }) {
                row = rowIndex
                return true
            } else {
                return false
            }
        }
        guard let row = row, let section = sectionIndex else {
            return .none
        }
        let indexPath = IndexPath(row: row, section: section)
        let sectionData = sections[section]
        if let header = sectionData.header, header.isFold {
            let fold = !header.isFold
            // 如果分组被折叠，则需要展开
            updateFoldState(section: sectionData.sectionId, isFold: fold)
            sections[section].header?.isFold = fold
            sections[section].footer.isFold = fold
        }
        return .scrollToItem(indexPath: indexPath)
    }

}

extension V3ListViewModel {

    // 时间格式化上下文
    var curTimeContext: TimeContext {
        return TimeContext(
            currentTime: Int64(Date().timeIntervalSince1970),
            timeZone: timeService?.rxTimeZone.value ?? .current,
            is12HourStyle: timeService?.rx12HourStyle.value ?? false
        )
    }
    // 当前UI数据
    var curViewData: V3ListViewData { queue.rxLatestData.value ?? .init() }
    // 当前用户id
    var curUserId: String { userResolver.userID }
    // 当前状态是否是全部
    var isAllCompleteStatus: Bool {
        guard let filters = context.store.state.view?.metaData?.viewFilters else {
            return false
        }
        return filters.conditions.contains { condition in
            if condition.fieldKey == FieldKey.completeStatus.rawValue,
                let first = condition.fieldFilterValue.first(where: { $0.hasTaskCompleteStatusValue }),
               first.taskCompleteStatusValue.taskCompleteStatus == .all {
                return true
            }
            return false
        }
    }
    // 是否在我负责的view下
    var isOwnedView: Bool { context.store.state.container?.key == ContainerKey.owned.rawValue }
    // 当前containerid
    var curContainerID: String { context.store.state.container?.guid ?? "" }
    // 当前view
    var curView: TaskView { context.store.state.view ?? .init() }
    // 是否是任务清单
    var isTaskList: Bool { context.store.state.container?.category == .taskList }
    // 是否有加载更多标识
    var hasMore: Bool { curViewData.data.contains(where: { $0.isSkeleton }) }
    // 任务在容器中是否有编辑权限
    var isTaskEditableInContainer: Bool { context.store.state.container?.canEditTask ?? false }
    // 获取当前列表的元数据
    var curListMetaData: ListMetaData? {
        return isTaskList ? listScene.temporary : listScene.persist
    }

    // 获取当前任务清单
    var curTaskList: Rust.TaskContainer? {
        guard isTaskList, let container = context.store.state.container else { return nil }
        return container
    }

    // 我负责的相关
    var curContainerSection: Rust.ContainerSection? {
        guard !isTaskList, isOwnedView else { return nil }
        var param = Rust.ContainerSection()
        param.containerGuid = curContainerID
        param.sectionGuid = curListMetaData?.sections.first(where: { $0.isDefault })?.guid ?? ""
        param.rank = Utils.Rank.defaultMinRank
        return param
    }

    func indexPath(from guid: String) -> IndexPath? {
        guard !guid.isEmpty, !curViewData.data.isEmpty else { return nil }
        for section in 0..<curViewData.data.count {
            let index = curViewData.data[section].items.firstIndex(where: { $0.todo.guid == guid })
            if let row = index {
                return IndexPath(row: row, section: section)
            }
        }
        return nil
    }

    func cellData(at indexPath: IndexPath, with guid: String) -> V3ListCellData? {
        let data = curViewData.data
        guard let (section, row) = V3ListSectionData.safeCheckIndexPath(at: indexPath, with: data) else {
            return nil
        }
        let cellData = data[section].items[row]
        guard cellData.todo.guid == guid else { return nil }
        return cellData
    }

    func isSectionValid(in section: Int, with sectionId: String) -> Bool {
        guard V3ListSectionData.safeCheckSection(in: section, with: curViewData.data) != nil else {
            return false
        }
        return curViewData.data[section].sectionId == sectionId
    }

    // 获取展开收起状态
    func getFoldState(sectionId: String) -> Bool {
        guard let viewGuid = context.store.state.view?.metaData?.guid else {
            return false
        }
        guard let map = sectionFoldState[viewGuid] else {
            return false
        }
        return map[sectionId] ?? false
    }
    // 更新状态
    func updateFoldState(section: String, isFold: Bool) {
        guard let viewGuid = context.store.state.view?.metaData?.guid else { return }
        var map = sectionFoldState[viewGuid]
        if map == nil {
            map = [String: Bool]()
        }
        map?[section] = isFold
        sectionFoldState[viewGuid] = map
    }

    // 移除任务清单的展示收起，清单不需要记录
    func removeTaskListFoldState() {
        guard isTaskList else { return }
        guard let viewGuid = context.store.state.view?.metaData?.guid else { return }
        sectionFoldState.removeValue(forKey: viewGuid)
    }

    func containerTrack() {
        let container = context.store.state.container
        V3Home.Track.viewList(with: container)
        if isTaskList {
            var isOnePage = false
            if case .onePage = context.scene {
                isOnePage = true
            }
            V3Home.Track.viewTaskList(with: container, isOnePage: isOnePage)
        }

    }
}

// MARK: - Notice
extension V3ListViewModel {

    func showNoticeIfNeeded() {
        rxNotice.accept(launchScreen())
    }

    func closeNotice() {
        guard let launchScreen = launchScreen() else {
            return
        }
        var newValue = launchScreen
        newValue.status = .exit
        settingService?.update([newValue], forKeyPath: \.listLaunchScreen) {
            V3Home.logger.info("update launch screen failed")
        }
        rxNotice.accept(launchScreen)
    }

    func launchScreen() -> Rust.ListLaunchScreen? {
        guard let container = context.store.state.container else { return nil }
        return settingService?.value(forKeyPath: \.listLaunchScreen).first { launchScreen in
            return launchScreen.enableTabs.contains(where: { listViewTypeToContainerCategory($0) == container.category })
        }
    }

    private func listViewTypeToContainerCategory(_ type: Rust.ListViewType) -> Rust.TaskContainer.Category? {
        switch type {
        case .assignToMe: return .ownedTasks
        case .followed: return .followedTasks
        case .all: return .savedSearchTasks
        @unknown default: return nil
        }
    }

}
