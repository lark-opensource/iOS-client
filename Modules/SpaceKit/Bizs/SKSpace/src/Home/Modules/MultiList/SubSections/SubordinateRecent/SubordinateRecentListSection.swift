//
//  SubordinateRecentListSection.swift
//  SKSpace
//
//  Created by peilongfei on 2023/9/13.
//  


import UIKit
import RxSwift
import RxRelay
import RxCocoa
import SKCommon
import SKFoundation
import SKResource
import LarkSceneManager
import UniverseDesignEmpty
import UniverseDesignColor
import SKUIKit

public final class SubordinateRecentListSection: SpaceListSubSection, SpaceListSectionAutoLayout, SpaceListSectionAutoDataSource, SpaceListSectionCommonDelegate {

    public let identifier: String = "subordinate-recent"
    public let subSectionTitle: String = BundleI18n.SKResource.Doc_List_Recent
    public let subSectionIdentifier: String = "subordinate-recent"

    public var listTools: [SpaceListTool] {
        return [
            .sort(stateRelay: viewModel.sortStateRelay,
                  titleRelay: viewModel.sortNameRelay,
                  isEnabled: .just(false),
                  clickHandler: { [weak self] view in
                      self?.changeSortState(sourceView: view)
                  }),
            .modeSwitch(modeRelay: displayModeRelay, clickHandler: { [weak self] _ in
                self?.switchDisplayMode()
            })
        ]
    }
    
    public var createIntent: SpaceCreateIntent {
        SpaceCreateIntent(context: .subordinateRecent, source: .other, createButtonLocation: .bottomRight)
    }

    var titleRelay: BehaviorRelay<String> {
        return viewModel.titleRelay
    }

    private let displayModeRelay = BehaviorRelay<SpaceListDisplayMode>(value: .list)
    private var displayMode: SpaceListDisplayMode { displayModeRelay.value }

    private let reloadInput = PublishRelay<ReloadAction>()
    public var reloadSignal: Signal<ReloadAction> {
        reloadInput.asSignal()
    }

    private let actionInput = PublishRelay<Action>()
    public var actionSignal: Signal<Action> {
        actionInput.asSignal()
    }

    // UI 数据源，负责 CollectionView 的 Item 数据，注意只在主线程进行操作，且需要刷新 UI
    private var listState = ListState.loading

    private let viewModel: SubordinateRecentListViewModel
    private var tracker: SpaceSubSectionTracker { viewModel.tracker }
    private lazy var stateHelper: SpaceSubSectionStateHelper = {
        let differ = SpaceListDifferFactory.createListStateDiffer()
        return SpaceSubSectionStateHelper(differ: differ,
                                          listID: identifier,
                                          stateProvider: self)
    }()

    public private(set) lazy var sectionLayoutHelper: SpaceListSectionLayoutHelper = {
        SpaceSubSectionLayoutHelper(delegate: self)
    }()

    public private(set) lazy var sectionDataSourceHelper: SpaceListSectionDataSourceHelper = {
        SpaceSubSectionDataSourceHelper(delegate: self)
    }()

    public private(set) lazy var sectionDelegateProxy: SpaceListSectionDelegateProxy = {
        SpaceSubSectionDelegateHelper(provider: self)
    }()

    private let disposeBag = DisposeBag()

    // 同步获取当前可见的 item 下标，用于 Rust 列表自动刷新的判断
    public var visableIndicesHelper: (() -> [Int])?

    init(viewModel: SubordinateRecentListViewModel) {
        self.viewModel = viewModel
    }

    public func prepare() {
        setupDisplayMode()
        stateHelper.actionSignal.emit(to: actionInput).disposed(by: disposeBag)
        stateHelper.reloadSignal.emit(to: reloadInput).disposed(by: disposeBag)
        viewModel.update(refreshPresenter: self)
        viewModel.itemsUpdated.observeOn(SerialDispatchQueueScheduler(internalSerialQueueName: "space.subordinate-recent.section"))
            .subscribe(onNext: { [weak self] newItems in
                self?.handle(newItems: newItems)
            }).disposed(by: disposeBag)
        viewModel.actionSignal.emit(to: actionInput).disposed(by: disposeBag)
        viewModel.prepare()
    }

    private func setupDisplayMode() {
        let mode: SpaceListDisplayMode = LayoutManager.shared.isGrid ? .grid : .list
        displayModeRelay.accept(mode)

        NotificationCenter.default.rx
            .notification(LayoutManager.layoutChangeNotification)
            .subscribe(onNext: { [weak self] _ in
                guard let self = self else { return }
                let mode: SpaceListDisplayMode = LayoutManager.shared.isGrid ? .grid : .list
                self.displayModeRelay.accept(mode)
                self.reloadInput.accept(.reloadSection(animated: false))
            })
            .disposed(by: disposeBag)
    }

    private func switchDisplayMode() {
        LayoutManager.shared.isGrid = !LayoutManager.shared.isGrid
        let newMode: SpaceListDisplayMode
        if LayoutManager.shared.isGrid {
            newMode = .grid
        } else {
            newMode = .list
        }
        tracker.reportChangeDisplayMode(newMode: newMode, subModule: .recent)
    }

    private func changeFilterAndSortState(filterView: UIView) {
        let config = viewModel.listFilterSortConfig
        let panelController = SpaceFilterSortPanelController(config: config)
        panelController.delegate = viewModel
        panelController.setupPopover(sourceView: filterView, direction: .any)
        panelController.popoverPresentationController?.sourceRect = filterView.bounds.inset(by: UIEdgeInsets(top: -4, left: -4, bottom: -4, right: -4)) // 向外偏移一点
        panelController.dismissalStrategy = .larkSizeClassChanged
        actionInput.accept(.present(viewController: panelController, popoverConfiguration: nil))
        tracker.reportClickFilterPanel()
        DocsTracker.reportSpaceHeaderFilterView(bizParms: tracker.bizParameter)
        DocsTracker.reportSpaceHomePageClick(params: .filter, bizParms: tracker.bizParameter)
    }

    private func changeFilterState(sourceView: UIView) {
        guard let config = viewModel.generateLegacySortFilterConfig() else {
            DocsLogger.error("space.subordinate-recent.section --- unable to get sort filter config")
            return
        }
        let selectedIndex = config.filterItems.firstIndex(where: \.isSelected) ?? 0
        let panelController = SpaceFilterPanelController(options: config.filterItems, initialSelection: selectedIndex)
        panelController.delegate = viewModel
        panelController.setupPopover(sourceView: sourceView, direction: .any)
        panelController.popoverPresentationController?.sourceRect = sourceView.bounds.inset(by: UIEdgeInsets(top: -4, left: -4, bottom: -4, right: -4)) // 向外偏移一点
        panelController.dismissalStrategy = .larkSizeClassChanged
        actionInput.accept(.present(viewController: panelController, popoverConfiguration: nil))
        tracker.reportClickFilterPanel()
        DocsTracker.reportSpaceHeaderFilterView(bizParms: tracker.bizParameter)
        DocsTracker.reportSpaceSharedPageClick(params: .filter)
    }

    private func changeSortState(sourceView: UIView) {
        guard let config = viewModel.generateLegacySortFilterConfig() else {
            DocsLogger.error("space.subordinate-recent.section --- unable to get sort filter config")
            return
        }
        guard viewModel.isReachable else {
            actionInput.accept(.showHUD(.failure(BundleI18n.SKResource.Doc_Facade_Offline)))
            return
        }
        let selectedIndex = config.sortItems.firstIndex(where: \.isSelected) ?? 0
        let panelController = SpaceSortPanelController(options: config.sortItems, initialSelection: selectedIndex, canReset: config.sortChanged)
        panelController.delegate = viewModel
        panelController.setupPopover(sourceView: sourceView, direction: .any)
        panelController.popoverPresentationController?.sourceRect = sourceView.bounds.inset(by: UIEdgeInsets(top: -4, left: -4, bottom: -4, right: -4)) // 向外偏移一点
        panelController.dismissalStrategy = .larkSizeClassChanged
        actionInput.accept(.present(viewController: panelController, popoverConfiguration: nil))
        tracker.reportClickFilterPanel()
        DocsTracker.reportSpaceHeaderFilterView(bizParms: tracker.bizParameter)
        DocsTracker.reportSpaceSharedPageClick(params: .filter)
    }

    public func notifyPullToRefresh() {
        viewModel.notifyPullToRefresh()
    }

    public func notifyPullToLoadMore() {
        viewModel.notifyPullToLoadMore()
    }

    // TODO: 优化后台加载逻辑
    public func notifySectionDidAppear() {
        viewModel.notifySectionDidAppear()
    }
    public func notifySectionWillDisappear() {
        viewModel.notifySectionWillDisappear()
    }

    public func didShowSubSection() {
        viewModel.didBecomeActive()
        switch listState {
        case .empty, .loading, .networkUnavailable:
            actionInput.accept(.stopPullToLoadMore(hasMore: false))
        default:
            break
        }
        DocsLogger.info("space.subordinate-recent.section --- preload visable items when didShowSubSection")
        preloadVisableItems()
    }
    public func willHideSubSection() {
        viewModel.willResignActive()
    }
}

extension SubordinateRecentListSection: SpaceSubSectionLayoutDelegate {
    var layoutListState: SpaceListSubSection.ListState { listState }
    var layoutDisplayMode: SpaceListDisplayMode { displayMode }
}

extension SubordinateRecentListSection: SpaceSectionLayout {}

extension SubordinateRecentListSection: SpaceSubSectionDataSourceDelegate {
    var dataSourceListState: SpaceListSubSection.ListState { listState }
    var dataSourceDisplayMode: SpaceListDisplayMode { displayMode }
    var dataSourceCellTrackerModule: PageModule { tracker.module }
}

extension SubordinateRecentListSection: SpaceSectionDataSource {}

extension SubordinateRecentListSection: SpaceSubSectionDelegateProvider {
    var providerListState: SpaceListSubSection.ListState { listState }
    var listViewModel: SpaceListViewModel { viewModel }
    func open(newScene: Scene) {
        actionInput.accept(.newScene(newScene))
    }
}

extension SubordinateRecentListSection: SpaceSectionDelegate {
    public func notifyDidEndDragging(willDecelerate: Bool) {
        if !willDecelerate {
            DocsLogger.info("space.subordinate-recent.section --- preload visable items when end dragging")
            preloadVisableItems()
        }
    }

    public func notifyDidEndDecelerating() {
        DocsLogger.info("space.subordinate-recent.section --- preload visable items when end decelerating")
        preloadVisableItems()
    }

    private func preloadVisableItems() {
        reloadInput.accept(.getVisableIndices(callback: { [weak self] (indices, _) in
            guard let self = self else { return }
            guard case let .normal(items) = self.listState else {
                return
            }
            let preloadKeys = indices.compactMap { index -> PreloadKey? in
                guard index < items.count else {
                    assertionFailure()
                    return nil
                }
                let itemType = items[index]
                guard case let .spaceItem(item) = itemType else { return nil }
                let entry = item.entry
                guard entry.type.shouldPreloadClientVar else { return nil }
                var preloadKey = entry.preloadKey
                preloadKey.fromSource = PreloadFromSource(.recentPreload)
                return preloadKey
            }
            DocsLogger.info("space.subordinate-recent.section --- prepare to preload recent \(preloadKeys.count) entries from index \(indices.first ?? 0)", component: LogComponents.preload)
            NotificationCenter.default.post(name: NSNotification.Name.Docs.addToPreloadQueue,
                                            object: nil,
                                            userInfo: [DocPreloaderManager.preloadNotificationKey: preloadKeys])
        }))
    }
}

extension SubordinateRecentListSection: SpaceSubSectionStateProvider {
    var canReloadState: Bool { viewModel.isActive }
    func handle(newState: SpaceListSubSection.ListState, helper: SpaceSubSectionStateHelper) {
        listState = newState
    }
    func didShowListAfterLoading() {
        DocsLogger.info("space.subordinate-recent.section --- preload visable items when end loading")
        preloadVisableItems()
        let dataModel = viewModel.dataModel
    }

    private func handle(newItems: [SpaceListItemType]) {
        let newState = newListState(from: newItems)
        stateHelper.handle(newState: newState)
    }

    private func newListState(from newItems: [SpaceListItemType]) -> ListState {
        guard newItems.isEmpty else { return .normal(itemTypes: newItems) }
        if viewModel.dataModel.listContainer.state == .restoring {
            DocsLogger.info("space.subordinate-recent.section --- DB data not ready, show loading")
            return .loading
        }
        guard viewModel.isReachable else { return .networkUnavailable }
        switch viewModel.serverDataState {
        case .loading:
            // 本地数据为空时，服务端请求还未结束，继续loading
            DocsLogger.info("space.subordinate-recent.section --- still loading server data, show loading")
            return .loading
        case .synced:
            // 服务端数据返回空，展示空白页
            let emptyTip = BundleI18n.SKResource.LarkCCM_CM_LeaderAccess_NoRecents_Empty
            let createButtonTitle = BundleI18n.SKResource.Doc_Facade_CreateDocument
            return .empty(description: emptyTip,
                          emptyType: .documentDefault,
                          createEnable: .just(false),
                          createButtonTitle: createButtonTitle) { _ in }
        case .fetchFailed:
            // 服务端数据拉取失败，本地数据为空，展示失败重试页
            return .failure(description: BundleI18n.SKResource.Doc_Facade_LoadFailed) { [weak self] in
                guard let self = self else { return }
                self.listState = .loading
                self.reloadInput.accept(.reloadSection(animated: false))
                self.viewModel.notifyPullToRefresh()
            }
        }
    }
}

extension SubordinateRecentListSection: SpaceRefreshPresenter {
    public func showRefreshTips(callback: @escaping () -> Void) {
        // 新刷新策略FG关闭时走旧的通知刷新逻辑
        guard !UserScopeNoChangeFG.MJ.newRecentListRefreshStrategy else {
            return
        }
        actionInput.accept(.showRefreshTips(callback: callback))
    }

    public func dismissRefreshTips(result: Result<Void, Error>) {
        let needScrollToTop: Bool
        switch result {
        case .success:
            needScrollToTop = true
        case let .failure(error):
            DocsLogger.error("space.subordinate-recent.list.vm -- dismiss refresh tips with error", error: error)
            needScrollToTop = false
        }
        actionInput.accept(.dismissRefreshTips(needScrollToTop: needScrollToTop))
    }
}
