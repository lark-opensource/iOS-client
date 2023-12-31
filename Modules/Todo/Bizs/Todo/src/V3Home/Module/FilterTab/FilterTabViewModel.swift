//
//  FilterTabViewModel.swift
//  Todo
//
//  Created by baiyantao on 2022/8/19.
//

import Foundation
import RxSwift
import RxCocoa
import LarkContainer

final class FilterTabViewModel: UserResolverWrapper {
    var userResolver: LarkContainer.UserResolver
    typealias Fields = (
        status: FilterTab.StatusField,
        group: FilterTab.GroupField,
        sorting: FilterTab.SortingCollection
    )

    // dependencies
    @ScopedInjectedLazy private var operateApi: TodoOperateApi?
    private let context: V3HomeModuleContext
    private let disposeBag = DisposeBag()

    // view drivers
    let rxVisableItems = BehaviorRelay<Set<FilterTab.Item>>(value: Set())
    let rxCurrentContainer = BehaviorRelay<Rust.TaskContainer>(value: .init())
    // 自定义侧边栏
    let rxCustomSideBar = BehaviorRelay<SideBarItem.CustomCategory>(value: .none)
    let rxSelectorData = BehaviorRelay<FilterTabContaienrViewData>(value: .init())
    let rxFields = BehaviorRelay<Fields>(value: (
        status: .uncompleted,
        group: .custom,
        sorting: .init(field: .custom, indicator: .check)
    ))

    // internal state
    private var currentView: Rust.TaskView?
    private var enableGroupFieldKeys = [String]()
    private var enableSortFieldKeys = [String]()

    init(resolver: UserResolver, context: V3HomeModuleContext) {
        self.userResolver = resolver
        self.context = context
        switch context.scene {
        case .center:
            updateSelectorData()
            rxVisableItems.accept([.lineContainer])
        case .onePage:
            rxVisableItems.accept([.selector])
        }

        context.store.rxValue(forKeyPath: \.sideBarItem)
            .distinctUntilChanged { $0 == $1 }
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] item in
                guard let self = self, let item = item else { return }
                switch item {
                case .metaData(let metaData):
                    guard let metaData = metaData else { return }
                    self.rxCustomSideBar.accept(.none)
                    self.handleMeteData(metaData)
                case .custom(let key):
                    guard let key = key else { return }
                    if key.isActivity {
                        // 动态清空其他，只保留lineContainer
                        self.rxVisableItems.accept([.lineContainer])
                    } else if key.isTaskLists {
                        var values = self.rxVisableItems.value
                        values.remove(.archivedNotice)
                        self.rxVisableItems.accept(values)
                    }
                    self.rxCustomSideBar.accept(key)
                    self.updateSelectorData()
                    // 重置掉view
                    self.context.store.dispatch(.changeView(nil))
                }
            })
            .disposed(by: disposeBag)

        rxFields.skip(1)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] fields in
                guard let self = self, let view = self.currentView else { return }
                FilterTab.logger.info("do send changeView noti, status: \(fields.status.rawValue), group: \(fields.group.rawValue), sort: \(fields.sorting.logInfo)")
                let taskView = TaskView(
                    group: fields.group,
                    sort: fields.sorting,
                    metaData: view,
                    permission: self.rxCurrentContainer.value.currentUserPermission
                )
                self.context.store.dispatch(.changeView(taskView))
            })
            .disposed(by: disposeBag)
    }

    private func handleMeteData(_ data: Rust.ContainerMetaData) {
        FilterTab.logger.info("handleMeteData category: \(data.container.category), info: \(data.container.logInfo)")
        rxCurrentContainer.accept(data.container)
        let isArchived = data.container.isTaskList && data.container.isArchived
        if isArchived != rxVisableItems.value.contains(.archivedNotice) {
            var set = rxVisableItems.value
            if isArchived {
                set.insert(.archivedNotice)
            } else {
                set.remove(.archivedNotice)
            }
            rxVisableItems.accept(set)
        }
        currentView = data.views.first(where: { $0.type == .table })

        guard let view = currentView else { return }
        enableGroupFieldKeys = view.fieldConfig.enableGroupFieldKeys
        enableSortFieldKeys = view.fieldConfig.enableSortFieldKeys

        let fields: Fields = (
            FilterTab.StatusField(from: view.viewFilters),
            FilterTab.GroupField(from: view.viewGroups),
            FilterTab.SortingCollection(from: view.viewSorts)
        )
        rxFields.accept(fields)
        updateSelectorData()
    }

    private func updateSelectorData() {
        if case .taskLists(let tab, _)  = rxCustomSideBar.value {
            rxSelectorData.accept(.init(taskLists: tab))
        } else {
            let fields = rxFields.value
            let container = FilterTabSelectorViewData(
                statusBtnInfo: (title: fields.status.title(), isSeleted: false),
                groupBtnInfo: (title: I18N.Todo_New_GroupByOptions_Text(fields.group.title()), isSeleted: false),
                sortingBtnInfo: (title: I18N.Todo_New_SortSelectNum_Title(fields.sorting.field.title()), isSeleted: false)
            )
            rxSelectorData.accept(.init(container: container))
        }
    }

    private func updateView(by field: FilterPanelViewModel.Field) {
        guard var view = currentView else {
            assertionFailure()
            return
        }
        var updateFields = [Rust.ViewUpdateField]()
        switch field {
        case .status(let field):
            field.appendSelfTo(pb: &view.viewFilters)
        case .group(let field):
            view.viewGroups = field.toPb()
            updateFields.append(.viewGroups)
        case .sorting(let collection):
            view.viewSorts = collection.toPb()
            updateFields.append(.viewSorts)
        }
        currentView = view
        let container = rxCurrentContainer.value
        context.bus.post(.localUpdateTaskView(containerGuid: container.guid, view: view))
        // 仅非任务清单需要调用保存接口
        if !updateFields.isEmpty, container.category != .taskList {
            operateApi?.updateTaskView(view: view, updateFields: updateFields)
                .take(1).asSingle().subscribe().disposed(by: disposeBag)
        }
    }
}

// MARK: - View Action

extension FilterTabViewModel {
    func doToggleExpandFilterBtn() {
        FilterTab.logger.info("doToggleExpandFilterBtn")
        V3Home.Track.clickListToolbar(with: rxCurrentContainer.value)
        var set = rxVisableItems.value
        if set.contains(.selector) {
            set.remove(.selector)
        } else {
            set.insert(.selector)
        }
        rxVisableItems.accept(set)
    }

    func doSelectContainer(key: ContainerKey) {
        FilterTab.logger.info("doSelectContainer: \(key.rawValue)")
        context.bus.post(.changeContainerByKey(key))
    }

    func doExpandStatusPanel() -> FilterPanelViewModel.Input {
        FilterTab.logger.info("doExpandStatusPanel")
        var data = rxSelectorData.value.container
        data?.statusBtnInfo?.isSeleted = true
        data?.updateType = .status
        rxSelectorData.accept(.init(container: data))
        return .status(list: [.uncompleted, .completed, .all], seleted: rxFields.value.status)
    }

    func doExpandGroupPanel() -> FilterPanelViewModel.Input {
        FilterTab.logger.info("doExpandGroupPanel")
        var data = rxSelectorData.value.container
        data?.groupBtnInfo?.isSeleted = true
        data?.updateType = .group
        rxSelectorData.accept(.init(container: data))

        var options: [FilterTab.GroupField] = [.empty]
        options += enableGroupFieldKeys.compactMap {
            FilterTab.GroupField(from: $0)
        }
        return .group(list: options, seleted: rxFields.value.group)
    }

    func doExpandSortingPanel() -> FilterPanelViewModel.Input {
        FilterTab.logger.info("doExpandSortingPanel")
        var data = rxSelectorData.value.container
        data?.sortingBtnInfo?.isSeleted = true
        data?.updateType = .sorting
        rxSelectorData.accept(.init(container: data))

        var options: [FilterTab.SortingCollection] = []
        // 我负责的 and 任务清单，默认填充自定义排序
        let container = rxCurrentContainer.value
        if container.key == ContainerKey.owned.rawValue || container.category == .taskList {
            options.append(.init(field: .custom, indicator: .check))
        }
        options += enableSortFieldKeys.compactMap {
            FilterTab.SortingCollection(from: $0)
        }
        return .sorting(list: options, seleted: rxFields.value.sorting)
    }

    func doUpdateField(field: FilterPanelViewModel.Field) {
        FilterTab.logger.info("doUpdateField, f: \(field.logInfo)")
        var data = rxSelectorData.value.container
        var fields = rxFields.value
        switch field {
        case .status(let field):
            fields.status = field
            data?.statusBtnInfo?.title = field.title()
            data?.statusBtnInfo?.isSeleted = false
            V3Home.Track.clickListCompleteStatus(with: rxCurrentContainer.value, completeType: field)
        case .group(let field):
            fields.group = field
            data?.groupBtnInfo?.title = I18N.Todo_New_GroupByOptions_Text(field.title())
            data?.groupBtnInfo?.isSeleted = false
            V3Home.Track.clickListGroup(with: rxCurrentContainer.value)
        case .sorting(let collection):
            fields.sorting = collection
            data?.sortingBtnInfo?.title = I18N.Todo_New_SortSelectNum_Title(collection.field.title())
            data?.sortingBtnInfo?.isSeleted = false
            V3Home.Track.clickListSort(with: rxCurrentContainer.value)
        }
        data?.updateType = .all
        rxSelectorData.accept(.init(container: data))
        updateView(by: field)
        rxFields.accept(fields)
    }

    func doRestoreSeletedTab() {
        FilterTab.logger.info("doRestoreSeletedTab")
        var data = rxSelectorData.value.container
        if data?.statusBtnInfo?.isSeleted == .some(true) {
            data?.statusBtnInfo?.isSeleted = false
        }
        if data?.groupBtnInfo?.isSeleted == .some(true) {
            data?.groupBtnInfo?.isSeleted = false
        }
        if data?.sortingBtnInfo?.isSeleted == .some(true) {
            data?.sortingBtnInfo?.isSeleted = false
        }
        data?.updateType = .all
        rxSelectorData.accept(.init(container: data))
    }

    func doTaskListsSelectedTab(_ tab: Rust.TaskListTabFilter) {
        if case .taskLists(_, let isArchived)  = rxCustomSideBar.value {
            rxSelectorData.accept(.init(taskLists: tab))
            context.store.dispatch(.changeContainer(.custom(.taskLists(tab: tab, isArchived: isArchived))))
        }
    }
}
