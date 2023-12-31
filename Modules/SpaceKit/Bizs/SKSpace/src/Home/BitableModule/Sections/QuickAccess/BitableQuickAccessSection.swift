//
//  BitableQuickAccessSection.swift
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
import SKUIKit
import LarkContainer


public final class BitableQuickAccessSection: BitableMultiListSubSection, BitableMultiListSectionHelperProtocol {
    public let userResolver: UserResolver
    public let identifier: String = BitableMultiListSubSectionConfig.quickAccessIdentifier
    public let subSectionTitle: String = BitableMultiListSubSectionConfig.quickAccessSectionTitle
    public let subSectionIdentifier: String = BitableMultiListSubSectionConfig.quickAccessSectionIdentifier
    public var listTools: [SpaceListTool] = []
    
    public var createIntent: SpaceCreateIntent {
        SpaceCreateIntent(context: .quickAccess, source: .quickAccess, createButtonLocation: .bottomRight)
    }

    private let displayModeRelay = BehaviorRelay<SpaceListDisplayMode>(value: .list)
    private var displayMode: SpaceListDisplayMode { .list }

    private let reloadInput = PublishRelay<ReloadAction>()
    public var reloadSignal: Signal<ReloadAction> {
        reloadInput.asSignal()
    }

    private let actionInput = PublishRelay<Action>()
    public var actionSignal: Signal<Action> {
        actionInput.asSignal()
    }

    var listState = ListState.loading

    private let viewModel: BitableQuickAccessViewModel
    private var tracker: SpaceSubSectionTracker { viewModel.tracker }
    private lazy var stateHelper: SpaceSubSectionStateHelper = {
        let differ = SpaceListDifferFactory.createListStateDiffer()
        return SpaceSubSectionStateHelper(differ: differ,
                                          listID: identifier,
                                          stateProvider: self)
    }()

    public private(set) lazy var sectionHelper: BitableMultiListSectionDependency = {
        BitableMultiListSectionDependency(delegate: self)
    }()

    private let disposeBag = DisposeBag()
    
    public init(userResolver: UserResolver, viewModel: BitableQuickAccessViewModel) {
        self.userResolver = userResolver
        self.viewModel = viewModel
    }

    public func prepare() {
        stateHelper.actionSignal.emit(to: actionInput).disposed(by: disposeBag)
        stateHelper.reloadSignal.emit(to: reloadInput).disposed(by: disposeBag)
        viewModel.itemsUpdated.observeOn(SerialDispatchQueueScheduler(internalSerialQueueName: "bitable.quickaccess.section"))
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

    public func notifySectionDidAppear() {}
    public func notifyViewDidLayoutSubviews(hostVCWidth: CGFloat) {}

    public func didShowSubSection() {
        viewModel.didBecomeActive()
        sectionHelper.didShowSubSection(self)
        DocsLogger.info("bitable.quickaccess.section --- preload visable items when didShowSubSection")
        preloadVisableItems()
    }
    public func willHideSubSection() {
        viewModel.willResignActive()
    }
}

extension BitableQuickAccessSection: BitableMultiListSectionHelperDelegate {
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

extension BitableQuickAccessSection: SpaceSectionDelegate {
    public func notifyDidEndDragging(willDecelerate: Bool) {
        if !willDecelerate {
            DocsLogger.info("bitable.quickaccess.section --- preload visable items when end dragging")
            preloadVisableItems()
        }
    }

    public func notifyDidEndDecelerating() {
        DocsLogger.info("bitable.quickaccess.section --- preload visable items when end decelerating")
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
                preloadKey.fromSource = PreloadFromSource(.quickAccess)
                return preloadKey
            }
            DocsLogger.info("bitable.quickaccess.section --- prepare to preload quickaccess \(preloadKeys.count) entries from index \(indices.first ?? 0)", component: LogComponents.preload)
            NotificationCenter.default.post(name: NSNotification.Name.Docs.addToPreloadQueue,
                                            object: nil,
                                            userInfo: [DocPreloaderManager.preloadNotificationKey: preloadKeys])
        }))
    }
}

extension BitableQuickAccessSection: SpaceSubSectionStateProvider {
    var canReloadState: Bool { viewModel.isActive }
    func handle(newState: SpaceListSubSection.ListState, helper: SpaceSubSectionStateHelper) {
        listState = newState
    }
    func didShowListAfterLoading() {
        DocsLogger.info("bitable.quickaccess.section --- preload visable items when end loading")
        preloadVisableItems()
    }

    private func handle(newItems: [SpaceListItemType]) {
        let newState = newListState(from: newItems)
        stateHelper.handle(newState: newState)
    }

    private func newListState(from newItems: [SpaceListItemType]) -> ListState {
        guard newItems.isEmpty else { return .normal(itemTypes: newItems) }
        if viewModel.dataModel.listContainer.state == .restoring {
            DocsLogger.info("bitable.quickaccess.section --- DB data not ready, show loading")
            return .loading
        }
        guard viewModel.isReachable else { return .networkUnavailable }
        switch viewModel.serverDataState {
            case .loading:
                // 本地数据为空时，服务端请求还未结束，继续loading
                DocsLogger.info("bitable.quickaccess.section --- still loading server data, show loading")
                return .loading
            case .synced:
                // 服务端数据返回空，展示空白页
                return .empty(description: BundleI18n.SKResource.Doc_List_Pin_Empty_Tips,
                          emptyType: .noContent,
                          createEnable: .just(false),
                          createButtonTitle: BundleI18n.SKResource.Doc_Facade_CreateDocument) { [weak self] button in
                            guard let self = self else { return }
                            let intent = SpaceCreateIntent(context: .quickAccess, source: .other, createButtonLocation: .blankPage)
                            self.actionInput.accept(.create(with: intent, sourceView: button))
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
