//
//  BitableRecentListSection.swift
//  SKSpace
//
//  Created by ByteDance on 2023/10/27.
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
import UniverseDesignIcon
import SKUIKit
import LarkContainer

public final class BitableRecentListSection: BitableMultiListSubSection, BitableMultiListSectionHelperProtocol {

    public let identifier: String = BitableMultiListSubSectionConfig.recentIdentifier
    public var subSectionTitle: String = BitableMultiListSubSectionConfig.recentSectionTitle
    public let subSectionIdentifier: String = BitableMultiListSubSectionConfig.recentSectionIdentifier
    public var listTools: [SpaceListTool] = []
    
    private let displayModeRelay = BehaviorRelay<SpaceListDisplayMode>(value: .list)
    private var displayMode: SpaceListDisplayMode { .list }

    public var createIntent: SpaceCreateIntent {
        SpaceCreateIntent(context: UserScopeNoChangeFG.WWJ.newSpaceTabEnable ? .spaceNewHome : .recent,
                          source: .recent,
                          createButtonLocation: .blankPage)
    }

    private let reloadInput = PublishRelay<ReloadAction>()
    public var reloadSignal: Signal<ReloadAction> {
        reloadInput.asSignal()
    }

    private let actionInput = PublishRelay<Action>()
    public var actionSignal: Signal<Action> {
        actionInput.asSignal()
    }

    // UI 数据源，负责 CollectionView 的 Item 数据，注意只在主线程进行操作，且需要刷新 UI
    var listState = ListState.loading

    private let viewModel: BitableRecentListViewModel
    private var tracker: SpaceSubSectionTracker { viewModel.tracker }
    private lazy var stateHelper: SpaceSubSectionStateHelper = {
        let differ = SpaceListDifferFactory.createListStateDiffer()
        return SpaceSubSectionStateHelper(differ: differ,
                                          listID: identifier,
                                          stateProvider: self)
    }()
    
    public private(set) lazy var sectionHelper: BitableMultiListSectionDependency = {
        return BitableMultiListSectionDependency(delegate: self)
    }()
    
    private let disposeBag = DisposeBag()
    private let homeType: SpaceHomeType

    // 同步获取当前可见的 item 下标，用于 Rust 列表自动刷新的判断
    public var visableIndicesHelper: (() -> [Int])?

    public let userResolver: UserResolver
    
    deinit {
        NotificationCenter.default.post(name: .Docs.notifySelectedSpaceEntarnce, object: (SpaceEntranceSection.EntranceIdentifier.ipadHome, false))
    }
    
    init(userResolver: UserResolver,
         viewModel: BitableRecentListViewModel,
         homeType: SpaceHomeType = .spaceTab) {
        self.userResolver = userResolver
        self.homeType = homeType
        self.viewModel = viewModel
    }

    public func prepare() {
        stateHelper.actionSignal.emit(to: actionInput).disposed(by: disposeBag)
        stateHelper.reloadSignal.emit(to: reloadInput).disposed(by: disposeBag)
        viewModel.update(refreshPresenter: self)
        viewModel.itemsUpdated.observeOn(SerialDispatchQueueScheduler(internalSerialQueueName: "bitable.recent.section"))
            .subscribe(onNext: { [weak self] newItems in
                self?.handle(newItems: newItems)
            }).disposed(by: disposeBag)
        viewModel.actionSignal.emit(to: actionInput).disposed(by: disposeBag)
        viewModel.prepare()
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
        NotificationCenter.default.post(name: .Docs.notifySelectedSpaceEntarnce, object: (SpaceEntranceSection.EntranceIdentifier.ipadHome, true))
    }
    public func notifySectionWillDisappear() {
        viewModel.notifySectionWillDisappear()
        NotificationCenter.default.post(name: .Docs.notifySelectedSpaceEntarnce, object: (SpaceEntranceSection.EntranceIdentifier.ipadHome, false))
    }

    public func didShowSubSection() {
        viewModel.didBecomeActive()
        sectionHelper.didShowSubSection(self)
        switch listState {
        case .empty, .loading, .networkUnavailable:
            actionInput.accept(.stopPullToLoadMore(hasMore: false))
        default:
            break
        }
        DocsLogger.info("bitable.recent.section --- preload visable items when didShowSubSection")
        preloadVisableItems()
    }
    public func willHideSubSection() {
        viewModel.willResignActive()
    }

    func emptyListCreatButtonAction(button: UIView) {
        let context: SpaceCreateContext
        if homeType.isBaseHomeType(), let module = homeType.pageModule() {
            context = .bitableHome(module)
        } else {
            context = .recent
        }
        let intent = SpaceCreateIntent(context: UserScopeNoChangeFG.WWJ.newSpaceTabEnable ? .spaceNewHome : context, source: .other, createButtonLocation: .blankPage)
        self.actionInput.accept(.create(with: intent, sourceView: button))
    }
}

extension BitableRecentListSection: BitableMultiListSectionHelperDelegate {
    //dataSource
    var dataSourceListState: SpaceListSubSection.ListState { listState }
    var dataSourceDisplayMode: SpaceListDisplayMode { displayMode }
    var dataSourceCellTrackerModule: PageModule { tracker.module }
    var dataSourceSectionIdentifier: String { identifier }
    var dataSourceSectionIsActive: Bool { viewModel.isActive }
    //layout
    var layoutListState: SpaceListSubSection.ListState { listState }
    var layoutDisplayMode: SpaceListDisplayMode { displayMode }
    //common-delegate
    var providerListState: SpaceListSubSection.ListState { listState }
    var listViewModel: SpaceListViewModel { viewModel }
    func open(newScene: Scene) {
        actionInput.accept(.newScene(newScene))
    }
}

extension BitableRecentListSection: SpaceSectionDelegate {
    public func notifyDidEndDragging(willDecelerate: Bool) {
        if !willDecelerate {
            DocsLogger.info("bitable.recent.section --- preload visable items when end dragging")
            preloadVisableItems()
        }
    }

    public func notifyDidEndDecelerating() {
        DocsLogger.info("bitable.recent.section --- preload visable items when end decelerating")
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
            DocsLogger.info("bitable.recent.section --- prepare to preload recent \(preloadKeys.count) entries from index \(indices.first ?? 0)", component: LogComponents.preload)
            NotificationCenter.default.post(name: NSNotification.Name.Docs.addToPreloadQueue,
                                            object: nil,
                                            userInfo: [DocPreloaderManager.preloadNotificationKey: preloadKeys])
        }))
    }
}

extension BitableRecentListSection: SpaceSubSectionStateProvider {
    var canReloadState: Bool { viewModel.isActive }
    func handle(newState: SpaceListSubSection.ListState, helper: SpaceSubSectionStateHelper) {
        listState = newState
    }
    func didShowListAfterLoading() {
        DocsLogger.info("bitable.recent.section --- preload visable items when end loading")
        preloadVisableItems()
        let dataModel = viewModel.dataModel
        if case .defaultHome = homeType {
            SpacePerformanceTracker.shared.reportOpenFinish(filterOption: dataModel.filterHelper.selectedOption,
                                                            sortType: dataModel.sortHelper.selectedOption.type,
                                                            displayMode: displayMode,
                                                            scene: .recent)
        }
    }

    private func handle(newItems: [SpaceListItemType]) {
        let newState = newListState(from: newItems)
        stateHelper.handle(newState: newState)
    }

    private func newListState(from newItems: [SpaceListItemType]) -> ListState {
        guard newItems.isEmpty else { return .normal(itemTypes: newItems) }
        if viewModel.dataModel.listContainer.state == .restoring {
            DocsLogger.info("bitable.recent.section --- DB data not ready, show loading")
            return .loading
        }
        guard viewModel.isReachable else { return .networkUnavailable }
        switch viewModel.serverDataState {
        case .loading:
            // 本地数据为空时，服务端请求还未结束，继续loading
            DocsLogger.info("bitable.recent.section --- still loading server data, show loading")
            return .loading
        case .synced:
            // 服务端数据返回空，展示空白页
            let emptyTip = BundleI18n.SKResource.Bitable_HomeDashboard_NoContent_Desc
            let createButtonTitle = BundleI18n.SKResource.Bitable_HomeDashboard_CreateNew_Button
            return .empty(description: emptyTip,
                          emptyType: .documentDefault,
                          createEnable: .just(true),
                          createButtonTitle: createButtonTitle) { [weak self] button in
                guard let self = self else { return }
                // TODO: 初始化时配置好 context
                self.emptyListCreatButtonAction(button: button)
            }
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

extension BitableRecentListSection: SpaceRefreshPresenter {
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
            DocsLogger.error("bitable.recent.list.vm -- dismiss refresh tips with error", error: error)
            needScrollToTop = false
        }
        actionInput.accept(.dismissRefreshTips(needScrollToTop: needScrollToTop))
    }
}
