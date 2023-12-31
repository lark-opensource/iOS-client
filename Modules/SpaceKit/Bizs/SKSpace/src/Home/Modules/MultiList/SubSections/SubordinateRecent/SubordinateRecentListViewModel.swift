//
//  SubordinateRecentListViewModel.swift
//  SKSpace
//
//  Created by peilongfei on 2023/9/13.
//  


import Foundation
import SKCommon
import RxSwift
import RxRelay
import RxCocoa
import SKFoundation
import SwiftyJSON
import EENavigator
import SKResource
import SKUIKit
import SpaceInterface
import SKInfra

extension SubordinateRecentListViewModel {
    public typealias Action = SpaceSection.Action
    public enum DataFrom: Equatable {
        case database(isEmpty: Bool)
        case server
        case unknow
    }
}

public final class SubordinateRecentListViewModel: SpaceListViewModel {

    private let workQueue = DispatchQueue(label: "space.subordinate-recent.vm")

    /// 表示当前列表是否正在被展示，切换至其他子列表时，isActive 需要置 false
    /// 仅限于 multiSection 间切换的状态，用于控制 UI Section 的数据是否同步到 UI 上
    private(set) var isActive = false

    /// 是否允许数据流更新，影响是否响应 dataModel 数据变化，对应 viewAppear、viewDisappear 生命周期，减少后台更新列表开销
    var dataFlowActive: Bool { dataFlowUpdateRelay.value }
    private let dataFlowUpdateRelay = BehaviorRelay<Bool>(value: false)

    // 表明是否请求过服务端数据，用于解决本地为空的情况下，继续展示loading
    private(set) var serverDataState = ServerDataState.loading

    private let actionInput = PublishRelay<Action>()
    public var actionSignal: Signal<Action> {
        actionInput.asSignal()
    }

    public var datatUpdatedFrom: ((DataFrom) -> Void)?
    let dataModel: SubordinateRecentListDataModel
    // 排序过滤二合一状态
    let filterAndSortStateRelay = BehaviorRelay<SpaceListFilterState>(value: .deactivated)
    var filterAndSortState: SpaceListFilterState { filterAndSortStateRelay.value }
    var hasActiveFilterAndSort: Bool { filterAndSortState != .deactivated }
    var hasActiveFilter: Bool {
        return filterState != .deactivated
    }

    // 排序状态
    let sortStateRelay = BehaviorRelay<SpaceListFilterState>(value: .deactivated)
    let sortNameRelay = BehaviorRelay<String>(value: "")
    let filterStateRelay = BehaviorRelay<SpaceListFilterState>(value: .deactivated)
    var filterState: SpaceListFilterState { filterStateRelay.value }

    let updateItemInput = PublishRelay<Void>()

    // 列表中的文档数据
    private let itemsRelay = BehaviorRelay<[SpaceListItem]>(value: [])
    private var items: [SpaceListItem] { itemsRelay.value }

    // 为了适配 drive 的上传进度特殊 cell，这里需要包装一层，和列表展示的数据对应
    private let itemTypesRelay = BehaviorRelay<[SpaceListItemType]>(value: [])
    var itemTypes: [SpaceListItemType] { itemTypesRelay.value }

    var itemsUpdated: Observable<[SpaceListItemType]> {
        itemTypesRelay.skip(1).asObservable()
    }

    var titleRelay: BehaviorRelay<String> {
        return dataModel.titleRelay
    }

    private let reachabilityRelay = BehaviorRelay(value: true)
    private var reachabilityChanged: Observable<Bool> {
        reachabilityRelay.distinctUntilChanged().asObservable()
    }
    var isReachable: Bool { reachabilityRelay.value }

    private lazy var slideActionHelper: SpaceListSlideDelegateProxyV2 = {
        return SpaceListSlideDelegateProxyV2(helper: self)
    }()

    private let disposeBag = DisposeBag()
    // 为避免切换筛选项后，多个列表不同筛选请求返回顺序不一致，导致列表内容为空，所有列表请求用一个单独的 bag
    // 筛选项切换的时候，会重置这个 bag
    private var listBag = DisposeBag()
    private weak var refreshPresenter: SpaceRefreshPresenter?
    private var refresher: SpaceListAutoRefresher?

    private(set) var tracker = SpaceSubSectionTracker(bizParameter: SpaceBizParameter(module: .home(.recent)))

    public init(dataModel: SubordinateRecentListDataModel) {
        self.dataModel = dataModel
    }

    func prepare() {
        RxNetworkMonitor.networkStatus(observerObj: self)
            .map { $1 }
            .bind(to: reachabilityRelay)
            .disposed(by: disposeBag)

        reachabilityChanged.skip(1)
            .subscribe(onNext: { [weak self] reachable in
                guard let self = self else { return }
                let entries = self.dataModel.listContainer.items
                self.updateList(entries: entries)
                // 切到有网时，若 DB 没有同步成功过服务端数据，主动刷新一次
                if reachable && !self.dataModel.listContainer.synced {
                    self.dataModel.refresh().subscribe().disposed(by: self.listBag)
                }
            })
            .disposed(by: disposeBag)

        dataModel.setup()

        Observable.combineLatest(dataFlowUpdateRelay.asObservable(),
                                 dataModel.itemChanged)
        .filter { $0.0 } // 若当前列表非 active 状态，停止从 dataModel 获取数据更新
        .subscribe(onNext: { [weak self] (_, entries) in
            guard let self = self else { return }
            DocsLogger.info("updating data from recent data model")
            self.updateList(entries: entries)
            DispatchQueue.main.async {
                DocsLogger.info("logging cold start event start")
                self.datatUpdatedFrom?(self.dataFrom(isEmpty: entries.isEmpty))
            }
        })
        .disposed(by: disposeBag)

        dataModel.reloadSignal.subscribe(onNext: { [weak self] in
            self?.refresher?.notifySyncEvent()
        }).disposed(by: disposeBag)

        dataModel.refresh().subscribe { [weak self] in
            // err 为空表示拉取成功，走 itemChanged 内的逻辑
            guard let self = self else { return }
            let hasMore = self.dataModel.listContainer.hasMore
            self.actionInput.accept(.stopPullToLoadMore(hasMore: hasMore))
            self.serverDataState = .synced
        } onError: { [weak self] error in
            guard let self = self else { return }
            // 过滤部分特殊的错误码，避免影响loading的展示
            let errorCode = (error as NSError).code
            if errorCode == SpecialError.running.rawValue || errorCode == SpecialError.notLogged.rawValue {
                DocsLogger.info("errorCode = \(errorCode)")
                return
            }

            self.serverDataState = .fetchFailed
            // 拉取失败的情况下，不会触发 didUpdate，需要主动触发一次列表数据更新的事件
            DocsLogger.warning("fetch subordinate-recent file error \(error.localizedDescription)")
            self.itemsRelay.accept(self.items)
        }
        .disposed(by: listBag)

        let filterAndSortState = generateFilterAndSortState()
        filterAndSortStateRelay.accept(filterAndSortState)
        let currentSortState = getSortState()
        sortStateRelay.accept(currentSortState)
        sortNameRelay.accept(dataModel.sortHelper.selectedOption.legacyItem.fullDescription)
        let currentFilterState = getFilterState()
        filterStateRelay.accept(currentFilterState)

        itemsRelay.skip(1).subscribe(onNext: { [weak self] items in
            guard let self = self else { return }
            let listItems = items.map { SpaceListItemType.spaceItem(item: $0) }
            self.itemTypesRelay.accept(listItems)
        }).disposed(by: disposeBag)

        updateItemInput.subscribe(onNext: { [weak self] in
            guard let self = self else { return }
            let listItems = self.items.map { SpaceListItemType.spaceItem(item: $0) }
            self.itemTypesRelay.accept(listItems)
        }).disposed(by: disposeBag)

        let filterAction = dataModel.filterHelper.selectedOption.reportName
        let sortAction = dataModel.sortHelper.selectedOption.type.reportName
        tracker.filterAction = filterAction
        tracker.sortAction = sortAction
    }

    // multiSection 列表切换到当前 section
    func didBecomeActive() {
        isActive = true
        tracker.reportEnter(module: "home", subModule: "subordinate-recent", srcModule: nil)
        let hasMore = dataModel.listContainer.hasMore
        actionInput.accept(.stopPullToLoadMore(hasMore: hasMore))
    }

    // multiSection 列表即将切换到其他 section
    func willResignActive() {
        isActive = false
        // 列表即将隐藏时，需要隐藏掉当前的刷新提示
        actionInput.accept(.dismissRefreshTips(needScrollToTop: false))
    }

    func select(at index: Int, item: SpaceListItemType) {
        select(item: item)
        if case let .spaceItem(spaceItem) = item {
            // 列表中可能存在drive上传进度等不属于文档的内容，在计算实际点击的位置时，需要排除掉
            let actualIndex: Int
            if let firstIndex = itemTypes.firstIndex(where: \.isDocument) {
                actualIndex = index - firstIndex
            } else {
                actualIndex = index
            }
            tracker.reportClick(entry: spaceItem.entry, at: actualIndex, pageModule: nil, pageSubModule: .recent)
        }
    }

    func select(item: SpaceListItemType) {
        if case let .spaceItem(item) = item {
            didSelect(entry: item.entry)
        }
    }

    private func didSelect(entry: SpaceEntry) {
        if !isReachable, entry.canOpenWhenOffline == false {
            offlineSelect(entry: entry)
            return
        }

        let entryLists = items.compactMap { item -> SpaceEntry? in
            let entry = item.entry
            if entry.type.isUnknownType { return nil }
            return entry
        }
        entry.fromModule = "subordinate-recent"
        FileListStatistics.curFileObjToken = entry.objToken
        FileListStatistics.curFileType = entry.type
        FileListStatistics.prepareStatisticsData(.recent)

        let body = SKEntryBody(entry)
        let context: [String: Any] = [SKEntryBody.fileEntryListKey: entryLists,
                                      SKEntryBody.fromKey: FileListStatistics.Module.home]

        actionInput.accept(.open(entry: body, context: context))
    }

    // 离线时点击某文档
    private func offlineSelect(entry: SpaceEntry) {
        guard entry.canSetManualOffline, !entry.isSetManuOffline else {
            let tips: String
            if entry.type == .file {
                tips = BundleI18n.SKResource.Doc_List_OfflineClickTips
            } else {
                tips = BundleI18n.SKResource.Doc_List_OfflineOpenDocFail
            }
            actionInput.accept(.showHUD(.tips(tips)))
            return
        }
        if entry.docsType == .file, !DriveFeatureGate.driveEnabled {
            DocsLogger.info("space.subordinate-recent.list.vm --- drive disable by FG, forbidden offline open drive action")
            actionInput.accept(.showHUD(.tips(BundleI18n.SKResource.Drive_Drive_FileSecurityRestrictDownloadActionGeneralMessage)))
            return
        }
        actionInput.accept(.showManualOfflineSuggestion(completion: { [weak self] shouldSetManualOffline in
            guard let self = self else { return }
            guard shouldSetManualOffline else { return }
            self.slideActionHelper.toggleManualOffline(for: entry)
        }))
    }

    private func updateList(entries: [SpaceEntry]) {
        workQueue.async { [weak self] in
            guard let self = self else { return }
            let items = SpaceModelConverter.convert(entries: entries,
                                                    context: .init(sortType: self.dataModel.sortHelper.selectedOption.type,
                                                                   folderEntry: nil,
                                                                   listSource: .recent),
                                                    config: .default,
                                                    handler: self)
            self.itemsRelay.accept(items)
        }
    }

    func notifyPullToRefresh() {
        serverDataState = .loading
        dataModel.refresh().subscribe { [weak self] in
            guard let self = self else { return }
            self.serverDataState = .synced
            let total = self.dataModel.listContainer.totalCount
            self.actionInput.accept(.stopPullToRefresh(total: total))
            let hasMore = self.dataModel.listContainer.hasMore
            self.actionInput.accept(.stopPullToLoadMore(hasMore: hasMore))
        } onError: { [weak self] error in
            guard let self = self else { return }
            self.actionInput.accept(.stopPullToRefresh(total: nil))
            DocsLogger.error(" --- pull to refresh failed with error", error: error)
            // show error
            self.serverDataState = .fetchFailed
            self.itemsRelay.accept(self.items)
            return
        }
        .disposed(by: listBag)
    }

    func notifyPullToLoadMore() {
        dataModel.loadMore().subscribe { [weak self] in
            guard let self = self else { return }
            let hasMore = self.dataModel.listContainer.hasMore
            self.actionInput.accept(.stopPullToLoadMore(hasMore: hasMore))
        } onError: { [weak self] error in
            guard let self = self else { return }
            if let recentListError = error as? RecentListDataModel.RecentDataError, recentListError == .unableToLoadMore {
                self.actionInput.accept(.stopPullToLoadMore(hasMore: false))
            } else {
                self.actionInput.accept(.stopPullToLoadMore(hasMore: true))
            }
            DocsLogger.error(" --- pull to load more failed with error", error: error)
        }
        .disposed(by: listBag)
    }

    // 对应 viewDidAppear 生命周期事件，列表显示后恢复数据流更新
    func notifySectionDidAppear() {
        dataFlowUpdateRelay.accept(true)
    }

    // 对应 viewWillDisappear 生命周期事件，列表即将隐藏时暂停数据流更新，避免触发 SpaceEntry 转 SpaceListItem 开销
    func notifySectionWillDisappear() {
        dataFlowUpdateRelay.accept(false)
    }

    func updateItemTypes(items: [SpaceListItem]) {
        var itemTypes: [SpaceListItemType] = []
        let listItems = items.map { SpaceListItemType.spaceItem(item: $0) }
        itemTypes.append(contentsOf: listItems)
        itemTypesRelay.accept(itemTypes)
    }

    func contextMenuConfig(for entry: SpaceEntry) -> SpaceListItem.SlideConfig? {
        return generateSlideConfig(for: entry)
    }
}

extension SubordinateRecentListViewModel {

    private func dataFrom(isEmpty: Bool) -> DataFrom {
        if dataModel.listContainer.synced {
            return .server
        }
        if dataModel.listContainer.restored {
            return .database(isEmpty: isEmpty)
        }
        return .unknow
    }
}

// MARK: - SpaceFilterSortPanelDelegate
extension SubordinateRecentListViewModel: SpaceFilterSortPanelDelegate {

    var filterEnabled: Observable<Bool> {
        reachabilityChanged
    }

    var listFilterSortConfig: SpaceSortFilterConfigV2 {
        SpaceSortFilterConfigV2(filterIndex: dataModel.filterHelper.selectedIndex,
                                filterOptions: dataModel.filterHelper.options,
                                defaultFilterOption: dataModel.filterHelper.defaultOption,
                                sortIndex: dataModel.sortHelper.selectedIndex,
                                sortOptions: dataModel.sortHelper.options,
                                defaultSortOption: dataModel.sortHelper.defaultOption)
    }

    func invalidReasonForCombination(filterOption: SpaceFilterHelper.FilterOption, sortOption: SpaceSortHelper.SortOption, panel: SpaceFilterSortPanelController) -> String? {
        if filterOption == .wiki, sortOption.type == .lastModifiedTime {
            return BundleI18n.SKResource.LarkCCM_Drive_UnsupportedAction_Toast
        }
        return nil
    }

    func filterSortPanel(_ panel: SpaceFilterSortPanelController, didConfirmWith filterIndex: Int, sortIndex: Int) {
        update(sortIndex: sortIndex, filterIndex: filterIndex, action: "done")
    }

    func didClickResetFor(filterSortPanel: SpaceFilterSortPanelController) {
        dataModel.resetSortOption()
        dataModel.resetFilterOption()
        updateAfterFilterSortOptionChanged(action: "reset")
    }

    private func updateAfterFilterSortOptionChanged(action: String) {
        // 切换筛选、排序项时，重置一下列表请求
        listBag = DisposeBag()
        actionInput.accept(.stopPullToRefresh(total: nil))
        actionInput.accept(.stopPullToLoadMore(hasMore: false))
        self.serverDataState = .loading
        // 这里需要通知 dataModel 检查筛选过滤缓存的 tokens，使用缓存填充数据（若有）
        dataModel.refresh().subscribe { [weak self] in
            guard let self = self else { return }
            let hasMore = self.dataModel.listContainer.hasMore
            self.actionInput.accept(.stopPullToLoadMore(hasMore: hasMore))
            self.serverDataState = .synced
        } onError: { [weak self] error in
            guard let self = self else { return }
            DocsLogger.error("space.subordinate-recent.vm --- pull to refresh failed with error", error: error)
            self.actionInput.accept(.showHUD(.failure(BundleI18n.SKResource.Doc_Doc_NetException)))
            self.serverDataState = .fetchFailed
        }
        .disposed(by: listBag)

        let filterAndSortState = generateFilterAndSortState()
        filterAndSortStateRelay.accept(filterAndSortState)
        let currentSortState = getSortState()
        sortStateRelay.accept(currentSortState)
        sortNameRelay.accept(dataModel.sortHelper.selectedOption.legacyItem.fullDescription)
        let currentFilterState = getFilterState()
        filterStateRelay.accept(currentFilterState)

        actionInput.accept(.stopPullToLoadMore(hasMore: true))
        let filterOption = dataModel.filterHelper.selectedOption
        let sortOption = dataModel.sortHelper.selectedOption
        let filterAction = filterOption.reportName
        let sortAction = sortOption.type.reportName
        tracker.reportFilterPanelUpdated(action: action,
                                         filterAction: filterAction,
                                         sortAction: sortAction)
        let filterItem = FilterItem(isSelected: true, filterType: filterOption.legacyType)
        DocsTracker.reportSpaceHeaderFilterClick(by: filterItem,
                                                 by: sortOption.legacyItem,
                                                 lastActionName: action,
                                                 eventType: DocsTracker.EventType.spaceHomePageView,
                                                 bizParms: tracker.bizParameter)
    }

    private func update(sortIndex: Int, filterIndex: Int, action: String) {
        // 这里需要通知 dataModel 存储当前展示的列表tokens
        dataModel.update(sortIndex: sortIndex, descending: true)
        dataModel.update(filterIndex: filterIndex)
        updateAfterFilterSortOptionChanged(action: action)
    }

    private func generateFilterAndSortState() -> SpaceListFilterState {
        var sortName: String?
        if dataModel.sortHelper.changed {
            sortName = dataModel.sortHelper.selectedOption.type.displayName
        }

        var filterName: String?
        if dataModel.filterHelper.changed {
            filterName = dataModel.filterHelper.selectedOption.displayName
        }

        if sortName == nil, filterName == nil {
            return .deactivated
        } else {
            let descending = dataModel.sortHelper.selectedOption.descending
            return .activated(type: filterName, sortOption: sortName, descending: descending)
        }
    }

    private func getFilterState() -> SpaceListFilterState {
        var filterName: String?
        if dataModel.filterHelper.changed {
            filterName = dataModel.filterHelper.selectedOption.displayName
        }

        if filterName == nil {
            return .deactivated
        } else {
            return .activated(type: filterName, sortOption: nil, descending: true)
        }
    }

    private func getSortState() -> SpaceListFilterState {
        var sortName: String?
        if dataModel.sortHelper.changed {
            sortName = dataModel.sortHelper.selectedOption.type.displayName
        }
        let descending = dataModel.sortHelper.selectedOption.descending

        if sortName == nil {
            return .deactivated
        } else {
            return .activated(type: nil, sortOption: sortName, descending: descending)
        }
    }
}

extension SubordinateRecentListViewModel: SpaceFilterPanelDelegate {
    func generateLegacySortFilterConfig() -> SpaceSortFilterConfig? {
        return SpaceSortFilterConfig(sortItems: dataModel.sortHelper.legacyItemsForSortPanel,
                                     defaultSortItems: dataModel.sortHelper.defaultLegacyItemsForSortPanel,
                                     filterItems: dataModel.filterHelper.legacyItemsForFilterPanel,
                                     defaultFilterItems: dataModel.filterHelper.defaultLegacyItemsForFilterPanel)
    }

    public func filterPanel(_ panel: SpaceFilterPanelController, didConfirmWith selection: FilterItem) {
        guard let index = panel.options.firstIndex(where: { $0.filterType == selection.filterType }) else {
            return
        }
        update(sortIndex: dataModel.sortHelper.selectedIndex, filterIndex: index, action: "done")
    }

    public func didClickResetFor(filterPanel: SpaceFilterPanelController) {
        update(sortIndex: dataModel.sortHelper.selectedIndex, filterIndex: 0, action: "reset")
    }
}

extension SubordinateRecentListViewModel: SpaceSortPanelDelegate {
    public func sortPanel(_ panel: SpaceSortPanelController, didSelect selectionIndex: Int, descending: Bool) {
        update(sortIndex: selectionIndex, filterIndex: dataModel.filterHelper.selectedIndex, action: "done")
    }

    public func sortPanelDidClickReset(_ panel: SpaceSortPanelController) {
        dataModel.resetSortOption()
        updateAfterFilterSortOptionChanged(action: "reset")
    }
}

extension SubordinateRecentListViewModel: SpaceListItemInteractHandler {
    // 网格模式下，more 按钮
    func handleMoreAction(for entry: SpaceEntry) -> ((UIView) -> Void)? {
        let handler: (UIView) -> Void = { [weak self] view in
            guard let self = self else { return }
            if entry.secretKeyDelete == true {
                self.actionInput.accept(.showHUD(.failure(BundleI18n.SKResource.CreationDoc_Docs_KeyInvalidCanNotOperate)))
                return
            }
            self.tracker.source = .gridMore
            self.showMoreVC(for: entry, sourceView: view, forbiddenItems: [.delete])
            self.tracker.reportClickGridMore(entryType: entry.type)
        }
        return handler
    }

    func handlePermissionTips(for entry: SpaceEntry) -> ((UIView) -> Void)? {
        return nil
    }

    func generateSlideConfig(for entry: SpaceEntry) -> SpaceListItem.SlideConfig? {
        let actions: [SlideAction] = [.share, .more]
        return SpaceListItem.SlideConfig(actions: actions) { [weak self] (cell, action) in
            guard let self = self else { return }
            if entry.secretKeyDelete == true {
                self.actionInput.accept(.showHUD(.failure(BundleI18n.SKResource.CreationDoc_Docs_KeyInvalidCanNotOperate)))
                return
            }
            self.tracker.source = .slide
            self.tracker.bizParameter.update(fileID: entry.objToken, fileType: entry.docsType, driveType: entry.fileType)
            self.tracker.reportClick(slideAction: action)
            switch action {
            case .readyToDelete, .delete, .remove:
                self.handleDelete(for: entry)
            case .share:
                self.slideActionHelper.share(entry: entry, sourceView: cell, shareSource: .list)
            case .more:
                self.showMoreVC(for: entry, sourceView: cell, forbiddenItems: [.share, .delete])
            default:
                spaceAssertionFailure("space.subordinate-recent.list.vm --- unhandle slide action: \(action)")
                return
            }
        }
    }

    private func showMoreVC(for entry: SpaceEntry, sourceView: UIView, forbiddenItems: [MoreItemType]) {
        var moreProvider = SpaceMoreProviderFactory.createMoreProvider(for: entry, sourceView: sourceView, forbiddenItems: forbiddenItems, listType: .recent)
        let listMoreItemClickTracker = ListMoreItemClickTracker(isShareFolder: entry.isShareFolder, type: entry.type, originInWiki: entry.originInWiki)
        moreProvider.handler = slideActionHelper
        let moreVM = MoreViewModel(dataProvider: moreProvider, docsInfo: entry.transform(), moreItemClickTracker: listMoreItemClickTracker)
        let moreVC = MoreViewControllerV2(viewModel: moreVM)
        moreVC.modalPresentationStyle = .overFullScreen
        actionInput.accept(.present(viewController: moreVC, popoverConfiguration: { controller in
            controller.modalPresentationStyle = .popover
            controller.popoverPresentationController?.sourceView = sourceView
            controller.popoverPresentationController?.sourceRect = sourceView.bounds
            controller.popoverPresentationController?.permittedArrowDirections = .any
        }))
    }
}

// SlideAction
extension SubordinateRecentListViewModel: SpaceListSlideDelegateHelperV2 {

    func refreshForMoreAction() {
        notifyPullToRefresh()
    }

    var slideActionInput: PublishRelay<SpaceSection.Action> { actionInput }
    var slideTracker: SpaceSubSectionTracker { tracker }
    var interactionHelper: SpaceInteractionHelper { dataModel.interactionHelper }
    var listType: SKObserverDataType? { dataModel.type }

    func handleDelete(for entry: SpaceEntry) {
    }

    var userID: String { dataModel.currentUserID }
}

// MARK: 列表自动刷新逻辑，待梳理
extension SubordinateRecentListViewModel: SpaceRefresherListProvider {

    var listEntries: [SpaceEntry] {
        dataModel.listContainer.items
    }

    func fetchCurrentList(size: Int, handler: @escaping (Result<FileDataDiff, Error>) -> Void) {
        dataModel.fetchCurrentList(size: size, handler: handler)
    }

    func update(refreshPresenter: SpaceRefreshPresenter) {
        self.refreshPresenter = refreshPresenter
        let factory = DocsContainer.shared.resolve(SpaceAutoRefresherFactory.self)!
        var refresher = factory.createRecentListRefresher(userID: dataModel.currentUserID, listProvider: self)
        refresher.setup()
        refresher.actionHandler = { [weak self] action, shouldShowRefreshTips in
            self?.handleRefresher(action: action, shouldShowRefreshTips: shouldShowRefreshTips)
        }
        refresher.start()
        self.refresher = refresher
    }

    private func handleRefresher(action: @escaping SpaceListAutoRefresher.RefreshActionHandler, shouldShowRefreshTips: Bool) {
        DocsLogger.info("space.subordinate-recent.vm handling action from auto refresher",
                        extraInfo: ["shouldShowRefreshTips": shouldShowRefreshTips])
        let refreshAction = {
            action { [weak self] result in
                guard let self = self else { return }
                switch result {
                case let .success(dataDiff):
                    self.dataModel.apply(refreshData: dataDiff)
                    let hasMore = self.dataModel.listContainer.hasMore
                    self.actionInput.accept(.stopPullToLoadMore(hasMore: hasMore))
                    self.refreshPresenter?.dismissRefreshTips(result: .success(()))
                case let .failure(error):
                    DocsLogger.error("space.subordinate-recent.vm auto refresh failed with error", error: error)
                    self.refreshPresenter?.dismissRefreshTips(result: .failure(error))
                }
            }
        }
        guard shouldShowRefreshTips else {
            // 不需要tips，直接执行
            refreshAction()
            return
        }
        // 需要 tips
        refreshPresenter?.showRefreshTips(callback: refreshAction)
    }
}
